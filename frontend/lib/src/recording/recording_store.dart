import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'recording_models.dart';
import 'recording_export.dart';

/// Each batch is committed by rename. An interrupted batch never leaves a
/// partially written row in the library, and a failed batch can be retried.
class RecordingStore {
  RecordingStore({this.rootOverride});
  final Directory? rootOverride;

  Future<Directory> get root async {
    final base =
        rootOverride ??
        Directory(
          '${(await getApplicationSupportDirectory()).path}/recordings',
        );
    await base.create(recursive: true);
    return base;
  }

  Future<Directory> _directory(String id) async {
    if (!RegExp(r'^\d+$').hasMatch(id)) {
      throw const FormatException('Invalid session ID');
    }
    return Directory('${(await root).path}/$id');
  }

  Future<void> saveMetadata(RecordingSession session) async {
    final dir = await _directory(session.id);
    await dir.create(recursive: true);
    final temp = File('${dir.path}/session.tmp');
    await temp.writeAsString(jsonEncode(session.toJson()), flush: true);
    await temp.rename('${dir.path}/session.json');
  }

  Future<void> writeBatch(
    String id,
    int sequence,
    List<Map<String, dynamic>> rows,
  ) async {
    final dir = await _directory(id);
    final name = sequence.toString().padLeft(8, '0');
    final encoded = await compute(_encodeRows, rows);
    final temp = File('${dir.path}/$name.tmp');
    await temp.writeAsString(encoded, flush: true);
    await temp.rename('${dir.path}/$name.ndjson');
  }

  Future<List<RecordingSession>> list() async {
    final result = <RecordingSession>[];
    await for (final entry in (await root).list()) {
      if (entry is! Directory) continue;
      final file = File('${entry.path}/session.json');
      if (!await file.exists()) continue;
      // Surface corruption rather than silently hiding stored sessions.
      result.add(
        RecordingSession.fromJson(
          jsonDecode(await file.readAsString()) as Map<String, dynamic>,
        ),
      );
    }
    result.sort((a, b) => b.recordPressedAt.compareTo(a.recordPressedAt));
    return result;
  }

  Future<RecordingData> read(
    RecordingSession session, {
    bool recover = false,
  }) async {
    final dir = await _directory(session.id);
    final rows = await compute(_readRows, dir.path);
    var metadata = session;
    if (recover && !session.isComplete) {
      final samples = rows.where((r) => r['row_type'] == 'sample').toList();
      final end = samples.isEmpty
          ? session.recordPressedAt
          : DateTime.parse(samples.last['timestamp_utc'] as String);
      metadata = session.finish(samples.length, end, 'interrupted');
      await saveMetadata(metadata);
    }
    return RecordingData(metadata, rows);
  }

  Future<RecordingSession> inspect(
    RecordingSession session, {
    bool recover = false,
  }) async {
    if (session.isComplete || !recover) return session;
    final counts = await compute(
      _scanSession,
      (await _directory(session.id)).path,
    );
    final recovered = session.finish(
      counts.count,
      counts.end ?? session.recordPressedAt,
      'interrupted',
    );
    await saveMetadata(recovered);
    return recovered;
  }

  /// Export work reads one committed batch at a time in a worker isolate.
  /// The UI receives a file path, never a full-session sample list.
  Future<void> exportToFile(
    RecordingSession session,
    RecordingExportOptions options, {
    required bool pdf,
    required String outputPath,
  }) async {
    await compute(
      _exportFile,
      _DiskExportJob(
        (await _directory(session.id)).path,
        session,
        options,
        pdf,
        outputPath,
      ),
    );
  }

  Future<void> delete(RecordingSession session) async {
    await (await _directory(session.id)).delete(recursive: true);
  }
}

String _encodeRows(List<Map<String, dynamic>> rows) =>
    '${rows.map(jsonEncode).join('\n')}\n';
List<Map<String, dynamic>> _readRows(String path) {
  final files =
      Directory(path)
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.ndjson'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  return [
    for (final file in files)
      for (final line in file.readAsLinesSync())
        if (line.isNotEmpty) jsonDecode(line) as Map<String, dynamic>,
  ];
}

Iterable<File> _batchFiles(String path) =>
    Directory(path)
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.ndjson'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

Iterable<Map<String, dynamic>> _streamRows(String path) sync* {
  for (final file in _batchFiles(path)) {
    for (final line in file.readAsLinesSync()) {
      if (line.isNotEmpty) yield jsonDecode(line) as Map<String, dynamic>;
    }
  }
}

class _SessionCounts {
  const _SessionCounts(this.count, this.end);
  final int count;
  final DateTime? end;
}

_SessionCounts _scanSession(String path) {
  int count = 0;
  DateTime? end;
  for (final row in _streamRows(path)) {
    if (row['row_type'] != 'sample') continue;
    count++;
    end = DateTime.parse(row['timestamp_utc'] as String);
  }
  return _SessionCounts(count, end);
}

class _DiskExportJob {
  const _DiskExportJob(
    this.path,
    this.session,
    this.options,
    this.pdf,
    this.outputPath,
  );
  final String path;
  final RecordingSession session;
  final RecordingExportOptions options;
  final bool pdf;
  final String outputPath;
}

Future<void> _exportFile(_DiskExportJob job) async {
  final stats = RecordingSummary();
  final strips = <Map<String, dynamic>>[];
  final starts = selectedStripStarts(
    job.options.startSeconds,
    job.options.endSeconds,
  );
  final out = File(job.outputPath).openSync(mode: FileMode.write);
  try {
    if (!job.pdf) {
      out.writeStringSync(
        recordingCsv(RecordingData(job.session, const []), job.options),
      );
    }
    var csvBatch = <Map<String, dynamic>>[];
    void writeCsvBatch() {
      if (csvBatch.isEmpty) return;
      final csv = recordingCsv(
        RecordingData(job.session, csvBatch),
        job.options,
      );
      out.writeStringSync(csv.substring(csv.indexOf('\n') + 1));
      csvBatch = [];
    }

    for (final row in _streamRows(job.path)) {
      if (!job.options.contains(row)) continue;
      if (row['row_type'] == 'sample') {
        stats.add(row);
        final seconds = (row['offset_ms'] as num) / 1000;
        if (job.pdf &&
            starts.any((start) => seconds >= start && seconds < start + 6)) {
          strips.add(row);
        }
      }
      if (!job.pdf) {
        csvBatch.add(row);
        if (csvBatch.length >= 500) writeCsvBatch();
      }
    }
    if (stats.sampleCount == 0) {
      throw StateError('No ECG samples in the selected range.');
    }
    if (job.pdf) {
      out.writeFromSync(
        await recordingPdf(
          RecordingData(job.session, strips),
          job.options,
          summary: stats,
        ),
      );
    } else {
      writeCsvBatch();
    }
    out.flushSync();
  } finally {
    out.closeSync();
  }
}
