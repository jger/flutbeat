class RecordingSession {
  const RecordingSession({
    required this.id,
    required this.startedAt,
    required this.recordPressedAt,
    required this.device,
    required this.baudRate,
    this.preRollSamples = 0,
    this.sampleCount = 0,
    this.endedAt,
    this.stopReason = 'recording',
  });

  final String id;
  final DateTime startedAt;
  final DateTime recordPressedAt;
  final DateTime? endedAt;
  final String device;
  final int baudRate;
  final int preRollSamples;
  final int sampleCount;
  final String stopReason;
  String get name =>
      'ECG ${recordPressedAt.toLocal().toString().split('.').first}';
  double get durationSeconds => sampleCount / 250;
  bool get isComplete => stopReason != 'recording';

  RecordingSession finish(int count, DateTime end, String reason) =>
      RecordingSession(
        id: id,
        startedAt: startedAt,
        recordPressedAt: recordPressedAt,
        device: device,
        baudRate: baudRate,
        preRollSamples: preRollSamples,
        sampleCount: count,
        endedAt: end,
        stopReason: reason,
      );

  Map<String, dynamic> toJson() => {
    'schema_version': 1,
    'id': id,
    'started_at_utc': startedAt.toUtc().toIso8601String(),
    'record_pressed_at_utc': recordPressedAt.toUtc().toIso8601String(),
    'ended_at_utc': endedAt?.toUtc().toIso8601String(),
    'device': device,
    'baud_rate': baudRate,
    'pre_roll_samples': preRollSamples,
    'sample_count': sampleCount,
    'stop_reason': stopReason,
    'nominal_sample_rate_hz': 250,
    'voltage_calibration':
        'Assumed ADC reference 3.2 V and analog gain 1100; not calibrated',
    'time_basis': 'Waveform offsets use sample order at nominal 250 Hz; UTC times are host arrival times.',
    'dsp': 'DC blocker alpha=0.992 (~0.32 Hz); 50 Hz notch; 40 Hz low-pass',
  };

  factory RecordingSession.fromJson(Map<String, dynamic> json) =>
      RecordingSession(
        id: json['id'] as String,
        startedAt: DateTime.parse(json['started_at_utc'] as String),
        recordPressedAt: DateTime.parse(
          json['record_pressed_at_utc'] as String,
        ),
        endedAt: json['ended_at_utc'] == null
            ? null
            : DateTime.parse(json['ended_at_utc'] as String),
        device: json['device'] as String,
        baudRate: json['baud_rate'] as int,
        preRollSamples: json['pre_roll_samples'] as int,
        sampleCount: json['sample_count'] as int,
        stopReason: json['stop_reason'] as String,
      );
}

class RecordingStatus {
  const RecordingStatus({
    this.session,
    this.isRecording = false,
    this.isSaving = false,
    this.elapsedSeconds = 0,
    this.error,
    this.libraryRevision = 0,
  });
  final RecordingSession? session;
  final bool isRecording;
  final bool isSaving;
  final int elapsedSeconds;
  final String? error;
  final int libraryRevision;
  bool get hasUnsavedSession => session != null && !isRecording && !isSaving;
}

class RecordingData {
  const RecordingData(this.session, this.rows);
  final RecordingSession session;
  final List<Map<String, dynamic>> rows;
  List<Map<String, dynamic>> get samples =>
      rows.where((r) => r['row_type'] == 'sample').toList();
}
