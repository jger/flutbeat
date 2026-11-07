import 'package:flutter/material.dart';
import '../../generated/telemetry.pb.dart';
import '../../models/telemetry_state.dart';
import '../../providers/telemetry_provider.dart';

class EcgControlToolbar extends StatelessWidget {
  const EcgControlToolbar({
    super.key,
    required this.state,
    required this.notifier,
  });

  final TelemetryState state;
  final Telemetry notifier;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // 1. Freeze / Resume Button
          FilledButton.tonalIcon(
            onPressed: notifier.toggleFreeze,
            icon: Icon(
              state.isFrozen ? Icons.play_arrow_rounded : Icons.pause_rounded,
              size: 16,
              color: state.isFrozen ? const Color(0xFF00FF88) : Colors.white70,
            ),
            label: Text(
              state.isFrozen ? 'RESUME' : 'FREEZE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: state.isFrozen ? const Color(0xFF00FF88) : Colors.white,
              ),
            ),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              backgroundColor: state.isFrozen
                  ? const Color(0xFF00FF88).withValues(alpha: 0.15)
                  : const Color(0xFF1E2634),
            ),
          ),
          const SizedBox(width: 8),

          // 2. Sweep Mode (Sweep vs. Scroll)
          OutlinedButton.icon(
            onPressed: notifier.toggleSweepMode,
            icon: Icon(
              state.sweepMode == SweepMode.eraseBarSweep
                  ? Icons.swipe_right_alt_rounded
                  : Icons.sync_alt_rounded,
              size: 14,
            ),
            label: Text(
              state.sweepMode == SweepMode.eraseBarSweep ? 'ICU SWEEP' : 'SCROLL',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
            ),
          ),
          const SizedBox(width: 8),

          // 3. Paper Speed Menu (25 vs 50 mm/s)
          PopupMenuButton<PaperSpeed>(
            initialValue: state.paperSpeed,
            onSelected: notifier.setPaperSpeed,
            tooltip: 'ECG Paper Speed',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.speed_rounded, size: 14, color: Colors.white70),
                  const SizedBox(width: 6),
                  Text(
                    state.paperSpeed.label,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 14, color: Colors.white54),
                ],
              ),
            ),
            itemBuilder: (_) => PaperSpeed.values
                .map((speed) => PopupMenuItem(
                      value: speed,
                      child: Text(speed.label, style: const TextStyle(fontSize: 12)),
                    ))
                .toList(),
          ),
          const SizedBox(width: 8),

          // 4. Gain Menu (5, 10, 20 mm/mV)
          PopupMenuButton<GainSetting>(
            initialValue: state.gain,
            onSelected: notifier.setGain,
            tooltip: 'Voltage Gain (Sensitivity)',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.expand_less_rounded, size: 14, color: Colors.white70),
                  const SizedBox(width: 6),
                  Text(
                    state.gain.label,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 14, color: Colors.white54),
                ],
              ),
            ),
            itemBuilder: (_) => GainSetting.values
                .map((gain) => PopupMenuItem(
                      value: gain,
                      child: Text(gain.label, style: const TextStyle(fontSize: 12)),
                    ))
                .toList(),
          ),
          const SizedBox(width: 8),

          // 5. Filter Mode Toggle
          OutlinedButton.icon(
            onPressed: notifier.toggleFilter,
            icon: Icon(
              state.filterMode == SignalFilterMode.dspFiltered
                  ? Icons.filter_alt_rounded
                  : Icons.filter_alt_off_rounded,
              size: 14,
              color: state.filterMode == SignalFilterMode.dspFiltered
                  ? const Color(0xFF38BDF8)
                  : Colors.amber,
            ),
            label: Text(
              state.filterMode == SignalFilterMode.dspFiltered ? 'FILTER: ON' : 'FILTER: RAW',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: state.filterMode == SignalFilterMode.dspFiltered
                    ? const Color(0xFF38BDF8)
                    : Colors.amber,
              ),
            ),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              side: BorderSide(
                color: state.filterMode == SignalFilterMode.dspFiltered
                    ? const Color(0xFF38BDF8).withValues(alpha: 0.3)
                    : Colors.amber.withValues(alpha: 0.3),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 6. Source & Sim BPM Configuration
          PopupMenuButton<SourceMode>(
            initialValue: state.sourceMode,
            onSelected: (mode) => notifier.configureSource(mode: mode),
            tooltip: 'Ingestion Source',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.hub_outlined, size: 14, color: Colors.white70),
                  const SizedBox(width: 6),
                  Text(
                    state.sourceMode == SourceMode.UDP_WIFI
                        ? 'D1 MINI (UDP)'
                        : (state.sourceMode == SourceMode.USB_SERIAL ? 'SERIAL' : 'SIMULATOR'),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 14, color: Colors.white54),
                ],
              ),
            ),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: SourceMode.SIMULATOR,
                child: Text('Synthetic ECG Simulator', style: TextStyle(fontSize: 12)),
              ),
              const PopupMenuItem(
                value: SourceMode.UDP_WIFI,
                child: Text('WeMos D1 Mini (Wi-Fi UDP)', style: TextStyle(fontSize: 12)),
              ),
              const PopupMenuItem(
                value: SourceMode.USB_SERIAL,
                child: Text('USB Serial / UART', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(width: 8),

          // 7. Sim BPM Quick Adjust (if in simulator mode)
          if (state.sourceMode == SourceMode.SIMULATOR)
            IconButton(
              icon: const Icon(Icons.tune_rounded, size: 18),
              tooltip: 'Adjust Simulated BPM',
              visualDensity: VisualDensity.compact,
              onPressed: () => _showSimBpmDialog(context, state, notifier),
            ),

          // 8. CSV Export Button
          IconButton(
            icon: const Icon(Icons.download_rounded, size: 18),
            tooltip: 'Export ECG Ring Buffer to CSV',
            visualDensity: VisualDensity.compact,
            onPressed: () async {
              await notifier.exportCsv();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ECG waveform samples copied to clipboard as CSV!'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showSimBpmDialog(
    BuildContext context,
    TelemetryState state,
    Telemetry notifier,
  ) {
    double currentBpm = state.targetSimBpm.toDouble();
    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Simulated Heart Rate (BPM)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${currentBpm.round()} BPM',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF00FF88),
                  fontFamily: 'monospace',
                ),
              ),
              Slider(
                value: currentBpm,
                min: 40,
                max: 180,
                divisions: 28,
                label: '${currentBpm.round()} BPM',
                onChanged: (val) => setState(() => currentBpm = val),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => setState(() => currentBpm = 50),
                    child: const Text('Brady (50)'),
                  ),
                  TextButton(
                    onPressed: () => setState(() => currentBpm = 75),
                    child: const Text('Normal (75)'),
                  ),
                  TextButton(
                    onPressed: () => setState(() => currentBpm = 120),
                    child: const Text('Tachy (120)'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                notifier.configureSource(targetSimBpm: currentBpm.round());
                Navigator.of(dialogCtx).pop();
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }
}

