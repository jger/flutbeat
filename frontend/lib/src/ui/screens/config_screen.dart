import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/config_provider.dart';
import '../../providers/telemetry_provider.dart';

class ConfigScreen extends ConsumerStatefulWidget {
  const ConfigScreen({super.key});

  @override
  ConsumerState<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends ConsumerState<ConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _hostController;
  late TextEditingController _portController;
  late TextEditingController _clientIdController;
  late bool _useTls;

  @override
  void initState() {
    super.initState();
    final config = ref.read(configProvider);
    _hostController = TextEditingController(text: config.host);
    _portController = TextEditingController(text: config.port.toString());
    _clientIdController = TextEditingController(text: config.clientId);
    _useTls = config.useTls;
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _clientIdController.dispose();
    super.dispose();
  }

  void _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    final port = int.tryParse(_portController.text.trim()) ?? 50051;
    await ref.read(configProvider.notifier).updateConfig(
          host: _hostController.text.trim(),
          port: port,
          clientId: _clientIdController.text.trim(),
          useTls: _useTls,
        );

    ref.read(telemetryProvider.notifier).reconnect();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuration saved. Reconnecting...'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  void _restoreDefaults() async {
    await ref.read(configProvider.notifier).resetToDefaults();
    final config = ref.read(configProvider);
    _hostController.text = config.host;
    _portController.text = config.port.toString();
    _clientIdController.text = config.clientId;
    setState(() {
      _useTls = config.useTls;
    });

    ref.read(telemetryProvider.notifier).reconnect();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reset to default values (127.0.0.1:50051)'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Connection Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton.icon(
            onPressed: _restoreDefaults,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Defaults'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E28) : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.blue.shade100,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: isDark ? const Color(0xFF38BDF8) : Colors.blue.shade700,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Connects to the FlutBeat ECG gRPC server (`ecg_node.rs`). '
                        'Use `127.0.0.1` for local testing or your workstation / Raspberry Pi LAN IP.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : Colors.blue.shade900,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Host field
              TextFormField(
                controller: _hostController,
                decoration: InputDecoration(
                  labelText: 'Host IP / Hostname',
                  hintText: '127.0.0.1 or 192.168.x.x',
                  prefixIcon: const Icon(Icons.lan_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Host cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),

              // Quick Presets
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.computer_outlined, size: 14),
                    label: const Text('127.0.0.1 (Localhost / ADB)', style: TextStyle(fontSize: 11)),
                    onPressed: () {
                      setState(() => _hostController.text = '127.0.0.1');
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.phone_android_outlined, size: 14),
                    label: const Text('10.0.2.2 (Android Emulator)', style: TextStyle(fontSize: 11)),
                    onPressed: () {
                      setState(() => _hostController.text = '10.0.2.2');
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.wifi_outlined, size: 14),
                    label: const Text('192.168.178.37 (Host LAN)', style: TextStyle(fontSize: 11)),
                    onPressed: () {
                      setState(() => _hostController.text = '192.168.178.37');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Port field
              TextFormField(
                controller: _portController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'gRPC Port',
                  hintText: '50051',
                  prefixIcon: const Icon(Icons.numbers_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Port cannot be empty';
                  }
                  final port = int.tryParse(value.trim());
                  if (port == null || port <= 0 || port > 65535) {
                    return 'Enter a valid port (1 - 65535)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Client ID field
              TextFormField(
                controller: _clientIdController,
                decoration: InputDecoration(
                  labelText: 'Client ID',
                  hintText: 'flutter-dashboard',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Client ID cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // TLS Toggle
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                title: const Text('Use TLS / Secure gRPC'),
                subtitle: const Text('Disabled by default for local Pi node'),
                value: _useTls,
                onChanged: (val) => setState(() => _useTls = val),
              ),
              const SizedBox(height: 32),

              // Save & Reconnect Button
              FilledButton.icon(
                onPressed: _saveConfig,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.save_rounded),
                label: const Text(
                  'Save & Connect',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
