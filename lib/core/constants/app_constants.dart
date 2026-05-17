// lib/core/constants/app_constants.dart

/// Central registry of application-wide constants.
/// Avoids magic strings scattered throughout the codebase.
class AppConstants {
  AppConstants._();

  // Firebase Collections
  static const String eventsCollection = 'events';
  static const String participantsCollection = 'participants';
  static const String chatCollection = 'chat';
  static const String messagesCollection = 'messages';

  // Raid Document
  static const String dragonRaidDocId = 'dragon_raid';
  static const String slotsFilledField = 'slots_filled';
  static const String maxSlotsField = 'max_slots';
  static const int defaultMaxSlots = 15;

  // World Boss
  static const String bossName = 'Ignis the Undying';
  static const Duration bossSpawnCycle = Duration(minutes: 30);
  static const Duration timerTickInterval = Duration(milliseconds: 100);

  // Chat
  /// Hard limit on live listener batch. Beyond this, paginate.
  /// This is the key cost-control knob for Firebase reads.
  static const int chatPageSize = 25;
  static const int chatMaxLiveMessages = 50;

  // UI
  static const Duration snackBarDuration = Duration(seconds: 3);
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 400);
}

/// Firestore field name constants to prevent typos.
class FirestoreFields {
  FirestoreFields._();

  static const String timestamp = 'timestamp';
  static const String userId = 'userId';
  static const String displayName = 'displayName';
  static const String message = 'message';
  static const String slotsFilledField = 'slots_filled';
  static const String maxSlotsField = 'max_slots';
  static const String joinedAt = 'joined_at';
}
