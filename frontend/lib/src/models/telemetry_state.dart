import 'cardiac_metrics.dart';

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

enum SweepMode {
  eraseBarSweep, // Classic ICU monitor: cursor moves L->R overwriting trace
  continuousScroll, // Continuous left-scrolling trace
}

enum PaperSpeed {
  speed25(25.0, '25 mm/s'),
  speed50(50.0, '50 mm/s');

  const PaperSpeed(this.mmPerSec, this.label);
  final double mmPerSec;
  final String label;
}

enum GainSetting {
  gain5(5.0, '5 mm/mV (0.5x)'),
  gain10(10.0, '10 mm/mV (1.0x)'),
  gain20(20.0, '20 mm/mV (2.0x)');

  const GainSetting(this.mmPerMv, this.label);
  final double mmPerMv;
  final String label;
}

enum SignalFilterMode {
  dspFiltered('DSP Filtered'),
  rawAdc('Raw ADC');

  const SignalFilterMode(this.label);
  final String label;
}

/// Single point cached in the oscilloscope ring buffer
class EcgPointData {
  const EcgPointData({
    required this.timestampMs,
    required this.rawAdc,
    required this.voltageMv,
    required this.filteredMv,
    this.isRPeak = false,
    this.leadOff = false,
  });

  final int timestampMs;
  final int rawAdc;
  final double voltageMv;
  final double filteredMv;
  final bool isRPeak;
  final bool leadOff;

  static const EcgPointData zero = EcgPointData(
    timestampMs: 0,
    rawAdc: 512,
    voltageMv: 0.0,
    filteredMv: 0.0,
    isRPeak: false,
    leadOff: false,
  );
}

class TelemetryState {
  TelemetryState({
    this.connectionStatus = ConnectionStatus.disconnected,
    this.errorMessage,
    CardiacMetrics? metrics,
    this.sourceMode = SourceMode.usbSerial,
    List<EcgPointData>? buffer,
    this.cursorIndex = 0,
    this.cardiacEvents = const [],
    this.logs = const [],
    this.lastHeartbeat,
    this.uptimeSeconds = 0,
    this.sweepMode = SweepMode.eraseBarSweep,
    this.paperSpeed = PaperSpeed.speed25,
    this.gain = GainSetting.gain10,
    this.filterMode = SignalFilterMode.dspFiltered,
    this.isFrozen = false,
    this.totalSamples = 0,
    this.targetSimBpm = 72,
    this.connectedDeviceName,
    this.baudRate = 115200,
  })  : metrics = metrics ?? const CardiacMetrics(),
        buffer = buffer ?? List.filled(1250, EcgPointData.zero);

  static const int bufferCapacity = 1250; // 5.0 seconds @ 250 Hz

  final ConnectionStatus connectionStatus;
  final String? errorMessage;
  final CardiacMetrics metrics;
  final SourceMode sourceMode;
  final List<EcgPointData> buffer;
  final int cursorIndex;
  final List<CardiacEvent> cardiacEvents;
  final List<LogEntry> logs;
  final DateTime? lastHeartbeat;
  final int uptimeSeconds;

  // Clinical Oscilloscope display settings
  final SweepMode sweepMode;
  final PaperSpeed paperSpeed;
  final GainSetting gain;
  final SignalFilterMode filterMode;
  final bool isFrozen;
  final int totalSamples;
  final int targetSimBpm;
  final String? connectedDeviceName;
  final int baudRate;

  bool get isConnected => connectionStatus == ConnectionStatus.connected;
  bool get isLeadOff => metrics.leadStatus != LeadStatus.leadsConnected;

  TelemetryState copyWith({
    ConnectionStatus? connectionStatus,
    String? errorMessage,
    bool clearError = false,
    CardiacMetrics? metrics,
    SourceMode? sourceMode,
    List<EcgPointData>? buffer,
    int? cursorIndex,
    List<CardiacEvent>? cardiacEvents,
    List<LogEntry>? logs,
    DateTime? lastHeartbeat,
    int? uptimeSeconds,
    SweepMode? sweepMode,
    PaperSpeed? paperSpeed,
    GainSetting? gain,
    SignalFilterMode? filterMode,
    bool? isFrozen,
    int? totalSamples,
    int? targetSimBpm,
    String? connectedDeviceName,
    bool clearDeviceName = false,
    int? baudRate,
  }) {
    return TelemetryState(
      connectionStatus: connectionStatus ?? this.connectionStatus,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      metrics: metrics ?? this.metrics,
      sourceMode: sourceMode ?? this.sourceMode,
      buffer: buffer ?? this.buffer,
      cursorIndex: cursorIndex ?? this.cursorIndex,
      cardiacEvents: cardiacEvents ?? this.cardiacEvents,
      logs: logs ?? this.logs,
      lastHeartbeat: lastHeartbeat ?? this.lastHeartbeat,
      uptimeSeconds: uptimeSeconds ?? this.uptimeSeconds,
      sweepMode: sweepMode ?? this.sweepMode,
      paperSpeed: paperSpeed ?? this.paperSpeed,
      gain: gain ?? this.gain,
      filterMode: filterMode ?? this.filterMode,
      isFrozen: isFrozen ?? this.isFrozen,
      totalSamples: totalSamples ?? this.totalSamples,
      targetSimBpm: targetSimBpm ?? this.targetSimBpm,
      connectedDeviceName: clearDeviceName
          ? null
          : (connectedDeviceName ?? this.connectedDeviceName),
      baudRate: baudRate ?? this.baudRate,
    );
  }
}
