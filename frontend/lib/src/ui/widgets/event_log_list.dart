import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../generated/telemetry.pb.dart';
import '../../providers/telemetry_provider.dart';

class EventLogList extends ConsumerStatefulWidget {
  const EventLogList({
    super.key,
    required this.isExpanded,
    required this.onToggleExpanded,
  });

  final bool isExpanded;
  final VoidCallback onToggleExpanded;

  @override
  ConsumerState<EventLogList> createState() => _EventLogListState();
}

class _EventLogListState extends ConsumerState<EventLogList> {
  int _activeTab = 0; // 0 = Cardiac Events, 1 = DSP / System Logs
  final DateFormat _timeFormatter = DateFormat('HH:mm:ss.SSS');

  @override
  Widget build(BuildContext context) {
    final telemetry = ref.watch(telemetryProvider);
    final events = telemetry.cardiacEvents;
    final logs = telemetry.logs;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F141C),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        mainAxisSize: widget.isExpanded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          // Collapsible Header Bar
          InkWell(
            onTap: widget.onToggleExpanded,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    widget.isExpanded
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_up_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                  const SizedBox(width: 8),

                  // Tab Buttons
                  _HeaderTab(
                    label: 'CARDIAC EVENTS',
                    count: events.length,
                    selected: _activeTab == 0,
                    onTap: () {
                      if (!widget.isExpanded) widget.onToggleExpanded();
                      setState(() => _activeTab = 0);
                    },
                  ),
                  const SizedBox(width: 8),
                  _HeaderTab(
                    label: 'SYSTEM LOGS',
                    count: logs.length,
                    selected: _activeTab == 1,
                    onTap: () {
                      if (!widget.isExpanded) widget.onToggleExpanded();
                      setState(() => _activeTab = 1);
                    },
                  ),

                  const Spacer(),

                  // Clear button
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined, size: 16),
                    tooltip: 'Clear history',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    onPressed: () {
                      if (_activeTab == 0) {
                        ref.read(telemetryProvider.notifier).clearEvents();
                      } else {
                        ref.read(telemetryProvider.notifier).clearLogs();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          if (widget.isExpanded) const Divider(height: 1, thickness: 1, color: Colors.white10),

          // Body list
          if (widget.isExpanded)
            Expanded(
              child: _activeTab == 0
                  ? _buildEventsList(events)
                  : _buildLogsList(logs),
            ),
        ],
      ),
    );
  }

  Widget _buildEventsList(List<CardiacEvent> events) {
    if (events.isEmpty) {
      return const Center(
        child: Text(
          'Waiting for cardiac events (R-peaks, Lead-Off alarms)...',
          style: TextStyle(fontSize: 12, color: Colors.white38),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      itemCount: events.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final ev = events[index];
        final ts = DateTime.fromMillisecondsSinceEpoch(ev.timestampUnixMillis.toInt());

        final (badgeText, badgeColor) = switch (ev.eventType) {
          CardiacEventType.R_PEAK_DETECTED => ('R-PEAK', const Color(0xFF00FF88)),
          CardiacEventType.LEAD_OFF_TRIGGERED => ('LEAD-OFF', const Color(0xFFEF4444)),
          CardiacEventType.LEAD_RECONNECTED => ('LEAD-OK', const Color(0xFF10B981)),
          CardiacEventType.BRADYCARDIA_TRIGGERED => ('BRADY', const Color(0xFFF59E0B)),
          CardiacEventType.TACHYCARDIA_TRIGGERED => ('TACHY', const Color(0xFFD946EF)),
          CardiacEventType.SOURCE_MODE_SWITCHED => ('SOURCE', const Color(0xFF38BDF8)),
          _ => ('EVENT', Colors.white54),
        };

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF161E2B),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Text(
                '#${ev.sequenceNumber}',
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: Colors.white38,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.4), width: 0.8),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: badgeColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ev.description,
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _timeFormatter.format(ts),
                style: const TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: Colors.white38,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogsList(List<LogEntry> logs) {
    if (logs.isEmpty) {
      return const Center(
        child: Text(
          'No diagnostic logs received yet...',
          style: TextStyle(fontSize: 12, color: Colors.white38),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      itemCount: logs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final log = logs[index];
        final ts = DateTime.fromMillisecondsSinceEpoch(log.timestampUnixMillis.toInt());

        final levelColor = switch (log.level) {
          LogLevel.DEBUG => const Color(0xFF38BDF8),
          LogLevel.INFO => const Color(0xFF10B981),
          LogLevel.WARN => const Color(0xFFF59E0B),
          LogLevel.ERROR => const Color(0xFFEF4444),
          _ => Colors.white54,
        };

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _timeFormatter.format(ts),
                style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.white38),
              ),
              const SizedBox(width: 6),
              Text(
                '[${log.level.name.toUpperCase()}]',
                style: TextStyle(fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold, color: levelColor),
              ),
              const SizedBox(width: 6),
              Text(
                '[${log.component}]',
                style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFFA78BFA)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  log.message,
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.white70),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderTab extends StatelessWidget {
  const _HeaderTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : Colors.white54,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
