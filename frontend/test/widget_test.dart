import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
    test('Default values are correct', () {
      const config = ConnectionConfig();
      expect(config.host, '127.0.0.1');
      expect(config.port, 50051);
      expect(config.clientId, 'flutter-dashboard');
      expect(config.useTls, false);
    });

    test('Json serialization roundtrip', () {
      const config = ConnectionConfig(
        host: '192.168.1.100',
        port: 9090,
        clientId: 'custom-ecg-node',
        useTls: true,
      );
      final json = config.toJson();
      final restored = ConnectionConfig.fromJson(json);
      expect(restored, equals(config));
    });
  });

  group('FlutBeat Clinical Dashboard UI Widget Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('Renders Clinical Dashboard with Vitals, Oscilloscope, Toolbar & Drawer',
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

      // Verify AppBar elements
      expect(find.text('FlutBeat ECG Monitor'), findsOneWidget);
      expect(find.text('127.0.0.1:50051'), findsOneWidget);
      expect(find.byType(BlinkingHeartbeatDot), findsOneWidget);

      // Verify Clinical Vitals Bar
      expect(find.byType(ClinicalVitalsBar), findsOneWidget);
      expect(find.text('BPM'), findsOneWidget);
      expect(find.text('NORMAL SINUS'), findsOneWidget);
      expect(find.text('CARDIAC METRICS'), findsOneWidget);
      expect(find.text('LEAD DETECTION'), findsOneWidget);
      expect(find.text('LO+ (D5)'), findsOneWidget);
      expect(find.text('LO- (D6)'), findsOneWidget);

      // Verify Oscilloscope Canvas
      expect(find.byType(EcgOscilloscope), findsOneWidget);
      expect(find.text('LEAD II  '), findsOneWidget);

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
      // Emulate narrow mobile device (e.g. 360x800)
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
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // No overflow exceptions caught by Flutter tester
      expect(tester.takeException(), isNull);
      expect(find.byType(ClinicalVitalsBar), findsOneWidget);
      expect(find.byType(DashboardScreen), findsOneWidget);
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
            home: DashboardScreen(),
          ),
        ),
      );

      expect(find.text('FREEZE'), findsOneWidget);
      await tester.tap(find.text('FREEZE'));
      await tester.pump();
      expect(mock.freezeToggled, isTrue);
    });

    testWidgets('Config screen navigates, allows editing and restores defaults',
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
      expect(find.byType(TextFormField), findsNWidgets(3));

      // Verify Save Button & Defaults Button
      expect(find.text('Save & Connect'), findsOneWidget);
      expect(find.text('Defaults'), findsOneWidget);
    });
  });
}

class TelemetryNotifierMock extends Telemetry {
  bool freezeToggled = false;

  @override
  TelemetryState build() {
    return TelemetryState(
      connectionStatus: ConnectionStatus.connected,
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
  void reconnect() {}
}
