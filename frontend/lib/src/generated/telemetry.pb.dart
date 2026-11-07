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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'telemetry.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'telemetry.pbenum.dart';

/// Request to stream ECG waveform chunks
class StreamEcgRequest extends $pb.GeneratedMessage {
  factory StreamEcgRequest({
    $core.String? clientId,
  }) {
    final result = StreamEcgRequest._();
    if (clientId != null) result.clientId = clientId;
    return result;
  }

  StreamEcgRequest._();

  factory StreamEcgRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StreamEcgRequest()..mergeFromBuffer(data, registry);
  factory StreamEcgRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StreamEcgRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StreamEcgRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'telemetry.v1'),
      createEmptyInstance: StreamEcgRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'clientId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamEcgRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamEcgRequest copyWith(void Function(StreamEcgRequest) updates) =>
      super.copyWith((message) => updates(message as StreamEcgRequest))
          as StreamEcgRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use StreamEcgRequest() / StreamEcgRequest.new instead')
  static StreamEcgRequest create() => StreamEcgRequest._();
  static $pb.GeneratedMessage $_createMessage() => StreamEcgRequest._();
  @$core.override
  StreamEcgRequest createEmptyInstance() => StreamEcgRequest._();
  @$core.pragma('dart2js:noInline')
  static StreamEcgRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StreamEcgRequest>(
          StreamEcgRequest.$_createMessage);
  static StreamEcgRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get clientId => $_getSZ(0);
  @$pb.TagNumber(1)
  set clientId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasClientId() => $_has(0);
  @$pb.TagNumber(1)
  void clearClientId() => $_clearField(1);
}

/// Request to stream cardiac events
class StreamEventsRequest extends $pb.GeneratedMessage {
  factory StreamEventsRequest({
    $core.String? clientId,
  }) {
    final result = StreamEventsRequest._();
    if (clientId != null) result.clientId = clientId;
    return result;
  }

  StreamEventsRequest._();

  factory StreamEventsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StreamEventsRequest()..mergeFromBuffer(data, registry);
  factory StreamEventsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StreamEventsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StreamEventsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'telemetry.v1'),
      createEmptyInstance: StreamEventsRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'clientId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamEventsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamEventsRequest copyWith(void Function(StreamEventsRequest) updates) =>
      super.copyWith((message) => updates(message as StreamEventsRequest))
          as StreamEventsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use StreamEventsRequest() / StreamEventsRequest.new instead')
  static StreamEventsRequest create() => StreamEventsRequest._();
  static $pb.GeneratedMessage $_createMessage() => StreamEventsRequest._();
  @$core.override
  StreamEventsRequest createEmptyInstance() => StreamEventsRequest._();
  @$core.pragma('dart2js:noInline')
  static StreamEventsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StreamEventsRequest>(
          StreamEventsRequest.$_createMessage);
  static StreamEventsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get clientId => $_getSZ(0);
  @$pb.TagNumber(1)
  set clientId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasClientId() => $_has(0);
  @$pb.TagNumber(1)
  void clearClientId() => $_clearField(1);
}

/// Request to stream logs
class StreamLogsRequest extends $pb.GeneratedMessage {
  factory StreamLogsRequest({
    $core.String? clientId,
    LogLevel? minLevel,
  }) {
    final result = StreamLogsRequest._();
    if (clientId != null) result.clientId = clientId;
    if (minLevel != null) result.minLevel = minLevel;
    return result;
  }

  StreamLogsRequest._();

  factory StreamLogsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StreamLogsRequest()..mergeFromBuffer(data, registry);
  factory StreamLogsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StreamLogsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StreamLogsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'telemetry.v1'),
      createEmptyInstance: StreamLogsRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'clientId')
    ..aE<LogLevel>(2, _omitFieldNames ? '' : 'minLevel',
        enumValues: LogLevel.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamLogsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamLogsRequest copyWith(void Function(StreamLogsRequest) updates) =>
      super.copyWith((message) => updates(message as StreamLogsRequest))
          as StreamLogsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use StreamLogsRequest() / StreamLogsRequest.new instead')
  static StreamLogsRequest create() => StreamLogsRequest._();
  static $pb.GeneratedMessage $_createMessage() => StreamLogsRequest._();
  @$core.override
  StreamLogsRequest createEmptyInstance() => StreamLogsRequest._();
  @$core.pragma('dart2js:noInline')
  static StreamLogsRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StreamLogsRequest>(
          StreamLogsRequest.$_createMessage);
  static StreamLogsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get clientId => $_getSZ(0);
  @$pb.TagNumber(1)
  set clientId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasClientId() => $_has(0);
  @$pb.TagNumber(1)
  void clearClientId() => $_clearField(1);

  @$pb.TagNumber(2)
  LogLevel get minLevel => $_getN(1);
  @$pb.TagNumber(2)
  set minLevel(LogLevel value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasMinLevel() => $_has(1);
  @$pb.TagNumber(2)
  void clearMinLevel() => $_clearField(2);
}

/// Single sampled point in time
class EcgSample extends $pb.GeneratedMessage {
  factory EcgSample({
    $fixnum.Int64? timestampUnixMillis,
    $core.int? rawAdc,
    $core.double? voltageMv,
    $core.double? filteredMv,
    $core.bool? isRPeak,
    $core.bool? leadOff,
  }) {
    final result = EcgSample._();
    if (timestampUnixMillis != null)
      result.timestampUnixMillis = timestampUnixMillis;
    if (rawAdc != null) result.rawAdc = rawAdc;
    if (voltageMv != null) result.voltageMv = voltageMv;
    if (filteredMv != null) result.filteredMv = filteredMv;
    if (isRPeak != null) result.isRPeak = isRPeak;
    if (leadOff != null) result.leadOff = leadOff;
    return result;
  }

  EcgSample._();

  factory EcgSample.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EcgSample()..mergeFromBuffer(data, registry);
  factory EcgSample.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EcgSample()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EcgSample',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'telemetry.v1'),
      createEmptyInstance: EcgSample.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'timestampUnixMillis')
    ..aI(2, _omitFieldNames ? '' : 'rawAdc', fieldType: $pb.PbFieldType.OU3)
    ..aD(3, _omitFieldNames ? '' : 'voltageMv', fieldType: $pb.PbFieldType.OF)
    ..aD(4, _omitFieldNames ? '' : 'filteredMv', fieldType: $pb.PbFieldType.OF)
    ..aOB(5, _omitFieldNames ? '' : 'isRPeak')
    ..aOB(6, _omitFieldNames ? '' : 'leadOff')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EcgSample clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EcgSample copyWith(void Function(EcgSample) updates) =>
      super.copyWith((message) => updates(message as EcgSample)) as EcgSample;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use EcgSample() / EcgSample.new instead')
  static EcgSample create() => EcgSample._();
  static $pb.GeneratedMessage $_createMessage() => EcgSample._();
  @$core.override
  EcgSample createEmptyInstance() => EcgSample._();
  @$core.pragma('dart2js:noInline')
  static EcgSample getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EcgSample>(EcgSample.$_createMessage);
  static EcgSample? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get timestampUnixMillis => $_getI64(0);
  @$pb.TagNumber(1)
  set timestampUnixMillis($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTimestampUnixMillis() => $_has(0);
  @$pb.TagNumber(1)
  void clearTimestampUnixMillis() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get rawAdc => $_getIZ(1);
  @$pb.TagNumber(2)
  set rawAdc($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRawAdc() => $_has(1);
  @$pb.TagNumber(2)
  void clearRawAdc() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get voltageMv => $_getN(2);
  @$pb.TagNumber(3)
  set voltageMv($core.double value) => $_setFloat(2, value);
  @$pb.TagNumber(3)
  $core.bool hasVoltageMv() => $_has(2);
  @$pb.TagNumber(3)
  void clearVoltageMv() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get filteredMv => $_getN(3);
  @$pb.TagNumber(4)
  set filteredMv($core.double value) => $_setFloat(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFilteredMv() => $_has(3);
  @$pb.TagNumber(4)
  void clearFilteredMv() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get isRPeak => $_getBF(4);
  @$pb.TagNumber(5)
  set isRPeak($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasIsRPeak() => $_has(4);
  @$pb.TagNumber(5)
  void clearIsRPeak() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get leadOff => $_getBF(5);
  @$pb.TagNumber(6)
  set leadOff($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasLeadOff() => $_has(5);
  @$pb.TagNumber(6)
  void clearLeadOff() => $_clearField(6);
}

/// Comprehensive real-time cardiac metrics computed by the Rust DSP engine
class CardiacMetrics extends $pb.GeneratedMessage {
  factory CardiacMetrics({
    $core.int? heartRateBpm,
    $core.int? rrIntervalMs,
    $core.double? hrvSdnnMs,
    $core.double? hrvRmssdMs,
    LeadStatus? leadStatus,
    RhythmClassification? rhythm,
    $core.int? signalQualityPercent,
    $fixnum.Int64? totalBeats,
    $fixnum.Int64? lastBeatTimestampMs,
  }) {
    final result = CardiacMetrics._();
    if (heartRateBpm != null) result.heartRateBpm = heartRateBpm;
    if (rrIntervalMs != null) result.rrIntervalMs = rrIntervalMs;
    if (hrvSdnnMs != null) result.hrvSdnnMs = hrvSdnnMs;
    if (hrvRmssdMs != null) result.hrvRmssdMs = hrvRmssdMs;
    if (leadStatus != null) result.leadStatus = leadStatus;
    if (rhythm != null) result.rhythm = rhythm;
    if (signalQualityPercent != null)
      result.signalQualityPercent = signalQualityPercent;
    if (totalBeats != null) result.totalBeats = totalBeats;
    if (lastBeatTimestampMs != null)
      result.lastBeatTimestampMs = lastBeatTimestampMs;
    return result;
  }

  CardiacMetrics._();

  factory CardiacMetrics.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CardiacMetrics()..mergeFromBuffer(data, registry);
  factory CardiacMetrics.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CardiacMetrics()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CardiacMetrics',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'telemetry.v1'),
      createEmptyInstance: CardiacMetrics.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'heartRateBpm',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'rrIntervalMs',
        fieldType: $pb.PbFieldType.OU3)
    ..aD(3, _omitFieldNames ? '' : 'hrvSdnnMs', fieldType: $pb.PbFieldType.OF)
    ..aD(4, _omitFieldNames ? '' : 'hrvRmssdMs', fieldType: $pb.PbFieldType.OF)
    ..aE<LeadStatus>(5, _omitFieldNames ? '' : 'leadStatus',
        enumValues: LeadStatus.values)
    ..aE<RhythmClassification>(6, _omitFieldNames ? '' : 'rhythm',
        enumValues: RhythmClassification.values)
    ..aI(7, _omitFieldNames ? '' : 'signalQualityPercent',
        fieldType: $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(
        8, _omitFieldNames ? '' : 'totalBeats', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aInt64(9, _omitFieldNames ? '' : 'lastBeatTimestampMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CardiacMetrics clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CardiacMetrics copyWith(void Function(CardiacMetrics) updates) =>
      super.copyWith((message) => updates(message as CardiacMetrics))
          as CardiacMetrics;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CardiacMetrics() / CardiacMetrics.new instead')
  static CardiacMetrics create() => CardiacMetrics._();
  static $pb.GeneratedMessage $_createMessage() => CardiacMetrics._();
  @$core.override
  CardiacMetrics createEmptyInstance() => CardiacMetrics._();
  @$core.pragma('dart2js:noInline')
  static CardiacMetrics getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CardiacMetrics>(
          CardiacMetrics.$_createMessage);
  static CardiacMetrics? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get heartRateBpm => $_getIZ(0);
  @$pb.TagNumber(1)
  set heartRateBpm($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasHeartRateBpm() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeartRateBpm() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get rrIntervalMs => $_getIZ(1);
  @$pb.TagNumber(2)
  set rrIntervalMs($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRrIntervalMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearRrIntervalMs() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get hrvSdnnMs => $_getN(2);
  @$pb.TagNumber(3)
  set hrvSdnnMs($core.double value) => $_setFloat(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHrvSdnnMs() => $_has(2);
  @$pb.TagNumber(3)
  void clearHrvSdnnMs() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get hrvRmssdMs => $_getN(3);
  @$pb.TagNumber(4)
  set hrvRmssdMs($core.double value) => $_setFloat(3, value);
  @$pb.TagNumber(4)
  $core.bool hasHrvRmssdMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearHrvRmssdMs() => $_clearField(4);

  @$pb.TagNumber(5)
  LeadStatus get leadStatus => $_getN(4);
  @$pb.TagNumber(5)
  set leadStatus(LeadStatus value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasLeadStatus() => $_has(4);
  @$pb.TagNumber(5)
  void clearLeadStatus() => $_clearField(5);

  @$pb.TagNumber(6)
  RhythmClassification get rhythm => $_getN(5);
  @$pb.TagNumber(6)
  set rhythm(RhythmClassification value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasRhythm() => $_has(5);
  @$pb.TagNumber(6)
  void clearRhythm() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get signalQualityPercent => $_getIZ(6);
  @$pb.TagNumber(7)
  set signalQualityPercent($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasSignalQualityPercent() => $_has(6);
  @$pb.TagNumber(7)
  void clearSignalQualityPercent() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get totalBeats => $_getI64(7);
  @$pb.TagNumber(8)
  set totalBeats($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasTotalBeats() => $_has(7);
  @$pb.TagNumber(8)
  void clearTotalBeats() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get lastBeatTimestampMs => $_getI64(8);
  @$pb.TagNumber(9)
  set lastBeatTimestampMs($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasLastBeatTimestampMs() => $_has(8);
  @$pb.TagNumber(9)
  void clearLastBeatTimestampMs() => $_clearField(9);
}

/// Batched chunk of ECG waveform samples
class EcgWaveformChunk extends $pb.GeneratedMessage {
  factory EcgWaveformChunk({
    $fixnum.Int64? sequenceNumber,
    $core.int? sampleRateHz,
    $core.Iterable<EcgSample>? samples,
    CardiacMetrics? metrics,
    SourceMode? sourceMode,
  }) {
    final result = EcgWaveformChunk._();
    if (sequenceNumber != null) result.sequenceNumber = sequenceNumber;
    if (sampleRateHz != null) result.sampleRateHz = sampleRateHz;
    if (samples != null) result.samples.addAll(samples);
    if (metrics != null) result.metrics = metrics;
    if (sourceMode != null) result.sourceMode = sourceMode;
    return result;
  }

  EcgWaveformChunk._();

  factory EcgWaveformChunk.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EcgWaveformChunk()..mergeFromBuffer(data, registry);
  factory EcgWaveformChunk.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EcgWaveformChunk()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EcgWaveformChunk',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'telemetry.v1'),
      createEmptyInstance: EcgWaveformChunk.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'sequenceNumber')
    ..aI(2, _omitFieldNames ? '' : 'sampleRateHz',
        fieldType: $pb.PbFieldType.OU3)
    ..pPM<EcgSample>(3, _omitFieldNames ? '' : 'samples',
        subBuilder: EcgSample.$_createMessage)
    ..aOM<CardiacMetrics>(4, _omitFieldNames ? '' : 'metrics',
        subBuilder: CardiacMetrics.$_createMessage)
    ..aE<SourceMode>(5, _omitFieldNames ? '' : 'sourceMode',
        enumValues: SourceMode.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EcgWaveformChunk clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EcgWaveformChunk copyWith(void Function(EcgWaveformChunk) updates) =>
      super.copyWith((message) => updates(message as EcgWaveformChunk))
          as EcgWaveformChunk;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use EcgWaveformChunk() / EcgWaveformChunk.new instead')
  static EcgWaveformChunk create() => EcgWaveformChunk._();
  static $pb.GeneratedMessage $_createMessage() => EcgWaveformChunk._();
  @$core.override
  EcgWaveformChunk createEmptyInstance() => EcgWaveformChunk._();
  @$core.pragma('dart2js:noInline')
  static EcgWaveformChunk getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EcgWaveformChunk>(
          EcgWaveformChunk.$_createMessage);
  static EcgWaveformChunk? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get sequenceNumber => $_getI64(0);
  @$pb.TagNumber(1)
  set sequenceNumber($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSequenceNumber() => $_has(0);
  @$pb.TagNumber(1)
  void clearSequenceNumber() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get sampleRateHz => $_getIZ(1);
  @$pb.TagNumber(2)
  set sampleRateHz($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSampleRateHz() => $_has(1);
  @$pb.TagNumber(2)
  void clearSampleRateHz() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<EcgSample> get samples => $_getList(2);

  @$pb.TagNumber(4)
  CardiacMetrics get metrics => $_getN(3);
  @$pb.TagNumber(4)
  set metrics(CardiacMetrics value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasMetrics() => $_has(3);
  @$pb.TagNumber(4)
  void clearMetrics() => $_clearField(4);
  @$pb.TagNumber(4)
  CardiacMetrics ensureMetrics() => $_ensure(3);

  @$pb.TagNumber(5)
  SourceMode get sourceMode => $_getN(4);
  @$pb.TagNumber(5)
  set sourceMode(SourceMode value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasSourceMode() => $_has(4);
  @$pb.TagNumber(5)
  void clearSourceMode() => $_clearField(5);
}

class CardiacEvent extends $pb.GeneratedMessage {
  factory CardiacEvent({
    $fixnum.Int64? sequenceNumber,
    $fixnum.Int64? timestampUnixMillis,
    CardiacEventType? eventType,
    $core.int? bpm,
    $core.int? rrIntervalMs,
    $core.String? description,
  }) {
    final result = CardiacEvent._();
    if (sequenceNumber != null) result.sequenceNumber = sequenceNumber;
    if (timestampUnixMillis != null)
      result.timestampUnixMillis = timestampUnixMillis;
    if (eventType != null) result.eventType = eventType;
    if (bpm != null) result.bpm = bpm;
    if (rrIntervalMs != null) result.rrIntervalMs = rrIntervalMs;
    if (description != null) result.description = description;
    return result;
  }

  CardiacEvent._();

  factory CardiacEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CardiacEvent()..mergeFromBuffer(data, registry);
  factory CardiacEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CardiacEvent()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CardiacEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'telemetry.v1'),
      createEmptyInstance: CardiacEvent.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'sequenceNumber')
    ..aInt64(2, _omitFieldNames ? '' : 'timestampUnixMillis')
    ..aE<CardiacEventType>(3, _omitFieldNames ? '' : 'eventType',
        enumValues: CardiacEventType.values)
    ..aI(4, _omitFieldNames ? '' : 'bpm', fieldType: $pb.PbFieldType.OU3)
    ..aI(5, _omitFieldNames ? '' : 'rrIntervalMs',
        fieldType: $pb.PbFieldType.OU3)
    ..aOS(6, _omitFieldNames ? '' : 'description')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CardiacEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CardiacEvent copyWith(void Function(CardiacEvent) updates) =>
      super.copyWith((message) => updates(message as CardiacEvent))
          as CardiacEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CardiacEvent() / CardiacEvent.new instead')
  static CardiacEvent create() => CardiacEvent._();
  static $pb.GeneratedMessage $_createMessage() => CardiacEvent._();
  @$core.override
  CardiacEvent createEmptyInstance() => CardiacEvent._();
  @$core.pragma('dart2js:noInline')
  static CardiacEvent getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CardiacEvent>(
          CardiacEvent.$_createMessage);
  static CardiacEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get sequenceNumber => $_getI64(0);
  @$pb.TagNumber(1)
  set sequenceNumber($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSequenceNumber() => $_has(0);
  @$pb.TagNumber(1)
  void clearSequenceNumber() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get timestampUnixMillis => $_getI64(1);
  @$pb.TagNumber(2)
  set timestampUnixMillis($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTimestampUnixMillis() => $_has(1);
  @$pb.TagNumber(2)
  void clearTimestampUnixMillis() => $_clearField(2);

  @$pb.TagNumber(3)
  CardiacEventType get eventType => $_getN(2);
  @$pb.TagNumber(3)
  set eventType(CardiacEventType value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasEventType() => $_has(2);
  @$pb.TagNumber(3)
  void clearEventType() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get bpm => $_getIZ(3);
  @$pb.TagNumber(4)
  set bpm($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBpm() => $_has(3);
  @$pb.TagNumber(4)
  void clearBpm() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get rrIntervalMs => $_getIZ(4);
  @$pb.TagNumber(5)
  set rrIntervalMs($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasRrIntervalMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearRrIntervalMs() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get description => $_getSZ(5);
  @$pb.TagNumber(6)
  set description($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasDescription() => $_has(5);
  @$pb.TagNumber(6)
  void clearDescription() => $_clearField(6);
}

/// Diagnostic and operational log entry
class LogEntry extends $pb.GeneratedMessage {
  factory LogEntry({
    $fixnum.Int64? timestampUnixMillis,
    LogLevel? level,
    $core.String? component,
    $core.String? message,
  }) {
    final result = LogEntry._();
    if (timestampUnixMillis != null)
      result.timestampUnixMillis = timestampUnixMillis;
    if (level != null) result.level = level;
    if (component != null) result.component = component;
    if (message != null) result.message = message;
    return result;
  }

  LogEntry._();

  factory LogEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LogEntry()..mergeFromBuffer(data, registry);
  factory LogEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LogEntry()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LogEntry',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'telemetry.v1'),
      createEmptyInstance: LogEntry.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'timestampUnixMillis')
    ..aE<LogLevel>(2, _omitFieldNames ? '' : 'level',
        enumValues: LogLevel.values)
    ..aOS(3, _omitFieldNames ? '' : 'component')
    ..aOS(4, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogEntry copyWith(void Function(LogEntry) updates) =>
      super.copyWith((message) => updates(message as LogEntry)) as LogEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LogEntry() / LogEntry.new instead')
  static LogEntry create() => LogEntry._();
  static $pb.GeneratedMessage $_createMessage() => LogEntry._();
  @$core.override
  LogEntry createEmptyInstance() => LogEntry._();
  @$core.pragma('dart2js:noInline')
  static LogEntry getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LogEntry>(LogEntry.$_createMessage);
  static LogEntry? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get timestampUnixMillis => $_getI64(0);
  @$pb.TagNumber(1)
  set timestampUnixMillis($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTimestampUnixMillis() => $_has(0);
  @$pb.TagNumber(1)
  void clearTimestampUnixMillis() => $_clearField(1);

  @$pb.TagNumber(2)
  LogLevel get level => $_getN(1);
  @$pb.TagNumber(2)
  set level(LogLevel value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasLevel() => $_has(1);
  @$pb.TagNumber(2)
  void clearLevel() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get component => $_getSZ(2);
  @$pb.TagNumber(3)
  set component($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasComponent() => $_has(2);
  @$pb.TagNumber(3)
  void clearComponent() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get message => $_getSZ(3);
  @$pb.TagNumber(4)
  set message($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMessage() => $_has(3);
  @$pb.TagNumber(4)
  void clearMessage() => $_clearField(4);
}

class GetStatusRequest extends $pb.GeneratedMessage {
  factory GetStatusRequest() => GetStatusRequest._();

  GetStatusRequest._();

  factory GetStatusRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetStatusRequest()..mergeFromBuffer(data, registry);
  factory GetStatusRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetStatusRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetStatusRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'telemetry.v1'),
      createEmptyInstance: GetStatusRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStatusRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStatusRequest copyWith(void Function(GetStatusRequest) updates) =>
      super.copyWith((message) => updates(message as GetStatusRequest))
          as GetStatusRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetStatusRequest() / GetStatusRequest.new instead')
  static GetStatusRequest create() => GetStatusRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetStatusRequest._();
  @$core.override
  GetStatusRequest createEmptyInstance() => GetStatusRequest._();
  @$core.pragma('dart2js:noInline')
  static GetStatusRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetStatusRequest>(
          GetStatusRequest.$_createMessage);
  static GetStatusRequest? _defaultInstance;
}

class StatusResponse extends $pb.GeneratedMessage {
  factory StatusResponse({
    $fixnum.Int64? timestampUnixMillis,
    $fixnum.Int64? uptimeSeconds,
    SourceMode? sourceMode,
    CardiacMetrics? metrics,
    $fixnum.Int64? totalSamplesProcessed,
    $core.int? targetSimBpm,
  }) {
    final result = StatusResponse._();
    if (timestampUnixMillis != null)
      result.timestampUnixMillis = timestampUnixMillis;
    if (uptimeSeconds != null) result.uptimeSeconds = uptimeSeconds;
    if (sourceMode != null) result.sourceMode = sourceMode;
    if (metrics != null) result.metrics = metrics;
    if (totalSamplesProcessed != null)
      result.totalSamplesProcessed = totalSamplesProcessed;
    if (targetSimBpm != null) result.targetSimBpm = targetSimBpm;
    return result;
  }

  StatusResponse._();

  factory StatusResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StatusResponse()..mergeFromBuffer(data, registry);
  factory StatusResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StatusResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StatusResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'telemetry.v1'),
      createEmptyInstance: StatusResponse.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'timestampUnixMillis')
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'uptimeSeconds', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aE<SourceMode>(3, _omitFieldNames ? '' : 'sourceMode',
        enumValues: SourceMode.values)
    ..aOM<CardiacMetrics>(4, _omitFieldNames ? '' : 'metrics',
        subBuilder: CardiacMetrics.$_createMessage)
    ..a<$fixnum.Int64>(
        5, _omitFieldNames ? '' : 'totalSamplesProcessed', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aI(6, _omitFieldNames ? '' : 'targetSimBpm',
        fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatusResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatusResponse copyWith(void Function(StatusResponse) updates) =>
      super.copyWith((message) => updates(message as StatusResponse))
          as StatusResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use StatusResponse() / StatusResponse.new instead')
  static StatusResponse create() => StatusResponse._();
  static $pb.GeneratedMessage $_createMessage() => StatusResponse._();
  @$core.override
  StatusResponse createEmptyInstance() => StatusResponse._();
  @$core.pragma('dart2js:noInline')
  static StatusResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StatusResponse>(
          StatusResponse.$_createMessage);
  static StatusResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get timestampUnixMillis => $_getI64(0);
  @$pb.TagNumber(1)
  set timestampUnixMillis($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTimestampUnixMillis() => $_has(0);
  @$pb.TagNumber(1)
  void clearTimestampUnixMillis() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get uptimeSeconds => $_getI64(1);
  @$pb.TagNumber(2)
  set uptimeSeconds($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUptimeSeconds() => $_has(1);
  @$pb.TagNumber(2)
  void clearUptimeSeconds() => $_clearField(2);

  @$pb.TagNumber(3)
  SourceMode get sourceMode => $_getN(2);
  @$pb.TagNumber(3)
  set sourceMode(SourceMode value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasSourceMode() => $_has(2);
  @$pb.TagNumber(3)
  void clearSourceMode() => $_clearField(3);

  @$pb.TagNumber(4)
  CardiacMetrics get metrics => $_getN(3);
  @$pb.TagNumber(4)
  set metrics(CardiacMetrics value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasMetrics() => $_has(3);
  @$pb.TagNumber(4)
  void clearMetrics() => $_clearField(4);
  @$pb.TagNumber(4)
  CardiacMetrics ensureMetrics() => $_ensure(3);

  @$pb.TagNumber(5)
  $fixnum.Int64 get totalSamplesProcessed => $_getI64(4);
  @$pb.TagNumber(5)
  set totalSamplesProcessed($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTotalSamplesProcessed() => $_has(4);
  @$pb.TagNumber(5)
  void clearTotalSamplesProcessed() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get targetSimBpm => $_getIZ(5);
  @$pb.TagNumber(6)
  set targetSimBpm($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasTargetSimBpm() => $_has(5);
  @$pb.TagNumber(6)
  void clearTargetSimBpm() => $_clearField(6);
}

class ConfigureSourceRequest extends $pb.GeneratedMessage {
  factory ConfigureSourceRequest({
    SourceMode? sourceMode,
    $core.int? targetSimBpm,
    $core.bool? resetDsp,
  }) {
    final result = ConfigureSourceRequest._();
    if (sourceMode != null) result.sourceMode = sourceMode;
    if (targetSimBpm != null) result.targetSimBpm = targetSimBpm;
    if (resetDsp != null) result.resetDsp = resetDsp;
    return result;
  }

  ConfigureSourceRequest._();

  factory ConfigureSourceRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConfigureSourceRequest()..mergeFromBuffer(data, registry);
  factory ConfigureSourceRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConfigureSourceRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ConfigureSourceRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'telemetry.v1'),
      createEmptyInstance: ConfigureSourceRequest.$_createMessage)
    ..aE<SourceMode>(1, _omitFieldNames ? '' : 'sourceMode',
        enumValues: SourceMode.values)
    ..aI(2, _omitFieldNames ? '' : 'targetSimBpm',
        fieldType: $pb.PbFieldType.OU3)
    ..aOB(3, _omitFieldNames ? '' : 'resetDsp')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConfigureSourceRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConfigureSourceRequest copyWith(
          void Function(ConfigureSourceRequest) updates) =>
      super.copyWith((message) => updates(message as ConfigureSourceRequest))
          as ConfigureSourceRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ConfigureSourceRequest() / ConfigureSourceRequest.new instead')
  static ConfigureSourceRequest create() => ConfigureSourceRequest._();
  static $pb.GeneratedMessage $_createMessage() => ConfigureSourceRequest._();
  @$core.override
  ConfigureSourceRequest createEmptyInstance() => ConfigureSourceRequest._();
  @$core.pragma('dart2js:noInline')
  static ConfigureSourceRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ConfigureSourceRequest>(
          ConfigureSourceRequest.$_createMessage);
  static ConfigureSourceRequest? _defaultInstance;

  @$pb.TagNumber(1)
  SourceMode get sourceMode => $_getN(0);
  @$pb.TagNumber(1)
  set sourceMode(SourceMode value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSourceMode() => $_has(0);
  @$pb.TagNumber(1)
  void clearSourceMode() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get targetSimBpm => $_getIZ(1);
  @$pb.TagNumber(2)
  set targetSimBpm($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTargetSimBpm() => $_has(1);
  @$pb.TagNumber(2)
  void clearTargetSimBpm() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get resetDsp => $_getBF(2);
  @$pb.TagNumber(3)
  set resetDsp($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasResetDsp() => $_has(2);
  @$pb.TagNumber(3)
  void clearResetDsp() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
