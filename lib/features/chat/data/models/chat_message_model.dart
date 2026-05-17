// lib/features/chat/data/models/chat_message_model.dart
//
// SCALING DECISION — FIRESTORE CHAT STRUCTURE:
// We store messages in /events/dragon_raid/chat/messages/{messageId}
// Rather than a root /messages collection, scoping to the raid event
// allows Firestore security rules to be event-scoped, and allows
// TTL deletion (Cloud Functions) to clean up old event chats cheaply.
//
// Each document contains only essential fields — no nested arrays —
// because Firestore charges per document read, not per field.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/chat_message.dart';

/// DTO that handles serialization/deserialization between Firestore and domain.
/// The domain entity [ChatMessage] has no knowledge of Firestore types.
class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.message,
    required this.timestamp,
  });

  factory ChatMessageModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    final Timestamp? ts = data['timestamp'] as Timestamp?;

    return ChatMessageModel(
      id: doc.id,
      userId: (data['userId'] as String?) ?? '',
      displayName: (data['displayName'] as String?) ?? 'Adventurer',
      message: (data['message'] as String?) ?? '',
      timestamp: ts?.toDate() ?? DateTime.now(),
    );
  }

  final String id;
  final String userId;
  final String displayName;
  final String message;
  final DateTime timestamp;

  Map<String, dynamic> toFirestore() => <String, dynamic>{
        'userId': userId,
        'displayName': displayName,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      };

  ChatMessage toDomain() => ChatMessage(
        id: id,
        userId: userId,
        displayName: displayName,
        message: message,
        timestamp: timestamp,
      );
}
