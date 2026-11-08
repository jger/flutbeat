import 'dart:math' as math;
import 'ecg_dsp_pipeline.dart';

/// Morphological P-Q-R-S-T Synthetic ECG Waveform Generator
class EcgSimulator {
  EcgSimulator({int targetBpm = 72}) : _targetBpm = targetBpm.clamp(40, 180);

  int _targetBpm;
  double _phase = 0.0; // [0, 2*PI)
  int _sampleIndex = 0;
  bool _leadOffActive = false;

  int get targetBpm => _targetBpm;
  set targetBpm(int bpm) => _targetBpm = bpm.clamp(40, 180);

  bool get isLeadOff => _leadOffActive;
  set leadOff(bool active) => _leadOffActive = active;

  /// Generates the next sample at 250 Hz (every 4 ms)
  /// Returns a record: (rawAdc, loPlus, loMinus)
  ({int rawAdc, bool loPlus, bool loMinus}) nextSample() {
    _sampleIndex++;

    if (_leadOffActive) {
      return (rawAdc: 1023, loPlus: true, loMinus: true);
    }

    // Heart rate with natural Respiratory Sinus Arrhythmia (RSA) modulation (~0.2 Hz)
    const rsaFreq = 0.2; // 12 breaths per minute
    const rsaAmp = 0.04; // 4% heart rate modulation
    final timeSec = _sampleIndex / kSampleRateHz;
    final instantaneousBpm =
        _targetBpm * (1.0 + rsaAmp * math.sin(2.0 * math.pi * rsaFreq * timeSec));

    final frequencyHz = instantaneousBpm / 60.0;
    final phaseStep = (2.0 * math.pi * frequencyHz) / kSampleRateHz;
    _phase = (_phase + phaseStep) % (2.0 * math.pi);

    // Normalize phase around R-peak (0) in range [-PI, +PI)
    double theta = _phase;
    if (theta > math.pi) {
      theta -= 2.0 * math.pi;
    }

    // McSharry-style Gaussian P-Q-R-S-T wave components
    final pWave = _gaussian(theta, -0.35 * math.pi, 0.16, 0.12);
    final qWave = _gaussian(theta, -0.09 * math.pi, -0.18, 0.04);
    final rPeak = _gaussian(theta, 0.0, 1.45, 0.05);
    final sWave = _gaussian(theta, 0.09 * math.pi, -0.32, 0.04);
    final tWave = _gaussian(theta, 0.48 * math.pi, 0.32, 0.22);

    final cardiacMv = pWave + qWave + rPeak + sWave + tWave;

    // Subtle baseline physiological micro-noise (~0.015 mV)
    final noise = 0.015 * (math.sin(13.0 * _phase) + math.cos(29.0 * _phase));
    final totalMv = cardiacMv + noise;

    // Convert physiological mV back to 10-bit raw ADC reading (0..1023)
    final centeredAdc = (totalMv * kAd8232Gain * kAdcMax) / kVrefMv;
    final rawAdc = (512.0 + centeredAdc).clamp(0.0, 1023.0).round();

    return (rawAdc: rawAdc, loPlus: false, loMinus: false);
  }

  static double _gaussian(double theta, double center, double amplitude, double width) {
    final diff = theta - center;
    return amplitude * math.exp(-0.5 * math.pow(diff / width, 2));
  }

  void reset() {
    _phase = 0.0;
    _sampleIndex = 0;
  }
}

