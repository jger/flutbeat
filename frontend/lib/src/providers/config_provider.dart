import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cardiac_metrics.dart';
import '../models/connection_config.dart';

part 'config_provider.g.dart';

@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) {
  throw UnimplementedError('SharedPreferences must be initialized in main()');
}

@Riverpod(keepAlive: true)
class Config extends _$Config {
  static const _key = 'connection_config_v2';

  @override
  ConnectionConfig build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return ConnectionConfig.fromJson(decoded);
      } catch (_) {
        return const ConnectionConfig();
      }
    }
    return const ConnectionConfig();
  }

  Future<void> updateConfig({
    int? baudRate,
    String? selectedDeviceName,
    bool clearDeviceName = false,
    SourceMode? sourceMode,
    int? targetSimBpm,
    String? host,
    int? port,
    String? clientId,
    bool? useTls,
  }) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final updated = state.copyWith(
      baudRate: baudRate,
      selectedDeviceName: selectedDeviceName,
      clearDeviceName: clearDeviceName,
      sourceMode: sourceMode,
      targetSimBpm: targetSimBpm,
      host: host,
      port: port,
      clientId: clientId,
      useTls: useTls,
    );
    state = updated;
    await prefs.setString(_key, jsonEncode(updated.toJson()));
  }

  Future<void> resetToDefaults() async {
    final prefs = ref.read(sharedPreferencesProvider);
    const defaults = ConnectionConfig();
    state = defaults;
    await prefs.setString(_key, jsonEncode(defaults.toJson()));
  }
}
