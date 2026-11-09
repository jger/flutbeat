import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'recording_models.dart';

const exportGroups = <String, List<String>>{
  'Raw ECG': ['raw_adc', 'voltage_mv'],
  'Filtered ECG': ['filtered_mv'],
  'Cardiac metrics': [
    'heart_rate_bpm',
    'rr_interval_ms',
    'hrv_available',
    'rr_interval_count',
    'sdnn_ms',
    'rmssd_ms',
    'rhythm',
    'total_beats',
    'last_beat_timestamp_ms',
  ],
  'Signal & events': [
    'lo_plus',
    'lo_minus',
    'lead_off',
    'lead_status',
    'signal_quality_percent',
    'is_r_peak',
    'event_type',
    'event_description',
    'event_sequence',
    'event_timestamp_ms',
    'event_heart_rate_bpm',
  ],
  'Display settings': [
    'paper_speed_mm_s',
    'gain_mm_mv',
    'vertical_zoom',
    'filter_mode',
    'sweep_mode',
    'display_frozen',
    'source',
  ],
  'System logs': ['level', 'component', 'message'],
};

class RecordingExportOptions {
  const RecordingExportOptions({
    required this.startSeconds,
    required this.endSeconds,
    required this.groups,
    this.pdfFiltered = true,
  });
  final double startSeconds;
  final double endSeconds;
  final Set<String> groups;
  final bool pdfFiltered;
  bool contains(Map<String, dynamic> row) {
    final offset = (row['offset_ms'] as num).toDouble();
    return offset >= startSeconds * 1000 &&
        (offset < endSeconds * 1000 ||
            (row['row_type'] == 'log' && offset == endSeconds * 1000));
  }
}

String recordingCsv(RecordingData data, RecordingExportOptions options) {
  final columns = [
    'session_id',
    'record_pressed_at_utc',
    'device',
    'nominal_sample_rate_hz',
    'pre_roll_samples',
    'row_type',
    'timestamp_utc',
    'source_timestamp_ms',
    'sample_index',
    'offset_ms',
    for (final group in exportGroups.keys)
      if (options.groups.contains(group)) ...exportGroups[group]!,
  ];
  final buffer = StringBuffer()..writeln(columns.join(','));
  for (final row in data.rows) {
    if (!options.contains(row) ||
        (row['row_type'] == 'log' && !options.groups.contains('System logs'))) {
      continue;
    }
    final values = {
      ...row,
      'session_id': data.session.id,
      'record_pressed_at_utc': data.session.recordPressedAt
          .toUtc()
          .toIso8601String(),
      'device': data.session.device,
      'nominal_sample_rate_hz': 250,
      'pre_roll_samples': data.session.preRollSamples,
    };
    buffer.writeln(columns.map((key) => _csvCell(values[key])).join(','));
  }
  return buffer.toString();
}

String _csvCell(Object? value) {
  var text = value?.toString() ?? '';
  // Keep names/log text from being interpreted as spreadsheet formulas.
  if (value is String && RegExp(r'^[=+\-@\t\r]').hasMatch(text)) {
    text = "'$text";
  }
  return '"${text.replaceAll('"', '""')}"';
}

List<double> selectedStripStarts(double start, double end) {
  final duration = end - start;
  if (duration <= 6) return [start];
  if (duration <= 18) return [for (double t = start; t < end; t += 6) t];
  return [start, start + (duration - 6) / 2, end - 6];
}

class RecordingSummary {
  int sampleCount = 0;
  int peaks = 0;
  int leadOffCount = 0;
  int? minBpm;
  int? maxBpm;

  void add(Map<String, dynamic> row) {
    sampleCount++;
    if (row['is_r_peak'] == true) peaks++;
    if (row['lead_status'] != 'leadsConnected') {
      leadOffCount++;
    } else {
      final bpm = (row['heart_rate_bpm'] as num).toInt();
      if (bpm > 0) {
        minBpm = minBpm == null ? bpm : math.min(minBpm!, bpm);
        maxBpm = maxBpm == null ? bpm : math.max(maxBpm!, bpm);
      }
    }
  }
}

Future<Uint8List> recordingPdf(
  RecordingData data,
  RecordingExportOptions options, {
  RecordingSummary? summary,
}) async {
  final samples = data.samples.where(options.contains).toList();
  final stats = summary ?? RecordingSummary();
  if (summary == null) {
    for (final sample in samples) {
      stats.add(sample);
    }
  }
  if (stats.sampleCount == 0) {
    throw StateError('No samples in the selected range.');
  }
  final starts = selectedStripStarts(options.startSeconds, options.endSeconds);
  final signal = options.pdfFiltered ? 'filtered_mv' : 'voltage_mv';
  final doc = pw.Document(title: data.session.name, author: 'FlutBeat');
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      footer: (context) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'FlutBeat | ${data.session.id}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.Text(
            '${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
      build: (context) => [
        pw.Text(
          'ECG SESSION',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.teal700,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          'Recording summary',
          style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          'Recorded (UTC): ${data.session.recordPressedAt.toUtc().toIso8601String()}',
        ),
        pw.Text(
          'Source: ${_pdfText(data.session.device)} | ${data.session.baudRate} baud',
        ),
        pw.Text(
          'Stopped: ${data.session.stopReason} | Pre-record samples: ${data.session.preRollSamples}',
        ),
        pw.Text(
          'Selected range: ${options.startSeconds.toStringAsFixed(2)} - ${options.endSeconds.toStringAsFixed(2)} s from first saved sample',
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          color: PdfColors.grey100,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '${stats.sampleCount} samples | ${((options.endSeconds - options.startSeconds)).toStringAsFixed(1)} seconds | Nominal 250 Hz',
              ),
              if (options.groups.contains('Cardiac metrics'))
                pw.Text(
                  stats.minBpm == null
                      ? 'Heart rate: unavailable in selected range'
                      : 'Heart rate range: ${stats.minBpm} - ${stats.maxBpm} BPM',
                ),
              if (options.groups.contains('Signal & events'))
                pw.Text(
                  '${stats.peaks} detected R peaks | Lead-off: ${(stats.leadOffCount / stats.sampleCount * 100).toStringAsFixed(1)}% of selected samples',
                ),
            ],
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          'Selected ECG strips',
          style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          '${options.pdfFiltered ? 'DSP filtered' : 'Unfiltered ADC-converted'} | 25 mm/s | 10 mm/mV | ${starts.length} excerpts; intervening data omitted',
          style: const pw.TextStyle(fontSize: 9),
        ),
        pw.SizedBox(height: 6),
        for (final start in starts) ...[
          pw.Text(
            '${start.toStringAsFixed(2)} - ${math.min(start + 6, options.endSeconds).toStringAsFixed(2)} s',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 4),
          pw.CustomPaint(
            size: PdfPoint(150 * PdfPageFormat.mm, 36 * PdfPageFormat.mm),
            painter: (canvas, size) => _paintStrip(
              canvas,
              size,
              samples,
              start,
              math.min(start + 6, options.endSeconds),
              signal,
            ),
          ),
          pw.SizedBox(height: 10),
        ],
        pw.Text(
          'For fun and experimentation only. Not a medical device; cannot replace a medical ECG. Time basis: sample order at nominal 250 Hz. UTC timestamps are host arrival times, not device acquisition timestamps. Lead-off intervals appear as gaps. Voltage is uncalibrated: assumed 3.2 V ADC reference and gain 1100.',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
        if (options.pdfFiltered)
          pw.Text(
            'DSP: DC blocker alpha=0.992 (~0.32 Hz), 50 Hz notch, 40 Hz low-pass.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        pw.Text(
          'Print at 100% to preserve the labeled paper scale. The PDF contains selected excerpts; CSV exports include all selected samples.',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
      ],
    ),
  );
  return doc.save();
}

String _pdfText(String text) => text.replaceAll(RegExp(r'[^\x20-\x7E]'), '?');

void _paintStrip(
  PdfGraphics canvas,
  PdfPoint size,
  List<Map<String, dynamic>> samples,
  double start,
  double end,
  String signal,
) {
  const mm = PdfPageFormat.mm;
  canvas.saveContext();
  canvas.drawRect(0, 0, size.x, size.y);
  canvas.clipPath();
  for (int i = 0; i <= 150; i++) {
    canvas.setStrokeColor(i % 5 == 0 ? PdfColors.red200 : PdfColors.red50);
    canvas.setLineWidth(i % 5 == 0 ? 0.4 : 0.2);
    canvas.drawLine(i * mm, 0, i * mm, size.y);
    canvas.strokePath();
  }
  for (int i = 0; i <= 36; i++) {
    canvas.setStrokeColor(i % 5 == 0 ? PdfColors.red200 : PdfColors.red50);
    canvas.setLineWidth(i % 5 == 0 ? 0.4 : 0.2);
    canvas.drawLine(0, i * mm, size.x, i * mm);
    canvas.strokePath();
  }
  canvas.setStrokeColor(PdfColors.teal900);
  canvas.setLineWidth(0.7);
  bool drawing = false;
  for (final row in samples) {
    final time = (row['offset_ms'] as num) / 1000;
    if (time < start || time >= end) continue;
    if (row['lead_status'] != 'leadsConnected') {
      if (drawing) canvas.strokePath();
      drawing = false;
      continue;
    }
    final x = (time - start) * 25 * mm;
    final y = size.y / 2 + (row[signal] as num) * 10 * mm;
    if (!drawing) {
      canvas.moveTo(x, y);
      drawing = true;
    } else {
      canvas.lineTo(x, y);
    }
  }
  if (drawing) canvas.strokePath();
  canvas.restoreContext();
}

Uint8List csvBytes(RecordingData data, RecordingExportOptions options) =>
    Uint8List.fromList(utf8.encode(recordingCsv(data, options)));

class RecordingExportJob {
  const RecordingExportJob(this.data, this.options, this.pdf);
  final RecordingData data;
  final RecordingExportOptions options;
  final bool pdf;
}

Future<Uint8List> buildRecordingExport(RecordingExportJob job) async => job.pdf
    ? recordingPdf(job.data, job.options)
    : csvBytes(job.data, job.options);
