import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:usb_serial/usb_serial.dart';
import '../../models/cardiac_metrics.dart';
import '../../providers/config_provider.dart';
import '../../providers/telemetry_provider.dart';
import '../../services/usb_serial_service.dart';

class ConfigScreen extends ConsumerStatefulWidget {
  const ConfigScreen({super.key});

  @override
  ConsumerState<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends ConsumerState<ConfigScreen> {
  final UsbSerialService _serialService = UsbSerialService();
  List<UsbDevice> _usbDevices = [];
  bool _isScanning = false;
  late int _selectedBaudRate;
  late SourceMode _selectedMode;
  late int _simBpm;

  static const List<int> _supportedBaudRates = [
    115200,
    74880,
    57600,
    38400,
    19200,
    9600,
  ];

  @override
  void initState() {
    super.initState();
    final config = ref.read(configProvider);
    _selectedBaudRate = config.baudRate;
    _selectedMode = config.sourceMode;
    _simBpm = config.targetSimBpm;
    _scanUsbDevices();
  }

  Future<void> _scanUsbDevices() async {
    setState(() => _isScanning = true);
    try {
      final devices = await _serialService.getAvailableDevices();
      if (mounted) {
        setState(() {
          _usbDevices = devices;
          _isScanning = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  void _saveAndConnect() async {
    await ref.read(configProvider.notifier).updateConfig(
          baudRate: _selectedBaudRate,
          sourceMode: _selectedMode,
          targetSimBpm: _simBpm,
        );

    await ref.read(telemetryProvider.notifier).configureSource(
          mode: _selectedMode,
          baudRate: _selectedBaudRate,
          targetSimBpm: _simBpm,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedMode == SourceMode.usbSerial
                ? 'Connecting to USB Serial @ $_selectedBaudRate baud...'
                : 'Switched to Built-in ECG Simulator ($_simBpm BPM)',
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  void _restoreDefaults() async {
    await ref.read(configProvider.notifier).resetToDefaults();
    final config = ref.read(configProvider);
    setState(() {
      _selectedBaudRate = config.baudRate;
      _selectedMode = config.sourceMode;
      _simBpm = config.targetSimBpm;
    });

    ref.read(telemetryProvider.notifier).reconnect();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reset to default settings (115200 baud, USB-OTG)'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // OTG Direct Cable Connection Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2638),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.usb_rounded, color: Color(0xFF38BDF8), size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Direct USB OTG Connection',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Connect your ESP8266 / ESP32 board directly to your mobile device using a USB-C OTG cable. No backend or Wi-Fi required!',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Source Mode Selection
            const Text(
              'TELEMETRY DATA SOURCE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white54,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            SegmentedButton<SourceMode>(
              segments: const [
                ButtonSegment<SourceMode>(
                  value: SourceMode.usbSerial,
                  icon: Icon(Icons.usb_rounded, size: 18),
                  label: Text('ESP USB OTG'),
                ),
                ButtonSegment<SourceMode>(
                  value: SourceMode.simulator,
                  icon: Icon(Icons.tune_rounded, size: 18),
                  label: Text('ECG Simulator'),
                ),
              ],
              selected: {_selectedMode},
              onSelectionChanged: (newSelection) {
                setState(() => _selectedMode = newSelection.first);
              },
            ),
            const SizedBox(height: 24),

            // USB OTG Devices Card
            if (_selectedMode == SourceMode.usbSerial) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'DETECTED USB DEVICES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white54,
                      letterSpacing: 0.8,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _isScanning ? null : _scanUsbDevices,
                    icon: _isScanning
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Scan Ports', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_usbDevices.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141923),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Colors.white38, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isScanning
                              ? 'Scanning for USB OTG devices...'
                              : 'No USB serial devices detected. Connect your ESP board via OTG and tap "Scan Ports".',
                          style: const TextStyle(fontSize: 12, color: Colors.white60),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._usbDevices.map((dev) {
                  final title = dev.productName ?? 'USB Serial Device';
                  final subtitle =
                      'VID: 0x${dev.vid?.toRadixString(16).padLeft(4, '0')} | PID: 0x${dev.pid?.toRadixString(16).padLeft(4, '0')} | Device ID: ${dev.deviceId}';
                  return Card(
                    color: const Color(0xFF141923),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFF00FF88), width: 1.5),
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.developer_board_rounded, color: Color(0xFF00FF88)),
                      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.white54)),
                      trailing: const Icon(Icons.check_circle_rounded, color: Color(0xFF00FF88), size: 20),
                    ),
                  );
                }),
              const SizedBox(height: 20),

              // Baud Rate Selector
              const Text(
                'SERIAL BAUD RATE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white54,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _selectedBaudRate,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.speed_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _supportedBaudRates
                    .map((baud) => DropdownMenuItem(
                          value: baud,
                          child: Text(
                            '$baud baud ${baud == 115200 ? "(Standard USB)" : (baud == 74880 ? "(ESP8266 Bootloader)" : "")}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedBaudRate = val);
                  }
                },
              ),
            ] else ...[
              // Simulator settings
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141923),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Simulated Heart Rate',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          '$_simBpm BPM',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF00FF88),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _simBpm.toDouble(),
                      min: 40,
                      max: 180,
                      divisions: 28,
                      label: '$_simBpm BPM',
                      onChanged: (val) => setState(() => _simBpm = val.round()),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Save & Connect Button
            FilledButton.icon(
              onPressed: _saveAndConnect,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF00FF88),
                foregroundColor: const Color(0xFF090D15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.power_rounded, size: 20),
              label: Text(
                _selectedMode == SourceMode.usbSerial ? 'Connect to ESP OTG' : 'Activate Simulator',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _serialService.dispose();
    super.dispose();
  }
}
