// test/features/raid/raid_service_test.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aether_project/features/raid/data/datasources/raid_service.dart';

void main() {
  group('RaidService Unit Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late RaidService raidService;

    setUp(() async {
      fakeFirestore = FakeFirebaseFirestore();
      raidService = RaidService(firestore: fakeFirestore);

      await fakeFirestore.collection('events').doc('dragon_raid').set(
        <String, dynamic>{'slots_filled': 0, 'max_slots': 15},
      );
    });

    test('joinRaid returns true on successful join', () async {
      final bool result = await raidService.joinRaid(userId: 'user_a');
      expect(result, isTrue);
    });

    test('joinRaid increments slots_filled', () async {
      await raidService.joinRaid(userId: 'user_a');

      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await fakeFirestore.collection('events').doc('dragon_raid').get();
      expect(snapshot.data()?['slots_filled'], 1);
    });

    test('joinRaid creates participant document', () async {
      await raidService.joinRaid(userId: 'user_a');

      final DocumentSnapshot<Map<String, dynamic>> participantSnap = await fakeFirestore
          .collection('events')
          .doc('dragon_raid')
          .collection('participants')
          .doc('user_a')
          .get();

      expect(participantSnap.exists, isTrue);
    });

    test('duplicate join returns false without incrementing slot', () async {
      await raidService.joinRaid(userId: 'user_dup');
      final bool secondJoin = await raidService.joinRaid(userId: 'user_dup');

      expect(secondJoin, isFalse);

      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await fakeFirestore.collection('events').doc('dragon_raid').get();
      expect(snapshot.data()?['slots_filled'], 1);
    });

    test('join on full raid returns false', () async {
      await fakeFirestore.collection('events').doc('dragon_raid').set(
        <String, dynamic>{'slots_filled': 15, 'max_slots': 15},
      );

      final bool result = await raidService.joinRaid(userId: 'late_user');
      expect(result, isFalse);
    });

    test('watchRaid stream emits current raid state', () async {
      final Map<String, dynamic>? raidData =
          await raidService.watchRaid().first;

      expect(raidData, isNotNull);
      expect(raidData?['slots_filled'], 0);
      expect(raidData?['max_slots'], 15);
    });
  });
}
