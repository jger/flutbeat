// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sharedPreferences)
final sharedPreferencesProvider = SharedPreferencesProvider._();

final class SharedPreferencesProvider
    extends
        $FunctionalProvider<
          SharedPreferences,
          SharedPreferences,
          SharedPreferences
        >
    with $Provider<SharedPreferences> {
  SharedPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharedPreferencesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharedPreferencesHash();

  @$internal
  @override
  $ProviderElement<SharedPreferences> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SharedPreferences create(Ref ref) {
    return sharedPreferences(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SharedPreferences value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SharedPreferences>(value),
    );
  }
}

String _$sharedPreferencesHash() => r'2778c338c027ade6ee2751071100784ca4fade18';

@ProviderFor(Config)
final configProvider = ConfigProvider._();

final class ConfigProvider extends $NotifierProvider<Config, ConnectionConfig> {
  ConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'configProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$configHash();

  @$internal
  @override
  Config create() => Config();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConnectionConfig value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConnectionConfig>(value),
    );
  }
}

String _$configHash() => r'8a6e1e7b5217eb15227c2cc11cb9da09857feb0a';

abstract class _$Config extends $Notifier<ConnectionConfig> {
  ConnectionConfig build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ConnectionConfig, ConnectionConfig>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ConnectionConfig, ConnectionConfig>,
              ConnectionConfig,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
