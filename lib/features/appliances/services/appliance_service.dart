import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/inceptium/services/inceptium_http_client.dart';
import '../../../core/inceptium/models/inceptium_credentials.dart';
import '../models/my_device.dart';

class ApplianceService {
  ApplianceService({required InceptiumHttpClient client}) : _client = client;

  static const _usernameKey = 'inceptium_login';
  static const _passwordKey = 'inceptium_password';
  static const _inceptiumIdKey = 'inceptium_id';

  static const _inceptiumAppClass = 'com.incappmyshelter.IncAppMyShelter';
  static const _recordsCommandBase =
      'callappcommand?command=getrecords::class=com.incappmyshelteradmin.data.mydevice.MyDevice::filter.b64=::order.b64=';

  final InceptiumHttpClient _client;

  Future<List<MyDevice>> loadAppliances() async {
    debugPrint('[APPLIANCES] Caricamento iniziato');

    await _hydrateCredentialsFromStorage();

    debugPrint('[APPLIANCES] Sessione corrente: ${_client.currentWebSession}');

    if ((_client.currentWebSession ?? '').isEmpty) {
      final opened = await _client.getNewWebSession();
      if (!opened) {
        throw StateError('Impossibile ottenere una nuova sessione Inceptium');
      }
    }

    debugPrint('[APPLIANCES] Load InceptiumApp...');
    final task = await _client.loadInceptiumApp(_inceptiumAppClass);
    debugPrint('[APPLIANCES] Task: $task');

    await _client.waitTask(task, timeoutMs: 10000);
    debugPrint('[APPLIANCES] WaitTask completato');

    final orderB64 = base64Encode(utf8.encode('Order by deviceName'));
    final command = '$_recordsCommandBase$orderB64::';

    debugPrint('[APPLIANCES] Comando lista appliance: $command');
    final response = await _client.sendCommand(command);

    if (response.trim() == '[]') {
      debugPrint('[APPLIANCES] Numero appliance: 0');
      return const [];
    }

    late final List<MyDevice> devices;
    try {
      final decoded = jsonDecode(response);
      devices = _mapDecodedToDevices(decoded);
    } catch (e) {
      print('[APPLIANCES PARSE ERROR] $e');
      rethrow;
    }

    debugPrint('[APPLIANCES] Numero appliance: ${devices.length}');
    for (final device in devices) {
      final status = device.online ? 'online' : 'offline';
      final localIp = device.localIp.isEmpty ? '-' : device.localIp;
      final softwareCode =
          (device.raw['softwareCode']?.toString().trim().isNotEmpty ?? false)
              ? device.raw['softwareCode'].toString().trim()
              : device.deviceCode;
      debugPrint(
        '[APPLIANCES] Device: ${device.deviceName} | $softwareCode | $status | $localIp',
      );
    }
    return devices;
  }

  Future<void> _hydrateCredentialsFromStorage() async {
    final preferences = await SharedPreferences.getInstance();

    final username = preferences.getString(_usernameKey) ?? '';
    final password = preferences.getString(_passwordKey) ?? '';
    final inceptiumId =
        preferences.getString(_inceptiumIdKey) ?? _client.config.inceptiumId;

    _client.credentials = InceptiumCredentials(
      username: username,
      password: password,
      inceptiumId: inceptiumId,
    );
  }

  List<MyDevice> _mapDecodedToDevices(dynamic decoded) {
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((item) => MyDevice.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false);
    }

    if (decoded is Map<String, dynamic>) {
      final records = decoded['records'];
      if (records is List) {
        return records
            .whereType<Map>()
            .map((item) => MyDevice.fromJson(Map<String, dynamic>.from(item)))
            .toList(growable: false);
      }

      return [MyDevice.fromJson(decoded)];
    }

    throw const FormatException('Formato JSON appliance non riconosciuto');
  }
}
