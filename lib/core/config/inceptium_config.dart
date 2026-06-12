class InceptiumConfig {
  static const String serverIP = 'myshelter.inceptium.it';
  static const String serverPort = '443';
  static const String reverseProxyPath = 'inapi/';
  static const bool sslMode = true;
  static const String inceptiumID = 'myshelter';

  static const String getNewInceptiumSessionCommand =
      'get_new_inceptium_session?';

  static String get protocol => sslMode ? 'https' : 'http';

  static String get normalizedReverseProxyPath =>
      reverseProxyPath.endsWith('/') ? reverseProxyPath : '$reverseProxyPath/';

  static String get baseUrl =>
      '$protocol://$serverIP:$serverPort/$normalizedReverseProxyPath';
}
