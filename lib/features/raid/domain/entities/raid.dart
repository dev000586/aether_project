// lib/features/raid/domain/entities/raid.dart

import 'package:equatable/equatable.dart';

/// Domain entity representing the current raid state.
class Raid extends Equatable {
  const Raid({
    required this.id,
    required this.slotsFilled,
    required this.maxSlots,
    required this.participants,
  });

  final String id;
  final int slotsFilled;
  final int maxSlots;
  final List<String> participants;

  bool get isFull => slotsFilled >= maxSlots;
  int get availableSlots => maxSlots - slotsFilled;
  double get fillFraction => maxSlots > 0 ? slotsFilled / maxSlots : 0;

  @override
  List<Object?> get props => <Object?>[id, slotsFilled, maxSlots, participants];
}
