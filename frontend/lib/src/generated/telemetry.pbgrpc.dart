// This is a generated file - do not edit.
//
// Generated from telemetry.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'telemetry.pb.dart' as $0;

export 'telemetry.pb.dart';

/// Service exposed by the FlutBeat ECG hardware / DSP node
@$pb.GrpcServiceName('telemetry.v1.TelemetryService')
class TelemetryServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  TelemetryServiceClient(super.channel, {super.options, super.interceptors});

  /// High-frequency server-streaming RPC: emits batched ECG samples (e.g. 10 samples @ 250 Hz = every 40ms)
  /// along with instantaneous vitals and lead-off status.
  $grpc.ResponseStream<$0.EcgWaveformChunk> streamEcg(
    $0.StreamEcgRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$streamEcg, $async.Stream.fromIterable([request]),
        options: options);
  }

  /// Server-streaming RPC: emits discrete cardiac events (R-peak detected, Lead-Off alarm, rhythm change)
  $grpc.ResponseStream<$0.CardiacEvent> streamCardiacEvents(
    $0.StreamEventsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$streamCardiacEvents, $async.Stream.fromIterable([request]),
        options: options);
  }

  /// Server-streaming RPC: emits operational and DSP diagnostic logs
  $grpc.ResponseStream<$0.LogEntry> streamLogs(
    $0.StreamLogsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$streamLogs, $async.Stream.fromIterable([request]),
        options: options);
  }

  /// Unary RPC: query current system & cardiac status snapshot
  $grpc.ResponseFuture<$0.StatusResponse> getStatus(
    $0.GetStatusRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getStatus, request, options: options);
  }

  /// Unary RPC: switch between Hardware (UDP/Serial) and Synthetic ECG Simulator or adjust target BPM/filter
  $grpc.ResponseFuture<$0.StatusResponse> configureSource(
    $0.ConfigureSourceRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$configureSource, request, options: options);
  }

  // method descriptors

  static final _$streamEcg =
      $grpc.ClientMethod<$0.StreamEcgRequest, $0.EcgWaveformChunk>(
          '/telemetry.v1.TelemetryService/StreamEcg',
          ($0.StreamEcgRequest value) => value.writeToBuffer(),
          $0.EcgWaveformChunk.fromBuffer);
  static final _$streamCardiacEvents =
      $grpc.ClientMethod<$0.StreamEventsRequest, $0.CardiacEvent>(
          '/telemetry.v1.TelemetryService/StreamCardiacEvents',
          ($0.StreamEventsRequest value) => value.writeToBuffer(),
          $0.CardiacEvent.fromBuffer);
  static final _$streamLogs =
      $grpc.ClientMethod<$0.StreamLogsRequest, $0.LogEntry>(
          '/telemetry.v1.TelemetryService/StreamLogs',
          ($0.StreamLogsRequest value) => value.writeToBuffer(),
          $0.LogEntry.fromBuffer);
  static final _$getStatus =
      $grpc.ClientMethod<$0.GetStatusRequest, $0.StatusResponse>(
          '/telemetry.v1.TelemetryService/GetStatus',
          ($0.GetStatusRequest value) => value.writeToBuffer(),
          $0.StatusResponse.fromBuffer);
  static final _$configureSource =
      $grpc.ClientMethod<$0.ConfigureSourceRequest, $0.StatusResponse>(
          '/telemetry.v1.TelemetryService/ConfigureSource',
          ($0.ConfigureSourceRequest value) => value.writeToBuffer(),
          $0.StatusResponse.fromBuffer);
}

@$pb.GrpcServiceName('telemetry.v1.TelemetryService')
abstract class TelemetryServiceBase extends $grpc.Service {
  $core.String get $name => 'telemetry.v1.TelemetryService';

  TelemetryServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.StreamEcgRequest, $0.EcgWaveformChunk>(
        'StreamEcg',
        streamEcg_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.StreamEcgRequest.fromBuffer(value),
        ($0.EcgWaveformChunk value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.StreamEventsRequest, $0.CardiacEvent>(
        'StreamCardiacEvents',
        streamCardiacEvents_Pre,
        false,
        true,
        ($core.List<$core.int> value) =>
            $0.StreamEventsRequest.fromBuffer(value),
        ($0.CardiacEvent value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.StreamLogsRequest, $0.LogEntry>(
        'StreamLogs',
        streamLogs_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.StreamLogsRequest.fromBuffer(value),
        ($0.LogEntry value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetStatusRequest, $0.StatusResponse>(
        'GetStatus',
        getStatus_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetStatusRequest.fromBuffer(value),
        ($0.StatusResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ConfigureSourceRequest, $0.StatusResponse>(
            'ConfigureSource',
            configureSource_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ConfigureSourceRequest.fromBuffer(value),
            ($0.StatusResponse value) => value.writeToBuffer()));
  }

  $async.Stream<$0.EcgWaveformChunk> streamEcg_Pre($grpc.ServiceCall $call,
      $async.Future<$0.StreamEcgRequest> $request) async* {
    yield* streamEcg($call, await $request);
  }

  $async.Stream<$0.EcgWaveformChunk> streamEcg(
      $grpc.ServiceCall call, $0.StreamEcgRequest request);

  $async.Stream<$0.CardiacEvent> streamCardiacEvents_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.StreamEventsRequest> $request) async* {
    yield* streamCardiacEvents($call, await $request);
  }

  $async.Stream<$0.CardiacEvent> streamCardiacEvents(
      $grpc.ServiceCall call, $0.StreamEventsRequest request);

  $async.Stream<$0.LogEntry> streamLogs_Pre($grpc.ServiceCall $call,
      $async.Future<$0.StreamLogsRequest> $request) async* {
    yield* streamLogs($call, await $request);
  }

  $async.Stream<$0.LogEntry> streamLogs(
      $grpc.ServiceCall call, $0.StreamLogsRequest request);

  $async.Future<$0.StatusResponse> getStatus_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetStatusRequest> $request) async {
    return getStatus($call, await $request);
  }

  $async.Future<$0.StatusResponse> getStatus(
      $grpc.ServiceCall call, $0.GetStatusRequest request);

  $async.Future<$0.StatusResponse> configureSource_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ConfigureSourceRequest> $request) async {
    return configureSource($call, await $request);
  }

  $async.Future<$0.StatusResponse> configureSource(
      $grpc.ServiceCall call, $0.ConfigureSourceRequest request);
}
