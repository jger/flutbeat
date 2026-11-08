import 'package:flutter/material.dart';
import '../../models/cardiac_metrics.dart';
import '../../models/telemetry_state.dart';

class ClinicalVitalsBar extends StatefulWidget {
  const ClinicalVitalsBar({
    super.key,
    required this.state,
  });

  final TelemetryState state;

  @override
  State<ClinicalVitalsBar> createState() => _ClinicalVitalsBarState();
}

class _ClinicalVitalsBarState extends State<ClinicalVitalsBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _heartAnimController;
  late Animation<double> _heartScale;
  int _lastBeatTimestamp = 0;

  @override
  void initState() {
    super.initState();
    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _heartScale = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _heartAnimController, curve: Curves.easeOutBack),
    );
  }

  @override
  void didUpdateWidget(covariant ClinicalVitalsBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentBeatTs = widget.state.metrics.lastBeatTimestampMs.toInt();
    if (currentBeatTs > 0 && currentBeatTs != _lastBeatTimestamp) {
      _lastBeatTimestamp = currentBeatTs;
      _heartAnimController.forward().then((_) => _heartAnimController.reverse());
    }
  }

  @override
  void dispose() {
    _heartAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metrics = widget.state.metrics;
    final isLeadOff = widget.state.isLeadOff;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 720;

        final card1 = _HeartRateCard(
          bpm: metrics.heartRateBpm,
          rhythm: metrics.rhythm,
          isLeadOff: isLeadOff,
          heartAnim: _heartScale,
        );

        final card2 = _HrvMetricsCard(
          rrMs: metrics.rrIntervalMs,
          sdnnMs: metrics.hrvSdnnMs,
          rmssdMs: metrics.hrvRmssdMs,
          totalBeats: metrics.totalBeats,
          isLeadOff: isLeadOff,
        );

        final card3 = _SignalStatusCard(
          leadStatus: metrics.leadStatus,
          signalQuality: metrics.signalQualityPercent,
          sourceMode: widget.state.sourceMode,
        );

        if (constraints.maxWidth < 340) {
          return Column(
            children: [
              card1,
              const SizedBox(height: 8),
              card2,
              const SizedBox(height: 8),
              card3,
            ],
          );
        } else if (isNarrow) {
          return Column(
            children: [
              card1,
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: card2),
                  const SizedBox(width: 10),
                  Expanded(child: card3),
                ],
              ),
            ],
          );
        } else {
          return Row(
            children: [
              Expanded(flex: 3, child: card1),
              const SizedBox(width: 12),
              Expanded(flex: 4, child: card2),
              const SizedBox(width: 12),
              Expanded(flex: 3, child: card3),
            ],
          );
        }
      },
    );
  }
}

class _HeartRateCard extends StatelessWidget {
  const _HeartRateCard({
    required this.bpm,
    required this.rhythm,
    required this.isLeadOff,
    required this.heartAnim,
  });

  final int bpm;
  final RhythmClassification rhythm;
  final bool isLeadOff;
  final Animation<double> heartAnim;

  @override
  Widget build(BuildContext context) {
    final (rhythmText, rhythmColor) = switch (rhythm) {
      RhythmClassification.normalSinus => ('NORMAL SINUS', const Color(0xFF10B981)),
      RhythmClassification.bradycardia => ('BRADYCARDIA', const Color(0xFFF59E0B)),
      RhythmClassification.tachycardia => ('TACHYCARDIA', const Color(0xFFD946EF)),
      RhythmClassification.irregularArrhythmia => ('IRREGULAR', const Color(0xFFEF4444)),
      _ => ('NO SIGNAL', const Color(0xFF6B7280)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF141923),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          // Pulsing Heart Icon
          ScaleTransition(
            scale: heartAnim,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isLeadOff ? Colors.grey : const Color(0xFFEF4444)).withValues(alpha: 0.18),
              ),
              child: Icon(
                Icons.favorite_rounded,
                color: isLeadOff ? Colors.white38 : const Color(0xFFEF4444),
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Numeric BPM readout
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      isLeadOff || bpm == 0 ? '--' : '$bpm',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'BPM',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: rhythmColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: rhythmColor.withValues(alpha: 0.4), width: 0.8),
                  ),
                  child: Text(
                    rhythmText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: rhythmColor,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HrvMetricsCard extends StatelessWidget {
  const _HrvMetricsCard({
    required this.rrMs,
    required this.sdnnMs,
    required this.rmssdMs,
    required this.totalBeats,
    required this.isLeadOff,
  });

  final int rrMs;
  final double sdnnMs;
  final double rmssdMs;
  final int totalBeats;
  final bool isLeadOff;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141923),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'CARDIAC METRICS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white38,
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'BEATS: $totalBeats',
                  style: const TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF38BDF8),
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _MetricItem(
                  label: 'R-R INT',
                  value: isLeadOff ? '--' : '$rrMs ms',
                  color: const Color(0xFF00E5FF),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _MetricItem(
                  label: 'SDNN',
                  value: isLeadOff ? '--' : '${sdnnMs.toStringAsFixed(1)} ms',
                  color: const Color(0xFFA78BFA),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _MetricItem(
                  label: 'RMSSD',
                  value: isLeadOff ? '--' : '${rmssdMs.toStringAsFixed(1)} ms',
                  color: const Color(0xFFF472B6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Colors.white54,
            ),
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _SignalStatusCard extends StatelessWidget {
  const _SignalStatusCard({
    required this.leadStatus,
    required this.signalQuality,
    required this.sourceMode,
  });

  final LeadStatus leadStatus;
  final int signalQuality;
  final SourceMode sourceMode;

  @override
  Widget build(BuildContext context) {
    final loPlusOk = leadStatus != LeadStatus.leadOffPositive &&
        leadStatus != LeadStatus.leadOffBoth;
    final loMinusOk = leadStatus != LeadStatus.leadOffNegative &&
        leadStatus != LeadStatus.leadOffBoth;

    final sourceLabel = switch (sourceMode) {
      SourceMode.usbSerial => 'USB OTG',
      SourceMode.simulator => 'SIMULATOR',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141923),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'LEAD DETECTION',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white38,
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  sourceLabel,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF38BDF8),
                    letterSpacing: 0.4,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Flexible(
                child: _LeadPill(label: 'LO+ (D5)', isOk: loPlusOk),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: _LeadPill(label: 'LO- (D6)', isOk: loMinusOk),
              ),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$signalQuality%',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w800,
                    color: signalQuality > 80
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeadPill extends StatelessWidget {
  const _LeadPill({required this.label, required this.isOk});

  final String label;
  final bool isOk;

  @override
  Widget build(BuildContext context) {
    final color = isOk ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

