// lib/features/raid/presentation/bloc/raid_event.dart

import 'package:equatable/equatable.dart';

import '../../domain/entities/raid.dart';

sealed class RaidEvent extends Equatable {
  const RaidEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class RaidWatchStarted extends RaidEvent {
  const RaidWatchStarted();
}

class RaidUpdated extends RaidEvent {
  const RaidUpdated({required this.raid});

  final Raid raid;

  @override
  List<Object?> get props => <Object?>[raid];
}

class RaidJoinRequested extends RaidEvent {
  const RaidJoinRequested({required this.userId});

  final String userId;

  @override
  List<Object?> get props => <Object?>[userId];
}

class RaidJoinSucceeded extends RaidEvent {
  const RaidJoinSucceeded();
}

class RaidJoinFailed extends RaidEvent {
  const RaidJoinFailed({required this.message});

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}

class RaidErrorOccurred extends RaidEvent {
  const RaidErrorOccurred({required this.message});

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}
