// lib/features/world_boss/presentation/bloc/world_boss_state.dart

import 'package:equatable/equatable.dart';

/// Immutable state for the world boss countdown BLoC.
/// Granular props ensure [buildWhen] can filter precisely —
/// preventing UI from rebuilding unless the specific field it
/// renders has actually changed.
class WorldBossState extends Equatable {
  const WorldBossState({
    required this.remaining,
    required this.totalCycle,
    required this.bossName,
    required this.isAlive,
    required this.isLoading,
  });

  const WorldBossState.initial({
    required this.bossName,
    required this.totalCycle,
  })  : remaining = totalCycle,
        isAlive = false,
        isLoading = true;

  final Duration remaining;
  final Duration totalCycle;
  final String bossName;
  final bool isAlive;
  final bool isLoading;

  /// [progress] is intentionally a computed getter, not a field.
  /// Equatable ignores it — avoids spurious inequality from floating point.
  double get progress {
    if (totalCycle.inMilliseconds == 0) return 0;
    final double elapsed =
        (totalCycle.inMilliseconds - remaining.inMilliseconds).toDouble();
    return (elapsed / totalCycle.inMilliseconds).clamp(0.0, 1.0);
  }

  WorldBossState copyWith({
    Duration? remaining,
    Duration? totalCycle,
    String? bossName,
    bool? isAlive,
    bool? isLoading,
  }) {
    return WorldBossState(
      remaining: remaining ?? this.remaining,
      totalCycle: totalCycle ?? this.totalCycle,
      bossName: bossName ?? this.bossName,
      isAlive: isAlive ?? this.isAlive,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        remaining,
        totalCycle,
        bossName,
        isAlive,
        isLoading,
      ];
}
