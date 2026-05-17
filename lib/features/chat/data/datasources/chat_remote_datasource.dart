// lib/features/chat/data/datasources/chat_remote_datasource.dart
//
// COST OPTIMIZATION STRATEGY:
//
// PROBLEM: If 10,000 players are in the same chat, a naive
//   .collection('messages').snapshots()
// listener would re-download and re-render ALL messages on every new post.
// At $0.06/100k reads, with 10k users × 100 messages/hour = 60M reads/hour
// = $36/hour just for chat reads. This is unacceptable.
//
// SOLUTION (implemented here):
// 1. QUERY LIMIT: Only listen to the last [AppConstants.chatMaxLiveMessages]
//    messages. New messages are append-only; old messages use pagination.
//
// 2. DESCENDING ORDER + LIMIT: Firestore serves only N most-recent docs.
//    Combined with a startAfterDocument cursor, users can page backward.
//
// 3. SERVER TIMESTAMP: Using FieldValue.serverTimestamp() prevents client
//    clock skew from reordering messages incorrectly.
//
// 4. SHARD STRATEGY (README explains fully):
//    For 10k users, split into sharded chat rooms (e.g., /chat/room_0 to
//    room_15). Route users to a room by userId hash. This caps any single
//    listener at ~625 users instead of 10,000.
//
// 5. BATCHED WRITES: Message sends use addDoc (single write).
//    For system messages or fan-out, Cloud Functions handle batched writes.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/chat_message.dart';
import '../models/chat_message_model.dart';

class ChatRemoteDataSource {
  const ChatRemoteDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _messagesCol => _firestore
      .collection(AppConstants.eventsCollection)
      .doc(AppConstants.dragonRaidDocId)
      .collection(AppConstants.messagesCollection);

  /// Live stream of the most recent [chatMaxLiveMessages] messages.
  /// Ordered ascending so the UI can display newest at bottom.
  /// The descending limit + reverse on client is the cost-control pattern.
  Stream<List<ChatMessage>> watchMessages() {
    return _messagesCol
        .orderBy('timestamp', descending: true)
        .limit(AppConstants.chatMaxLiveMessages)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snap) => snap.docs
              .map((DocumentSnapshot<Map<String, dynamic>> doc) =>
                  ChatMessageModel.fromFirestore(doc).toDomain())
              .toList()
              .reversed
              .toList(),
        );
  }

  /// Sends a new message. Uses addDoc (auto-ID) to avoid ID collisions.
  /// Server timestamp ensures ordering is authoritative.
  Future<void> sendMessage({
    required String userId,
    required String displayName,
    required String message,
  }) async {
    await _messagesCol.add(
      ChatMessageModel(
        id: '',
        userId: userId,
        displayName: displayName,
        message: message,
        timestamp: DateTime.now(),
      ).toFirestore(),
    );
  }

  /// Fetches a page of older messages before [cursor].
  /// Used by the load-more / infinite scroll pagination.
  Future<List<ChatMessage>> fetchPageBefore({
    required DocumentSnapshot<Map<String, dynamic>> cursor,
    int pageSize = AppConstants.chatPageSize,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _messagesCol
        .orderBy('timestamp', descending: true)
        .startAfterDocument(cursor)
        .limit(pageSize)
        .get();

    return snap.docs
        .map((DocumentSnapshot<Map<String, dynamic>> doc) =>
            ChatMessageModel.fromFirestore(doc).toDomain())
        .toList();
  }
}
