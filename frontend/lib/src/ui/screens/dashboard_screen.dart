import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/telemetry_state.dart';
import '../../providers/config_provider.dart';
import '../../providers/telemetry_provider.dart';
import '../widgets/blinking_heartbeat_dot.dart';
import '../widgets/clinical_vitals_bar.dart';
import '../widgets/ecg_control_toolbar.dart';
import '../widgets/ecg_oscilloscope_painter.dart';
import '../widgets/event_log_list.dart';
import 'config_screen.dart';
import '../help/app_help.dart';
import '../../recording/recording_ui.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key, this.initialShowAllUi = false});

  final bool initialShowAllUi;

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late bool _showAllUi;
  bool _isEventDrawerExpanded = false;

  @override
  void initState() {
    super.initState();
    _showAllUi = widget.initialShowAllUi;
  }

  @override
  Widget build(BuildContext context) {
    final telemetry = ref.watch(telemetryProvider);
    final notifier = ref.read(telemetryProvider.notifier);
    final config = ref.watch(configProvider);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final statusSubtitle =
        'USB OTG: ${telemetry.connectedDeviceName ?? "Direct ESP"} (${config.baudRate} baud)';

    return Scaffold(
      backgroundColor: const Color(0xFF090D15),
      // In horizontal/landscape, hide AppBar to give maximum vertical space to the graph
      appBar: isLandscape
          ? null
          : AppBar(
              backgroundColor: const Color(0xFF0F141E),
              elevation: 0,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.monitor_heart_rounded,
                        color: Color(0xFF00FF88),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Flexible(
                        child: Text(
                          'FlutBeat ECG Monitor',
                          style: TextStyle(
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
                    statusSubtitle,
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
                  tooltip: 'Reconnect to ESP USB OTG',
                  onPressed: () {
                    notifier.reconnect();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reconnecting to ESP device...'),
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),

                // Settings Button
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: 'USB Connection Settings',
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
        top: true,
        bottom: true,
        child: Column(
          children: [
            // Error banner only in portrait when not connected to save landscape vertical space

            // Main body area (Fullscreen Graph vs Responsive UI)
            Expanded(
              child: _buildMainContent(telemetry, notifier, isLandscape),
            ),
            const RecordingBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(
    TelemetryState telemetry,
    Telemetry notifier,
    bool isLandscape,
  ) {
    void handleSettings() {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const ConfigScreen()));
    }

    void handleReconnect() {
      notifier.reconnect();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reconnecting to ESP device...'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    if (!telemetry.isConnected) {
      return OfflineSetup(
        connecting: telemetry.connectionStatus == ConnectionStatus.connecting,
        error: telemetry.errorMessage,
        onConnect: handleReconnect,
      );
    }
    if (!_showAllUi) {
      // FULL GRAPH VIEW: uses all available space (edge-to-edge in landscape)
      return Padding(
        padding: const EdgeInsets.all(8),
        child: EcgOscilloscope(
          state: telemetry,
          notifier: notifier,
          onToggleAllUi: () => setState(() => _showAllUi = true),
          isAllUiVisible: false,
          onOpenSettings: handleSettings,
          onReconnect: handleReconnect,
        ),
      );
    }

    if (isLandscape && MediaQuery.sizeOf(context).width >= 700) {
      // LANDSCAPE RESPONSIVE VIEW: Graph on left, Controls & Vitals on right
      return Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left: Maximized ECG Oscilloscope canvas
            Expanded(
              flex: 6,
              child: EcgOscilloscope(
                state: telemetry,
                notifier: notifier,
                onToggleAllUi: () => setState(() => _showAllUi = false),
                isAllUiVisible: true,
                onOpenSettings: handleSettings,
                onReconnect: handleReconnect,
              ),
            ),

            const SizedBox(width: 6),

            // Right: Scrollable Controls & Vitals side panel
            SizedBox(
              width: 320,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClinicalVitalsBar(state: telemetry),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F141E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: EcgControlToolbar(
                        state: telemetry,
                        notifier: notifier,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 220,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: EventLogList(
                          isExpanded: true,
                          onToggleExpanded: () {},
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Keep the graph usable when the details exceed a short viewport.
    return LayoutBuilder(
      builder: (context, constraints) {
        final scrollDetails = constraints.maxHeight < 700;
        final content = Column(
          children: [
            // Top Section: Responsive Clinical Vitals Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: ClinicalVitalsBar(state: telemetry),
            ),

            // Middle Section: Interactive ECG Oscilloscope Canvas
            if (scrollDetails)
              SizedBox(
                height: 320,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: EcgOscilloscope(
                    state: telemetry,
                    notifier: notifier,
                    onToggleAllUi: () => setState(() => _showAllUi = false),
                    isAllUiVisible: true,
                    onOpenSettings: handleSettings,
                    onReconnect: handleReconnect,
                  ),
                ),
              )
            else
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: EcgOscilloscope(
                    state: telemetry,
                    notifier: notifier,
                    onToggleAllUi: () => setState(() => _showAllUi = false),
                    isAllUiVisible: true,
                  ),
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
        );
        return scrollDetails ? SingleChildScrollView(child: content) : content;
      },
    );
  }
}
