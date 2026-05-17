// lib/features/chat/data/repositories/chat_repository_impl.dart

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  const ChatRepositoryImpl({required ChatRemoteDataSource dataSource})
      : _dataSource = dataSource;

  final ChatRemoteDataSource _dataSource;

  @override
  Stream<Either<Failure, List<ChatMessage>>> watchMessages() {
    return _dataSource.watchMessages().map(
          (List<ChatMessage> messages) =>
              Right<Failure, List<ChatMessage>>(messages),
        ).handleError(
          (Object error) => Left<Failure, List<ChatMessage>>(
            ServerFailure(error.toString()),
          ),
        );
  }

  @override
  Future<Either<Failure, Unit>> sendMessage({
    required String userId,
    required String displayName,
    required String message,
  }) async {
    try {
      await _dataSource.sendMessage(
        userId: userId,
        displayName: displayName,
        message: message,
      );
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      return Left<Failure, Unit>(ServerFailure(e.toString()));
    }
  }
}
