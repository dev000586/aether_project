// lib/features/raid/presentation/bloc/raid_bloc.dart

import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/raid.dart';
import '../../domain/repositories/raid_repository.dart';
import 'raid_event.dart';
import 'raid_state.dart';

/// Orchestrates raid join flow and live raid state updates.
///
/// STREAM MANAGEMENT:
/// [_raidSubscription] listens to Firestore and maps updates to events.
/// It is always cancelled before re-subscribing and on [close()].
/// This prevents ghost listeners that would accumulate and create read storms.
class RaidBloc extends Bloc<RaidEvent, RaidState> {
  RaidBloc({required RaidRepository raidRepository})
      : _raidRepository = raidRepository,
        super(const RaidState.initial()) {
    on<RaidWatchStarted>(_onWatchStarted);
    on<RaidUpdated>(_onRaidUpdated);
    on<RaidJoinRequested>(_onJoinRequested);
    on<RaidJoinSucceeded>(_onJoinSucceeded);
    on<RaidJoinFailed>(_onJoinFailed);
    on<RaidErrorOccurred>(_onErrorOccurred);
  }

  final RaidRepository _raidRepository;
  StreamSubscription<Either<Failure, Raid>>? _raidSubscription;

  void _onWatchStarted(
    RaidWatchStarted event,
    Emitter<RaidState> emit,
  ) {
    _raidSubscription?.cancel();
    _raidSubscription = _raidRepository.watchRaid().listen(
      (Either<Failure, Raid> result) {
        result.fold(
          (Failure failure) =>
              add(RaidErrorOccurred(message: failure.message)),
          (Raid raid) => add(RaidUpdated(raid: raid)),
        );
      },
    );
  }

  void _onRaidUpdated(
    RaidUpdated event,
    Emitter<RaidState> emit,
  ) {
    emit(state.copyWith(status: RaidStatus.loaded, raid: event.raid));
  }

  Future<void> _onJoinRequested(
    RaidJoinRequested event,
    Emitter<RaidState> emit,
  ) async {
    emit(state.copyWith(
      status: RaidStatus.joining,
      isJoining: true,
      currentUserId: event.userId,
    ));

    final Either<Failure, bool> result =
        await _raidRepository.joinRaid(userId: event.userId);

    result.fold(
      (Failure failure) => add(RaidJoinFailed(message: failure.message)),
      (bool joined) => joined
          ? add(const RaidJoinSucceeded())
          : add(const RaidJoinFailed(message: 'Raid is full or you already joined.')),
    );
  }

  void _onJoinSucceeded(
    RaidJoinSucceeded event,
    Emitter<RaidState> emit,
  ) {
    emit(state.copyWith(status: RaidStatus.loaded, isJoining: false));
  }

  void _onJoinFailed(
    RaidJoinFailed event,
    Emitter<RaidState> emit,
  ) {
    emit(state.copyWith(
      status: RaidStatus.error,
      errorMessage: event.message,
      isJoining: false,
    ));
  }

  void _onErrorOccurred(
    RaidErrorOccurred event,
    Emitter<RaidState> emit,
  ) {
    emit(state.copyWith(
      status: RaidStatus.error,
      errorMessage: event.message,
    ));
  }

  @override
  Future<void> close() async {
    await _raidSubscription?.cancel();
    return super.close();
  }
}
