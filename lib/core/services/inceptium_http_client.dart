import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/inceptium_config.dart';

class InceptiumHttpClient {
  InceptiumHttpClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<String?> getNewWebSession({
    required String inceptiumId,
    required String login,
    required String password,
  }) async {
    final commandUrl =
        '${InceptiumConfig.baseUrl}${InceptiumConfig.getNewInceptiumSessionCommand}';
    final maskedPayload =
        'inceptiumid=$inceptiumId::user=$login::password=******';

    debugPrint('[AUTH] URL: $commandUrl');
    debugPrint('[AUTH] Payload: $maskedPayload');

    final credentials =
        'inceptiumid=$inceptiumId::user=$login::password=$password';
    final encodedCredentials = Uri.encodeQueryComponent(credentials);
    final requestUrl = '$commandUrl$encodedCredentials';

    try {
      final response = await _httpClient
          .get(Uri.parse(requestUrl))
          .timeout(const Duration(seconds: 15));

      debugPrint('[AUTH] HTTP Status: ${response.statusCode}');
      debugPrint('[AUTH] Response:\n${response.body}');

      if (response.statusCode != 200) {
        debugPrint(
            '[AUTH][ERROR] HTTP status non valido: ${response.statusCode}');
        return null;
      }

      if (response.body.isEmpty) {
        throw const HttpException('Corpo risposta vuoto');
      }

      final sessionId = _extractWebSession(response.body);
      if (sessionId == null) {
        debugPrint('[AUTH][ERROR] wsession non trovata nella risposta');
        return null;
      }

      debugPrint('[AUTH] Session ID: $sessionId');
      return sessionId;
    } on SocketException catch (error) {
      debugPrint('[AUTH][ERROR] SocketException: $error');
      return null;
    } on TimeoutException catch (error) {
      debugPrint('[AUTH][ERROR] TimeoutException: $error');
      return null;
    } on HttpException catch (error) {
      debugPrint('[AUTH][ERROR] HttpException: $error');
      return null;
    } on Exception catch (error) {
      debugPrint('[AUTH][ERROR] Exception: $error');
      return null;
    }
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
}
