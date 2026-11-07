// This is a generated file - do not edit.
//
// Generated from telemetry.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// Log level
class LogLevel extends $pb.ProtobufEnum {
  static const LogLevel DEBUG = LogLevel._(0, _omitEnumNames ? '' : 'DEBUG');
  static const LogLevel INFO = LogLevel._(1, _omitEnumNames ? '' : 'INFO');
  static const LogLevel WARN = LogLevel._(2, _omitEnumNames ? '' : 'WARN');
  static const LogLevel ERROR = LogLevel._(3, _omitEnumNames ? '' : 'ERROR');

  static const $core.List<LogLevel> values = <LogLevel>[
    DEBUG,
    INFO,
    WARN,
    ERROR,
  ];

  static final $core.List<LogLevel?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static LogLevel? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const LogLevel._(super.value, super.name);
}

/// Data ingestion source mode
class SourceMode extends $pb.ProtobufEnum {
  static const SourceMode SOURCE_MODE_UNSPECIFIED =
      SourceMode._(0, _omitEnumNames ? '' : 'SOURCE_MODE_UNSPECIFIED');
  static const SourceMode SIMULATOR =
      SourceMode._(1, _omitEnumNames ? '' : 'SIMULATOR');
  static const SourceMode UDP_WIFI =
      SourceMode._(2, _omitEnumNames ? '' : 'UDP_WIFI');
  static const SourceMode USB_SERIAL =
      SourceMode._(3, _omitEnumNames ? '' : 'USB_SERIAL');

  static const $core.List<SourceMode> values = <SourceMode>[
    SOURCE_MODE_UNSPECIFIED,
    SIMULATOR,
    UDP_WIFI,
    USB_SERIAL,
  ];

  static final $core.List<SourceMode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static SourceMode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SourceMode._(super.value, super.name);
}

/// Lead attachment status from AD8232 LO+ / LO- pins
class LeadStatus extends $pb.ProtobufEnum {
  static const LeadStatus LEAD_STATUS_UNSPECIFIED =
      LeadStatus._(0, _omitEnumNames ? '' : 'LEAD_STATUS_UNSPECIFIED');
  static const LeadStatus LEADS_CONNECTED =
      LeadStatus._(1, _omitEnumNames ? '' : 'LEADS_CONNECTED');
  static const LeadStatus LEAD_OFF_POSITIVE =
      LeadStatus._(2, _omitEnumNames ? '' : 'LEAD_OFF_POSITIVE');
  static const LeadStatus LEAD_OFF_NEGATIVE =
      LeadStatus._(3, _omitEnumNames ? '' : 'LEAD_OFF_NEGATIVE');
  static const LeadStatus LEAD_OFF_BOTH =
      LeadStatus._(4, _omitEnumNames ? '' : 'LEAD_OFF_BOTH');

  static const $core.List<LeadStatus> values = <LeadStatus>[
    LEAD_STATUS_UNSPECIFIED,
    LEADS_CONNECTED,
    LEAD_OFF_POSITIVE,
    LEAD_OFF_NEGATIVE,
    LEAD_OFF_BOTH,
  ];

  static final $core.List<LeadStatus?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static LeadStatus? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const LeadStatus._(super.value, super.name);
}

/// Clinical rhythm classification
class RhythmClassification extends $pb.ProtobufEnum {
  static const RhythmClassification RHYTHM_UNSPECIFIED =
      RhythmClassification._(0, _omitEnumNames ? '' : 'RHYTHM_UNSPECIFIED');
  static const RhythmClassification NORMAL_SINUS =
      RhythmClassification._(1, _omitEnumNames ? '' : 'NORMAL_SINUS');
  static const RhythmClassification BRADYCARDIA =
      RhythmClassification._(2, _omitEnumNames ? '' : 'BRADYCARDIA');
  static const RhythmClassification TACHYCARDIA =
      RhythmClassification._(3, _omitEnumNames ? '' : 'TACHYCARDIA');
  static const RhythmClassification IRREGULAR_ARRHYTHMIA =
      RhythmClassification._(4, _omitEnumNames ? '' : 'IRREGULAR_ARRHYTHMIA');
  static const RhythmClassification NO_SIGNAL =
      RhythmClassification._(5, _omitEnumNames ? '' : 'NO_SIGNAL');

  static const $core.List<RhythmClassification> values = <RhythmClassification>[
    RHYTHM_UNSPECIFIED,
    NORMAL_SINUS,
    BRADYCARDIA,
    TACHYCARDIA,
    IRREGULAR_ARRHYTHMIA,
    NO_SIGNAL,
  ];

  static final $core.List<RhythmClassification?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static RhythmClassification? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const RhythmClassification._(super.value, super.name);
}

/// Discrete cardiac events (alarms, QRS beats, state changes)
class CardiacEventType extends $pb.ProtobufEnum {
  static const CardiacEventType CARDIAC_EVENT_UNSPECIFIED =
      CardiacEventType._(0, _omitEnumNames ? '' : 'CARDIAC_EVENT_UNSPECIFIED');
  static const CardiacEventType R_PEAK_DETECTED =
      CardiacEventType._(1, _omitEnumNames ? '' : 'R_PEAK_DETECTED');
  static const CardiacEventType LEAD_OFF_TRIGGERED =
      CardiacEventType._(2, _omitEnumNames ? '' : 'LEAD_OFF_TRIGGERED');
  static const CardiacEventType LEAD_RECONNECTED =
      CardiacEventType._(3, _omitEnumNames ? '' : 'LEAD_RECONNECTED');
  static const CardiacEventType BRADYCARDIA_TRIGGERED =
      CardiacEventType._(4, _omitEnumNames ? '' : 'BRADYCARDIA_TRIGGERED');
  static const CardiacEventType TACHYCARDIA_TRIGGERED =
      CardiacEventType._(5, _omitEnumNames ? '' : 'TACHYCARDIA_TRIGGERED');
  static const CardiacEventType SOURCE_MODE_SWITCHED =
      CardiacEventType._(6, _omitEnumNames ? '' : 'SOURCE_MODE_SWITCHED');

  static const $core.List<CardiacEventType> values = <CardiacEventType>[
    CARDIAC_EVENT_UNSPECIFIED,
    R_PEAK_DETECTED,
    LEAD_OFF_TRIGGERED,
    LEAD_RECONNECTED,
    BRADYCARDIA_TRIGGERED,
    TACHYCARDIA_TRIGGERED,
    SOURCE_MODE_SWITCHED,
  ];

  static final $core.List<CardiacEventType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 6);
  static CardiacEventType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CardiacEventType._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
