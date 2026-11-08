import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/config_provider.dart';
import '../../providers/telemetry_provider.dart';
import '../widgets/blinking_heartbeat_dot.dart';
import '../widgets/clinical_vitals_bar.dart';
import '../widgets/ecg_control_toolbar.dart';
import '../widgets/ecg_oscilloscope_painter.dart';
import '../widgets/event_log_list.dart';
import 'config_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isEventDrawerExpanded = false;

  @override
  Widget build(BuildContext context) {
    final telemetry = ref.watch(telemetryProvider);
    final notifier = ref.read(telemetryProvider.notifier);
    final config = ref.watch(configProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF090D15),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F141E),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monitor_heart_rounded, color: Color(0xFF00FF88), size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'FlutBeat ECG Monitor',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            Text(
              '${config.host}:${config.port}',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white54,
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
        actions: [
          // Blinking Live Indicator
          const BlinkingHeartbeatDot(),

          // Reconnect Button
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reconnect to Hardware Node',
            onPressed: () {
              notifier.reconnect();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reconnecting to FlutBeat node...'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),

          // Settings Button
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Connection Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ConfigScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Error banner if any
            if (telemetry.errorMessage != null && !telemetry.isConnected)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0xFFEF4444).withValues(alpha: 0.18),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        telemetry.errorMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            // Top Section: Responsive Clinical Vitals Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: ClinicalVitalsBar(state: telemetry),
            ),

            // Middle Section: Interactive ECG Oscilloscope Canvas
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: EcgOscilloscope(state: telemetry),
              ),
            ),

            // ECG Control Toolbar
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: EcgControlToolbar(state: telemetry, notifier: notifier),
            ),

            // Bottom Section: Collapsible Cardiac Events & System Logs Drawer
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              height: _isEventDrawerExpanded ? 220 : 64,
              child: ClipRect(
                child: EventLogList(
                  isExpanded: _isEventDrawerExpanded,
                  onToggleExpanded: () {
                    setState(() {
                      _isEventDrawerExpanded = !_isEventDrawerExpanded;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
