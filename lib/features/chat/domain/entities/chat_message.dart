// lib/features/chat/domain/entities/chat_message.dart

import 'package:equatable/equatable.dart';

/// Domain entity for a single chat message.
/// Pure Dart — no Firebase types leak into this layer.
class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.message,
    required this.timestamp,
  });

  final String id;
  final String userId;
  final String displayName;
  final String message;
  final DateTime timestamp;

  @override
  List<Object?> get props => <Object?>[id, userId, message, timestamp];
}
