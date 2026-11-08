import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/telemetry_state.dart';
import '../../providers/telemetry_provider.dart';

class BlinkingHeartbeatDot extends ConsumerStatefulWidget {
  const BlinkingHeartbeatDot({super.key});

  @override
  ConsumerState<BlinkingHeartbeatDot> createState() =>
      _BlinkingHeartbeatDotState();
}

class _BlinkingHeartbeatDotState extends ConsumerState<BlinkingHeartbeatDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final telemetry = ref.watch(telemetryProvider);
    final status = telemetry.connectionStatus;

    Color color;
    String statusText;
    bool shouldAnimate = true;

    switch (status) {
      case ConnectionStatus.connected:
        color = const Color(0xFF10B981); // Emerald green
        statusText = 'Connected • Heartbeat Active';
        break;
      case ConnectionStatus.connecting:
        color = const Color(0xFFF59E0B); // Amber
        statusText = 'Connecting to Pi Node...';
        break;
      case ConnectionStatus.error:
        color = const Color(0xFFEF4444); // Red
        statusText = 'Connection Error: ${telemetry.errorMessage ?? "Unknown"}';
        shouldAnimate = false;
        break;
      case ConnectionStatus.disconnected:
        color = const Color(0xFF6B7280); // Gray
        statusText = 'Disconnected';
        shouldAnimate = false;
        break;
    }

    if (!shouldAnimate && _controller.isAnimating) {
      _controller.stop();
    } else if (shouldAnimate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }

    final timeFormatter = DateFormat('HH:mm:ss');
    final lastSeen = telemetry.lastHeartbeat != null
        ? 'Last tick: ${timeFormatter.format(telemetry.lastHeartbeat!)}'
        : 'Awaiting first packet';

    final displayLabel = switch (status) {
      ConnectionStatus.connected => 'LIVE',
      ConnectionStatus.connecting => 'SYNC',
      ConnectionStatus.disconnected => 'OFFLINE',
      ConnectionStatus.error => 'ERR',
    };

    return Tooltip(
      message: '$statusText\n$lastSeen',
      preferBelow: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final scale = shouldAnimate ? _scaleAnimation.value : 1.0;
                final opacity = shouldAnimate ? _opacityAnimation.value : 0.8;

                return Container(
                  width: 14,
                  height: 14,
                  alignment: Alignment.center,
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: opacity),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: shouldAnimate ? 0.6 : 0.2),
                            blurRadius: shouldAnimate ? 8.0 : 2.0,
                            spreadRadius: shouldAnimate ? 2.0 : 0.0,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 6),
            Text(
              displayLabel,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
