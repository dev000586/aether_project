// lib/features/world_boss/presentation/bloc/world_boss_bloc.dart

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import 'world_boss_event.dart';
import 'world_boss_state.dart';

/// Manages the high-frequency world boss countdown (100ms ticks).
///
/// KEY CONCURRENCY DECISION:
/// The timer runs as a periodic Stream<Duration> rather than direct
/// setState calls. This decouples tick production from UI consumption.
/// BlocSelector in the UI further isolates which sub-tree actually rebuilds —
/// only the countdown text widget re-renders every 100ms, not the whole page.
///
/// MEMORY SAFETY:
/// - [StreamSubscription] is captured and cancelled on [WorldBossTimerStopped].
/// - [close()] also ensures cancellation as a safety net.
class WorldBossBloc extends Bloc<WorldBossEvent, WorldBossState> {
  WorldBossBloc()
      : super(
          const WorldBossState.initial(
            bossName: AppConstants.bossName,
            totalCycle: AppConstants.bossSpawnCycle,
          ),
        ) {
    on<WorldBossStarted>(_onStarted);
    on<WorldBossTimerTicked>(_onTicked);
    on<WorldBossSpawned>(_onSpawned);
    on<WorldBossTimerStopped>(_onStopped);
  }

  StreamSubscription<Duration>? _tickerSubscription;

  /// Computes the next spawn time relative to app launch.
  /// In a real system this would come from a Firestore document.
  Duration _computeInitialRemaining() {
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final int cycleMs = AppConstants.bossSpawnCycle.inMilliseconds;
    final int remainder = nowMs % cycleMs;
    return Duration(milliseconds: cycleMs - remainder);
  }

  /// Produces a stream that emits the remaining [Duration] every 100ms.
  /// The stream completes naturally when remaining hits zero.
  Stream<Duration> _buildTickerStream(Duration initial) async* {
    Duration remaining = initial;
    while (remaining.inMilliseconds > 0) {
      await Future<void>.delayed(AppConstants.timerTickInterval);
      remaining = remaining - AppConstants.timerTickInterval;
      if (remaining.isNegative) remaining = Duration.zero;
      yield remaining;
    }
  }

  void _onStarted(
    WorldBossStarted event,
    Emitter<WorldBossState> emit,
  ) {
    // Cancel any existing subscription to avoid double-ticking
    // if the bloc receives a redundant [WorldBossStarted] event.
    _tickerSubscription?.cancel();

    final Duration initial = _computeInitialRemaining();
    emit(
      state.copyWith(
        remaining: initial,
        totalCycle: AppConstants.bossSpawnCycle,
        isLoading: false,
      ),
    );

    _tickerSubscription = _buildTickerStream(initial).listen(
      (Duration remaining) => add(WorldBossTimerTicked(remaining: remaining)),
      onDone: () => add(const WorldBossSpawned()),
    );
  }

  void _onTicked(
    WorldBossTimerTicked event,
    Emitter<WorldBossState> emit,
  ) {
    emit(state.copyWith(remaining: event.remaining));
  }

  void _onSpawned(
    WorldBossSpawned event,
    Emitter<WorldBossState> emit,
  ) {
    emit(state.copyWith(isAlive: true, remaining: Duration.zero));
    // After a brief "alive" window, restart the cycle.
    // In production, this would be driven by a Firestore document update.
    // unawaited is intentional: fire-and-forget respawn timer.
    unawaited(
      Future<void>.delayed(const Duration(seconds: 30), () {
        if (!isClosed) {
          add(const WorldBossStarted());
        }
      }),
    );
  }

  void _onStopped(
    WorldBossTimerStopped event,
    Emitter<WorldBossState> emit,
  ) {
    _tickerSubscription?.cancel();
    _tickerSubscription = null;
  }

  @override
  Future<void> close() async {
    await _tickerSubscription?.cancel();
    return super.close();
  }
}
