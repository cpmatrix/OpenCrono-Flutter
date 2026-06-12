import '../models/inceptium_connection_status.dart';

enum InceptiumEventType {
  info,
  statusChanged,
  commandSent,
  responseReceived,
  sessionOpened,
  sessionCleared,
  error,
}

class InceptiumEvent {
  InceptiumEvent({
    required this.type,
    required this.message,
    this.status,
    this.command,
    this.response,
    this.error,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final InceptiumEventType type;
  final String message;
  final InceptiumConnectionStatus? status;
  final String? command;
  final String? response;
  final Object? error;
  final DateTime timestamp;
}
