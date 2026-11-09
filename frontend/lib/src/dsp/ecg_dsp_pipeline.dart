import 'dart:collection';
import 'dart:math' as math;
import '../models/cardiac_metrics.dart';

const double kSampleRateHz = 250.0;
const double kAdcMax = 1023.0;
const double kVrefMv = 3200.0;
const double kAd8232Gain = 1100.0;

/// Maps raw 10-bit ADC value (0..1023) to physiological cardiac millivolts
double adcToMv(int rawAdc) {
  final centered = rawAdc.toDouble() - (kAdcMax / 2.0);
  return (centered * (kVrefMv / kAdcMax)) / kAd8232Gain;
}

/// 0.5 Hz High-Pass DC-blocking filter (eliminates baseline drift)
class DcBlocker {
  DcBlocker({this.alpha = 0.992});

  final double alpha;
  double _prevX = 0.0;
  double _prevY = 0.0;

  double process(double x) {
    final y = x - _prevX + alpha * _prevY;
    _prevX = x;
    _prevY = y;
    return y;
  }

  void reset() {
    _prevX = 0.0;
    _prevY = 0.0;
  }
}

/// 50 Hz Biquad Notch Filter at 250 Hz sampling rate to suppress mains hum
class NotchFilter50Hz {
  NotchFilter50Hz() {
    final w0 = 2.0 * math.pi * 50.0 / kSampleRateHz;
    const q = 8.0;
    final alpha = math.sin(w0) / (2.0 * q);
    final cosW0 = math.cos(w0);

    final a0 = 1.0 + alpha;
    _b0 = 1.0 / a0;
    _b1 = (-2.0 * cosW0) / a0;
    _b2 = 1.0 / a0;
    _a1 = (-2.0 * cosW0) / a0;
    _a2 = (1.0 - alpha) / a0;
  }

  late final double _b0;
  late final double _b1;
  late final double _b2;
  late final double _a1;
  late final double _a2;

  double _x1 = 0.0;
  double _x2 = 0.0;
  double _y1 = 0.0;
  double _y2 = 0.0;

  double process(double x) {
    final y = _b0 * x + _b1 * _x1 + _b2 * _x2 - _a1 * _y1 - _a2 * _y2;
    _x2 = _x1;
    _x1 = x;
    _y2 = _y1;
    _y1 = y;
    return y;
  }

  void reset() {
    _x1 = 0.0;
    _x2 = 0.0;
    _y1 = 0.0;
    _y2 = 0.0;
  }
}

/// 40 Hz Low-Pass Smoothing Filter to suppress high-frequency muscle noise
class LowPass40Hz {
  LowPass40Hz() {
    final w0 = 2.0 * math.pi * 40.0 / kSampleRateHz;
    final cosW0 = math.cos(w0);
    final sinW0 = math.sin(w0);
    final alpha = sinW0 / (2.0 * (1.0 / math.sqrt2));

    final a0 = 1.0 + alpha;
    _b0 = ((1.0 - cosW0) / 2.0) / a0;
    _b1 = (1.0 - cosW0) / a0;
    _b2 = ((1.0 - cosW0) / 2.0) / a0;
    _a1 = (-2.0 * cosW0) / a0;
    _a2 = (1.0 - alpha) / a0;
  }

  late final double _b0;
  late final double _b1;
  late final double _b2;
  late final double _a1;
  late final double _a2;

  double _x1 = 0.0;
  double _x2 = 0.0;
  double _y1 = 0.0;
  double _y2 = 0.0;

  double process(double x) {
    final y = _b0 * x + _b1 * _x1 + _b2 * _x2 - _a1 * _y1 - _a2 * _y2;
    _x2 = _x1;
    _x1 = x;
    _y2 = _y1;
    _y1 = y;
    return y;
  }

  void reset() {
    _x1 = 0.0;
    _x2 = 0.0;
    _y1 = 0.0;
    _y2 = 0.0;
  }
}

/// Pan-Tompkins QRS Detection Engine
class PanTompkinsDetector {
  PanTompkinsDetector()
      : mwiWindowSize = (0.12 * kSampleRateHz).round().clamp(1, 100),
        refractorySamples = (0.26 * kSampleRateHz).round(); // 65 samples = 260 ms

  final int mwiWindowSize;
  final int refractorySamples;

  final List<double> _derivBuffer = List.filled(5, 0.0);
  int _derivIdx = 0;

  final Queue<double> _mwiBuffer = Queue<double>();
  double _mwiSum = 0.0;

  double _mwiPrev2 = 0.0;
  double _mwiPrev1 = 0.0;

  double _threshold = 0.005;
  double _noiseLevel = 0.001;
  double _signalLevel = 0.02;
  int _refractoryCount = 0;
  int _samplesSinceLastPeak = 0;

  bool process(double filteredSample) {
    // 1. Derivative: y[n] = (2x[n] + x[n-1] - x[n-3] - 2x[n-4]) / 8
    _derivBuffer[_derivIdx] = filteredSample;
    final x0 = _derivBuffer[_derivIdx];
    final x1 = _derivBuffer[(_derivIdx + 4) % 5];
    final x3 = _derivBuffer[(_derivIdx + 2) % 5];
    final x4 = _derivBuffer[(_derivIdx + 1) % 5];
    _derivIdx = (_derivIdx + 1) % 5;

    final deriv = (2.0 * x0 + x1 - x3 - 2.0 * x4) / 8.0;

    // 2. Squaring
    final squared = deriv * deriv;

    // 3. Moving-Window Integration (MWI)
    _mwiBuffer.addLast(squared);
    _mwiSum += squared;
    if (_mwiBuffer.length > mwiWindowSize) {
      final old = _mwiBuffer.removeFirst();
      _mwiSum = math.max(0.0, _mwiSum - old);
    }
    final mwiCurr = _mwiSum / mwiWindowSize;

    _samplesSinceLastPeak++;

    // 4. Searchback mechanism: if no beat in 1.5 seconds, gradually lower threshold
    if (_samplesSinceLastPeak > (1.5 * kSampleRateHz).round()) {
      _threshold = math.max(_noiseLevel * 1.2, _threshold * 0.995);
    }

    if (_refractoryCount > 0) {
      _refractoryCount--;
      _mwiPrev2 = _mwiPrev1;
      _mwiPrev1 = mwiCurr;
      return false;
    }

    // 5. Peak Detection on MWI (detect local maximum)
    bool isPeak = false;
    if (_mwiPrev1 > _mwiPrev2 && _mwiPrev1 >= mwiCurr && _mwiPrev1 > 0.00005) {
      final candidatePeak = _mwiPrev1;

      if (candidatePeak > _threshold) {
        _signalLevel = 0.125 * candidatePeak + 0.875 * _signalLevel;
        _threshold = _noiseLevel + 0.25 * (_signalLevel - _noiseLevel);
        _refractoryCount = refractorySamples;
        _samplesSinceLastPeak = 0;
        isPeak = true;
      } else {
        _noiseLevel = 0.125 * candidatePeak + 0.875 * _noiseLevel;
        _threshold = _noiseLevel + 0.25 * (_signalLevel - _noiseLevel);
      }
    }

    _mwiPrev2 = _mwiPrev1;
    _mwiPrev1 = mwiCurr;

    return isPeak;
  }

  void reset() {
    _derivBuffer.fillRange(0, 5, 0.0);
    _derivIdx = 0;
    _mwiBuffer.clear();
    _mwiSum = 0.0;
    _mwiPrev2 = 0.0;
    _mwiPrev1 = 0.0;
    _threshold = 0.005;
    _noiseLevel = 0.001;
    _signalLevel = 0.02;
    _refractoryCount = 0;
    _samplesSinceLastPeak = 0;
  }
}

/// Output bundle from processing a single ECG raw sample
class ProcessedEcgSample {
  const ProcessedEcgSample({
    required this.timestampMs,
    required this.rawAdc,
    required this.voltageMv,
    required this.filteredMv,
    required this.isRPeak,
    required this.leadOff,
    required this.metrics,
    this.event,
  });

  final int timestampMs;
  final int rawAdc;
  final double voltageMv;
  final double filteredMv;
  final bool isRPeak;
  final bool leadOff;
  final CardiacMetrics metrics;
  final CardiacEvent? event;
}

/// Real-Time Digital Signal Processing & Cardiac Analytics Pipeline
class EcgDspPipeline {
  final DcBlocker _dcBlocker = DcBlocker();
  final NotchFilter50Hz _notchFilter = NotchFilter50Hz();
  final LowPass40Hz _lowPass = LowPass40Hz();
  final PanTompkinsDetector _detector = PanTompkinsDetector();

  int _sampleCount = 0;
  int? _lastRPeakSample;
  final List<int> _rrIntervalsMs = [];
  int _totalBeats = 0;
  int _currentBpm = 0;
  int _currentRrMs = 0;
  int _lastBeatTsMs = 0;
  int _eventSequence = 0;
  LeadStatus _lastLeadStatus = LeadStatus.leadsConnected;

  ProcessedEcgSample processSample({
    required int rawAdc,
    required bool loPlus,
    required bool loMinus,
    required int timestampMs,
  }) {
    _sampleCount++;

    // 1. Determine Lead-Off Status
    final leadStatus = switch ((loPlus, loMinus)) {
      (true, true) => LeadStatus.leadOffBoth,
      (true, false) => LeadStatus.leadOffPositive,
      (false, true) => LeadStatus.leadOffNegative,
      _ => LeadStatus.leadsConnected,
    };
    final isLeadOff = leadStatus != LeadStatus.leadsConnected;

    // 2. Voltage conversion & DSP filtering
    final voltageMv = adcToMv(rawAdc);
    final dcCleaned = _dcBlocker.process(voltageMv);
    final notched = _notchFilter.process(dcCleaned);
    final filteredMv = _lowPass.process(notched);

    // 3. Pan-Tompkins QRS Detection
    bool isRPeak = false;
    CardiacEvent? event;

    if (!isLeadOff) {
      isRPeak = _detector.process(filteredMv);
      if (isRPeak) {
        _totalBeats++;
        _lastBeatTsMs = timestampMs;

        if (_lastRPeakSample != null) {
          final deltaSamples = _sampleCount - _lastRPeakSample!;
          final rrMs = ((deltaSamples / kSampleRateHz) * 1000.0).round();

          // Physiologically valid heart rate bounds: 30 BPM (2000 ms) to 230 BPM (260 ms)
          if (rrMs >= 260 && rrMs <= 2000) {
            _currentRrMs = rrMs;
            _rrIntervalsMs.add(rrMs);
            if (_rrIntervalsMs.length > 8) {
              _rrIntervalsMs.removeAt(0);
            }

            // Robust median / trimmed-mean computation to reject outliers
            final sorted = List<int>.from(_rrIntervalsMs)..sort();
            double avgRr;
            if (sorted.length >= 4) {
              final trimmed = sorted.sublist(1, sorted.length - 1);
              avgRr = trimmed.reduce((a, b) => a + b) / trimmed.length;
            } else {
              avgRr = sorted.reduce((a, b) => a + b) / sorted.length;
            }
            _currentBpm = (60000.0 / avgRr).round().clamp(30, 230);
          }
        }
        _lastRPeakSample = _sampleCount;

        event = CardiacEvent(
          type: CardiacEventType.rPeak,
          description: 'R-Peak Detected — Heart Rate: $_currentBpm BPM',
          timestampUnixMillis: timestampMs,
          heartRateBpm: _currentBpm,
          sequenceNumber: ++_eventSequence,
        );
      }
    } else {
      _detector.reset();
      _lastRPeakSample = null;
    }

    // Lead status transition events
    if (leadStatus != _lastLeadStatus) {
      if (isLeadOff) {
        event = CardiacEvent(
          type: CardiacEventType.leadOff,
          description: 'Electrode lead disconnected: ${leadStatus.name}',
          timestampUnixMillis: timestampMs,
          sequenceNumber: ++_eventSequence,
        );
      } else {
        event = CardiacEvent(
          type: CardiacEventType.leadRestored,
          description: 'Electrode leads attached. Signal restored.',
          timestampUnixMillis: timestampMs,
          sequenceNumber: ++_eventSequence,
        );
      }
      _lastLeadStatus = leadStatus;
    }

    // 4. Compute HRV (SDNN & RMSSD)
    double sdnn = 35.0;
    double rmssd = 28.0;

    if (_rrIntervalsMs.length >= 3) {
      final n = _rrIntervalsMs.length.toDouble();
      final mean = _rrIntervalsMs.reduce((a, b) => a + b) / n;

      final variance = _rrIntervalsMs.fold<double>(
            0.0,
            (acc, v) {
              final diff = v.toDouble() - mean;
              return acc + diff * diff;
            },
          ) /
          (n - 1.0);
      sdnn = math.sqrt(variance);

      double diffSumSq = 0.0;
      for (int i = 1; i < _rrIntervalsMs.length; i++) {
        final diff = (_rrIntervalsMs[i] - _rrIntervalsMs[i - 1]).toDouble();
        diffSumSq += diff * diff;
      }
      rmssd = math.sqrt(diffSumSq / (n - 1.0));
    }

    // 5. Rhythm Classification
    final rhythm = isLeadOff || _currentBpm == 0
        ? RhythmClassification.noSignal
        : _currentBpm < 60
            ? RhythmClassification.bradycardia
            : _currentBpm > 100
                ? RhythmClassification.tachycardia
                : sdnn > 65.0
                    ? RhythmClassification.irregularArrhythmia
                    : RhythmClassification.normalSinus;

    final signalQuality = isLeadOff
        ? 0
        : _rrIntervalsMs.isEmpty
            ? 75
            : 98;

    final metrics = CardiacMetrics(
      heartRateBpm: isLeadOff ? 0 : _currentBpm,
      rrIntervalMs: isLeadOff ? 0 : _currentRrMs,
      hrvSdnnMs: isLeadOff ? 0.0 : ((sdnn * 10).round() / 10.0),
      hrvRmssdMs: isLeadOff ? 0.0 : ((rmssd * 10).round() / 10.0),
      leadStatus: leadStatus,
      rhythm: rhythm,
      signalQualityPercent: signalQuality,
      totalBeats: _totalBeats,
      lastBeatTimestampMs: _lastBeatTsMs,
    );

    return ProcessedEcgSample(
      timestampMs: timestampMs,
      rawAdc: rawAdc,
      voltageMv: voltageMv,
      filteredMv: filteredMv,
      isRPeak: isRPeak,
      leadOff: isLeadOff,
      metrics: metrics,
      event: event,
    );
  }

  void reset() {
    _dcBlocker.reset();
    _notchFilter.reset();
    _lowPass.reset();
    _detector.reset();
    _sampleCount = 0;
    _lastRPeakSample = null;
    _rrIntervalsMs.clear();
    _totalBeats = 0;
    _currentBpm = 0;
    _currentRrMs = 0;
    _lastBeatTsMs = 0;
    _lastLeadStatus = LeadStatus.leadsConnected;
  }
}
