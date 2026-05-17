// lib/features/raid/presentation/bloc/raid_state.dart

import 'package:equatable/equatable.dart';

import '../../domain/entities/raid.dart';

/// Immutable raid UI state.
class RaidState extends Equatable {
  const RaidState({
    required this.status,
    this.raid,
    this.errorMessage,
    this.currentUserId,
    this.isJoining = false,
  });

  const RaidState.initial()
      : status = RaidStatus.loading,
        raid = null,
        errorMessage = null,
        currentUserId = null,
        isJoining = false;

  final RaidStatus status;
  final Raid? raid;
  final String? errorMessage;
  final String? currentUserId;
  final bool isJoining;

  bool get hasJoined =>
      currentUserId != null &&
      (raid?.participants.contains(currentUserId) ?? false);

  RaidState copyWith({
    RaidStatus? status,
    Raid? raid,
    String? errorMessage,
    String? currentUserId,
    bool? isJoining,
  }) {
    return RaidState(
      status: status ?? this.status,
      raid: raid ?? this.raid,
      errorMessage: errorMessage ?? this.errorMessage,
      currentUserId: currentUserId ?? this.currentUserId,
      isJoining: isJoining ?? this.isJoining,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        raid,
        errorMessage,
        currentUserId,
        isJoining,
      ];
}

enum RaidStatus { loading, loaded, joining, error }
