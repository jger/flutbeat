import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutbeat_frontend/src/dsp/ecg_dsp_pipeline.dart';
import 'package:flutbeat_frontend/src/dsp/ecg_simulator.dart';
import 'package:flutbeat_frontend/src/models/cardiac_metrics.dart';
import 'package:flutbeat_frontend/src/models/connection_config.dart';
import 'package:flutbeat_frontend/src/models/telemetry_state.dart';
import 'package:flutbeat_frontend/src/providers/config_provider.dart';
import 'package:flutbeat_frontend/src/providers/telemetry_provider.dart';
import 'package:flutbeat_frontend/src/ui/screens/config_screen.dart';
import 'package:flutbeat_frontend/src/ui/screens/dashboard_screen.dart';
import 'package:flutbeat_frontend/src/ui/widgets/blinking_heartbeat_dot.dart';
import 'package:flutbeat_frontend/src/ui/widgets/clinical_vitals_bar.dart';
import 'package:flutbeat_frontend/src/ui/widgets/ecg_control_toolbar.dart';
import 'package:flutbeat_frontend/src/ui/widgets/ecg_oscilloscope_painter.dart';
import 'package:flutbeat_frontend/src/ui/widgets/event_log_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConnectionConfig Model Tests', () {
    test('Default values are correct for direct USB OTG', () {
      const config = ConnectionConfig();
      expect(config.baudRate, 115200);
      expect(config.sourceMode, SourceMode.usbSerial);
      expect(config.targetSimBpm, 72);
      expect(config.selectedDeviceName, isNull);
    });

    test('Json serialization roundtrip', () {
      const config = ConnectionConfig(
        baudRate: 74880,
        sourceMode: SourceMode.simulator,
        targetSimBpm: 80,
        selectedDeviceName: 'WeMos D1 Mini CH340',
      );
      final json = config.toJson();
      final restored = ConnectionConfig.fromJson(json);
      expect(restored, equals(config));
    });
  });

  group('Pure Dart DSP & Simulator Engine Tests (No Backend Needed)', () {
    test('ADC to mV mapping', () {
      final baseline = adcToMv(512);
      expect(baseline.abs(), lessThan(0.05));

      final maxVal = adcToMv(1023);
      expect(maxVal, greaterThan(1.4));
      expect(maxVal, lessThan(1.7));

      final minVal = adcToMv(0);
      expect(minVal, lessThan(-1.4));
      expect(minVal, greaterThan(-1.7));
    });

    test('EcgSimulator generates valid ADC range and physiological signal', () {
      final sim = EcgSimulator(targetBpm: 75);
      int maxAdc = 0;
      for (int i = 0; i < 500; i++) {
        final sample = sim.nextSample();
        expect(sample.rawAdc, inInclusiveRange(0, 1023));
        expect(sample.loPlus, isFalse);
        expect(sample.loMinus, isFalse);
        if (sample.rawAdc > maxAdc) {
          maxAdc = sample.rawAdc;
        }
      }
      expect(maxAdc, greaterThan(800)); // R-peak excursion
    });

    test('EcgDspPipeline detects R-peaks and computes cardiac metrics', () {
      final pipeline = EcgDspPipeline();
      final sim = EcgSimulator(targetBpm: 60); // 1 Hz = 1 beat per second
      int rPeaksDetected = 0;

      // Feed 4 seconds of 250 Hz signal (1000 samples)
      for (int i = 0; i < 1000; i++) {
        final s = sim.nextSample();
        final processed = pipeline.processSample(
          rawAdc: s.rawAdc,
          loPlus: s.loPlus,
          loMinus: s.loMinus,
          timestampMs: i * 4,
        );

        if (processed.isRPeak) {
          rPeaksDetected++;
          expect(processed.event, isNotNull);
          expect(processed.event!.type, equals(CardiacEventType.rPeak));
        }
      }

      expect(rPeaksDetected, greaterThanOrEqualTo(2));
    });

    test('EcgDspPipeline accurately calculates BPM across different heart rates', () {
      for (final targetBpm in [50, 60, 72, 80, 100, 120]) {
        final pipeline = EcgDspPipeline();
        final sim = EcgSimulator(targetBpm: targetBpm);
        int detectedBpm = 0;

        // Feed 10 seconds of 250 Hz signal (2500 samples)
        for (int i = 0; i < 2500; i++) {
          final s = sim.nextSample();
          final processed = pipeline.processSample(
            rawAdc: s.rawAdc,
            loPlus: s.loPlus,
            loMinus: s.loMinus,
            timestampMs: i * 4,
          );
          if (processed.isRPeak) {
            detectedBpm = processed.metrics.heartRateBpm;
          }
        }

        // Expected to be within 2 BPM of target
        expect(
          (detectedBpm - targetBpm).abs(),
          lessThanOrEqualTo(2),
          reason: 'Failed for target BPM $targetBpm (detected: $detectedBpm)',
        );
      }
    });

    test('EcgDspPipeline recovers BPM detection after lead-off and reset', () {
      final pipeline = EcgDspPipeline();
      final sim = EcgSimulator(targetBpm: 75);

      // 1. Trigger lead-off
      pipeline.processSample(
        rawAdc: 1023,
        loPlus: true,
        loMinus: true,
        timestampMs: 0,
      );

      // 2. Feed regular signal after reconnection
      int peaksAfterReconnect = 0;
      for (int i = 1; i < 2500; i++) {
        final s = sim.nextSample();
        final p = pipeline.processSample(
          rawAdc: s.rawAdc,
          loPlus: s.loPlus,
          loMinus: s.loMinus,
          timestampMs: i * 4,
        );
        if (p.isRPeak) {
          peaksAfterReconnect++;
        }
      }

      expect(peaksAfterReconnect, greaterThanOrEqualTo(10));
    });

    test('EcgDspPipeline triggers Lead-Off status immediately', () {
      final pipeline = EcgDspPipeline();
      final processed = pipeline.processSample(
        rawAdc: 1023,
        loPlus: true,
        loMinus: true,
        timestampMs: 1000,
      );

      expect(processed.leadOff, isTrue);
      expect(processed.metrics.leadStatus, equals(LeadStatus.leadOffBoth));
      expect(processed.metrics.heartRateBpm, equals(0));
      expect(processed.event, isNotNull);
      expect(processed.event!.type, equals(CardiacEventType.leadOff));
    });
  });

  group('FlutBeat Clinical Dashboard UI Widget Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets(
        'Renders full graph view by default, reveals all UI when toggle icon button is tapped',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            telemetryProvider.overrideWith(() => TelemetryNotifierMock()),
          ],
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pump();

      // Verify AppBar elements
      expect(find.text('FlutBeat ECG Monitor'), findsOneWidget);
      expect(find.text('USB OTG: Direct ESP (115200 baud)'), findsOneWidget);
      expect(find.byType(BlinkingHeartbeatDot), findsOneWidget);

      // Oscilloscope Canvas uses all available space
      expect(find.byType(EcgOscilloscope), findsOneWidget);
      expect(find.text('LEAD II  '), findsOneWidget);

      // By default in full graph mode, full controls and vitals are hidden
      expect(find.byType(ClinicalVitalsBar), findsNothing);
      expect(find.byType(EcgControlToolbar), findsNothing);

      // Tap the toggle button to reveal all other UI
      expect(find.byKey(const Key('toggle_ui_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('toggle_ui_button')));
      await tester.pump();

      // Now all other UI is visible
      expect(find.byType(ClinicalVitalsBar), findsOneWidget);
      expect(find.text('BPM'), findsOneWidget);
      expect(find.text('NO SIGNAL'), findsOneWidget);
      expect(find.text('CARDIAC METRICS'), findsOneWidget);
      expect(find.text('LEAD DETECTION'), findsOneWidget);
      expect(find.text('LO+ (D5)'), findsOneWidget);
      expect(find.text('LO- (D6)'), findsOneWidget);

      // Verify Control Toolbar
      expect(find.byType(EcgControlToolbar), findsOneWidget);
      expect(find.text('FREEZE'), findsOneWidget);
      expect(find.text('ICU SWEEP'), findsOneWidget);
      expect(find.text('25 mm/s'), findsOneWidget);

      // Verify Event & Log List Drawer
      expect(find.byType(EventLogList), findsOneWidget);
      expect(find.text('CARDIAC EVENTS'), findsOneWidget);
      expect(find.text('SYSTEM LOGS'), findsOneWidget);
    });

    testWidgets('Renders cleanly on narrow mobile screen without RenderFlex overflow',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            telemetryProvider.overrideWith(() => TelemetryNotifierMock()),
          ],
          child: const MaterialApp(
            home: DashboardScreen(initialShowAllUi: true),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.byType(ClinicalVitalsBar), findsOneWidget);
      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('Renders cleanly in landscape orientation without RenderFlex overflow',
        (tester) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            telemetryProvider.overrideWith(() => TelemetryNotifierMock()),
          ],
          child: const MaterialApp(
            home: DashboardScreen(initialShowAllUi: true),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.byType(EcgOscilloscope), findsOneWidget);
      expect(find.byType(ClinicalVitalsBar), findsOneWidget);
      expect(find.byType(EcgControlToolbar), findsOneWidget);
    });

    testWidgets('Toggles Freeze button state', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mock = TelemetryNotifierMock();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            telemetryProvider.overrideWith(() => mock),
          ],
          child: const MaterialApp(
            home: DashboardScreen(initialShowAllUi: true),
          ),
        ),
      );

      expect(find.text('FREEZE'), findsOneWidget);
      await tester.tap(find.text('FREEZE'));
      await tester.pump();
      expect(mock.freezeToggled, isTrue);
    });

    testWidgets('Vertical zoom buttons interact properly', (tester) async {
      final mock = TelemetryNotifierMock();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            telemetryProvider.overrideWith(() => mock),
          ],
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pump();

      // Verify zoom controls on oscilloscope
      expect(find.byTooltip('Vertical Zoom In (+)'), findsOneWidget);
      expect(find.byTooltip('Vertical Zoom Out (-)'), findsOneWidget);
      expect(find.byTooltip('Auto-Scale Waveform Height'), findsOneWidget);

      await tester.tap(find.byTooltip('Vertical Zoom In (+)'));
      await tester.pump();

      await tester.tap(find.byTooltip('Vertical Zoom Out (-)'));
      await tester.pump();

      await tester.tap(find.byTooltip('Auto-Scale Waveform Height'));
      await tester.pump();
    });

    testWidgets('Config screen navigates, displays USB OTG settings and defaults button',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            telemetryProvider.overrideWith(() => TelemetryNotifierMock()),
          ],
          child: const MaterialApp(
            home: ConfigScreen(),
          ),
        ),
      );

      expect(find.text('Connection Settings'), findsOneWidget);
      expect(find.text('Direct USB OTG Connection'), findsOneWidget);
      expect(find.text('DETECTED USB DEVICES'), findsOneWidget);
      expect(find.text('Defaults'), findsOneWidget);
      expect(find.text('Connect to ESP OTG'), findsOneWidget);
    });
  });
}

class TelemetryNotifierMock extends Telemetry {
  bool freezeToggled = false;

  @override
  TelemetryState build() {
    return TelemetryState(
      connectionStatus: ConnectionStatus.connected,
      sourceMode: SourceMode.usbSerial,
    );
  }

  @override
  void toggleFreeze() {
    freezeToggled = true;
    state = state.copyWith(isFrozen: !state.isFrozen);
  }

  @override
  void toggleSweepMode() {
    state = state.copyWith(
      sweepMode: state.sweepMode == SweepMode.eraseBarSweep
          ? SweepMode.continuousScroll
          : SweepMode.eraseBarSweep,
    );
  }

  @override
  void clearEvents() {
    state = state.copyWith(cardiacEvents: const []);
  }

  @override
  void clearLogs() {
    state = state.copyWith(logs: const []);
  }

  @override
  void reconnect({int? baudRate}) {}
}
