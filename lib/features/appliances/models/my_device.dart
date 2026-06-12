class MyDevice {
  const MyDevice({
    required this.deviceName,
    required this.deviceCode,
    required this.localIp,
    required this.serverVersion,
    required this.online,
    required this.raw,
  });

  final String deviceName;
  final String deviceCode;
  final String localIp;
  final String serverVersion;
  final bool online;
  final Map<String, dynamic> raw;

  factory MyDevice.fromJson(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);

    String readString(List<String> keys) {
      for (final key in keys) {
        final value = normalized[key];
        if (value == null) {
          continue;
        }
        final text = value.toString().trim();
        if (text.isNotEmpty) {
          return text;
        }
      }
      return '';
    }

    bool readBool(List<String> keys) {
      for (final key in keys) {
        final value = normalized[key];
        if (value == null) {
          continue;
        }

        if (value is bool) {
          return value;
        }

        if (value is num) {
          return value != 0;
        }

        final rawText = value.toString().trim().toLowerCase();
        if (rawText.isEmpty) {
          continue;
        }

        if (rawText == 'true' ||
            rawText == '1' ||
            rawText == 'yes' ||
            rawText == 'online') {
          return true;
        }

        if (rawText == 'false' ||
            rawText == '0' ||
            rawText == 'no' ||
            rawText == 'offline') {
          return false;
        }
      }

      return false;
    }

    return MyDevice(
      deviceName: readString([
        'deviceName',
        'DeviceName',
        'name',
        'Name',
      ]),
      deviceCode: readString([
        'deviceCode',
        'DeviceCode',
        'code',
        'Code',
      ]),
      localIp: readString([
        'localIp',
        'LocalIp',
        'localIP',
        'ip',
        'IPAddress',
      ]),
      serverVersion: readString([
        'serverVersion',
        'ServerVersion',
        'version',
        'Version',
      ]),
      online: readBool([
        'online',
        'Online',
        'isOnline',
        'connected',
        'Connected',
      ]),
      raw: normalized,
    );
  }
}
