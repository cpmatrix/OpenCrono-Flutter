class InceptiumConfig {
  const InceptiumConfig({
    required this.serverIP,
    required this.serverPort,
    required this.reverseProxyPath,
    required this.sslMode,
    required this.inceptiumId,
  });

  const InceptiumConfig.myshelter()
      : serverIP = 'myshelter.inceptium.it',
        serverPort = '443',
        reverseProxyPath = 'inapi/',
        sslMode = true,
        inceptiumId = 'myshelter';

  final String serverIP;
  final String serverPort;
  final String reverseProxyPath;
  final bool sslMode;
  final String inceptiumId;

  String get protocol => sslMode ? 'https' : 'http';

  String get normalizedReverseProxyPath =>
      reverseProxyPath.endsWith('/') ? reverseProxyPath : '$reverseProxyPath/';

  String get baseUrl =>
      '$protocol://$serverIP:$serverPort/$normalizedReverseProxyPath';
}
