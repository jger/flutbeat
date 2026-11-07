import 'package:flutter/material.dart';
import '../../models/telemetry_state.dart';

class EcgOscilloscope extends StatelessWidget {
  const EcgOscilloscope({
    super.key,
    required this.state,
  });

  final TelemetryState state;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: const Color(0xFF070B11), // Deep medical ICU monitor dark background
        child: CustomPaint(
          painter: _EcgCanvasPainter(state: state),
          child: Stack(
            children: [
              // Standard medical paper legend in top-left corner
              Positioned(
                top: 8,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white12, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'LEAD II  ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF00FF88),
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        '${state.paperSpeed.label} • ${state.gain.label} • ${state.filterMode.label}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Frozen indicator overlay
              if (state.isFrozen)
                Positioned(
                  top: 8,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF00E5FF)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pause_circle_filled, size: 14, color: Color(0xFF00E5FF)),
                        SizedBox(width: 4),
                        Text(
                          'TRACE FROZEN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF00E5FF),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Lead-Off Alert Banner
              if (state.isLeadOff)
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 28),
                        SizedBox(width: 12),
                        Flexible(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LEADS OFF DETECTED',
                                style: TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Check electrode pads (RA: Right Arm, LA: Left Arm, RL: Right Leg)',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EcgCanvasPainter extends CustomPainter {
  _EcgCanvasPainter({required this.state});

  final TelemetryState state;

  // Grid sizing: 1 mm ~ 5.0 canvas pixels, 5 mm major square ~ 25.0 pixels
  static const double pxPerMm = 5.0;
  static const double minorGridPx = 1.0 * pxPerMm; // 5 px
  static const double majorGridPx = 5.0 * pxPerMm; // 25 px

  @override
  void paint(Canvas canvas, Size size) {
    _drawMedicalGrid(canvas, size);
    _drawCalibrationPulse(canvas, size);
    _drawWaveform(canvas, size);
  }

  void _drawMedicalGrid(Canvas canvas, Size size) {
    final minorPaint = Paint()
      ..color = const Color(0xFF1E2835).withValues(alpha: 0.25)
      ..strokeWidth = 0.5;

    final majorPaint = Paint()
      ..color = const Color(0xFF283B4D).withValues(alpha: 0.45)
      ..strokeWidth = 1.0;

    // Vertical grid lines
    for (double x = 0; x < size.width; x += minorGridPx) {
      final isMajor = (x % majorGridPx).abs() < 0.1 || (majorGridPx - (x % majorGridPx)).abs() < 0.1;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        isMajor ? majorPaint : minorPaint,
      );
    }

    // Horizontal grid lines
    for (double y = 0; y < size.height; y += minorGridPx) {
      final isMajor = (y % majorGridPx).abs() < 0.1 || (majorGridPx - (y % majorGridPx)).abs() < 0.1;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        isMajor ? majorPaint : minorPaint,
      );
    }

    // Baseline center line
    final baselinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(0, size.height / 2.0),
      Offset(size.width, size.height / 2.0),
      baselinePaint,
    );
  }

  void _drawCalibrationPulse(Canvas canvas, Size size) {
    // Standard medical calibration pulse: 1.0 mV square wave on left margin (X: 16 to 36)
    final calHeightPx = 1.0 * state.gain.mmPerMv * pxPerMm; // 1 mV height in pixels
    final centerY = size.height / 2.0;

    final pulsePaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    path.moveTo(8, centerY);
    path.lineTo(14, centerY);
    path.lineTo(14, centerY - calHeightPx);
    path.lineTo(26, centerY - calHeightPx);
    path.lineTo(26, centerY);
    path.lineTo(32, centerY);

    canvas.drawPath(path, pulsePaint);

    // Label "1mV"
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '1mV',
        style: TextStyle(
          color: Color(0xFF38BDF8),
          fontSize: 8,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(15, centerY - calHeightPx - 11));
  }

  void _drawWaveform(Canvas canvas, Size size) {
    final buffer = state.buffer;
    final cap = buffer.length;
    final startX = 36.0; // Offset after calibration pulse
    final waveWidth = size.width - startX;
    if (waveWidth <= 10) return;

    final centerY = size.height / 2.0;
    final gainScale = state.gain.mmPerMv * pxPerMm;

    final tracePaint = Paint()
      ..color = const Color(0xFF00FF88) // Phosphor clinical green
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2.0;

    final glowPaint = Paint()
      ..color = const Color(0xFF00FF88).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.5;

    final rPeakDotPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.fill;

    if (state.sweepMode == SweepMode.eraseBarSweep) {
      // Classic Hospital Sweep Mode:
      // The cursor maps to X = startX + (cursorIndex / cap) * waveWidth
      final cursorFraction = state.cursorIndex / cap;
      final cursorX = startX + cursorFraction * waveWidth;
      const eraseGapPx = 30.0; // 30 px blanking bar ahead of cursor

      final path = Path();
      bool first = true;

      for (int i = 0; i < cap; i++) {
        final x = startX + (i / cap) * waveWidth;

        // Skip drawing inside the erase bar gap
        final distAhead = (x - cursorX);
        if (distAhead > 0 && distAhead < eraseGapPx) {
          first = true;
          continue;
        }

        final pt = buffer[i];
        final valMv = state.filterMode == SignalFilterMode.dspFiltered
            ? pt.filteredMv
            : pt.voltageMv;

        // Y deflection: -1.0 mV points up on the screen
        final y = (centerY - (valMv * gainScale)).clamp(4.0, size.height - 4.0);

        if (first) {
          path.moveTo(x, y);
          first = false;
        } else {
          path.lineTo(x, y);
        }

        // Draw R-peak indicator dot
        if (pt.isRPeak && !pt.leadOff) {
          canvas.drawCircle(Offset(x, y - 4), 3.0, rPeakDotPaint);
        }
      }

      // Draw glowing trace
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, tracePaint);

      // Draw leading sweep cursor (glowing phosphor dot & beam)
      final cursorPt = buffer[state.cursorIndex % cap];
      final cursorVal = state.filterMode == SignalFilterMode.dspFiltered
          ? cursorPt.filteredMv
          : cursorPt.voltageMv;
      final cursorY = (centerY - (cursorVal * gainScale)).clamp(4.0, size.height - 4.0);

      final cursorGlow = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white,
            const Color(0xFF00FF88),
            const Color(0xFF00FF88).withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cursorX, cursorY), radius: 12));

      canvas.drawCircle(Offset(cursorX, cursorY), 12, cursorGlow);
      canvas.drawCircle(Offset(cursorX, cursorY), 3.5, Paint()..color = Colors.white);
    } else {
      // Continuous Left-Scrolling Mode:
      // The newest sample is on the right (X = size.width), oldest on the left (X = startX)
      final path = Path();
      bool first = true;

      for (int i = 0; i < cap; i++) {
        // Chronological order: (cursorIndex + i) % cap
        final idx = (state.cursorIndex + i) % cap;
        final x = startX + (i / cap) * waveWidth;
        final pt = buffer[idx];

        final valMv = state.filterMode == SignalFilterMode.dspFiltered
            ? pt.filteredMv
            : pt.voltageMv;

        final y = (centerY - (valMv * gainScale)).clamp(4.0, size.height - 4.0);

        if (first) {
          path.moveTo(x, y);
          first = false;
        } else {
          path.lineTo(x, y);
        }

        if (pt.isRPeak && !pt.leadOff) {
          canvas.drawCircle(Offset(x, y - 4), 3.0, rPeakDotPaint);
        }
      }

      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, tracePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EcgCanvasPainter oldDelegate) {
    return true; // Live 60 FPS repaint on each incoming gRPC chunk
  }
}
