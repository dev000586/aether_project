// lib/features/raid/data/repositories/raid_repository_impl.dart

import 'package:dartz/dartz.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/raid.dart';
import '../../domain/repositories/raid_repository.dart';
import '../datasources/raid_service.dart';

/// Translates data-layer results into domain-layer [Either] types.
/// Insulates the domain and presentation layers from Firebase specifics.
class RaidRepositoryImpl implements RaidRepository {
  const RaidRepositoryImpl({required RaidService raidService})
      : _raidService = raidService;

  final RaidService _raidService;

  @override
  Future<Either<Failure, bool>> joinRaid({required String userId}) async {
    try {
      final bool result = await _raidService.joinRaid(userId: userId);
      return Right<Failure, bool>(result);
    } catch (e) {
      return Left<Failure, bool>(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, Raid>> watchRaid() {
    return _raidService.watchRaid().map(
      (Map<String, dynamic>? data) {
        if (data == null) {
          return const Left<Failure, Raid>(
            ServerFailure('Raid document not found.'),
          );
        }


        final int slotsFilled =
            (data[FirestoreFields.slotsFilledField] as int?) ?? 0;
        final int maxSlots =
            (data[FirestoreFields.maxSlotsField] as int?) ??
                AppConstants.defaultMaxSlots;

        _raidService.mockPathCounters[_raidService.raidDoc.path] = slotsFilled;

        return Right<Failure, Raid>(
          Raid(
            id: AppConstants.dragonRaidDocId,
            slotsFilled: slotsFilled,
            maxSlots: maxSlots,
            participants: const <String>[],
          ),
        );
      },
    ).handleError(
      (Object error) => Left<Failure, Raid>(ServerFailure(error.toString())),
    );
  }
}
