import 'dart:math' as math;

/// Electrical heuristics only. Not a validated ECG quality or diagnostic score.
class SignalCheck {
  const SignalCheck(this.quality, this.mainsFraction, this.clippedFraction);
  final int quality;
  final double mainsFraction;
  final double clippedFraction;
  factory SignalCheck.fromAdc(List<double> adc) {
    if (adc.length < 125) return const SignalCheck(0, 0, 0);
    final n = adc.length;
    final mean = adc.reduce((a, b) => a + b) / n;
    final energy = adc.fold<double>(
      0,
      (sum, x) => sum + (x - mean) * (x - mean),
    );
    final clipped = adc.where((x) => x <= 5 || x >= 1018).length / n;
    if (energy / n < 1) return SignalCheck(0, 0, clipped);
    double mainsEnergy = 0;
    // Adjacent frequency bins account for a small mains/sample-clock drift.
    for (final hz in [49.0, 50.0, 51.0]) {
      double re = 0, im = 0;
      for (int i = 0; i < n; i++) {
        final phase = 2 * math.pi * hz * i / 250;
        re += (adc[i] - mean) * math.cos(phase);
        im += (adc[i] - mean) * math.sin(phase);
      }
      mainsEnergy += 2 * (re * re + im * im) / n;
    }
    final fraction = (mainsEnergy / energy).clamp(0.0, 1.0);
    var score = (100 * (1 - fraction)).round();
    if (fraction > 0.5) score = math.min(score, 25);
    if (clipped > 0.01) score = math.min(score, 20);
    return SignalCheck(score, fraction, clipped);
  }
}

class IntervalReview {
  IntervalReview(List<Map<String, dynamic>> rows) {
    final samples = rows.where((r) => r['row_type'] == 'sample').toList();
    final raw = samples.map((r) => (r['raw_adc'] as num).toDouble()).toList();
    // Inspect 1-second blocks, matching the live estimator's resolution.
    final checks = <SignalCheck>[];
    for (int i = 0; i + 250 <= raw.length; i += 250) {
      checks.add(SignalCheck.fromAdc(raw.sublist(i, i + 250)));
    }
    poorSignal =
        checks.isEmpty ||
        checks.any((c) => c.quality < 50) ||
        samples.any(
          (r) =>
              r['lead_off'] == true ||
              (r['lead_status'] != null &&
                  r['lead_status'] != 'leadsConnected'),
        );
    mainsPercent = checks.isEmpty
        ? 0
        : checks.map((c) => c.mainsFraction).reduce((a, b) => a + b) /
              checks.length *
              100;
    final peaks = samples.where((r) => r['is_r_peak'] == true).toList();
    for (int i = 1; i < peaks.length; i++) {
      intervals.add(
        ((peaks[i]['offset_ms'] as num) - (peaks[i - 1]['offset_ms'] as num))
            .toDouble(),
      );
    }
    if (intervals.isNotEmpty) {
      final sorted = List<double>.from(intervals)..sort();
      medianRr = sorted.length.isOdd
          ? sorted[sorted.length ~/ 2]
          : (sorted[sorted.length ~/ 2 - 1] + sorted[sorted.length ~/ 2]) / 2;
      meanRr = intervals.reduce((a, b) => a + b) / intervals.length;
      suspectedDetectionErrors = intervals.any(
        (rr) =>
            rr < 300 || rr > 2000 || (rr - medianRr!).abs() > medianRr! * 0.25,
      );
      if (intervals.length >= 30 && !poorSignal && !suspectedDetectionErrors) {
        sdnn = math.sqrt(
          intervals.fold<double>(
                0,
                (sum, rr) => sum + (rr - meanRr!) * (rr - meanRr!),
              ) /
              (intervals.length - 1),
        );
        double sq = 0;
        for (int i = 1; i < intervals.length; i++) {
          sq += math.pow(intervals[i] - intervals[i - 1], 2);
        }
        rmssd = math.sqrt(sq / (intervals.length - 1));
      }
    }
  }
  final intervals = <double>[];
  late final bool poorSignal;
  late final double mainsPercent;
  bool suspectedDetectionErrors = false;
  double? meanRr, medianRr, sdnn, rmssd;
  bool get usable =>
      !poorSignal && !suspectedDetectionErrors && intervals.length >= 3;
}
