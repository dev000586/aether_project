// lib/features/raid/domain/repositories/raid_repository.dart

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/raid.dart';

/// Domain-layer contract for raid operations.
/// Returns [Either] to force callers to handle both success and failure paths.
abstract class RaidRepository {
  Future<Either<Failure, bool>> joinRaid({required String userId});
  Stream<Either<Failure, Raid>> watchRaid();
}
