import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/telemetry_provider.dart';
import 'file_export_service.dart';
import 'recording_export.dart';
import 'recording_models.dart';
import 'recording_provider.dart';

String _duration(double seconds) {
  final whole = seconds.floor();
  return '${whole ~/ 60}:${(whole % 60).toString().padLeft(2, '0')}';
}

class RecordingBar extends ConsumerStatefulWidget {
  const RecordingBar({super.key});
  @override
  ConsumerState<RecordingBar> createState() => _RecordingBarState();
}

class _RecordingBarState extends ConsumerState<RecordingBar> {
  late final AppLifecycleListener _lifecycle;
  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onPause: () {
        if (ref.read(recordingProvider).isRecording) {
          unawaited(
            ref
                .read(recordingProvider.notifier)
                .stop(reason: 'app backgrounded'),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(recordingProvider);
    final live = ref.watch(telemetryProvider.select((s) => s.isConnected));
    ref.listen(recordingProvider, (previous, next) {
      if (previous?.session != null &&
          next.session == null &&
          next.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recording saved to session library.')),
        );
      }
    });
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF101722),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: status.isRecording
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF00FF88),
                  foregroundColor: status.isRecording
                      ? Colors.white
                      : const Color(0xFF090D15),
                ),
                onPressed:
                    status.isSaving ||
                        (!live &&
                            !status.isRecording &&
                            !status.hasUnsavedSession)
                    ? null
                    : () async {
                        final recorder = ref.read(recordingProvider.notifier);
                        if (status.isRecording || status.hasUnsavedSession) {
                          await recorder.stop(
                            reason: status.hasUnsavedSession
                                ? 'recovered after save error'
                                : 'manual',
                          );
                        } else {
                          final telemetry = ref.read(telemetryProvider);
                          await recorder.start(
                            device: telemetry.connectedDeviceName ?? 'USB ECG',
                            baudRate: telemetry.baudRate,
                          );
                        }
                      },
                icon: status.isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        status.isRecording
                            ? Icons.stop_rounded
                            : status.hasUnsavedSession
                            ? Icons.save_outlined
                            : Icons.fiber_manual_record,
                        size: 18,
                      ),
                label: Text(
                  status.isSaving
                      ? 'Saving'
                      : status.isRecording
                      ? 'Stop'
                      : status.hasUnsavedSession
                      ? 'Retry save'
                      : 'Record',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  status.isRecording
                      ? '${_duration(status.elapsedSeconds.toDouble())} / 10:00'
                      : status.hasUnsavedSession
                      ? 'Session awaiting save'
                      : 'Includes previous 5 sec',
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 11,
                    color: status.isRecording
                        ? const Color(0xFFEF8888)
                        : Colors.white54,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Session library',
                icon: const Icon(Icons.folder_outlined),
                onPressed: () {
                  ref.invalidate(recordingLibraryProvider);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const RecordingLibraryScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          if (status.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                status.error!,
                style: const TextStyle(color: Colors.amber, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}

class RecordingLibraryScreen extends ConsumerWidget {
  const RecordingLibraryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(recordingLibraryProvider);
    final active = ref.watch(recordingProvider).session?.id;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session library'),
        actions: [
          IconButton(
            tooltip: 'Refresh sessions',
            onPressed: () => ref.invalidate(recordingLibraryProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: sessions.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not read local sessions.\n$error'),
            ),
          ),
          data: (items) => items.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No recordings yet.\nConnect your ECG device and tap Record.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final session = items[index];
                    final isActive = active == session.id;
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Icon(
                          isActive
                              ? Icons.fiber_manual_record
                              : Icons.monitor_heart_outlined,
                          color: isActive
                              ? Colors.redAccent
                              : const Color(0xFF00FF88),
                        ),
                        title: Text(session.name),
                        subtitle: Text(
                          isActive
                              ? 'Recording or awaiting save'
                              : session.isComplete
                              ? '${_duration(session.durationSeconds)} • ${session.sampleCount} samples\n${session.stopReason}'
                              : 'Interrupted session • tap to recover saved samples',
                        ),
                        onTap: isActive
                            ? null
                            : () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        RecordingExportScreen(session: session),
                                  ),
                                );
                                ref.invalidate(recordingLibraryProvider);
                              },
                        trailing: isActive
                            ? null
                            : IconButton(
                                tooltip: 'Delete recording',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete recording?'),
                                      content: Text(
                                        'Delete ${session.name} from this device?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed != true) return;
                                  try {
                                    await ref
                                        .read(recordingStoreProvider)
                                        .delete(session);
                                    ref.invalidate(recordingLibraryProvider);
                                  } catch (error) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Could not delete recording: $error',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class RecordingExportScreen extends ConsumerStatefulWidget {
  const RecordingExportScreen({super.key, required this.session});
  final RecordingSession session;
  @override
  ConsumerState<RecordingExportScreen> createState() =>
      _RecordingExportScreenState();
}

class _RecordingExportScreenState extends ConsumerState<RecordingExportScreen> {
  RecordingSession? _session;
  Object? _error;
  RangeValues? _range;
  final _groups = exportGroups.keys.toSet();
  final _startInput = TextEditingController();
  final _endInput = TextEditingController();
  String? _rangeError;
  bool _pdfFiltered = true;
  bool _busy = false;
  String _format = 'CSV';
  final _files = FileExportService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final session = await ref
          .read(recordingStoreProvider)
          .inspect(widget.session, recover: true);
      if (!mounted) return;
      setState(() {
        _session = session;
        _range = RangeValues(0, session.durationSeconds);
        _startInput.text = '0';
        _endInput.text = session.durationSeconds.toStringAsFixed(3);
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  void dispose() {
    _startInput.dispose();
    _endInput.dispose();
    super.dispose();
  }

  void _readRange(String _) {
    final start = double.tryParse(_startInput.text);
    final end = double.tryParse(_endInput.text);
    final duration = _session!.durationSeconds;
    setState(() {
      if (start == null ||
          end == null ||
          !start.isFinite ||
          !end.isFinite ||
          start < 0 ||
          end > duration ||
          start >= end) {
        _rangeError =
            'Enter a start before the end, within 0 - ${duration.toStringAsFixed(3)} seconds.';
      } else {
        _rangeError = null;
        _range = RangeValues(start, end);
      }
    });
  }

  Future<void> _export(bool share) async {
    final session = _session;
    final range = _range;
    if (session == null || range == null) return;
    setState(() => _busy = true);
    final box = context.findRenderObject() as RenderBox;
    final origin = box.localToGlobal(Offset.zero) & box.size;
    try {
      final options = RecordingExportOptions(
        startSeconds: range.start,
        endSeconds: range.end,
        groups: Set.of(_groups),
        pdfFiltered: _pdfFiltered,
      );

      final mime = _format == 'CSV' ? 'text/csv' : 'application/pdf';
      final name =
          'ECG_${session.id}_${range.start.toStringAsFixed(2)}-${range.end.toStringAsFixed(2)}.${_format.toLowerCase()}';
      final file = await _files.allocate(name);
      await ref
          .read(recordingStoreProvider)
          .exportToFile(
            session,
            options,
            pdf: _format == 'PDF',
            outputPath: file.path,
          );
      if (!mounted) return;
      if (share) {
        await _files.share(file, mime, origin);
      } else {
        final saved = await _files.save(file, mime);
        if (mounted && saved) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Export saved.')));
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Export failed: $error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final range = _range;
    final hasSamples = session != null && session.sampleCount > 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Export recording')),
      body: SafeArea(
        child: _error != null
            ? Center(child: Text('Could not open recording: $_error'))
            : session == null || range == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    session.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_duration(session.durationSeconds)} • ${session.sampleCount} samples • ${session.preRollSamples} pre-record samples',
                    style: const TextStyle(color: Colors.white60),
                  ),
                  const SizedBox(height: 20),
                  const Text('Time range from first saved sample'),
                  if (hasSamples)
                    RangeSlider(
                      values: range,
                      min: 0,
                      max: session.durationSeconds,
                      labels: RangeLabels(
                        '${range.start.toStringAsFixed(2)} s',
                        '${range.end.toStringAsFixed(2)} s',
                      ),
                      onChanged: _busy
                          ? null
                          : (value) => setState(() {
                              _range = value;
                              _rangeError = null;
                              _startInput.text = value.start.toStringAsFixed(3);
                              _endInput.text = value.end.toStringAsFixed(3);
                            }),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _startInput,
                          enabled: !_busy && hasSamples,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Start (seconds)',
                          ),
                          onChanged: _readRange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _endInput,
                          enabled: !_busy && hasSamples,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'End (seconds)',
                          ),
                          onChanged: _readRange,
                        ),
                      ),
                    ],
                  ),
                  if (_rangeError != null)
                    Text(
                      _rangeError!,
                      style: const TextStyle(color: Colors.amber, fontSize: 12),
                    ),
                  const SizedBox(height: 20),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'CSV',
                        label: Text('CSV'),
                        icon: Icon(Icons.table_chart_outlined),
                      ),
                      ButtonSegment(
                        value: 'PDF',
                        label: Text('PDF report'),
                        icon: Icon(Icons.picture_as_pdf_outlined),
                      ),
                    ],
                    selected: {_format},
                    onSelectionChanged: _busy
                        ? null
                        : (selection) =>
                              setState(() => _format = selection.first),
                  ),
                  const SizedBox(height: 16),
                  if (_format == 'CSV') ...[
                    const Text('Include in export'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final group in exportGroups.keys)
                          FilterChip(
                            label: Text(group),
                            selected: _groups.contains(group),
                            onSelected: _busy
                                ? null
                                : (selected) => setState(() {
                                    if (selected) {
                                      _groups.add(group);
                                    } else {
                                      _groups.remove(group);
                                    }
                                  }),
                          ),
                      ],
                    ),
                  ] else ...[
                    DropdownButtonFormField<bool>(
                      initialValue: _pdfFiltered,
                      decoration: const InputDecoration(
                        labelText: 'ECG strip signal',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: true,
                          child: Text('DSP filtered'),
                        ),
                        DropdownMenuItem(
                          value: false,
                          child: Text('Unfiltered voltage'),
                        ),
                      ],
                      onChanged: _busy
                          ? null
                          : (value) =>
                                setState(() => _pdfFiltered = value ?? true),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Cardiac metrics summary'),
                      value: _groups.contains('Cardiac metrics'),
                      onChanged: _busy
                          ? null
                          : (value) => setState(() {
                              if (value) {
                                _groups.add('Cardiac metrics');
                              } else {
                                _groups.remove('Cardiac metrics');
                              }
                            }),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Signal and event summary'),
                      value: _groups.contains('Signal & events'),
                      onChanged: _busy
                          ? null
                          : (value) => setState(() {
                              if (value) {
                                _groups.add('Signal & events');
                              } else {
                                _groups.remove('Signal & events');
                              }
                            }),
                    ),
                    const Text(
                      'Summary plus up to three 6-second strips from the beginning, middle and end of the selected range.',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    'All captured data remains in your local library. Time offsets use nominal 250 Hz; UTC timestamps represent arrival at the phone.',
                    style: TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                  const SizedBox(height: 24),
                  if (_busy)
                    const Center(child: CircularProgressIndicator())
                  else
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed:
                              !hasSamples ||
                                  _rangeError != null ||
                                  range.end <= range.start ||
                                  (_format == 'CSV' && _groups.isEmpty)
                              ? null
                              : () => _export(false),
                          icon: const Icon(Icons.save_alt),
                          label: const Text('Save file'),
                        ),
                        OutlinedButton.icon(
                          onPressed:
                              !hasSamples ||
                                  _rangeError != null ||
                                  range.end <= range.start ||
                                  (_format == 'CSV' && _groups.isEmpty)
                              ? null
                              : () => _export(true),
                          icon: const Icon(Icons.share_outlined),
                          label: const Text('Share'),
                        ),
                      ],
                    ),
                ],
              ),
      ),
    );
  }
}
