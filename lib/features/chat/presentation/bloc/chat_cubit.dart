// lib/features/chat/presentation/bloc/chat_cubit.dart
//
// Using Cubit here (not Bloc) because chat has a simple event model:
// watch → receive messages → send. There's no complex event-to-event
// orchestration that would justify the extra boilerplate of full Bloc.

import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  ChatCubit({required ChatRepository chatRepository})
      : _chatRepository = chatRepository,
        super(const ChatState.initial());

  final ChatRepository _chatRepository;
  StreamSubscription<Either<Failure, List<ChatMessage>>>? _messagesSubscription;

  void startWatching() {
    _messagesSubscription?.cancel();
    _messagesSubscription =
        _chatRepository.watchMessages().listen(
      (Either<Failure, List<ChatMessage>> result) {
        result.fold(
          (Failure failure) => emit(
            state.copyWith(
              status: ChatStatus.error,
              errorMessage: failure.message,
            ),
          ),
          (List<ChatMessage> messages) => emit(
            state.copyWith(status: ChatStatus.loaded, messages: messages),
          ),
        );
      },
    );
  }

  Future<void> sendMessage({
    required String userId,
    required String displayName,
    required String message,
  }) async {
    if (message.trim().isEmpty) return;

    emit(state.copyWith(isSending: true));

    final Either<Failure, Unit> result = await _chatRepository.sendMessage(
      userId: userId,
      displayName: displayName,
      message: message.trim(),
    );

    result.fold(
      (Failure failure) => emit(
        state.copyWith(
          isSending: false,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(state.copyWith(isSending: false)),
    );
  }

  @override
  Future<void> close() async {
    await _messagesSubscription?.cancel();
    return super.close();
  }
}
