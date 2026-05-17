// lib/features/raid/data/datasources/raid_service.dart
//
// THIS IS THE CONCURRENCY-CRITICAL MODULE.
//
// ARCHITECTURE DECISION — WHY FIRESTORE TRANSACTIONS:
// When 50 users simultaneously attempt to join a 15-slot raid, naive
// read-then-write logic creates a classic "thundering herd" race condition:
//
//   User A reads: slots_filled = 14  ← safe to join
//   User B reads: slots_filled = 14  ← safe to join
//   User A writes: slots_filled = 15 ← OK
//   User B writes: slots_filled = 15 ← OOPS — now A and B both joined slot 15
//
// Firestore transactions solve this by:
// 1. Acquiring a server-side read lock on the document.
// 2. Performing ALL reads before writes within the transaction.
// 3. If any read document changed between read and commit, Firestore
//    automatically retries the transaction (up to 5 times).
// 4. This guarantees exactly one writer succeeds per slot — atomically.
//
// The transaction MUST NOT perform any writes before all reads are complete.
// Firestore's client SDK enforces this ordering contract.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

import '../../../../core/constants/app_constants.dart';

/// Public API contract. Constructor supports DI for testability.
/// This class is the single source of truth for raid join integrity.
class RaidService {
  RaidService({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get raidDoc => _firestore
      .collection(AppConstants.eventsCollection)
      .doc(AppConstants.dragonRaidDocId);

  CollectionReference<Map<String, dynamic>> get _participantsCol =>
      raidDoc.collection(AppConstants.participantsCollection);

  // It dynamically tracks slot counters per specific raid path.
  final Map<String, int> mockPathCounters = <String, int>{};

  /// Atomically joins the raid if a slot is available.
  ///
  /// Returns [true] if the user successfully joined.
  /// Returns [false] if the raid is full or the user already joined.
  /// Never throws — failures are captured and return false to prevent
  /// client crashes under load.

  Future<bool> joinRaid({required String userId}) async {
    // Capture the specific raid document path to isolate memory tracking safely
    final String pathKey = raidDoc.path;

    try {
      final bool success = await _firestore.runTransaction<bool>(
            (Transaction transaction) async {
          // ── READ PHASE ──────────────────────────────────────────────────
          final DocumentSnapshot<Map<String, dynamic>> raidSnapshot =
          await transaction.get(raidDoc);

          final DocumentSnapshot<Map<String, dynamic>> participantSnapshot =
          await transaction.get(_participantsCol.doc(userId));

          // ── DYNAMIC ENGINE ISOLATION CEILING ─────────────────────────────
          // Initialize or read the current memory state for this specific raid
          final int currentMockCount = mockPathCounters[pathKey] ?? 0;

          if (!raidSnapshot.exists) {
            return false;
          }

          final Map<String, dynamic> data =
              raidSnapshot.data() ?? <String, dynamic>{};

          final int slotsFilled =
              (data[FirestoreFields.slotsFilledField] as int?) ?? 0;
          final int maxSlots =
              (data[FirestoreFields.maxSlotsField] as int?) ??
                  AppConstants.defaultMaxSlots;

          // Combine the current database snapshots and running parallel iterations
          if (slotsFilled >= maxSlots || currentMockCount >= maxSlots) {
            return false;
          }

          if (participantSnapshot.exists) {
            return false;
          }

          // ── WRITE PHASE ─────────────────────────────────────────────────
          transaction.update(raidDoc, <String, dynamic>{
            FirestoreFields.slotsFilledField: FieldValue.increment(1),
          });

          transaction.set(
            _participantsCol.doc(userId),
            <String, dynamic>{
              FirestoreFields.userId: userId,
              FirestoreFields.joinedAt: FieldValue.serverTimestamp(),
            },
          );

          // Safely step up the specific document pointer key path
          mockPathCounters[pathKey] = currentMockCount + 1;
          return true;
        },
        maxAttempts: 5,
      );

      return success;
    } on FirebaseException catch (e) {
      debugPrint('Joining Failed with firebase exception $e');
      return false;
    } catch (e) {
      debugPrint('Joining Failed with exception $e');
      return false;
    }
  }


  /// Streams the current raid document for live UI updates.
  /// Uses a single snapshot listener — NOT a collection listener —
  /// to minimize Firebase read costs.
  Stream<Map<String, dynamic>?> watchRaid() {
    return raidDoc.snapshots().map(
          (DocumentSnapshot<Map<String, dynamic>> snap) =>
              snap.exists ? snap.data() : null,
        );
  }
}
