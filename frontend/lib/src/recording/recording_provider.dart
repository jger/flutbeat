import 'dart:async';
import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cardiac_metrics.dart';
import '../models/telemetry_state.dart';
import '../services/usb_serial_service.dart';
import 'recording_models.dart';
import 'recording_store.dart';
import 'file_export_service.dart';

final recordingClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);
final recordingStoreProvider = Provider<RecordingStore>(
  (ref) => RecordingStore(),
);
final recordingProvider =
    NotifierProvider<RecordingController, RecordingStatus>(
      RecordingController.new,
    );
final recordingLibraryProvider = FutureProvider<List<RecordingSession>>((ref) {
  ref.watch(recordingProvider.select((s) => s.libraryRevision));
  return ref.watch(recordingStoreProvider).list();
});

class RecordingController extends Notifier<RecordingStatus> {
  final _history = ListQueue<Map<String, dynamic>>();
  final _pending = <Map<String, dynamic>>[];
  Timer? _timer;
  Future<void>? _flushFuture;
  Future<void>? _stopFuture;
  bool _initialized = false;
  int _batch = 0;
  int _sampleCount = 0;
  DateTime? _lastSampleAt;
  DateTime? _recordedLastAt;

  @override
  RecordingStatus build() {
    ref.onDispose(() => _timer?.cancel());
    listenSelf((previous, next) {
      if (previous?.isRecording != next.isRecording) {
        unawaited(FileExportService.setRecordingActive(next.isRecording));
      }
    });
    return const RecordingStatus();
  }

  void capture(
    RawEcgFrame frame,
    EcgPointData point,
    CardiacMetrics metrics,
    TelemetryState display,
    CardiacEvent? event,
  ) {
    final now = ref.read(recordingClockProvider)().toUtc();
    _lastSampleAt = now;
    final row = <String, dynamic>{
      'row_type': 'sample',
      'timestamp_utc': now.toIso8601String(),
      'source_timestamp_ms': frame.timestampMs,
      'raw_adc': frame.rawAdc,
      'voltage_mv': point.voltageMv,
      'filtered_mv': point.filteredMv,
      'lo_plus': frame.loPlus,
      'lo_minus': frame.loMinus,
      'lead_off': point.leadOff,
      'is_r_peak': point.isRPeak,
      'heart_rate_bpm': metrics.heartRateBpm,
      'rr_interval_ms': metrics.rrIntervalMs,
      'sdnn_ms': metrics.hrvSdnnMs,
      'rmssd_ms': metrics.hrvRmssdMs,
      'signal_quality_percent': metrics.signalQualityPercent,
      'lead_status': metrics.leadStatus.name,
      'rhythm': metrics.rhythm.name,
      'total_beats': metrics.totalBeats,
      'last_beat_timestamp_ms': metrics.lastBeatTimestampMs,
      'event_type': event?.type.name,
      'event_description': event?.description,
      'event_sequence': event?.sequenceNumber,
      'event_timestamp_ms': event?.timestampUnixMillis,
      'event_heart_rate_bpm': event?.heartRateBpm,
      'paper_speed_mm_s': display.paperSpeed.mmPerSec,
      'gain_mm_mv': display.gain.mmPerMv,
      'vertical_zoom': display.verticalZoom,
      'filter_mode': display.filterMode.name,
      'sweep_mode': display.sweepMode.name,
      'display_frozen': display.isFrozen,
      'source': display.sourceMode.name,
    };
    _history.add(row);
    while (_history.length > 1250 ||
        (_history.isNotEmpty &&
            now
                    .difference(
                      DateTime.parse(_history.first['timestamp_utc'] as String),
                    )
                    .inMilliseconds >
                5000)) {
      _history.removeFirst();
    }
    if (state.isRecording) {
      if (now.difference(state.session!.recordPressedAt).inSeconds >= 600 ||
          _sampleCount >= state.session!.preRollSamples + 150000) {
        unawaited(stop(reason: '10 minute limit'));
      } else {
        _appendSample(row);
      }
    }
  }

  void _appendSample(Map<String, dynamic> row) {
    _pending.add({
      ...row,
      'sample_index': _sampleCount,
      'offset_ms': _sampleCount * 4,
    });
    _sampleCount++;
    _recordedLastAt = DateTime.parse(row['timestamp_utc'] as String);
  }

  void captureLog(LogEntry entry) {
    if (!state.isRecording) return;
    _pending.add({
      'row_type': 'log',
      'timestamp_utc': DateTime.fromMillisecondsSinceEpoch(
        entry.timestampUnixMillis,
        isUtc: true,
      ).toIso8601String(),
      'offset_ms': _sampleCount * 4,
      'level': entry.level.name,
      'component': entry.component,
      'message': entry.message,
    });
  }

  void clearHistory() {
    _history.clear();
    _lastSampleAt = null;
  }

  Future<void> start({required String device, required int baudRate}) async {
    if (state.session != null || state.isSaving) return;
    final now = ref.read(recordingClockProvider)().toUtc();
    if (_lastSampleAt == null ||
        now.difference(_lastSampleAt!).inSeconds >= 2) {
      state = RecordingStatus(
        error:
            'Waiting for live ECG samples. Connect the device and try again.',
        libraryRevision: state.libraryRevision,
      );
      return;
    }
    _batch = 0;
    _sampleCount = 0;
    _initialized = false;
    _pending.clear();
    final seed = _history.toList();
    for (final row in seed) {
      _appendSample(row);
    }
    final session = RecordingSession(
      id: now.microsecondsSinceEpoch.toString(),
      startedAt: DateTime.parse(seed.first['timestamp_utc'] as String),
      recordPressedAt: now,
      device: device,
      baudRate: baudRate,
      preRollSamples: seed.length,
    );
    state = RecordingStatus(
      session: session,
      isRecording: true,
      isSaving: true,
      libraryRevision: state.libraryRevision,
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.isRecording) return;
      final elapsed = ref
          .read(recordingClockProvider)()
          .toUtc()
          .difference(session.recordPressedAt)
          .inSeconds;
      state = RecordingStatus(
        session: session,
        isRecording: true,
        elapsedSeconds: elapsed,
        libraryRevision: state.libraryRevision,
      );
      if (elapsed >= 600) {
        unawaited(stop(reason: '10 minute limit'));
      } else {
        unawaited(_flush().catchError((Object error) => _saveFailed(error)));
      }
    });
    try {
      await _flush();
      if (state.isRecording) {
        state = RecordingStatus(
          session: session,
          isRecording: true,
          libraryRevision: state.libraryRevision,
        );
      }
    } catch (error) {
      _saveFailed(error);
    }
  }

  Future<void> _flush() {
    return _flushFuture ??= _persistPending().whenComplete(
      () => _flushFuture = null,
    );
  }

  Future<void> _persistPending() async {
    final store = ref.read(recordingStoreProvider);
    final session = state.session;
    if (session == null) return;
    if (!_initialized) {
      await store.saveMetadata(session);
      _initialized = true;
    }
    if (_pending.isEmpty) return;
    final rows = List<Map<String, dynamic>>.of(_pending);
    _pending.clear();
    try {
      await store.writeBatch(session.id, _batch, rows);
      _batch++;
    } catch (_) {
      _pending.insertAll(0, rows);
      rethrow;
    }
  }

  void _saveFailed(Object error) {
    _timer?.cancel();
    state = RecordingStatus(
      session: state.session,
      error:
          'Recording stopped: could not save locally. Free storage and tap Retry save. ($error)',
      elapsedSeconds: state.elapsedSeconds,
      libraryRevision: state.libraryRevision,
    );
  }

  Future<void> stop({String reason = 'manual'}) {
    return _stopFuture ??= _finish(reason)
        .whenComplete(() => _stopFuture = null);
  }

  Future<void> _finish(String reason) async {
    final session = state.session;
    if (session == null) return;
    _timer?.cancel();
    final elapsed = state.elapsedSeconds;
    state = RecordingStatus(
      session: session,
      isSaving: true,
      elapsedSeconds: elapsed,
      libraryRevision: state.libraryRevision,
    );
    try {
      await _flush();
      while (_pending.isNotEmpty) {
        await _flush();
      }
      final finished = session.finish(
        _sampleCount,
        _recordedLastAt ?? ref.read(recordingClockProvider)().toUtc(),
        reason,
      );
      await ref.read(recordingStoreProvider).saveMetadata(finished);
      state = RecordingStatus(libraryRevision: state.libraryRevision + 1);
    } catch (error) {
      _saveFailed(error);
    }
  }
}
