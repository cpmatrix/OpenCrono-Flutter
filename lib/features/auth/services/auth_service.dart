import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/inceptium/models/inceptium_config.dart';
import '../../../core/inceptium/models/inceptium_credentials.dart';
import '../../../core/inceptium/services/inceptium_http_client.dart';

class AuthService {
  AuthService({InceptiumHttpClient? inceptiumHttpClient})
      : _inceptiumHttpClient = inceptiumHttpClient ??
            InceptiumHttpClient(
              config: const InceptiumConfig.myshelter(),
              credentials: const InceptiumCredentials(
                username: '',
                password: '',
                inceptiumId: 'myshelter',
              ),
            );

  static const _usernameKey = 'inceptium_login';
  static const _passwordKey = 'inceptium_password';
  static const _inceptiumIdKey = 'inceptium_id';

  final InceptiumHttpClient _inceptiumHttpClient;

  InceptiumHttpClient get inceptiumClient => _inceptiumHttpClient;

  Future<bool> login(InceptiumCredentials credentials) async {
    debugPrint('[AUTH] Login iniziato');
    debugPrint('[AUTH] Server: ${_inceptiumHttpClient.config.serverIP}');
    debugPrint('[AUTH] Porta: ${_inceptiumHttpClient.config.serverPort}');
    debugPrint('[AUTH] SSL: ${_inceptiumHttpClient.config.sslMode}');
    debugPrint(
      '[AUTH] ReverseProxy: ${_inceptiumHttpClient.config.reverseProxyPath}',
    );
    debugPrint('[AUTH] InceptiumID: ${credentials.inceptiumId}');
    debugPrint('[AUTH] User: ${credentials.username}');
    debugPrint('[AUTH] Password: ******');

    if (!credentials.isValid) {
      debugPrint('[AUTH][ERROR] Credenziali non valide o incomplete');
      return false;
    }

    _inceptiumHttpClient.credentials = credentials;
    final openedSession = await _inceptiumHttpClient.getNewWebSession();

    if (!openedSession) {
      return false;
    }

    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setString(_usernameKey, credentials.username.trim()),
      preferences.setString(_passwordKey, credentials.password),
      preferences.setString(_inceptiumIdKey, credentials.inceptiumId.trim()),
    ]);

    return true;
  }

  Future<InceptiumCredentials> loadSavedCredentials() async {
    final preferences = await SharedPreferences.getInstance();
    final defaultConfig = _inceptiumHttpClient.config;

    return InceptiumCredentials(
      username: preferences.getString(_usernameKey) ?? '',
      password: preferences.getString(_passwordKey) ?? '',
      inceptiumId:
          preferences.getString(_inceptiumIdKey) ?? defaultConfig.inceptiumId,
    );
  }
}
