// test/features/chat/chat_cubit_test.dart

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aether_project/core/errors/failures.dart';
import 'package:aether_project/features/chat/domain/entities/chat_message.dart';
import 'package:aether_project/features/chat/domain/repositories/chat_repository.dart';
import 'package:aether_project/features/chat/presentation/bloc/chat_cubit.dart';
import 'package:aether_project/features/chat/presentation/bloc/chat_state.dart';

class MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late MockChatRepository mockRepository;
  late ChatCubit cubit;

  final List<ChatMessage> testMessages = <ChatMessage>[
    ChatMessage(
      id: 'msg_1',
      userId: 'user_1',
      displayName: 'Warrior',
      message: 'Ready to raid!',
      timestamp: DateTime(2024),
    ),
    ChatMessage(
      id: 'msg_2',
      userId: 'user_2',
      displayName: 'Mage',
      message: 'Let\'s go!',
      timestamp: DateTime(2024, 1, 1, 0, 0, 1),
    ),
  ];

  setUp(() {
    mockRepository = MockChatRepository();
    cubit = ChatCubit(chatRepository: mockRepository);
  });

  tearDown(() {
    cubit.close();
  });

  group('ChatCubit', () {
    test('initial state is loading', () {
      expect(cubit.state.status, ChatStatus.loading);
      expect(cubit.state.messages, isEmpty);
    });

    blocTest<ChatCubit, ChatState>(
      'startWatching emits loaded messages',
      build: () {
        when(() => mockRepository.watchMessages()).thenAnswer(
          (_) => Stream<Either<Failure, List<ChatMessage>>>.value(
            Right<Failure, List<ChatMessage>>(testMessages),
          ),
        );
        return cubit;
      },
      act: (ChatCubit cubit) => cubit.startWatching(),
      expect: () => <dynamic>[
        isA<ChatState>()
            .having((ChatState s) => s.status, 'status', ChatStatus.loaded)
            .having(
              (ChatState s) => s.messages.length,
              'messages.length',
              2,
            ),
      ],
    );

    blocTest<ChatCubit, ChatState>(
      'startWatching emits error on stream failure',
      build: () {
        when(() => mockRepository.watchMessages()).thenAnswer(
          (_) => Stream<Either<Failure, List<ChatMessage>>>.value(
            const Left<Failure, List<ChatMessage>>(
              ServerFailure('Stream error'),
            ),
          ),
        );
        return cubit;
      },
      act: (ChatCubit cubit) => cubit.startWatching(),
      expect: () => <dynamic>[
        isA<ChatState>().having(
          (ChatState s) => s.status,
          'status',
          ChatStatus.error,
        ),
      ],
    );

    blocTest<ChatCubit, ChatState>(
      'sendMessage with empty string does nothing',
      build: () => cubit,
      act: (ChatCubit cubit) => cubit.sendMessage(
        userId: 'user_1',
        displayName: 'Warrior',
        message: '   ',
      ),
      expect: () => <dynamic>[],
    );

    blocTest<ChatCubit, ChatState>(
      'sendMessage emits isSending then clears on success',
      build: () {
        when(
          () => mockRepository.sendMessage(
            userId: any(named: 'userId'),
            displayName: any(named: 'displayName'),
            message: any(named: 'message'),
          ),
        ).thenAnswer((_) async => const Right<Failure, Unit>(unit));
        return cubit;
      },
      act: (ChatCubit cubit) => cubit.sendMessage(
        userId: 'user_1',
        displayName: 'Warrior',
        message: 'Hello raid!',
      ),
      expect: () => <dynamic>[
        isA<ChatState>().having(
          (ChatState s) => s.isSending,
          'isSending',
          isTrue,
        ),
        isA<ChatState>().having(
          (ChatState s) => s.isSending,
          'isSending',
          isFalse,
        ),
      ],
    );
  });
}
