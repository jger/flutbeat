// This is a generated file - do not edit.
//
// Generated from telemetry.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use logLevelDescriptor instead')
const LogLevel$json = {
  '1': 'LogLevel',
  '2': [
    {'1': 'DEBUG', '2': 0},
    {'1': 'INFO', '2': 1},
    {'1': 'WARN', '2': 2},
    {'1': 'ERROR', '2': 3},
  ],
};

/// Descriptor for `LogLevel`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List logLevelDescriptor = $convert.base64Decode(
    'CghMb2dMZXZlbBIJCgVERUJVRxAAEggKBElORk8QARIICgRXQVJOEAISCQoFRVJST1IQAw==');

@$core.Deprecated('Use sourceModeDescriptor instead')
const SourceMode$json = {
  '1': 'SourceMode',
  '2': [
    {'1': 'SOURCE_MODE_UNSPECIFIED', '2': 0},
    {'1': 'SIMULATOR', '2': 1},
    {'1': 'UDP_WIFI', '2': 2},
    {'1': 'USB_SERIAL', '2': 3},
  ],
};

/// Descriptor for `SourceMode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List sourceModeDescriptor = $convert.base64Decode(
    'CgpTb3VyY2VNb2RlEhsKF1NPVVJDRV9NT0RFX1VOU1BFQ0lGSUVEEAASDQoJU0lNVUxBVE9SEA'
    'ESDAoIVURQX1dJRkkQAhIOCgpVU0JfU0VSSUFMEAM=');

@$core.Deprecated('Use leadStatusDescriptor instead')
const LeadStatus$json = {
  '1': 'LeadStatus',
  '2': [
    {'1': 'LEAD_STATUS_UNSPECIFIED', '2': 0},
    {'1': 'LEADS_CONNECTED', '2': 1},
    {'1': 'LEAD_OFF_POSITIVE', '2': 2},
    {'1': 'LEAD_OFF_NEGATIVE', '2': 3},
    {'1': 'LEAD_OFF_BOTH', '2': 4},
  ],
};

/// Descriptor for `LeadStatus`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List leadStatusDescriptor = $convert.base64Decode(
    'CgpMZWFkU3RhdHVzEhsKF0xFQURfU1RBVFVTX1VOU1BFQ0lGSUVEEAASEwoPTEVBRFNfQ09OTk'
    'VDVEVEEAESFQoRTEVBRF9PRkZfUE9TSVRJVkUQAhIVChFMRUFEX09GRl9ORUdBVElWRRADEhEK'
    'DUxFQURfT0ZGX0JPVEgQBA==');

@$core.Deprecated('Use rhythmClassificationDescriptor instead')
const RhythmClassification$json = {
  '1': 'RhythmClassification',
  '2': [
    {'1': 'RHYTHM_UNSPECIFIED', '2': 0},
    {'1': 'NORMAL_SINUS', '2': 1},
    {'1': 'BRADYCARDIA', '2': 2},
    {'1': 'TACHYCARDIA', '2': 3},
    {'1': 'IRREGULAR_ARRHYTHMIA', '2': 4},
    {'1': 'NO_SIGNAL', '2': 5},
  ],
};

/// Descriptor for `RhythmClassification`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List rhythmClassificationDescriptor = $convert.base64Decode(
    'ChRSaHl0aG1DbGFzc2lmaWNhdGlvbhIWChJSSFlUSE1fVU5TUEVDSUZJRUQQABIQCgxOT1JNQU'
    'xfU0lOVVMQARIPCgtCUkFEWUNBUkRJQRACEg8KC1RBQ0hZQ0FSRElBEAMSGAoUSVJSRUdVTEFS'
    'X0FSUkhZVEhNSUEQBBINCglOT19TSUdOQUwQBQ==');

@$core.Deprecated('Use cardiacEventTypeDescriptor instead')
const CardiacEventType$json = {
  '1': 'CardiacEventType',
  '2': [
    {'1': 'CARDIAC_EVENT_UNSPECIFIED', '2': 0},
    {'1': 'R_PEAK_DETECTED', '2': 1},
    {'1': 'LEAD_OFF_TRIGGERED', '2': 2},
    {'1': 'LEAD_RECONNECTED', '2': 3},
    {'1': 'BRADYCARDIA_TRIGGERED', '2': 4},
    {'1': 'TACHYCARDIA_TRIGGERED', '2': 5},
    {'1': 'SOURCE_MODE_SWITCHED', '2': 6},
  ],
};

/// Descriptor for `CardiacEventType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List cardiacEventTypeDescriptor = $convert.base64Decode(
    'ChBDYXJkaWFjRXZlbnRUeXBlEh0KGUNBUkRJQUNfRVZFTlRfVU5TUEVDSUZJRUQQABITCg9SX1'
    'BFQUtfREVURUNURUQQARIWChJMRUFEX09GRl9UUklHR0VSRUQQAhIUChBMRUFEX1JFQ09OTkVD'
    'VEVEEAMSGQoVQlJBRFlDQVJESUFfVFJJR0dFUkVEEAQSGQoVVEFDSFlDQVJESUFfVFJJR0dFUk'
    'VEEAUSGAoUU09VUkNFX01PREVfU1dJVENIRUQQBg==');

@$core.Deprecated('Use streamEcgRequestDescriptor instead')
const StreamEcgRequest$json = {
  '1': 'StreamEcgRequest',
  '2': [
    {'1': 'client_id', '3': 1, '4': 1, '5': 9, '10': 'clientId'},
  ],
};

/// Descriptor for `StreamEcgRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List streamEcgRequestDescriptor = $convert.base64Decode(
    'ChBTdHJlYW1FY2dSZXF1ZXN0EhsKCWNsaWVudF9pZBgBIAEoCVIIY2xpZW50SWQ=');

@$core.Deprecated('Use streamEventsRequestDescriptor instead')
const StreamEventsRequest$json = {
  '1': 'StreamEventsRequest',
  '2': [
    {'1': 'client_id', '3': 1, '4': 1, '5': 9, '10': 'clientId'},
  ],
};

/// Descriptor for `StreamEventsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List streamEventsRequestDescriptor =
    $convert.base64Decode(
        'ChNTdHJlYW1FdmVudHNSZXF1ZXN0EhsKCWNsaWVudF9pZBgBIAEoCVIIY2xpZW50SWQ=');

@$core.Deprecated('Use streamLogsRequestDescriptor instead')
const StreamLogsRequest$json = {
  '1': 'StreamLogsRequest',
  '2': [
    {'1': 'client_id', '3': 1, '4': 1, '5': 9, '10': 'clientId'},
    {
      '1': 'min_level',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.telemetry.v1.LogLevel',
      '10': 'minLevel'
    },
  ],
};

/// Descriptor for `StreamLogsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List streamLogsRequestDescriptor = $convert.base64Decode(
    'ChFTdHJlYW1Mb2dzUmVxdWVzdBIbCgljbGllbnRfaWQYASABKAlSCGNsaWVudElkEjMKCW1pbl'
    '9sZXZlbBgCIAEoDjIWLnRlbGVtZXRyeS52MS5Mb2dMZXZlbFIIbWluTGV2ZWw=');

@$core.Deprecated('Use ecgSampleDescriptor instead')
const EcgSample$json = {
  '1': 'EcgSample',
  '2': [
    {
      '1': 'timestamp_unix_millis',
      '3': 1,
      '4': 1,
      '5': 3,
      '10': 'timestampUnixMillis'
    },
    {'1': 'raw_adc', '3': 2, '4': 1, '5': 13, '10': 'rawAdc'},
    {'1': 'voltage_mv', '3': 3, '4': 1, '5': 2, '10': 'voltageMv'},
    {'1': 'filtered_mv', '3': 4, '4': 1, '5': 2, '10': 'filteredMv'},
    {'1': 'is_r_peak', '3': 5, '4': 1, '5': 8, '10': 'isRPeak'},
    {'1': 'lead_off', '3': 6, '4': 1, '5': 8, '10': 'leadOff'},
  ],
};

/// Descriptor for `EcgSample`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List ecgSampleDescriptor = $convert.base64Decode(
    'CglFY2dTYW1wbGUSMgoVdGltZXN0YW1wX3VuaXhfbWlsbGlzGAEgASgDUhN0aW1lc3RhbXBVbm'
    'l4TWlsbGlzEhcKB3Jhd19hZGMYAiABKA1SBnJhd0FkYxIdCgp2b2x0YWdlX212GAMgASgCUgl2'
    'b2x0YWdlTXYSHwoLZmlsdGVyZWRfbXYYBCABKAJSCmZpbHRlcmVkTXYSGgoJaXNfcl9wZWFrGA'
    'UgASgIUgdpc1JQZWFrEhkKCGxlYWRfb2ZmGAYgASgIUgdsZWFkT2Zm');

@$core.Deprecated('Use cardiacMetricsDescriptor instead')
const CardiacMetrics$json = {
  '1': 'CardiacMetrics',
  '2': [
    {'1': 'heart_rate_bpm', '3': 1, '4': 1, '5': 13, '10': 'heartRateBpm'},
    {'1': 'rr_interval_ms', '3': 2, '4': 1, '5': 13, '10': 'rrIntervalMs'},
    {'1': 'hrv_sdnn_ms', '3': 3, '4': 1, '5': 2, '10': 'hrvSdnnMs'},
    {'1': 'hrv_rmssd_ms', '3': 4, '4': 1, '5': 2, '10': 'hrvRmssdMs'},
    {
      '1': 'lead_status',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.telemetry.v1.LeadStatus',
      '10': 'leadStatus'
    },
    {
      '1': 'rhythm',
      '3': 6,
      '4': 1,
      '5': 14,
      '6': '.telemetry.v1.RhythmClassification',
      '10': 'rhythm'
    },
    {
      '1': 'signal_quality_percent',
      '3': 7,
      '4': 1,
      '5': 13,
      '10': 'signalQualityPercent'
    },
    {'1': 'total_beats', '3': 8, '4': 1, '5': 4, '10': 'totalBeats'},
    {
      '1': 'last_beat_timestamp_ms',
      '3': 9,
      '4': 1,
      '5': 3,
      '10': 'lastBeatTimestampMs'
    },
  ],
};

/// Descriptor for `CardiacMetrics`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cardiacMetricsDescriptor = $convert.base64Decode(
    'Cg5DYXJkaWFjTWV0cmljcxIkCg5oZWFydF9yYXRlX2JwbRgBIAEoDVIMaGVhcnRSYXRlQnBtEi'
    'QKDnJyX2ludGVydmFsX21zGAIgASgNUgxyckludGVydmFsTXMSHgoLaHJ2X3Nkbm5fbXMYAyAB'
    'KAJSCWhydlNkbm5NcxIgCgxocnZfcm1zc2RfbXMYBCABKAJSCmhydlJtc3NkTXMSOQoLbGVhZF'
    '9zdGF0dXMYBSABKA4yGC50ZWxlbWV0cnkudjEuTGVhZFN0YXR1c1IKbGVhZFN0YXR1cxI6CgZy'
    'aHl0aG0YBiABKA4yIi50ZWxlbWV0cnkudjEuUmh5dGhtQ2xhc3NpZmljYXRpb25SBnJoeXRobR'
    'I0ChZzaWduYWxfcXVhbGl0eV9wZXJjZW50GAcgASgNUhRzaWduYWxRdWFsaXR5UGVyY2VudBIf'
    'Cgt0b3RhbF9iZWF0cxgIIAEoBFIKdG90YWxCZWF0cxIzChZsYXN0X2JlYXRfdGltZXN0YW1wX2'
    '1zGAkgASgDUhNsYXN0QmVhdFRpbWVzdGFtcE1z');

@$core.Deprecated('Use ecgWaveformChunkDescriptor instead')
const EcgWaveformChunk$json = {
  '1': 'EcgWaveformChunk',
  '2': [
    {'1': 'sequence_number', '3': 1, '4': 1, '5': 3, '10': 'sequenceNumber'},
    {'1': 'sample_rate_hz', '3': 2, '4': 1, '5': 13, '10': 'sampleRateHz'},
    {
      '1': 'samples',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.telemetry.v1.EcgSample',
      '10': 'samples'
    },
    {
      '1': 'metrics',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.telemetry.v1.CardiacMetrics',
      '10': 'metrics'
    },
    {
      '1': 'source_mode',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.telemetry.v1.SourceMode',
      '10': 'sourceMode'
    },
  ],
};

/// Descriptor for `EcgWaveformChunk`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List ecgWaveformChunkDescriptor = $convert.base64Decode(
    'ChBFY2dXYXZlZm9ybUNodW5rEicKD3NlcXVlbmNlX251bWJlchgBIAEoA1IOc2VxdWVuY2VOdW'
    '1iZXISJAoOc2FtcGxlX3JhdGVfaHoYAiABKA1SDHNhbXBsZVJhdGVIehIxCgdzYW1wbGVzGAMg'
    'AygLMhcudGVsZW1ldHJ5LnYxLkVjZ1NhbXBsZVIHc2FtcGxlcxI2CgdtZXRyaWNzGAQgASgLMh'
    'wudGVsZW1ldHJ5LnYxLkNhcmRpYWNNZXRyaWNzUgdtZXRyaWNzEjkKC3NvdXJjZV9tb2RlGAUg'
    'ASgOMhgudGVsZW1ldHJ5LnYxLlNvdXJjZU1vZGVSCnNvdXJjZU1vZGU=');

@$core.Deprecated('Use cardiacEventDescriptor instead')
const CardiacEvent$json = {
  '1': 'CardiacEvent',
  '2': [
    {'1': 'sequence_number', '3': 1, '4': 1, '5': 3, '10': 'sequenceNumber'},
    {
      '1': 'timestamp_unix_millis',
      '3': 2,
      '4': 1,
      '5': 3,
      '10': 'timestampUnixMillis'
    },
    {
      '1': 'event_type',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.telemetry.v1.CardiacEventType',
      '10': 'eventType'
    },
    {'1': 'bpm', '3': 4, '4': 1, '5': 13, '10': 'bpm'},
    {'1': 'rr_interval_ms', '3': 5, '4': 1, '5': 13, '10': 'rrIntervalMs'},
    {'1': 'description', '3': 6, '4': 1, '5': 9, '10': 'description'},
  ],
};

/// Descriptor for `CardiacEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cardiacEventDescriptor = $convert.base64Decode(
    'CgxDYXJkaWFjRXZlbnQSJwoPc2VxdWVuY2VfbnVtYmVyGAEgASgDUg5zZXF1ZW5jZU51bWJlch'
    'IyChV0aW1lc3RhbXBfdW5peF9taWxsaXMYAiABKANSE3RpbWVzdGFtcFVuaXhNaWxsaXMSPQoK'
    'ZXZlbnRfdHlwZRgDIAEoDjIeLnRlbGVtZXRyeS52MS5DYXJkaWFjRXZlbnRUeXBlUglldmVudF'
    'R5cGUSEAoDYnBtGAQgASgNUgNicG0SJAoOcnJfaW50ZXJ2YWxfbXMYBSABKA1SDHJySW50ZXJ2'
    'YWxNcxIgCgtkZXNjcmlwdGlvbhgGIAEoCVILZGVzY3JpcHRpb24=');

@$core.Deprecated('Use logEntryDescriptor instead')
const LogEntry$json = {
  '1': 'LogEntry',
  '2': [
    {
      '1': 'timestamp_unix_millis',
      '3': 1,
      '4': 1,
      '5': 3,
      '10': 'timestampUnixMillis'
    },
    {
      '1': 'level',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.telemetry.v1.LogLevel',
      '10': 'level'
    },
    {'1': 'component', '3': 3, '4': 1, '5': 9, '10': 'component'},
    {'1': 'message', '3': 4, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `LogEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List logEntryDescriptor = $convert.base64Decode(
    'CghMb2dFbnRyeRIyChV0aW1lc3RhbXBfdW5peF9taWxsaXMYASABKANSE3RpbWVzdGFtcFVuaX'
    'hNaWxsaXMSLAoFbGV2ZWwYAiABKA4yFi50ZWxlbWV0cnkudjEuTG9nTGV2ZWxSBWxldmVsEhwK'
    'CWNvbXBvbmVudBgDIAEoCVIJY29tcG9uZW50EhgKB21lc3NhZ2UYBCABKAlSB21lc3NhZ2U=');

@$core.Deprecated('Use getStatusRequestDescriptor instead')
const GetStatusRequest$json = {
  '1': 'GetStatusRequest',
};

/// Descriptor for `GetStatusRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getStatusRequestDescriptor =
    $convert.base64Decode('ChBHZXRTdGF0dXNSZXF1ZXN0');

@$core.Deprecated('Use statusResponseDescriptor instead')
const StatusResponse$json = {
  '1': 'StatusResponse',
  '2': [
    {
      '1': 'timestamp_unix_millis',
      '3': 1,
      '4': 1,
      '5': 3,
      '10': 'timestampUnixMillis'
    },
    {'1': 'uptime_seconds', '3': 2, '4': 1, '5': 4, '10': 'uptimeSeconds'},
    {
      '1': 'source_mode',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.telemetry.v1.SourceMode',
      '10': 'sourceMode'
    },
    {
      '1': 'metrics',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.telemetry.v1.CardiacMetrics',
      '10': 'metrics'
    },
    {
      '1': 'total_samples_processed',
      '3': 5,
      '4': 1,
      '5': 4,
      '10': 'totalSamplesProcessed'
    },
    {'1': 'target_sim_bpm', '3': 6, '4': 1, '5': 13, '10': 'targetSimBpm'},
  ],
};

/// Descriptor for `StatusResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List statusResponseDescriptor = $convert.base64Decode(
    'Cg5TdGF0dXNSZXNwb25zZRIyChV0aW1lc3RhbXBfdW5peF9taWxsaXMYASABKANSE3RpbWVzdG'
    'FtcFVuaXhNaWxsaXMSJQoOdXB0aW1lX3NlY29uZHMYAiABKARSDXVwdGltZVNlY29uZHMSOQoL'
    'c291cmNlX21vZGUYAyABKA4yGC50ZWxlbWV0cnkudjEuU291cmNlTW9kZVIKc291cmNlTW9kZR'
    'I2CgdtZXRyaWNzGAQgASgLMhwudGVsZW1ldHJ5LnYxLkNhcmRpYWNNZXRyaWNzUgdtZXRyaWNz'
    'EjYKF3RvdGFsX3NhbXBsZXNfcHJvY2Vzc2VkGAUgASgEUhV0b3RhbFNhbXBsZXNQcm9jZXNzZW'
    'QSJAoOdGFyZ2V0X3NpbV9icG0YBiABKA1SDHRhcmdldFNpbUJwbQ==');

@$core.Deprecated('Use configureSourceRequestDescriptor instead')
const ConfigureSourceRequest$json = {
  '1': 'ConfigureSourceRequest',
  '2': [
    {
      '1': 'source_mode',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.telemetry.v1.SourceMode',
      '10': 'sourceMode'
    },
    {'1': 'target_sim_bpm', '3': 2, '4': 1, '5': 13, '10': 'targetSimBpm'},
    {'1': 'reset_dsp', '3': 3, '4': 1, '5': 8, '10': 'resetDsp'},
  ],
};

/// Descriptor for `ConfigureSourceRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List configureSourceRequestDescriptor = $convert.base64Decode(
    'ChZDb25maWd1cmVTb3VyY2VSZXF1ZXN0EjkKC3NvdXJjZV9tb2RlGAEgASgOMhgudGVsZW1ldH'
    'J5LnYxLlNvdXJjZU1vZGVSCnNvdXJjZU1vZGUSJAoOdGFyZ2V0X3NpbV9icG0YAiABKA1SDHRh'
    'cmdldFNpbUJwbRIbCglyZXNldF9kc3AYAyABKAhSCHJlc2V0RHNw');
