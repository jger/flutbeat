import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:flutbeat_frontend/src/models/cardiac_metrics.dart';
import 'package:flutbeat_frontend/src/models/telemetry_state.dart';
import 'package:flutbeat_frontend/src/providers/config_provider.dart';
import 'package:flutbeat_frontend/src/providers/telemetry_provider.dart';
import 'package:flutbeat_frontend/src/recording/file_export_service.dart';
import 'package:flutbeat_frontend/src/recording/recording_models.dart';
import 'package:flutbeat_frontend/src/recording/recording_provider.dart';
import 'package:flutbeat_frontend/src/recording/recording_store.dart';
import 'package:flutbeat_frontend/src/recording/recording_export.dart';
import 'package:flutbeat_frontend/src/services/usb_serial_service.dart';

const metrics = CardiacMetrics(
  heartRateBpm: 72,
  rrIntervalMs: 833,
  hrvSdnnMs: 12,
  hrvRmssdMs: 15,
  leadStatus: LeadStatus.leadsConnected,
  signalQualityPercent: 98,
  rhythm: RhythmClassification.normalSinus,
);
const point = EcgPointData(
  timestampMs: 0,
  rawAdc: 512,
  voltageMv: 0,
  filteredMv: 0,
);
const frame = RawEcgFrame(
  rawAdc: 512,
  loPlus: false,
  loMinus: false,
  timestampMs: 0,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late RecordingStore store;
  late ProviderContainer container;
  late DateTime now;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('flutbeat-recording-');
    store = RecordingStore(rootOverride: root);
    now = DateTime.utc(2026, 11, 9, 12);
    container = ProviderContainer(
      overrides: [
        recordingStoreProvider.overrideWithValue(store),
        recordingClockProvider.overrideWithValue(() => now),
      ],
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          FileExportService.channel,
          (call) async => null,
        );
  });
  tearDown(() async {
    container.dispose();
    await root.delete(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(FileExportService.channel, null);
  });

  test(
    'Five-second pre-roll captures all metrics and frozen-display samples',
    () async {
      final recorder = container.read(recordingProvider.notifier);
      for (int i = 0; i < 1300; i++) {
        now = now.add(const Duration(milliseconds: 4));
        recorder.capture(frame, point, metrics, TelemetryState(), null);
      }
      await recorder.start(device: 'ESP', baudRate: 115200);
      expect(container.read(recordingProvider).isRecording, isTrue);
      for (int i = 0; i < 10; i++) {
        now = now.add(const Duration(milliseconds: 4));
        recorder.capture(
          frame,
          point,
          metrics,
          TelemetryState(isFrozen: true),
          null,
        );
      }
      await recorder.stop();
      final sessions = await store.list();
      expect(sessions, hasLength(1));
      expect(sessions.single.preRollSamples, 1250);
      expect(sessions.single.sampleCount, 1260);
      final data = await store.read(sessions.single);
      expect(data.samples, hasLength(1260));
      expect(data.samples.first['sample_index'], 0);
      expect(data.samples.last['sample_index'], 1259);
      expect(data.samples.last['display_frozen'], isTrue);
      expect(data.samples.last['sdnn_ms'], 12);
      expect(data.samples.first['source_timestamp_ms'], 0);
      expect(container.read(recordingProvider).session, isNull);
    },
  );

  test(
    'Canceled Save file returns false and passes the requested MIME type',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(FileExportService.channel, (call) async {
            expect(call.method, 'saveFile');
            expect(call.arguments['mimeType'], 'text/csv');
            expect(call.arguments['name'], 'example.csv');
            return false;
          });
      expect(
        await FileExportService().save(File('/tmp/example.csv'), 'text/csv'),
        isFalse,
      );
    },
  );

  testWidgets(
    'USB polling finds a later device and does not repeat denied permission prompts',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final usb = _PollingUsb();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            recordingStoreProvider.overrideWithValue(store),
            telemetryProvider.overrideWith(() => Telemetry(serialService: usb)),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) =>
                  Text(ref.watch(telemetryProvider).connectionStatus.name),
            ),
          ),
        ),
      );
      for (int i = 0; i < 6; i++) {
        await tester.pump();
      }
      expect(usb.attempts, 0);
      usb.available = true;
      await tester.pump(const Duration(seconds: 5));
      for (int i = 0; i < 6; i++) {
        await tester.pump();
      }
      expect(usb.attempts, 1);
      await tester.pump(const Duration(seconds: 10));
      for (int i = 0; i < 6; i++) {
        await tester.pump();
      }
      expect(usb.attempts, 1);
      final scope = ProviderScope.containerOf(
        tester.element(find.byType(Text)),
      );
      scope.read(telemetryProvider.notifier).reconnect();
      for (int i = 0; i < 6; i++) {
        await tester.pump();
      }
      expect(usb.attempts, 2);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  test('Viewer reads only the requested sample window', () async {
    final session = RecordingSession(
      id: '222',
      startedAt: now,
      recordPressedAt: now,
      device: 'test',
      baudRate: 115200,
      sampleCount: 750,
    );
    await store.saveMetadata(session);
    await store.writeBatch(session.id, 0, [
      for (int i = 0; i < 750; i++) _row(i),
    ]);
    final window = await store.readWindow(session, 1, 2);
    expect(window.length, 250);
    expect(window.first['sample_index'], 250);
    expect(window.last['sample_index'], 499);
    expect(() => store.readWindow(session, 0, 61), throwsArgumentError);
  });

  test('Stale pre-roll is rejected until live samples arrive', () async {
    final recorder = container.read(recordingProvider.notifier);
    recorder.capture(frame, point, metrics, TelemetryState(), null);
    now = now.add(const Duration(seconds: 3));
    await recorder.start(device: 'ESP', baudRate: 115200);
    expect(container.read(recordingProvider).isRecording, isFalse);
    expect(
      container.read(recordingProvider).error,
      contains('Waiting for live ECG'),
    );
  });

  test('10 minute limit stops and saves automatically', () async {
    final recorder = container.read(recordingProvider.notifier);
    recorder.capture(frame, point, metrics, TelemetryState(), null);
    await recorder.start(device: 'ESP', baudRate: 115200);
    recorder.capture(frame, point, metrics, TelemetryState(), null);
    now = now.add(const Duration(minutes: 10));
    recorder.capture(frame, point, metrics, TelemetryState(), null);
    await _until(() => container.read(recordingProvider).session == null);
    final session = (await store.list()).single;
    expect(session.stopReason, '10 minute limit');
    expect(session.sampleCount, 2);
  });

  test('Failed batch retries without duplicate rows', () async {
    container.dispose();
    final failing = _FailOnceStore(root);
    container = ProviderContainer(
      overrides: [
        recordingStoreProvider.overrideWithValue(failing),
        recordingClockProvider.overrideWithValue(() => now),
      ],
    );
    final recorder = container.read(recordingProvider.notifier);
    recorder.capture(frame, point, metrics, TelemetryState(), null);
    await recorder.start(device: 'ESP', baudRate: 115200);
    expect(container.read(recordingProvider).hasUnsavedSession, isTrue);
    expect(container.read(recordingProvider).error, contains('Retry save'));
    await recorder.stop(reason: 'retry');
    final session = (await store.list()).single;
    expect((await store.read(session)).samples, hasLength(1));
    expect(container.read(recordingProvider).error, isNull);
  });

  test('Interrupted sessions recover committed batches only', () async {
    final session = RecordingSession(
      id: '1234',
      startedAt: now,
      recordPressedAt: now,
      device: 'ESP',
      baudRate: 115200,
    );
    await store.saveMetadata(session);
    await store.writeBatch(session.id, 0, [_row(0), _row(1)]);
    await File('${root.path}/1234/00000001.tmp').writeAsString('{incomplete');
    final recoveredSession = await store.inspect(session, recover: true);
    final recovered = await store.read(recoveredSession);
    expect(recovered.session.stopReason, 'interrupted');
    expect(recovered.session.sampleCount, 2);
    expect((await store.list()).single.isComplete, isTrue);
  });

  test('CSV filters fields and range and preserves timestamp zero', () {
    final session = RecordingSession(
      id: '123',
      startedAt: now,
      recordPressedAt: now,
      device: '=ESP',
      baudRate: 115200,
    );
    final data = RecordingData(session, [_row(0), _row(1), _row(2)]);
    final csv = recordingCsv(
      data,
      const RecordingExportOptions(
        startSeconds: 0,
        endSeconds: 0.008,
        groups: {'Raw ECG'},
      ),
    );
    final lines = csv.trim().split('\n');
    expect(lines, hasLength(3));
    expect(lines.first, contains('raw_adc'));
    expect(lines.first, isNot(contains('filtered_mv')));
    expect(lines[1], contains("'=ESP"));
    expect(lines[1], contains('"0"'));
  });

  test(
    'Full 10-minute CSV export streams all 150000 samples from disk',
    () async {
      final session = RecordingSession(
        id: '150000',
        startedAt: now,
        recordPressedAt: now,
        device: 'Synthetic 10-minute test',
        baudRate: 115200,
        sampleCount: 150000,
        stopReason: 'manual',
      );
      await store.saveMetadata(session);
      for (int batch = 0; batch < 120; batch++) {
        await store.writeBatch(session.id, batch, [
          for (int i = batch * 1250; i < (batch + 1) * 1250; i++) _row(i),
        ]);
      }
      final path = '${root.path}/full.csv';
      await store.exportToFile(
        session,
        const RecordingExportOptions(
          startSeconds: 0,
          endSeconds: 600,
          groups: {'Raw ECG', 'Filtered ECG'},
        ),
        pdf: false,
        outputPath: path,
      );
      final lines = File(path)
          .openRead()
          .transform(utf8.decoder)
          .transform(const LineSplitter());
      int count = 0;
      String? lastLine;
      await for (final line in lines) {
        count++;
        lastLine = line;
      }
      expect(count, 150001);
      expect(lastLine!.split(',')[8], '"149999"');
      final pdfPath = '${root.path}/full.pdf';
      await store.exportToFile(
        session,
        const RecordingExportOptions(
          startSeconds: 0,
          endSeconds: 600,
          groups: {'Cardiac metrics', 'Signal & events'},
        ),
        pdf: true,
        outputPath: pdfPath,
      );
      expect(await File(pdfPath).length(), greaterThan(1000));
      await File('/tmp/flutbeat-10-minute-report.pdf')
          .writeAsBytes(await File(pdfPath).readAsBytes());
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test('PDF renders summary and three selected strips', () async {
    final rows = [for (int i = 0; i < 7500; i++) _row(i)];
    final session = RecordingSession(
      id: '123',
      startedAt: now,
      recordPressedAt: now,
      device: 'ESP / AD8232',
      baudRate: 115200,
      sampleCount: rows.length,
      preRollSamples: 1250,
      stopReason: 'manual',
    );
    final pdf = await buildRecordingExport(
      RecordingExportJob(
        RecordingData(session, rows),
        const RecordingExportOptions(
          startSeconds: 0,
          endSeconds: 30,
          groups: {'Cardiac metrics', 'Signal & events'},
        ),
        true,
      ),
    );
    expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
    expect(selectedStripStarts(0, 30), [0, 12, 24]);
    await File('/tmp/flutbeat-recording-report.pdf').writeAsBytes(pdf);
  });

  test(
    'Freeze holds display while USB acquisition continues; disconnect saves',
    () async {
      container.dispose();
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final usb = _FakeUsb();
      container = ProviderContainer(
        overrides: [
          recordingStoreProvider.overrideWithValue(store),
          sharedPreferencesProvider.overrideWithValue(prefs),
          telemetryProvider.overrideWith(() => Telemetry(serialService: usb)),
        ],
      );
      final telemetry = container.read(telemetryProvider.notifier);
      await _until(() => container.read(telemetryProvider).isConnected);
      usb.frames.add(frame);
      final recorder = container.read(recordingProvider.notifier);
      await recorder.start(device: 'ESP', baudRate: 115200);
      telemetry.toggleFreeze();
      final frozen = container.read(telemetryProvider).buffer;
      usb.frames.add(
        const RawEcgFrame(
          rawAdc: 650,
          loPlus: false,
          loMinus: false,
          timestampMs: 4,
        ),
      );
      expect(container.read(telemetryProvider).buffer, same(frozen));
      expect(container.read(telemetryProvider).totalSamples, 2);
      telemetry.toggleFreeze();
      expect(container.read(telemetryProvider).buffer, isNot(same(frozen)));
      expect(container.read(telemetryProvider).buffer[1].rawAdc, 650);
      await usb.disconnect();
      await _until(() => container.read(recordingProvider).session == null);
      final session = (await store.list()).single;
      expect(session.stopReason, 'USB disconnected');
      expect(session.sampleCount, 2);
      expect(container.read(telemetryProvider).isConnected, isFalse);
    },
  );
}

Map<String, dynamic> _row(int i) => {
  'row_type': 'sample',
  'sample_index': i,
  'offset_ms': i * 4,
  'source_timestamp_ms': i * 4,
  'timestamp_utc': DateTime.utc(
    2026,
    11,
    9,
    12,
  ).add(Duration(milliseconds: i * 4)).toIso8601String(),
  'raw_adc': 512,
  'voltage_mv': 0.5 * math.sin(i / 20),
  'filtered_mv': 0.5 * math.sin(i / 20) + (i % 208 < 4 ? 0.8 : 0),
  'lead_status': i >= 2000 && i < 2250 ? 'leadOffBoth' : 'leadsConnected',
  'heart_rate_bpm': 72,
  'is_r_peak': i % 208 == 0,
};

Future<void> _until(bool Function() condition) async {
  for (int i = 0; i < 300; i++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Condition not reached');
}

class _FailOnceStore extends RecordingStore {
  _FailOnceStore(Directory root) : super(rootOverride: root);
  bool failNext = true;
  @override
  Future<void> writeBatch(
    String id,
    int sequence,
    List<Map<String, dynamic>> rows,
  ) async {
    if (failNext) {
      failNext = false;
      throw const FileSystemException('Disk full');
    }
    await super.writeBatch(id, sequence, rows);
  }
}

class _FakeUsb extends UsbSerialService {
  final frames = StreamController<RawEcgFrame>.broadcast(sync: true);
  final disconnected = StreamController<void>.broadcast(sync: true);
  bool connected = false;
  @override
  Stream<RawEcgFrame> get frameStream => frames.stream;
  @override
  Stream<void> get disconnectionStream => disconnected.stream;
  @override
  Future<List<UsbDevice>> getAvailableDevices() async => [
    UsbDevice('ESP', 1, 1, 'ESP', null, 1, null, 1),
  ];
  @override
  void listenToUsbEvents({
    required void Function(UsbDevice?) onAttached,
    required void Function(UsbDevice?) onDetached,
  }) {}
  @override
  Future<bool> connect({UsbDevice? device, int baudRate = 115200}) async {
    connected = true;
    return true;
  }

  @override
  Future<void> disconnect() async {
    if (connected) {
      connected = false;
      disconnected.add(null);
    }
  }

  @override
  void dispose() {
    frames.close();
    disconnected.close();
    super.dispose();
  }
}

class _PollingUsb extends _FakeUsb {
  bool available = false;
  int attempts = 0;
  @override
  Future<List<UsbDevice>> getAvailableDevices() async =>
      available ? super.getAvailableDevices() : [];
  @override
  Future<bool> connect({UsbDevice? device, int baudRate = 115200}) async {
    attempts++;
    return false;
  }
}
