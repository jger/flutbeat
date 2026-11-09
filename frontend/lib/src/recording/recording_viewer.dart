import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analysis/signal_checks.dart';
import '../ui/help/app_help.dart';
import 'recording_models.dart';
import 'recording_provider.dart';
import 'recording_ui.dart';

class RecordingViewerScreen extends ConsumerStatefulWidget {
  const RecordingViewerScreen({super.key, required this.session});
  final RecordingSession session;
  @override
  ConsumerState<RecordingViewerScreen> createState() =>
      _RecordingViewerScreenState();
}

class _RecordingViewerScreenState extends ConsumerState<RecordingViewerScreen> {
  RecordingSession? _session;
  List<Map<String, dynamic>> _rows = [];
  IntervalReview? _review;
  double _start = 0, _span = 5, _amplitude = 1;
  double _baseStart = 0, _baseSpan = 5, _baseAmplitude = 1;
  int _request = 0;
  bool _loading = true, _filtered = true;
  String? _error;
  final _cursors = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final session = await ref
          .read(recordingStoreProvider)
          .inspect(widget.session, recover: true);
      if (!mounted) return;
      _session = session;
      _span = math.min(5, session.durationSeconds);
      await _load();
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = '$error';
          _loading = false;
        });
      }
    }
  }

  Future<void> _load() async {
    final session = _session;
    if (session == null || session.sampleCount == 0) {
      setState(() {
        _loading = false;
        _rows = [];
      });
      return;
    }
    final request = ++_request;
    _span = _span.clamp(
      math.min(0.25, session.durationSeconds),
      math.min(60, session.durationSeconds),
    );
    _start = _start.clamp(0, math.max(0, session.durationSeconds - _span));
    setState(() {
      _loading = true;
      _error = null;
      _cursors.clear();
    });
    try {
      final rows = await ref
          .read(recordingStoreProvider)
          .readWindow(session, _start, _start + _span);
      if (!mounted || request != _request) return;
      setState(() {
        _rows = rows;
        _review = IntervalReview(rows);
        _loading = false;
      });
    } catch (error) {
      if (mounted && request == _request) {
        setState(() {
          _error = '$error';
          _loading = false;
        });
      }
    }
  }

  void _zoom(double factor) {
    _span *= factor;
    unawaited(_load());
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final review = _review;
    final maxStart = math.max(0.0, (session?.durationSeconds ?? 0) - _span);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recorded signal'),
        actions: [
          IconButton(
            tooltip: 'Export recording',
            icon: const Icon(Icons.ios_share),
            onPressed: session == null
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => RecordingExportScreen(session: session),
                    ),
                  ),
          ),
          IconButton(
            tooltip: 'Help',
            icon: const Icon(Icons.help_outline),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const HelpScreen())),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Text(
              session?.name ?? widget.session.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilterChip(
                  label: Text(_filtered ? 'DSP filtered' : 'Raw voltage'),
                  selected: _filtered,
                  onSelected: (value) => setState(() {
                    _filtered = value;
                    _cursors.clear();
                  }),
                ),
                IconButton(
                  tooltip: 'Zoom in time',
                  onPressed: _loading ? null : () => _zoom(.5),
                  icon: const Icon(Icons.zoom_in),
                ),
                IconButton(
                  tooltip: 'Zoom out time',
                  onPressed: _loading ? null : () => _zoom(2),
                  icon: const Icon(Icons.zoom_out),
                ),
                IconButton(
                  tooltip: 'Increase amplitude',
                  onPressed: () => setState(
                    () => _amplitude = (_amplitude * 1.4).clamp(.2, 20),
                  ),
                  icon: const Icon(Icons.unfold_more),
                ),
                IconButton(
                  tooltip: 'Decrease amplitude',
                  onPressed: () => setState(
                    () => _amplitude = (_amplitude / 1.4).clamp(.2, 20),
                  ),
                  icon: const Icon(Icons.unfold_less),
                ),
                Text('${_amplitude.toStringAsFixed(1)}× amplitude'),
              ],
            ),
            Text(
              '${_start.toStringAsFixed(2)} – ${(_start + _span).toStringAsFixed(2)} s • nominal 250 Hz • estimated mV',
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) => SizedBox(
                height: 300,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    GestureDetector(
                      onScaleStart: (_) {
                        _baseStart = _start;
                        _baseSpan = _span;
                        _baseAmplitude = _amplitude;
                      },
                      onScaleUpdate: _loading
                          ? null
                          : (details) => setState(() {
                              _span = (_baseSpan / details.scale).clamp(
                                math.min(.25, session?.durationSeconds ?? .25),
                                math.min(60, session?.durationSeconds ?? 60),
                              );
                              _start =
                                  (_baseStart -
                                          details.focalPointDelta.dx /
                                              constraints.maxWidth *
                                              _span)
                                      .clamp(
                                        0,
                                        math.max(
                                          0,
                                          (session?.durationSeconds ?? _span) -
                                              _span,
                                        ),
                                      );
                              _baseStart = _start;
                              if (details.pointerCount > 1 &&
                                  details.verticalScale != 1) {
                                _amplitude =
                                    (_baseAmplitude * details.verticalScale)
                                        .clamp(.2, 20);
                              }
                            }),
                      onScaleEnd: _loading ? null : (_) => unawaited(_load()),
                      onTapUp: _loading
                          ? null
                          : (details) {
                              if (_rows.isEmpty) return;
                              final time =
                                  _start +
                                  details.localPosition.dx /
                                      constraints.maxWidth *
                                      _span;
                              final closest = _rows.reduce(
                                (a, b) =>
                                    ((a['offset_ms'] as num) / 1000 - time)
                                            .abs() <
                                        ((b['offset_ms'] as num) / 1000 - time)
                                            .abs()
                                    ? a
                                    : b,
                              );
                              setState(() {
                                if (_cursors.length == 2) _cursors.clear();
                                _cursors.add(closest);
                              });
                            },
                      child: CustomPaint(
                        key: const Key('recorded_waveform'),
                        painter: _RecordingPainter(
                          _rows,
                          _start,
                          _span,
                          _amplitude,
                          _filtered,
                          _cursors,
                        ),
                      ),
                    ),
                    if (_loading)
                      const Center(child: CircularProgressIndicator()),
                    if (_error != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(_error!),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (_cursors.length == 2)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Calipers: Δt ${((_cursors[1]['offset_ms'] as num) - (_cursors[0]['offset_ms'] as num)).abs().toStringAsFixed(0)} ms • ΔV ${((_cursors[1][_filtered ? 'filtered_mv' : 'voltage_mv'] as num) - (_cursors[0][_filtered ? 'filtered_mv' : 'voltage_mv'] as num)).abs().toStringAsFixed(3)} estimated mV',
                ),
              ),
            Slider(
              value: _start.clamp(0, maxStart),
              min: 0,
              max: maxStart > 0 ? maxStart : 1,
              onChanged: _loading || maxStart == 0
                  ? null
                  : (value) => setState(() => _start = value),
              onChangeEnd: (_) => unawaited(_load()),
            ),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: _loading
                      ? null
                      : () {
                          _start -= _span * .8;
                          unawaited(_load());
                        },
                  child: const Text('Previous'),
                ),
                OutlinedButton(
                  onPressed: _loading
                      ? null
                      : () {
                          _start += _span * .8;
                          unawaited(_load());
                        },
                  child: const Text('Next'),
                ),
                TextButton(
                  onPressed: () => setState(() => _cursors.clear()),
                  child: const Text('Clear calipers'),
                ),
              ],
            ),
            const Text(
              'Drag to pan • pinch to zoom • tap two points for calipers. Blue markers are algorithm detections, not verified R peaks.',
              style: TextStyle(fontSize: 12, color: Colors.white54),
            ),
            if (review != null && !_loading)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Exploratory interval review',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${review.intervals.length} adjacent detected intervals in this window • 49–51 Hz power estimate ${review.mainsPercent.toStringAsFixed(0)}%',
                      ),
                      if (!review.usable)
                        const Text(
                          'Unreliable or insufficient detections. Review the waveform and reduce noise before interpreting intervals.',
                          style: TextStyle(color: Colors.amber),
                        ),
                      if (review.usable)
                        Text(
                          'Mean R–R: ${review.meanRr!.toStringAsFixed(0)} ms • Median: ${review.medianRr!.toStringAsFixed(0)} ms\nRate from mean interval: ${(60000 / review.meanRr!).toStringAsFixed(1)} BPM',
                        ),
                      if (review.sdnn != null)
                        Text(
                          'Exploratory RR SD: ${review.sdnn!.toStringAsFixed(1)} ms • Successive RR RMS: ${review.rmssd!.toStringAsFixed(1)} ms',
                        ),
                      const Text(
                        'RR variability is withheld for noise, outliers or fewer than 30 intervals. This is not validated NN/HRV analysis. No rhythm diagnosis, QT/QTc or ST interpretation is provided.',
                        style: TextStyle(fontSize: 12, color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            const Text(
              experimentalNotice,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white54,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordingPainter extends CustomPainter {
  _RecordingPainter(
    this.rows,
    this.start,
    this.span,
    this.amplitude,
    this.filtered,
    this.cursors,
  );
  final List<Map<String, dynamic>> rows, cursors;
  final double start, span, amplitude;
  final bool filtered;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawColor(const Color(0xFF070B11), BlendMode.src);
    final grid = Paint()
      ..color = const Color(0xFF263448)
      ..strokeWidth = .5;
    for (double x = 0; x < size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final trace = Paint()
      ..color = const Color(0xFF00FF88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    final path = Path();
    bool drawing = false;
    final key = filtered ? 'filtered_mv' : 'voltage_mv';
    for (final row in rows) {
      if (row['lead_off'] == true) {
        drawing = false;
        continue;
      }
      final x = ((row['offset_ms'] as num) / 1000 - start) / span * size.width;
      final y = size.height / 2 - (row[key] as num) * amplitude * 70;
      if (!drawing) {
        path.moveTo(x, y);
        drawing = true;
      } else {
        path.lineTo(x, y);
      }
      if (row['is_r_peak'] == true) {
        canvas.drawCircle(Offset(x, y), 2.5, Paint()..color = Colors.cyan);
      }
    }
    canvas.drawPath(path, trace);
    for (final point in cursors) {
      final x =
          ((point['offset_ms'] as num) / 1000 - start) / span * size.width;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = Colors.amber
          ..strokeWidth = 1,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RecordingPainter oldDelegate) => true;
}
