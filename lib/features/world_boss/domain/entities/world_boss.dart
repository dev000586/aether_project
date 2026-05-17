// lib/features/world_boss/domain/entities/world_boss.dart

import 'package:equatable/equatable.dart';

/// Domain entity representing the world boss state.
/// Pure Dart — no Firebase dependencies.
class WorldBoss extends Equatable {
  const WorldBoss({
    required this.name,
    required this.spawnCycle,
    required this.status,
  });

  final String name;
  final Duration spawnCycle;
  final WorldBossStatus status;

  @override
  List<Object?> get props => <Object?>[name, spawnCycle, status];
}

enum WorldBossStatus {
  /// Boss is spawning soon — countdown active.
  spawning,

  /// Boss is alive — raid window open.
  alive,

  /// Boss has been defeated.
  defeated,
}
