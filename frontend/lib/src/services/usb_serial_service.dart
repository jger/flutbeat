import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:usb_serial/usb_serial.dart';

/// Parsed sample frame from the ESP microcontroller
class RawEcgFrame {
  const RawEcgFrame({
    required this.rawAdc,
    required this.loPlus,
    required this.loMinus,
    required this.timestampMs,
  });

  final int rawAdc;
  final bool loPlus;
  final bool loMinus;
  final int timestampMs;
}

/// Service managing USB Serial OTG communication with the ESP
class UsbSerialService {
  UsbPort? _port;
  StreamSubscription<Uint8List>? _streamSub;
  StreamSubscription<UsbEvent>? _usbEventSub;

  final StreamController<RawEcgFrame> _frameController =
      StreamController<RawEcgFrame>.broadcast();
  final StreamController<String> _statusController =
      StreamController<String>.broadcast();

  Stream<RawEcgFrame> get frameStream => _frameController.stream;
  Stream<String> get statusStream => _statusController.stream;

  bool get isConnected => _port != null;

  String _lineBuffer = '';

  /// Discovers all connected USB devices
  Future<List<UsbDevice>> getAvailableDevices() async {
    try {
      return await UsbSerial.listDevices();
    } catch (e) {
      debugPrint('[USB_SERIAL] Error listing devices: $e');
      return [];
    }
  }

  /// Starts listening to OS USB attachment / detachment broadcast events
  void listenToUsbEvents({
    required void Function(UsbDevice? device) onAttached,
    required void Function(UsbDevice? device) onDetached,
  }) {
    _usbEventSub?.cancel();
    try {
      _usbEventSub = UsbSerial.usbEventStream?.listen((UsbEvent event) {
        if (event.event == UsbEvent.ACTION_USB_ATTACHED) {
          debugPrint('[USB_SERIAL] Device attached: ${event.device}');
          onAttached(event.device);
        } else if (event.event == UsbEvent.ACTION_USB_DETACHED) {
          debugPrint('[USB_SERIAL] Device detached: ${event.device}');
          onDetached(event.device);
        }
      });
    } catch (e) {
      debugPrint('[USB_SERIAL] USB events unsupported on this platform: $e');
    }
  }

  /// Connects to a USB Serial device at the specified baud rate
  Future<bool> connect({
    UsbDevice? device,
    int baudRate = 115200,
  }) async {
    await disconnect();

    try {
      UsbDevice? targetDevice = device;
      if (targetDevice == null) {
        final devices = await getAvailableDevices();
        if (devices.isEmpty) {
          _statusController.add('No USB devices found. Connect ESP via OTG.');
          return false;
        }
        targetDevice = devices.first;
      }

      _statusController.add('Connecting to ${targetDevice.productName ?? targetDevice.deviceName}...');

      final port = await targetDevice.create();
      if (port == null) {
        _statusController.add('Failed to create USB port. Check OTG permissions.');
        return false;
      }

      final opened = await port.open();
      if (!opened) {
        _statusController.add('Failed to open USB Serial port.');
        return false;
      }

      await port.setDTR(true);
      await port.setRTS(true);
      await port.setPortParameters(
        baudRate,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );

      _port = port;
      _lineBuffer = '';

      _streamSub = port.inputStream?.listen(
        _handleRawBytes,
        onError: (err) {
          _statusController.add('USB stream error: $err');
          disconnect();
        },
        onDone: () {
          _statusController.add('USB device disconnected.');
          disconnect();
        },
        cancelOnError: true,
      );

      _statusController.add('Connected @ $baudRate baud: ${targetDevice.productName ?? "ESP Device"}');
      return true;
    } catch (e) {
      _statusController.add('USB connection error: $e');
      await disconnect();
      return false;
    }
  }

  void _handleRawBytes(Uint8List chunk) {
    try {
      final text = ascii.decode(chunk, allowInvalid: true);
      _lineBuffer += text;

      // Process complete lines
      while (_lineBuffer.contains('\n')) {
        final newlineIndex = _lineBuffer.indexOf('\n');
        final line = _lineBuffer.substring(0, newlineIndex).trim();
        _lineBuffer = _lineBuffer.substring(newlineIndex + 1);

        if (line.isNotEmpty) {
          _parseLine(line);
        }
      }

      // Avoid runaway buffer if no newlines are received
      if (_lineBuffer.length > 512) {
        _lineBuffer = _lineBuffer.substring(_lineBuffer.length - 128);
      }
    } catch (e) {
      debugPrint('[USB_SERIAL] Line decode error: $e');
    }
  }

  void _parseLine(String line) {
    // Format: "adcVal,loP,loN" e.g. "512,0,0" or "1023,1023,1023"
    try {
      final parts = line.split(',');
      if (parts.isNotEmpty) {
        final adc = int.tryParse(parts[0].trim());
        if (adc != null && adc >= 0 && adc <= 1023) {
          final loP = parts.length > 1 && (parts[1].trim() != '0');
          final loN = parts.length > 2 && (parts[2].trim() != '0');

          _frameController.add(
            RawEcgFrame(
              rawAdc: adc,
              loPlus: loP,
              loMinus: loN,
              timestampMs: DateTime.now().millisecondsSinceEpoch,
            ),
          );
        }
      }
    } catch (_) {
      // Discard malformed line silently
    }
  }

  /// Closes the active USB connection
  Future<void> disconnect() async {
    await _streamSub?.cancel();
    _streamSub = null;

    if (_port != null) {
      try {
        await _port!.close();
      } catch (_) {}
      _port = null;
    }
  }

  void dispose() {
    _usbEventSub?.cancel();
    disconnect();
    _frameController.close();
    _statusController.close();
  }
}
