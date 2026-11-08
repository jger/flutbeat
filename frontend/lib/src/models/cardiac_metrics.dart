/// Clinical lead attachment state
enum LeadStatus {
  leadsConnected,
  leadOffPositive,
  leadOffNegative,
  leadOffBoth,
  unspecified;

  bool get isConnected => this == LeadStatus.leadsConnected;
}

/// Clinical cardiac rhythm categorization
enum RhythmClassification {
  normalSinus,
  bradycardia,
  tachycardia,
  irregularArrhythmia,
  noSignal,
  unspecified,
}

/// Telemetry input stream origin
enum SourceMode {
  usbSerial,
  simulator,
}

/// Real-time clinical cardiac vital metrics computed by the DSP engine
class CardiacMetrics {
  const CardiacMetrics({
    this.heartRateBpm = 72,
    this.rrIntervalMs = 833,
    this.hrvSdnnMs = 38.0,
    this.hrvRmssdMs = 29.0,
    this.leadStatus = LeadStatus.leadsConnected,
    this.rhythm = RhythmClassification.normalSinus,
    this.signalQualityPercent = 98,
    this.totalBeats = 0,
    this.lastBeatTimestampMs = 0,
  });

  final int heartRateBpm;
  final int rrIntervalMs;
  final double hrvSdnnMs;
  final double hrvRmssdMs;
  final LeadStatus leadStatus;
  final RhythmClassification rhythm;
  final int signalQualityPercent;
  final int totalBeats;
  final int lastBeatTimestampMs;

  CardiacMetrics copyWith({
    int? heartRateBpm,
    int? rrIntervalMs,
    double? hrvSdnnMs,
    double? hrvRmssdMs,
    LeadStatus? leadStatus,
    RhythmClassification? rhythm,
    int? signalQualityPercent,
    int? totalBeats,
    int? lastBeatTimestampMs,
  }) {
    return CardiacMetrics(
      heartRateBpm: heartRateBpm ?? this.heartRateBpm,
      rrIntervalMs: rrIntervalMs ?? this.rrIntervalMs,
      hrvSdnnMs: hrvSdnnMs ?? this.hrvSdnnMs,
      hrvRmssdMs: hrvRmssdMs ?? this.hrvRmssdMs,
      leadStatus: leadStatus ?? this.leadStatus,
      rhythm: rhythm ?? this.rhythm,
      signalQualityPercent: signalQualityPercent ?? this.signalQualityPercent,
      totalBeats: totalBeats ?? this.totalBeats,
      lastBeatTimestampMs: lastBeatTimestampMs ?? this.lastBeatTimestampMs,
    );
  }
}

/// Event types emitted during cardiac telemetry monitoring
enum CardiacEventType {
  rPeak,
  leadOff,
  leadRestored,
  arrhythmiaAlert,
}

/// Cardiac telemetry discrete event
class CardiacEvent {
  const CardiacEvent({
    required this.type,
    required this.description,
    required this.timestampUnixMillis,
    this.heartRateBpm = 0,
    this.sequenceNumber = 0,
  });

  final CardiacEventType type;
  final String description;
  final int timestampUnixMillis;
  final int heartRateBpm;
  final int sequenceNumber;
}

/// Diagnostic log severity level
enum LogLevel {
  debug,
  info,
  warn,
  error,
}

/// Diagnostic system log entry
class LogEntry {
  const LogEntry({
    required this.level,
    required this.component,
    required this.message,
    required this.timestampUnixMillis,
  });

  final LogLevel level;
  final String component;
  final String message;
  final int timestampUnixMillis;
}
