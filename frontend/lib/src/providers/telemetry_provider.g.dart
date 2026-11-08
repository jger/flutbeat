// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'telemetry_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Telemetry)
final telemetryProvider = TelemetryProvider._();

final class TelemetryProvider
    extends $NotifierProvider<Telemetry, TelemetryState> {
  TelemetryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'telemetryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$telemetryHash();

  @$internal
  @override
  Telemetry create() => Telemetry();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TelemetryState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TelemetryState>(value),
    );
  }
}

String _$telemetryHash() => r'846f19472ed1252447a283e786cacebffeec0ffd';

abstract class _$Telemetry extends $Notifier<TelemetryState> {
  TelemetryState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TelemetryState, TelemetryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TelemetryState, TelemetryState>,
              TelemetryState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
