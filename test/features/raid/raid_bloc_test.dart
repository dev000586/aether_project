// test/features/raid/raid_bloc_test.dart

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aether_project/core/errors/failures.dart';
import 'package:aether_project/features/raid/domain/entities/raid.dart';
import 'package:aether_project/features/raid/domain/repositories/raid_repository.dart';
import 'package:aether_project/features/raid/presentation/bloc/raid_bloc.dart';
import 'package:aether_project/features/raid/presentation/bloc/raid_event.dart';
import 'package:aether_project/features/raid/presentation/bloc/raid_state.dart';

class MockRaidRepository extends Mock implements RaidRepository {}

void main() {
  late MockRaidRepository mockRepository;
  late RaidBloc bloc;

  const Raid testRaid = Raid(
    id: 'dragon_raid',
    slotsFilled: 5,
    maxSlots: 15,
    participants: <String>[],
  );

  setUp(() {
    mockRepository = MockRaidRepository();
    bloc = RaidBloc(raidRepository: mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('RaidBloc', () {
    test('initial state is RaidState.initial', () {
      expect(bloc.state, const RaidState.initial());
    });

    blocTest<RaidBloc, RaidState>(
      'RaidWatchStarted emits loaded state when stream emits raid',
      build: () {
        when(() => mockRepository.watchRaid()).thenAnswer(
          (_) => Stream<Either<Failure, Raid>>.value(
            const Right<Failure, Raid>(testRaid),
          ),
        );
        return bloc;
      },
      act: (RaidBloc bloc) => bloc.add(const RaidWatchStarted()),
      expect: () => <dynamic>[
        isA<RaidState>().having(
          (RaidState s) => s.raid,
          'raid',
          testRaid,
        ),
      ],
    );

    blocTest<RaidBloc, RaidState>(
      'RaidWatchStarted emits error when stream emits failure',
      build: () {
        when(() => mockRepository.watchRaid()).thenAnswer(
          (_) => Stream<Either<Failure, Raid>>.value(
            const Left<Failure, Raid>(ServerFailure('Connection failed')),
          ),
        );
        return bloc;
      },
      act: (RaidBloc bloc) => bloc.add(const RaidWatchStarted()),
      expect: () => <dynamic>[
        isA<RaidState>().having(
          (RaidState s) => s.status,
          'status',
          RaidStatus.error,
        ),
      ],
    );

    blocTest<RaidBloc, RaidState>(
      'RaidJoinRequested emits joining then loaded on success',
      build: () {
        when(() => mockRepository.watchRaid()).thenAnswer(
          (_) => const Stream<Either<Failure, Raid>>.empty(),
        );
        when(() => mockRepository.joinRaid(userId: any(named: 'userId')))
            .thenAnswer((_) async => const Right<Failure, bool>(true));
        return bloc;
      },
      act: (RaidBloc bloc) =>
          bloc.add(const RaidJoinRequested(userId: 'user_1')),
      expect: () => <dynamic>[
        isA<RaidState>().having(
          (RaidState s) => s.isJoining,
          'isJoining',
          isTrue,
        ),
        isA<RaidState>().having(
          (RaidState s) => s.isJoining,
          'isJoining',
          isFalse,
        ),
      ],
    );

    blocTest<RaidBloc, RaidState>(
      'RaidJoinRequested emits error when raid is full',
      build: () {
        when(() => mockRepository.watchRaid()).thenAnswer(
          (_) => const Stream<Either<Failure, Raid>>.empty(),
        );
        when(() => mockRepository.joinRaid(userId: any(named: 'userId')))
            .thenAnswer((_) async => const Right<Failure, bool>(false));
        return bloc;
      },
      act: (RaidBloc bloc) =>
          bloc.add(const RaidJoinRequested(userId: 'late_user')),
      expect: () => <dynamic>[
        isA<RaidState>().having(
          (RaidState s) => s.isJoining,
          'isJoining',
          isTrue,
        ),
        isA<RaidState>().having(
          (RaidState s) => s.status,
          'status',
          RaidStatus.error,
        ),
      ],
    );

    blocTest<RaidBloc, RaidState>(
      'RaidJoinRequested emits error on server failure',
      build: () {
        when(() => mockRepository.watchRaid()).thenAnswer(
          (_) => const Stream<Either<Failure, Raid>>.empty(),
        );
        when(() => mockRepository.joinRaid(userId: any(named: 'userId')))
            .thenAnswer(
          (_) async =>
              const Left<Failure, bool>(ServerFailure('Firestore error')),
        );
        return bloc;
      },
      act: (RaidBloc bloc) =>
          bloc.add(const RaidJoinRequested(userId: 'user_fail')),
      expect: () => <dynamic>[
        isA<RaidState>().having(
          (RaidState s) => s.isJoining,
          'isJoining',
          isTrue,
        ),
        isA<RaidState>()
            .having((RaidState s) => s.status, 'status', RaidStatus.error)
            .having((RaidState s) => s.errorMessage, 'errorMessage', isNotNull),
      ],
    );
  });
}
