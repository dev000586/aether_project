// lib/features/chat/domain/repositories/chat_repository.dart

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/chat_message.dart';

abstract class ChatRepository {
  Stream<Either<Failure, List<ChatMessage>>> watchMessages();

  Future<Either<Failure, Unit>> sendMessage({
    required String userId,
    required String displayName,
    required String message,
  });
}
