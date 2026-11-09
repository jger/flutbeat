import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutbeat_frontend/src/analysis/signal_checks.dart';
import 'package:flutbeat_frontend/src/dsp/ecg_dsp_pipeline.dart';
import 'package:flutbeat_frontend/src/ui/help/app_help.dart';
import 'package:flutbeat_frontend/src/ui/widgets/ecg_oscilloscope_painter.dart';
import 'package:flutbeat_frontend/src/models/telemetry_state.dart';
import 'package:flutbeat_frontend/src/models/cardiac_metrics.dart';

void main() {
  test('Strong mains hum is not reported as clean ECG', () {
    final raw = [
      for (int i = 0; i < 250; i++)
        512 + 400 * math.sin(2 * math.pi * 50 * i / 250),
    ];
    final check = SignalCheck.fromAdc(raw);
    expect(check.mainsFraction, greaterThan(.95));
    expect(check.quality, lessThan(50));
    final pipeline = EcgDspPipeline();
    for (int i = 0; i < 1000; i++) {
      final sample = pipeline.processSample(
        rawAdc: raw[i % 250].round(),
        loPlus: false,
        loMinus: false,
        timestampMs: i * 4,
      );
      expect(sample.isRPeak, isFalse);
      expect(sample.metrics.heartRateBpm, 0);
      expect(sample.metrics.hasHrv, isFalse);
      expect(sample.metrics.rhythm.name, 'noSignal');
    }
  });
  test('Flatline and saturation fail the electrical quality estimate', () {
    expect(SignalCheck.fromAdc(List.filled(250, 512)).quality, 0);
    expect(
      SignalCheck.fromAdc([for (int i = 0; i < 250; i++) i.isEven ? 1023 : 0])
          .quality,
      lessThan(50),
    );
  });
  test('Short or outlying detector intervals do not become trusted HRV', () {
    final rows = [
      for (int i = 0; i < 1250; i++)
        <String, dynamic>{
          'row_type': 'sample',
          'raw_adc': 512 + 80 * math.sin(2 * math.pi * 2 * i / 250),
          'offset_ms': i * 4,
          'is_r_peak': [100, 300, 370, 570, 770, 970, 1170].contains(i),
          'lead_status': 'leadsConnected',
        },
    ];
    final review = IntervalReview(rows);
    expect(review.suspectedDetectionErrors, isTrue);
    expect(review.usable, isFalse);
    expect(review.sdnn, isNull);
  });
  for (final size in [const Size(360, 640), const Size(800, 360)]) {
    testWidgets('Offline setup shows electrode guide at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeArea(
              child: OfflineSetup(connecting: false, onConnect: () {}),
            ),
          ),
        ),
      );
      expect(find.text('No ECG device connected'), findsOneWidget);
      expect(find.byType(ElectrodeGuide), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'Noisy live signal has an explicit status and withholds pulse readout',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EcgOscilloscope(
              state: TelemetryState(
                connectionStatus: ConnectionStatus.connected,
                totalSamples: 250,
                metrics: const CardiacMetrics(
                  heartRateBpm: 80,
                  leadStatus: LeadStatus.leadsConnected,
                  signalQualityPercent: 10,
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('NOISY SIGNAL'), findsOneWidget);
      expect(find.textContaining('80'), findsNothing);
    },
  );

  testWidgets(
    'About shows installed version, experimental notice and license access',
    (tester) async {
      PackageInfo.setMockInitialValues(
        appName: 'FlutBeat',
        packageName: 'test.flutbeat',
        version: '1.1.0',
        buildNumber: '2',
        buildSignature: '',
      );
      await tester.pumpWidget(const MaterialApp(home: AboutScreen()));
      await tester.pumpAndSettle();
      expect(find.textContaining('Version 1.1.0 (2)'), findsOneWidget);
      expect(find.text(experimentalNotice), findsOneWidget);
      await tester.ensureVisible(find.text('Open-source licenses'));
      await tester.tap(find.text('Open-source licenses'));
      await tester.pumpAndSettle();
      expect(find.byType(LicensePage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Help includes explicit experimental limitation and patient-side labels',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HelpScreen()));
      expect(find.textContaining('your right is on the left'), findsOneWidget);
      expect(find.textContaining('RA: upper right chest'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text(experimentalNotice),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(experimentalNotice), findsOneWidget);
    },
  );
}
