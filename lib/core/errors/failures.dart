// lib/core/errors/failures.dart

import 'package:equatable/equatable.dart';

/// Base class for all domain-level failures.
/// Using sealed-class-style hierarchy for exhaustive pattern matching.
abstract class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}

/// Covers Firestore transaction failures, network issues, etc.
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Raised when raid is already at capacity.
class RaidFullFailure extends Failure {
  const RaidFullFailure() : super('The raid is full. All 15 slots are taken.');
}

/// Raised when a user is already in the raid.
class AlreadyJoinedFailure extends Failure {
  const AlreadyJoinedFailure() : super('You have already joined this raid.');
}

/// Covers input validation errors.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Covers unexpected or unknown errors.
class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
