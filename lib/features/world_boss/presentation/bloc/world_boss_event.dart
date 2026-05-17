// lib/features/world_boss/presentation/bloc/world_boss_event.dart

import 'package:equatable/equatable.dart';

/// Events for the WorldBoss BLoC.
/// Discrete events allow clean testability with bloc_test.
sealed class WorldBossEvent extends Equatable {
  const WorldBossEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Starts the countdown ticker.
class WorldBossStarted extends WorldBossEvent {
  const WorldBossStarted();
}

/// Fired every 100ms by the Ticker stream — carries current remaining time.
/// Keeping the payload here keeps the BLoC handler stateless relative to time.
class WorldBossTimerTicked extends WorldBossEvent {
  const WorldBossTimerTicked({required this.remaining});

  final Duration remaining;

  @override
  List<Object?> get props => <Object?>[remaining];
}

/// Fired when the countdown hits zero — boss spawns.
class WorldBossSpawned extends WorldBossEvent {
  const WorldBossSpawned();
}

/// Stops and disposes the timer. Called from widget dispose.
class WorldBossTimerStopped extends WorldBossEvent {
  const WorldBossTimerStopped();
}
