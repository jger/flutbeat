import 'package:flutter/material.dart';

import '../../models/telemetry_state.dart';
import '../../providers/telemetry_provider.dart';

class EcgOscilloscope extends StatefulWidget {
  const EcgOscilloscope({
    super.key,
    required this.state,
    this.notifier,
    this.onToggleAllUi,
    this.isAllUiVisible = false,
    this.onOpenSettings,
    this.onReconnect,
  });

  final TelemetryState state;
  final Telemetry? notifier;
  final VoidCallback? onToggleAllUi;
  final bool isAllUiVisible;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onReconnect;

  @override
  State<EcgOscilloscope> createState() => _EcgOscilloscopeState();
}

class _EcgOscilloscopeState extends State<EcgOscilloscope> {
  double _baseZoom = 1.0;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final notifier = widget.notifier;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final hasValidPulse =
        state.isConnected &&
        !state.isLeadOff &&
        state.metrics.signalQualityPercent >= 50 &&
        state.metrics.heartRateBpm > 0;
    final isNoisy =
        state.totalSamples >= 250 && state.metrics.signalQualityPercent < 50;
    final status = state.isFrozen
        ? 'FROZEN'
        : !state.isConnected
        ? state.connectionStatus == ConnectionStatus.connecting
              ? 'CONNECTING'
              : 'DISCONNECTED'
        : state.isLeadOff
        ? 'LEADS OFF'
        : state.totalSamples < 250
        ? 'WARMING UP'
        : isNoisy
        ? 'NOISY SIGNAL'
        : 'LIVE';
    final statusColor = state.isFrozen
        ? const Color(0xFF38BDF8)
        : !state.isConnected || state.isLeadOff || isNoisy
        ? Colors.amber
        : const Color(0xFF00FF88);

    final actions = Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        if (!widget.isAllUiVisible)
          Semantics(
            label: hasValidPulse
                ? '${state.metrics.heartRateBpm} beats per minute'
                : 'Heart rate unavailable',
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text.rich(
                TextSpan(
                  children: [
                    WidgetSpan(
                      child: Icon(
                        Icons.favorite_rounded,
                        size: 16,
                        color: hasValidPulse
                            ? const Color(0xFFEF4444)
                            : Colors.white38,
                      ),
                    ),
                    TextSpan(
                      text: hasValidPulse
                          ? '  ${state.metrics.heartRateBpm}'
                          : '  --',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: hasValidPulse
                            ? const Color(0xFF00FF88)
                            : Colors.white38,
                      ),
                    ),
                    const TextSpan(
                      text: ' BPM',
                      style: TextStyle(fontSize: 11, color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (isLandscape && widget.onReconnect != null)
          IconButton(
            tooltip: 'Reconnect ESP',
            onPressed: widget.onReconnect,
            icon: const Icon(Icons.refresh_rounded),
          ),
        if (isLandscape && widget.onOpenSettings != null)
          IconButton(
            tooltip: 'USB Settings',
            onPressed: widget.onOpenSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
        if (widget.onToggleAllUi != null)
          IconButton(
            key: const Key('toggle_ui_button'),
            tooltip: widget.isAllUiVisible
                ? 'Full Graph View (Hide Controls)'
                : 'Show Controls & Vitals',
            onPressed: widget.onToggleAllUi,
            icon: Icon(
              widget.isAllUiVisible
                  ? Icons.fullscreen_rounded
                  : Icons.tune_rounded,
            ),
          ),
      ],
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ColoredBox(
        color: const Color(0xFF070B11),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: const BoxDecoration(
                color: Color(0xFF101722),
                border: Border(bottom: BorderSide(color: Colors.white12)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final legend = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'SINGLE LEAD',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF00FF88),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${state.paperSpeed.label} • ${state.gain.mmPerMv} mm/mV • ${state.filterMode.label}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  );
                  if (constraints.maxWidth < 600) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        legend,
                        Align(alignment: Alignment.centerRight, child: actions),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: legend),
                      const SizedBox(width: 8),
                      actions,
                    ],
                  );
                },
              ),
            ),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onScaleStart: (_) => _baseZoom = state.verticalZoom,
                    onScaleUpdate: (details) {
                      final scale = details.verticalScale != 1.0
                          ? details.verticalScale
                          : details.scale;
                      if (scale != 1.0) {
                        notifier?.setVerticalZoom(_baseZoom * scale);
                      }
                    },
                    onDoubleTap: notifier?.resetVerticalZoom,
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _EcgCanvasPainter(state: state),
                      ),
                    ),
                  ),
                  if (state.isConnected && state.isLeadOff)
                    Center(
                      child: Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF27151C),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEF4444)),
                        ),
                        child: const Text(
                          'LEADS OFF DETECTED\nCheck electrode pads: RA, LA and RL',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF101722),
                border: Border(top: BorderSide(color: Colors.white12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Vertical Zoom Out (-)',
                    onPressed: notifier?.zoomOutVertical,
                    icon: const Icon(Icons.remove, size: 18),
                  ),
                  Text(
                    '${state.verticalZoom.toStringAsFixed(1)}x',
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                  IconButton(
                    tooltip: 'Vertical Zoom In (+)',
                    onPressed: notifier?.zoomInVertical,
                    icon: const Icon(Icons.add, size: 18),
                  ),
                  IconButton(
                    tooltip: 'Auto-Scale Waveform Height',
                    onPressed: notifier?.autoScaleVerticalZoom,
                    icon: const Icon(Icons.fit_screen_rounded, size: 18),
                  ),
                  if ((state.verticalZoom - 1).abs() > 0.05)
                    IconButton(
                      tooltip: 'Reset Zoom (1.0x)',
                      onPressed: notifier?.resetVerticalZoom,
                      icon: const Icon(
                        Icons.restart_alt_rounded,
                        size: 18,
                        color: Colors.amber,
                      ),
                    ),
                ],
              ),
            ),
          ],
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
      final isMajor =
          (x % majorGridPx).abs() < 0.1 ||
          (majorGridPx - (x % majorGridPx)).abs() < 0.1;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        isMajor ? majorPaint : minorPaint,
      );
    }

    // Horizontal grid lines
    for (double y = 0; y < size.height; y += minorGridPx) {
      final isMajor =
          (y % majorGridPx).abs() < 0.1 ||
          (majorGridPx - (y % majorGridPx)).abs() < 0.1;
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

  void _drawWaveform(Canvas canvas, Size size) {
    final buffer = state.buffer;
    final cap = buffer.length;
    final startX = 0.0;
    final waveWidth = size.width;
    if (waveWidth <= 10 ||
        size.height < 8 ||
        cap == 0 ||
        state.totalSamples == 0) {
      return;
    }

    final centerY = size.height / 2.0;
    final gainScale = state.gain.mmPerMv * pxPerMm * state.verticalZoom;

    final tracePaint = Paint()
      ..color =
          const Color(0xFF00FF88) // Phosphor clinical green
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
        if (identical(pt, EcgPointData.zero)) {
          first = true;
          continue;
        }
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
      final cursorPt = buffer[(state.cursorIndex - 1 + cap) % cap];
      final cursorVal = state.filterMode == SignalFilterMode.dspFiltered
          ? cursorPt.filteredMv
          : cursorPt.voltageMv;
      final cursorY = (centerY - (cursorVal * gainScale)).clamp(
        4.0,
        size.height - 4.0,
      );

      final cursorGlow = Paint()
        ..shader =
            RadialGradient(
              colors: [
                Colors.white,
                const Color(0xFF00FF88),
                const Color(0xFF00FF88).withValues(alpha: 0.0),
              ],
            ).createShader(
              Rect.fromCircle(center: Offset(cursorX, cursorY), radius: 12),
            );

      canvas.drawCircle(Offset(cursorX, cursorY), 12, cursorGlow);
      canvas.drawCircle(
        Offset(cursorX, cursorY),
        3.5,
        Paint()..color = Colors.white,
      );
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
