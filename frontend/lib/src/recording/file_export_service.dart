import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class FileExportService {
  static const channel = MethodChannel('flutbeat/files');

  Future<File> allocate(String name) async {
    final root = await getTemporaryDirectory();
    final exports = await Directory('${root.path}/exports')
        .create(recursive: true);
    final directory = await exports.createTemp('ecg_');
    final file = File('${directory.path}/$name');
    return file;
  }

  Future<bool> save(File file, String mimeType) async {
    return await channel.invokeMethod<bool>('saveFile', {
          'path': file.path,
          'name': file.uri.pathSegments.last,
          'mimeType': mimeType,
        }) ??
        false;
  }

  Future<void> share(File file, String mimeType, Rect origin) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: mimeType)],
        sharePositionOrigin: origin,
      ),
    );
  }

  static Future<void> setRecordingActive(bool active) async {
    try {
      await channel.invokeMethod<void>('setRecordingActive', active);
    } on MissingPluginException {
      // The Android host supplies this. Unit tests do not have a host activity.
    }
  }
}
