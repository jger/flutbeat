class ConnectionConfig {
  const ConnectionConfig({
    this.host = '192.168.178.33',
    this.port = 50051,
    this.clientId = 'flutter-dashboard',
    this.useTls = false,
  });

  final String host;
  final int port;
  final String clientId;
  final bool useTls;

  ConnectionConfig copyWith({
    String? host,
    int? port,
    String? clientId,
    bool? useTls,
  }) {
    return ConnectionConfig(
      host: host ?? this.host,
      port: port ?? this.port,
      clientId: clientId ?? this.clientId,
      useTls: useTls ?? this.useTls,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'host': host,
      'port': port,
      'clientId': clientId,
      'useTls': useTls,
    };
  }

  factory ConnectionConfig.fromJson(Map<String, dynamic> json) {
    return ConnectionConfig(
      host: json['host'] as String? ?? '192.168.178.33',
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
          host == other.host &&
          port == other.port &&
          clientId == other.clientId &&
          useTls == other.useTls;

  @override
  int get hashCode => Object.hash(host, port, clientId, useTls);
}
