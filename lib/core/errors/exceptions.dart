// lib/core/errors/exceptions.dart

// Data-layer exceptions (thrown in data sources, caught in repositories).
// Domain layer never sees these — it receives [Failure] objects instead.

class ServerException implements Exception {
  const ServerException(this.message);

  final String message;

  @override
  String toString() => 'ServerException: $message';
}

class RaidFullException implements Exception {
  const RaidFullException();

  @override
  String toString() => 'RaidFullException: Raid is at max capacity.';
}

class AlreadyJoinedException implements Exception {
  const AlreadyJoinedException();

  @override
  String toString() => 'AlreadyJoinedException: User already in raid.';
}

class TransactionException implements Exception {
  const TransactionException(this.message);

  final String message;

  @override
  String toString() => 'TransactionException: $message';
}
