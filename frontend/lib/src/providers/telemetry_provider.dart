import 'dart:async';
import 'package:flutter/services.dart';
import 'package:grpc/grpc.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../generated/telemetry.pbgrpc.dart';
import '../models/telemetry_state.dart';
import 'config_provider.dart';
import 'grpc_client_provider.dart';

part 'telemetry_provider.g.dart';

@Riverpod(keepAlive: true)
class Telemetry extends _$Telemetry {
  StreamSubscription<EcgWaveformChunk>? _ecgSub;
  StreamSubscription<CardiacEvent>? _eventSub;
  StreamSubscription<LogEntry>? _logSub;
  Timer? _reconnectTimer;
  bool _isDisposed = false;

  static const int _maxEvents = 300;
  static const int _maxLogs = 150;

  @override
  TelemetryState build() {
    _isDisposed = false;
    ref.onDispose(() {
      _isDisposed = true;
      _reconnectTimer?.cancel();
      _cleanupSubscriptions();
    });

    // Re-connect whenever client channel/config changes
    ref.watch(telemetryClientProvider);

    Future.microtask(() => _connect());
    return TelemetryState();
  }

  Future<void> _connect() async {
    if (_isDisposed) return;
    _cleanupSubscriptions();

    state = state.copyWith(
      connectionStatus: ConnectionStatus.connecting,
      clearError: true,
    );

    final client = ref.read(telemetryClientProvider);
    final config = ref.read(configProvider);

    try {
      // 1. Snapshot status
      try {
        final status = await client
            .getStatus(
              GetStatusRequest(),
              options: CallOptions(timeout: const Duration(seconds: 3)),
            )
            .catchError((_) => StatusResponse());

        if (!_isDisposed && status.hasUptimeSeconds()) {
          state = state.copyWith(
            uptimeSeconds: status.uptimeSeconds.toInt(),
            sourceMode: status.sourceMode,
            metrics: status.hasMetrics() ? status.metrics : state.metrics,
            totalSamples: status.totalSamplesProcessed.toInt(),
            targetSimBpm: status.targetSimBpm > 0 ? status.targetSimBpm : 72,
          );
        }
      } catch (_) {
        // Non-blocking
      }

      if (_isDisposed) return;

      // 2. Stream Real-Time ECG Waveform Chunks (250 Hz)
      final ecgStream = client.streamEcg(
        StreamEcgRequest(clientId: config.clientId),
      );

      _ecgSub = ecgStream.listen(
        (chunk) {
          if (_isDisposed) return;
          _handleEcgChunk(chunk);
        },
        onError: (err) {
          _handleError('ECG stream error: $err');
        },
        onDone: () {
          _handleDisconnect('ECG stream closed by server');
        },
        cancelOnError: true,
      );

      // 3. Stream Discrete Cardiac Events
      final eventStream = client.streamCardiacEvents(
        StreamEventsRequest(clientId: config.clientId),
      );

      _eventSub = eventStream.listen(
        (event) {
          if (_isDisposed) return;
          _handleCardiacEvent(event);
        },
        onError: (_) {},
        onDone: () {},
        cancelOnError: false,
      );

      // 4. Stream Operational & DSP Diagnostic Logs
      final logStream = client.streamLogs(
        StreamLogsRequest(
          clientId: config.clientId,
          minLevel: LogLevel.DEBUG,
        ),
      );

      _logSub = logStream.listen(
        (log) {
          if (_isDisposed) return;
          _handleLogEntry(log);
        },
        onError: (_) {},
        onDone: () {},
        cancelOnError: false,
      );

      state = state.copyWith(
        connectionStatus: ConnectionStatus.connected,
        lastHeartbeat: DateTime.now(),
        clearError: true,
      );
    } catch (e) {
      _handleError('Connection failed: $e');
    }
  }

  void _handleEcgChunk(EcgWaveformChunk chunk) {
    if (state.isFrozen) {
      // If frozen, keep metrics updated but do not advance waveform visual buffer
      if (chunk.hasMetrics()) {
        state = state.copyWith(
          metrics: chunk.metrics,
          sourceMode: chunk.sourceMode,
          totalSamples: state.totalSamples + chunk.samples.length,
          lastHeartbeat: DateTime.now(),
        );
      }
      return;
    }

    final newBuffer = List<EcgPointData>.from(state.buffer);
    int cursor = state.cursorIndex;
    final cap = TelemetryState.bufferCapacity;

    for (final s in chunk.samples) {
      final point = EcgPointData(
        timestampMs: s.timestampUnixMillis.toInt(),
        rawAdc: s.rawAdc,
        voltageMv: s.voltageMv,
        filteredMv: s.filteredMv,
        isRPeak: s.isRPeak,
        leadOff: s.leadOff,
      );

      newBuffer[cursor] = point;
      cursor = (cursor + 1) % cap;
    }

    state = state.copyWith(
      connectionStatus: ConnectionStatus.connected,
      buffer: newBuffer,
      cursorIndex: cursor,
      metrics: chunk.hasMetrics() ? chunk.metrics : state.metrics,
      sourceMode: chunk.sourceMode,
      totalSamples: state.totalSamples + chunk.samples.length,
      lastHeartbeat: DateTime.now(),
      clearError: true,
    );
  }

  void _handleCardiacEvent(CardiacEvent event) {
    final updated = [event, ...state.cardiacEvents];
    if (updated.length > _maxEvents) {
      updated.removeRange(_maxEvents, updated.length);
    }
    state = state.copyWith(cardiacEvents: updated);
  }

  void _handleLogEntry(LogEntry log) {
    final now = DateTime.now();
    final isHeartbeat =
        log.component == 'health' || log.message.contains('Heartbeat');

    final updated = [log, ...state.logs];
    if (updated.length > _maxLogs) {
      updated.removeRange(_maxLogs, updated.length);
    }

    state = state.copyWith(
      logs: updated,
      lastHeartbeat: isHeartbeat ? now : state.lastHeartbeat,
    );
  }

  void _handleError(String message) {
    if (_isDisposed) return;
    state = state.copyWith(
      connectionStatus: ConnectionStatus.error,
      errorMessage: message,
    );
    _scheduleReconnect();
  }

  void _handleDisconnect(String reason) {
    if (_isDisposed) return;
    state = state.copyWith(
      connectionStatus: ConnectionStatus.disconnected,
      errorMessage: reason,
    );
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _cleanupSubscriptions();
    _reconnectTimer?.cancel();
    if (_isDisposed) return;

    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (!_isDisposed) {
        _connect();
      }
    });
  }

  void _cleanupSubscriptions() {
    _ecgSub?.cancel();
    _ecgSub = null;
    _eventSub?.cancel();
    _eventSub = null;
    _logSub?.cancel();
    _logSub = null;
  }

  // --- Clinical Display Controls ---

  void toggleSweepMode() {
    final next = state.sweepMode == SweepMode.eraseBarSweep
        ? SweepMode.continuousScroll
        : SweepMode.eraseBarSweep;
    state = state.copyWith(sweepMode: next);
  }

  void setPaperSpeed(PaperSpeed speed) {
    state = state.copyWith(paperSpeed: speed);
  }

  void setGain(GainSetting gain) {
    state = state.copyWith(gain: gain);
  }

  void toggleFilter() {
    final next = state.filterMode == SignalFilterMode.dspFiltered
        ? SignalFilterMode.rawAdc
        : SignalFilterMode.dspFiltered;
    state = state.copyWith(filterMode: next);
  }

  void toggleFreeze() {
    state = state.copyWith(isFrozen: !state.isFrozen);
  }

  Future<void> configureSource({
    SourceMode? mode,
    int? targetSimBpm,
    bool resetDsp = false,
  }) async {
    final client = ref.read(telemetryClientProvider);
    try {
      final req = ConfigureSourceRequest(
        sourceMode: mode ?? state.sourceMode,
        targetSimBpm: targetSimBpm ?? state.targetSimBpm,
        resetDsp: resetDsp,
      );
      final res = await client.configureSource(req);
      state = state.copyWith(
        sourceMode: res.sourceMode,
        targetSimBpm: res.targetSimBpm > 0 ? res.targetSimBpm : state.targetSimBpm,
      );
    } catch (_) {}
  }

  Future<String> exportCsv() async {
    final buffer = StringBuffer();
    buffer.writeln('index,timestamp_ms,raw_adc,voltage_mv,filtered_mv,is_r_peak,lead_off');

    final cap = TelemetryState.bufferCapacity;
    final cursor = state.cursorIndex;

    // Export in chronological order
    for (int i = 0; i < cap; i++) {
      final idx = (cursor + i) % cap;
      final pt = state.buffer[idx];
      if (pt.timestampMs > 0) {
        buffer.writeln(
          '$i,${pt.timestampMs},${pt.rawAdc},${pt.voltageMv.toStringAsFixed(4)},'
          '${pt.filteredMv.toStringAsFixed(4)},${pt.isRPeak ? 1 : 0},${pt.leadOff ? 1 : 0}',
        );
      }
    }

    final csvText = buffer.toString();
    await Clipboard.setData(ClipboardData(text: csvText));
    return csvText;
  }

  void clearEvents() {
    state = state.copyWith(cardiacEvents: const []);
  }

  void clearLogs() {
    state = state.copyWith(logs: const []);
  }

  void reconnect() {
    _reconnectTimer?.cancel();
    _connect();
  }
}
