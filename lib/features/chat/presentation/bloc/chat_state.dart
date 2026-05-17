// lib/features/chat/presentation/bloc/chat_state.dart

import 'package:equatable/equatable.dart';

import '../../domain/entities/chat_message.dart';

class ChatState extends Equatable {
  const ChatState({
    required this.status,
    this.messages = const <ChatMessage>[],
    this.errorMessage,
    this.isSending = false,
  });

  const ChatState.initial()
      : status = ChatStatus.loading,
        messages = const <ChatMessage>[],
        errorMessage = null,
        isSending = false;

  final ChatStatus status;
  final List<ChatMessage> messages;
  final String? errorMessage;
  final bool isSending;

  ChatState copyWith({
    ChatStatus? status,
    List<ChatMessage>? messages,
    String? errorMessage,
    bool? isSending,
  }) {
    return ChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      errorMessage: errorMessage ?? this.errorMessage,
      isSending: isSending ?? this.isSending,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        messages,
        errorMessage,
        isSending,
      ];
}

enum ChatStatus { loading, loaded, error }
