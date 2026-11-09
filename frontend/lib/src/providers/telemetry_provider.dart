import 'dart:async';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../dsp/ecg_dsp_pipeline.dart';
import '../models/cardiac_metrics.dart';
import '../models/telemetry_state.dart';
import '../services/usb_serial_service.dart';
import 'config_provider.dart';

part 'telemetry_provider.g.dart';

@Riverpod(keepAlive: true)
class Telemetry extends _$Telemetry {
  static const int _maxEvents = 100;
  static const int _maxLogs = 200;

  final UsbSerialService _serialService = UsbSerialService();
  final EcgDspPipeline _dsp = EcgDspPipeline();

  StreamSubscription<RawEcgFrame>? _frameSub;
  StreamSubscription<String>? _statusSub;
  Timer? _uptimeTimer;
  bool _isDisposed = false;

  @override
  TelemetryState build() {
    final config = ref.watch(configProvider);

    _isDisposed = false;

    ref.onDispose(() {
      _isDisposed = true;
      _cleanup();
    });

    // Start 1-second uptime ticker
    _uptimeTimer?.cancel();
    _uptimeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isDisposed) {
        state = state.copyWith(uptimeSeconds: state.uptimeSeconds + 1);
      }
    });

    // Initialize direct USB Serial connection
    Future.microtask(() => _startUsbSerial(config.baudRate));

    return TelemetryState(
      sourceMode: SourceMode.usbSerial,
      baudRate: config.baudRate,
      connectionStatus: ConnectionStatus.connecting,
    );
  }

  void _cleanup() {
    _uptimeTimer?.cancel();
    _uptimeTimer = null;
    _frameSub?.cancel();
    _frameSub = null;
    _statusSub?.cancel();
    _statusSub = null;
    _serialService.dispose();
  }

  Future<void> _startUsbSerial(int baudRate) async {
    await _serialService.disconnect();

    _frameSub?.cancel();
    _statusSub?.cancel();

    state = state.copyWith(
      connectionStatus: ConnectionStatus.connecting,
      sourceMode: SourceMode.usbSerial,
      baudRate: baudRate,
      clearError: true,
    );

    _addLog(LogLevel.info, 'USB-OTG', 'Scanning for connected USB-to-UART devices...');

    final devices = await _serialService.getAvailableDevices();
    if (devices.isEmpty) {
      _addLog(LogLevel.warn, 'USB-OTG', 'No physical USB device found. Check OTG cable & permissions.');
      state = state.copyWith(
        connectionStatus: ConnectionStatus.disconnected,
        errorMessage: 'No USB device detected. Connect ESP board via OTG cable.',
      );
      return;
    }

    final targetDevice = devices.first;
    final devName = targetDevice.productName ?? targetDevice.deviceName;

    _statusSub = _serialService.statusStream.listen((msg) {
      _addLog(LogLevel.info, 'USB-OTG', msg);
    });

    _frameSub = _serialService.frameStream.listen(
      _handleRawFrame,
      onError: (err) {
        _handleError('USB stream error: $err');
      },
    );

    final connected = await _serialService.connect(
      device: targetDevice,
      baudRate: baudRate,
    );

    if (connected) {
      state = state.copyWith(
        connectionStatus: ConnectionStatus.connected,
        connectedDeviceName: devName,
        clearError: true,
      );
      _addLog(LogLevel.info, 'USB-OTG', 'Connected to $devName @ $baudRate baud.');
    } else {
      state = state.copyWith(
        connectionStatus: ConnectionStatus.error,
        errorMessage: 'Failed to open USB port for $devName.',
      );
    }
  }

  void _handleRawFrame(RawEcgFrame frame) {
    if (_isDisposed || state.isFrozen) return;

    final processed = _dsp.processSample(
      rawAdc: frame.rawAdc,
      loPlus: frame.loPlus,
      loMinus: frame.loMinus,
      timestampMs: frame.timestampMs,
    );

    final newBuffer = List<EcgPointData>.from(state.buffer);
    final cursor = state.cursorIndex;
    final cap = TelemetryState.bufferCapacity;

    newBuffer[cursor] = EcgPointData(
      timestampMs: processed.timestampMs,
      rawAdc: processed.rawAdc,
      voltageMv: processed.voltageMv,
      filteredMv: processed.filteredMv,
      isRPeak: processed.isRPeak,
      leadOff: processed.leadOff,
    );

    final nextCursor = (cursor + 1) % cap;

    List<CardiacEvent> updatedEvents = state.cardiacEvents;
    if (processed.event != null) {
      updatedEvents = [processed.event!, ...updatedEvents];
      if (updatedEvents.length > _maxEvents) {
        updatedEvents = updatedEvents.sublist(0, _maxEvents);
      }
    }

    state = state.copyWith(
      connectionStatus: ConnectionStatus.connected,
      buffer: newBuffer,
      cursorIndex: nextCursor,
      metrics: processed.metrics,
      cardiacEvents: updatedEvents,
      totalSamples: state.totalSamples + 1,
      lastHeartbeat: DateTime.now(),
      clearError: true,
    );
  }

  void _addLog(LogLevel level, String component, String message) {
    if (_isDisposed) return;
    final entry = LogEntry(
      level: level,
      component: component,
      message: message,
      timestampUnixMillis: DateTime.now().millisecondsSinceEpoch,
    );
    final updated = [entry, ...state.logs];
    if (updated.length > _maxLogs) {
      updated.removeRange(_maxLogs, updated.length);
    }
    state = state.copyWith(logs: updated);
  }

  void _handleError(String message) {
    if (_isDisposed) return;
    _addLog(LogLevel.error, 'CORE', message);
    state = state.copyWith(
      connectionStatus: ConnectionStatus.error,
      errorMessage: message,
    );
  }

  // --- Display & Operation Controls ---

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

  void setVerticalZoom(double zoom) {
    state = state.copyWith(verticalZoom: zoom.clamp(0.2, 10.0));
  }

  void adjustVerticalZoom(double deltaScale) {
    setVerticalZoom(state.verticalZoom * deltaScale);
  }

  void zoomInVertical() {
    setVerticalZoom(state.verticalZoom * 1.25);
  }

  void zoomOutVertical() {
    setVerticalZoom(state.verticalZoom / 1.25);
  }

  void resetVerticalZoom() {
    state = state.copyWith(verticalZoom: 1.0);
  }

  void autoScaleVerticalZoom() {
    double minVal = 0.0;
    double maxVal = 0.0;
    bool hasData = false;

    for (final pt in state.buffer) {
      if (pt.timestampMs == 0) continue;
      final val = state.filterMode == SignalFilterMode.dspFiltered
          ? pt.filteredMv
          : pt.voltageMv;
      if (!hasData) {
        minVal = val;
        maxVal = val;
        hasData = true;
      } else {
        if (val < minVal) minVal = val;
        if (val > maxVal) maxVal = val;
      }
    }

    final p2p = maxVal - minVal;
    if (p2p > 0.05) {
      final newZoom = (1.8 / p2p).clamp(0.25, 8.0);
      setVerticalZoom(newZoom);
    }
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
    int? baudRate,
    bool resetDsp = false,
  }) async {
    if (resetDsp) {
      _dsp.reset();
    }

    final newBaud = baudRate ?? state.baudRate;

    await ref.read(configProvider.notifier).updateConfig(
          baudRate: newBaud,
        );

    state = state.copyWith(
      baudRate: newBaud,
    );

    await _startUsbSerial(newBaud);
  }

  Future<String> exportCsv() async {
    final buffer = StringBuffer();
    buffer.writeln('index,timestamp_ms,raw_adc,voltage_mv,filtered_mv,is_r_peak,lead_off');

    final cap = TelemetryState.bufferCapacity;
    final cursor = state.cursorIndex;

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

  void reconnect({int? baudRate}) {
    _startUsbSerial(baudRate ?? state.baudRate);
  }
}
