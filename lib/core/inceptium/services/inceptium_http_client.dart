import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../events/inceptium_event.dart';
import '../models/inceptium_config.dart';
import '../models/inceptium_connection_status.dart';
import '../models/inceptium_credentials.dart';

class InceptiumHttpClient {
  InceptiumHttpClient({
    required this.config,
    required this.credentials,
    http.Client? httpClient,
    Duration timeout = const Duration(seconds: 15),
  })  : _httpClient = httpClient ?? http.Client(),
        _timeout = timeout;

  final http.Client _httpClient;
  final Duration _timeout;
  final StreamController<InceptiumEvent> _eventsController =
      StreamController<InceptiumEvent>.broadcast();

  InceptiumConfig config;
  InceptiumCredentials credentials;
  String? currentWebSession;
  InceptiumConnectionStatus currentStatus =
      InceptiumConnectionStatus.notConnected;

  Stream<InceptiumEvent> get events => _eventsController.stream;

  static const String _getNewSessionCommand = 'get_new_inceptium_session?';
  static const String _waitTaskCommand = 'get_task_status?taskid=';
  static const String _loadAppCommand = 'load_app?classapp=';
  static const String _executeMethodCommand =
      'callappcommand?command=executemethod::';

  Future<bool> getNewWebSession() async {
    _log('Apertura sessione');

    if (!credentials.isValid) {
      _setStatus(
        InceptiumConnectionStatus.unauthorized,
        'Credenziali mancanti o non valide',
      );
      _logError('Credenziali mancanti o non valide');
      return false;
    }

    final payload =
        'inceptiumid=${credentials.inceptiumId}::user=${credentials.username}::password=${credentials.password}';
    final maskedPayload =
        'inceptiumid=${credentials.inceptiumId}::user=${credentials.username}::password=******';
    final encodedPayload = Uri.encodeQueryComponent(payload);
    final url = '${config.baseUrl}$_getNewSessionCommand$encodedPayload';

    _log('Server: ${config.serverIP}');
    _log('Porta: ${config.serverPort}');
    _log('SSL: ${config.sslMode}');
    _log('ReverseProxy: ${config.reverseProxyPath}');
    _log('Invio comando: $_getNewSessionCommand');
    _log('URL: ${config.baseUrl}$_getNewSessionCommand');
    _log('Payload: $maskedPayload');

    try {
      final response = await _httpClient.get(Uri.parse(url)).timeout(_timeout);
      _log('HTTP Status: ${response.statusCode}');
      _log('Risposta: ${response.body}');

      if (response.statusCode == HttpStatus.unauthorized ||
          response.statusCode == HttpStatus.forbidden) {
        currentWebSession = null;
        _setStatus(InceptiumConnectionStatus.unauthorized,
            'Credenziali non autorizzate');
        return false;
      }

      if (response.statusCode != HttpStatus.ok) {
        currentWebSession = null;
        _setStatus(
          InceptiumConnectionStatus.connectionError,
          'HTTP status non valido: ${response.statusCode}',
        );
        return false;
      }

      final sessionId = _extractWebSession(response.body);
      if (sessionId == null) {
        currentWebSession = null;
        _setStatus(
          InceptiumConnectionStatus.connectionError,
          'wsession non trovata nella risposta',
        );
        return false;
      }

      currentWebSession = sessionId;
      _setStatus(InceptiumConnectionStatus.connected, 'Sessione attiva');
      _emit(
        InceptiumEvent(
          type: InceptiumEventType.sessionOpened,
          message: 'Sessione ottenuta',
          status: currentStatus,
          response: sessionId,
        ),
      );
      _log('Sessione ottenuta: $sessionId');
      return true;
    } on SocketException catch (error) {
      currentWebSession = null;
      _setStatus(InceptiumConnectionStatus.connectionError, 'SocketException');
      _logError('SocketException: $error', error: error);
      return false;
    } on TimeoutException catch (error) {
      currentWebSession = null;
      _setStatus(InceptiumConnectionStatus.sessionTimeout,
          'Timeout apertura sessione');
      _logError('TimeoutException: $error', error: error);
      return false;
    } on HttpException catch (error) {
      currentWebSession = null;
      _setStatus(InceptiumConnectionStatus.connectionError, 'HttpException');
      _logError('HttpException: $error', error: error);
      return false;
    } on Exception catch (error) {
      currentWebSession = null;
      _setStatus(InceptiumConnectionStatus.connectionError,
          'Errore generico apertura sessione');
      _logError('Exception: $error', error: error);
      return false;
    }
  }

  Future<String> sendCommand(String command, {Duration? timeout}) async {
    final normalizedCommand = command.trim();
    if (normalizedCommand.isEmpty) {
      _setStatus(InceptiumConnectionStatus.connectionError, 'Comando vuoto');
      throw const FormatException('Command non puo essere vuoto');
    }

    if (currentWebSession == null) {
      _log('Sessione assente, apertura automatica');
      final opened = await getNewWebSession();
      if (!opened || currentWebSession == null) {
        throw const HttpException('Impossibile aprire una sessione valida');
      }
    }

    final commandWithSuffix = normalizedCommand.endsWith('::')
        ? normalizedCommand
        : '$normalizedCommand::';
    final credentialsSegment = _buildCredentialsSegment();
    final sessionSegment = 'session=${currentWebSession!}';
    final commandWithAuth =
        '$commandWithSuffix$credentialsSegment::$sessionSegment';
    final commandUrl = '${config.baseUrl}$commandWithAuth';
    final maskedUrl = _maskPasswordInMessage(commandUrl);

    _emit(
      InceptiumEvent(
        type: InceptiumEventType.commandSent,
        message: 'Invio comando',
        status: currentStatus,
        command: _maskPasswordInMessage(commandWithAuth),
      ),
    );
    _log('Invio comando: $commandWithSuffix');
    _log('URL finale: $maskedUrl');

    try {
      final response = await _httpClient
          .get(Uri.parse(commandUrl))
          .timeout(timeout ?? _timeout);
      _log('HTTP Status: ${response.statusCode}');
      if (response.body.length > 500) {
        _log('Risposta lunga ricevuta: ${response.body.length} caratteri');
      } else {
        _log('Risposta: ${response.body}');
      }

      if (response.statusCode == HttpStatus.unauthorized ||
          response.statusCode == HttpStatus.forbidden) {
        _setStatus(
            InceptiumConnectionStatus.unauthorized, 'Accesso non autorizzato');
        throw const HttpException('Richiesta non autorizzata');
      }

      if (response.statusCode != HttpStatus.ok) {
        _setStatus(
          InceptiumConnectionStatus.connectionError,
          'HTTP status non valido: ${response.statusCode}',
        );
        throw HttpException('HTTP status non valido: ${response.statusCode}');
      }

      if (_containsSessionTimeout(response.body)) {
        currentWebSession = null;
        _setStatus(
            InceptiumConnectionStatus.sessionTimeout, 'Sessione scaduta');
        throw TimeoutException('Sessione scaduta');
      }

      _setStatus(InceptiumConnectionStatus.connected, 'Comando completato');
      _emit(
        InceptiumEvent(
          type: InceptiumEventType.responseReceived,
          message: 'Risposta ricevuta',
          status: currentStatus,
          command: _maskPasswordInMessage(commandWithAuth),
          response: response.body,
        ),
      );
      return response.body;
    } on SocketException catch (error) {
      _setStatus(InceptiumConnectionStatus.connectionError, 'SocketException');
      _logError('SocketException: $error', error: error);
      rethrow;
    } on TimeoutException catch (error) {
      _setStatus(InceptiumConnectionStatus.sessionTimeout, 'Timeout richiesta');
      _logError('TimeoutException: $error', error: error);
      rethrow;
    } on HttpException catch (error) {
      _logError('HttpException: $error', error: error);
      rethrow;
    } on Exception catch (error) {
      _setStatus(InceptiumConnectionStatus.connectionError,
          'Errore generico invio comando');
      _logError('Exception: $error', error: error);
      rethrow;
    }
  }

  Future<String> executeCommand(String method, {Duration? timeout}) async {
    _log('Esecuzione metodo: $method');
    return sendCommand(method, timeout: timeout);
  }

  Future<String> executeMethod(
    String className,
    String methodName,
    String params,
  ) async {
    final command =
        '${_executeMethodCommand}class=${className.trim()}::method=${methodName.trim()}::$params::';

    _log('executeMethod params plain: $params');
    _log('executeMethod command finale: $command');

    return executeCommand(command);
  }

  Future<void> waitTask(String task, {int timeoutMs = 15000}) async {
    final encodedTask = Uri.encodeQueryComponent(task.trim());
    final waitTaskCommand = '$_waitTaskCommand$encodedTask::';

    _log('Attesa task remoto: $task');
    await executeCommand(
      waitTaskCommand,
      timeout: Duration(milliseconds: timeoutMs),
    );
  }

  Future<String> loadInceptiumApp(String appClassName) async {
    final encodedAppClass = Uri.encodeQueryComponent(appClassName.trim());
    final loadCommand = '$_loadAppCommand$encodedAppClass::';

    _log('Caricamento app Inceptium: $appClassName');
    final response = await executeCommand(loadCommand);
    if (response.trim().isEmpty) {
      _setStatus(InceptiumConnectionStatus.appNotLoaded, 'App non caricata');
      throw StateError('App Inceptium non caricata');
    }

    final task = _extractTaskFromResponse(response);
    if (task == null) {
      _setStatus(
        InceptiumConnectionStatus.appNotLoaded,
        'Task non trovato durante il caricamento app',
      );
      throw StateError('Task non trovato durante il caricamento app');
    }

    _log('Task app ottenuto: $task');
    return task;
  }

  Future<void> loadAppAsync(String appClassName) async {
    final task = await loadInceptiumApp(appClassName);
    await waitTask(task);
  }

  Future<void> clearSession() async {
    currentWebSession = null;
    _setStatus(InceptiumConnectionStatus.notConnected, 'Sessione cancellata');
    _emit(
      InceptiumEvent(
        type: InceptiumEventType.sessionCleared,
        message: 'Sessione cancellata',
        status: currentStatus,
      ),
    );
    _log('Sessione cancellata');
  }

  Future<bool> isConnected() async {
    return currentStatus == InceptiumConnectionStatus.connected &&
        currentWebSession != null;
  }

  Future<void> disconnect() async {
    await clearSession();
    _httpClient.close();
    _log('Disconnessione completata');
  }

  void dispose() {
    _httpClient.close();
    _eventsController.close();
  }

  String? _extractWebSession(String body) {
    const marker = 'wsession=';
    final markerIndex = body.indexOf(marker);
    if (markerIndex == -1) {
      return null;
    }

    final afterMarker = body.substring(markerIndex + marker.length).trim();
    if (afterMarker.isEmpty) {
      return null;
    }

    final session = afterMarker.split(RegExp(r'[&\\s]')).first.trim();
    return session.isEmpty ? null : session;
  }

  String _buildCredentialsSegment() {
    final encodedUser = Uri.encodeQueryComponent(credentials.username);
    final encodedPassword = Uri.encodeQueryComponent(credentials.password);

    return 'inceptiumid=${credentials.inceptiumId}::user=$encodedUser::password=$encodedPassword';
  }

  bool _containsSessionTimeout(String body) {
    final lowerBody = body.toLowerCase();
    return lowerBody.contains('session timeout') ||
        lowerBody.contains('wsession expired') ||
        lowerBody.contains('invalid wsession');
  }

  String? _extractTaskFromResponse(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    const taskMarker = 'task=';
    final markerIndex = trimmed.toLowerCase().indexOf(taskMarker);
    if (markerIndex != -1) {
      final afterMarker = trimmed.substring(markerIndex + taskMarker.length);
      final extracted = afterMarker.split(RegExp(r'[&\\s]')).first.trim();
      if (extracted.isNotEmpty) {
        return extracted;
      }
    }

    return trimmed;
  }

  String _maskPasswordInMessage(String text) {
    final passwordPattern = RegExp(r'password=[^:]*');
    return text.replaceAllMapped(passwordPattern, (_) => 'password=******');
  }

  void _setStatus(InceptiumConnectionStatus status, String reason) {
    currentStatus = status;
    _emit(
      InceptiumEvent(
        type: InceptiumEventType.statusChanged,
        message: reason,
        status: status,
      ),
    );
    _log('Stato aggiornato: $status ($reason)');
  }

  void _log(String message) {
    debugPrint('[INCEPTIUM] $message');
  }

  void _logError(String message, {Object? error}) {
    debugPrint('[INCEPTIUM][ERROR] $message');
    _emit(
      InceptiumEvent(
        type: InceptiumEventType.error,
        message: message,
        status: currentStatus,
        error: error,
      ),
    );
  }

  void _emit(InceptiumEvent event) {
    if (!_eventsController.isClosed) {
      _eventsController.add(event);
    }
  }
}
