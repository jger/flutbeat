import 'cardiac_metrics.dart';

class ConnectionConfig {
  const ConnectionConfig({
    this.baudRate = 115200,
    this.selectedDeviceName,
    this.sourceMode = SourceMode.usbSerial,
    this.targetSimBpm = 72,
    this.host = '127.0.0.1',
    this.port = 50051,
    this.clientId = 'flutter-dashboard',
    this.useTls = false,
  });

  final int baudRate;
  final String? selectedDeviceName;
  final SourceMode sourceMode;
  final int targetSimBpm;

  // Legacy fields kept for backward compatibility
  final String host;
  final int port;
  final String clientId;
  final bool useTls;

  ConnectionConfig copyWith({
    int? baudRate,
    String? selectedDeviceName,
    bool clearDeviceName = false,
    SourceMode? sourceMode,
    int? targetSimBpm,
    String? host,
    int? port,
    String? clientId,
    bool? useTls,
  }) {
    return ConnectionConfig(
      baudRate: baudRate ?? this.baudRate,
      selectedDeviceName: clearDeviceName
          ? null
          : (selectedDeviceName ?? this.selectedDeviceName),
      sourceMode: sourceMode ?? this.sourceMode,
      targetSimBpm: targetSimBpm ?? this.targetSimBpm,
      host: host ?? this.host,
      port: port ?? this.port,
      clientId: clientId ?? this.clientId,
      useTls: useTls ?? this.useTls,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'baudRate': baudRate,
      'selectedDeviceName': selectedDeviceName,
      'sourceMode': sourceMode.name,
      'targetSimBpm': targetSimBpm,
      'host': host,
      'port': port,
      'clientId': clientId,
      'useTls': useTls,
    };
  }

  factory ConnectionConfig.fromJson(Map<String, dynamic> json) {
    SourceMode mode = SourceMode.usbSerial;
    if (json['sourceMode'] == 'simulator') {
      mode = SourceMode.simulator;
    }

    return ConnectionConfig(
      baudRate: (json['baudRate'] as num?)?.toInt() ?? 115200,
      selectedDeviceName: json['selectedDeviceName'] as String?,
      sourceMode: mode,
      targetSimBpm: (json['targetSimBpm'] as num?)?.toInt() ?? 72,
      host: json['host'] as String? ?? '127.0.0.1',
      port: (json['port'] as num?)?.toInt() ?? 50051,
      clientId: json['clientId'] as String? ?? 'flutter-dashboard',
      useTls: json['useTls'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectionConfig &&
          runtimeType == other.runtimeType &&
          baudRate == other.baudRate &&
          selectedDeviceName == other.selectedDeviceName &&
          sourceMode == other.sourceMode &&
          targetSimBpm == other.targetSimBpm &&
          host == other.host &&
          port == other.port &&
          clientId == other.clientId &&
          useTls == other.useTls;

  @override
  int get hashCode => Object.hash(
        baudRate,
        selectedDeviceName,
        sourceMode,
        targetSimBpm,
        host,
        port,
        clientId,
        useTls,
      );
}
