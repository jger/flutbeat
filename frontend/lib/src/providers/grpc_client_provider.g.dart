// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grpc_client_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(grpcChannel)
final grpcChannelProvider = GrpcChannelProvider._();

final class GrpcChannelProvider
    extends $FunctionalProvider<ClientChannel, ClientChannel, ClientChannel>
    with $Provider<ClientChannel> {
  GrpcChannelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'grpcChannelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$grpcChannelHash();

  @$internal
  @override
  $ProviderElement<ClientChannel> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ClientChannel create(Ref ref) {
    return grpcChannel(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClientChannel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClientChannel>(value),
    );
  }
}

String _$grpcChannelHash() => r'92b6b7a976a775bba247c05e5d3c93f54b3e4fd8';

@ProviderFor(telemetryClient)
final telemetryClientProvider = TelemetryClientProvider._();

final class TelemetryClientProvider
    extends
        $FunctionalProvider<
          TelemetryServiceClient,
          TelemetryServiceClient,
          TelemetryServiceClient
        >
    with $Provider<TelemetryServiceClient> {
  TelemetryClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'telemetryClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$telemetryClientHash();

  @$internal
  @override
  $ProviderElement<TelemetryServiceClient> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TelemetryServiceClient create(Ref ref) {
    return telemetryClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TelemetryServiceClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TelemetryServiceClient>(value),
    );
  }
}

String _$telemetryClientHash() => r'2c6c3f55fa763907e8a9ccdd325b616ce16ce948';
