import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutbeat_frontend/src/recording/recording_models.dart';
import 'package:flutbeat_frontend/src/recording/recording_provider.dart';
import 'package:flutbeat_frontend/src/recording/recording_store.dart';
import 'package:flutbeat_frontend/src/recording/recording_ui.dart';

void main() {
  final now = DateTime.utc(2026, 11, 9, 12);
  final session = RecordingSession(
    id: '123',
    startedAt: now,
    recordPressedAt: now,
    device: 'ESP',
    baudRate: 115200,
    sampleCount: 7500,
    stopReason: 'manual',
  );
  final data = RecordingData(session, [
    for (int i = 0; i < 7500; i++)
      {'row_type': 'sample', 'sample_index': i, 'offset_ms': i * 4},
  ]);

  for (final size in [const Size(360, 640), const Size(800, 360)]) {
    testWidgets('Export fields validate ranges and fit $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recordingStoreProvider.overrideWithValue(_FixtureStore(data)),
          ],
          child: MaterialApp(home: RecordingExportScreen(session: session)),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byType(TextField).first, '31');
      await tester.pump();
      expect(
        find.textContaining('Enter a start before the end'),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextField).first, '5');
      await tester.enterText(find.byType(TextField).last, '10');
      await tester.pump();
      expect(find.textContaining('Enter a start before the end'), findsNothing);
      final slider = tester.widget<RangeSlider>(find.byType(RangeSlider));
      expect(slider.values, const RangeValues(5, 10));
      await tester.ensureVisible(find.text('PDF report'));
      await tester.tap(find.text('PDF report'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Summary plus up to three'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Session library opens stored recordings for export', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recordingStoreProvider.overrideWithValue(_FixtureStore(data)),
        ],
        child: const MaterialApp(home: RecordingLibraryScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(session.name), findsOneWidget);
    await tester.tap(find.text(session.name));
    await tester.pumpAndSettle();
    expect(find.text('Export recording'), findsOneWidget);
    expect(find.text('Raw ECG'), findsOneWidget);
    expect(find.text('Filtered ECG'), findsOneWidget);
  });
}

class _FixtureStore extends RecordingStore {
  _FixtureStore(this.data);
  final RecordingData data;
  @override
  Future<List<RecordingSession>> list() async => [data.session];
  @override
  Future<RecordingData> read(
    RecordingSession session, {
    bool recover = false,
  }) async => data;
}
