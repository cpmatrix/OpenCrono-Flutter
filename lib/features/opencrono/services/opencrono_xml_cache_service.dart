import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../appliances/models/my_device.dart';

class OpenCronoXmlCacheService {
  const OpenCronoXmlCacheService();

  Future<bool> hasCachedXml(MyDevice device) async {
    final file = await _cacheFile(device);
    return file.exists();
  }

  Future<String?> readCachedXml(MyDevice device) async {
    final file = await _cacheFile(device);
    if (!await file.exists()) {
      return null;
    }
    return file.readAsString();
  }

  Future<void> saveCachedXml(MyDevice device, String xml) async {
    final file = await _cacheFile(device);
    await file.writeAsString(xml, flush: true);
  }

  Future<File> _cacheFile(MyDevice device) async {
    final directory = await getApplicationDocumentsDirectory();
    final identifier = _sanitize(_deviceIdentifier(device));
    final name = 'opencrono_cache_$identifier.xml';
    return File('${directory.path}/$name');
  }

  String _deviceIdentifier(MyDevice device) {
    final softwareCode = device.softwareCode.trim();
    if (softwareCode.isNotEmpty) {
      return softwareCode;
    }

    final serial = device.serialDevice.trim();
    if (serial.isNotEmpty) {
      return serial;
    }

    return device.deviceName.trim().isEmpty ? 'unknown' : device.deviceName;
  }

  String _sanitize(String input) {
    return input.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }
}
