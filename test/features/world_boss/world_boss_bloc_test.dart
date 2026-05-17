// test/features/world_boss/world_boss_bloc_test.dart

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aether_project/features/world_boss/presentation/bloc/world_boss_bloc.dart';
import 'package:aether_project/features/world_boss/presentation/bloc/world_boss_event.dart';
import 'package:aether_project/features/world_boss/presentation/bloc/world_boss_state.dart';
import 'package:aether_project/core/constants/app_constants.dart';

void main() {
  group('WorldBossBloc', () {
    late WorldBossBloc bloc;

    setUp(() {
      bloc = WorldBossBloc();
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state has correct defaults', () {
      expect(bloc.state.bossName, AppConstants.bossName);
      expect(bloc.state.isLoading, isTrue);
      expect(bloc.state.isAlive, isFalse);
    });

    blocTest<WorldBossBloc, WorldBossState>(
      'emits loaded state after WorldBossStarted',
      build: () => bloc,
      act: (WorldBossBloc bloc) => bloc.add(const WorldBossStarted()),
      wait: const Duration(milliseconds: 200),
      expect: () => <dynamic>[
        isA<WorldBossState>().having(
          (WorldBossState s) => s.isLoading,
          'isLoading',
          isFalse,
        ),isA<WorldBossState>().having(
          (WorldBossState s) => s.isLoading,
          'isLoading',
          isFalse,
        ),
      ],
    );

    blocTest<WorldBossBloc, WorldBossState>(
      'tick event updates remaining duration',
      build: () => bloc,
      act: (WorldBossBloc bloc) => bloc
        ..add(const WorldBossStarted())
        ..add(const WorldBossTimerTicked(
          remaining: Duration(minutes: 15),
        )),
      skip: 1,
      expect: () => <dynamic>[
        isA<WorldBossState>().having(
          (WorldBossState s) => s.remaining,
          'remaining',
          const Duration(minutes: 15),
        ),
      ],
    );

    blocTest<WorldBossBloc, WorldBossState>(
      'WorldBossSpawned sets isAlive to true',
      build: () => bloc,
      act: (WorldBossBloc bloc) => bloc
        ..add(const WorldBossStarted())
        ..add(const WorldBossSpawned()),
      wait: const Duration(milliseconds: 200),
      expect: () => <dynamic>[
        isA<WorldBossState>(), // started state — isLoading = false
        isA<WorldBossState>().having(
          (WorldBossState s) => s.isAlive,
          'isAlive',
          isTrue,
        ),
        isA<WorldBossState>().having(
          (WorldBossState s) => s.isAlive,
          'isAlive',
          isTrue,
        ),
      ],
    );

    blocTest<WorldBossBloc, WorldBossState>(
      'WorldBossTimerStopped cancels ticker without error',
      build: () => bloc,
      act: (WorldBossBloc bloc) => bloc
        ..add(const WorldBossStarted())
        ..add(const WorldBossTimerStopped()),
      errors: () => isEmpty,
    );

    test('progress is 0.0 on initial state', () {
      expect(bloc.state.progress, 0.0);
    });

    test('progress clamps to [0.0, 1.0]', () {
      const WorldBossState state = WorldBossState(
        remaining: Duration(minutes: 35),
        totalCycle: Duration(minutes: 30),
        bossName: 'Test Boss',
        isAlive: false,
        isLoading: false,
      );
      expect(state.progress, 0.0);
    });
  });
}
