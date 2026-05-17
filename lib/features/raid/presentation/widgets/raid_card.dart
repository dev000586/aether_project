// lib/features/raid/presentation/widgets/raid_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/aether_card.dart';
import '../../domain/entities/raid.dart';
import '../bloc/raid_bloc.dart';
import '../bloc/raid_event.dart';
import '../bloc/raid_state.dart';

class RaidCard extends StatefulWidget {
  const RaidCard({super.key});

  @override
  State<RaidCard> createState() => _RaidCardState();
}

class _RaidCardState extends State<RaidCard> {
  @override
  void initState() {
    super.initState();
    context.read<RaidBloc>().add(const RaidWatchStarted());
  }

  void _handleJoin(BuildContext context) {
    // In production, userId comes from FirebaseAuth.
    // For the demo, we generate a pseudo-unique session ID.
    final String userId =
        'user_${DateTime.now().millisecondsSinceEpoch}';
    context.read<RaidBloc>().add(RaidJoinRequested(userId: userId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RaidBloc, RaidState>(
      listener: (BuildContext context, RaidState state) {
        if (state.status == RaidStatus.error && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: <Widget>[
                  const Icon(Icons.warning_amber, color: AppTheme.accentAmber, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(state.errorMessage!)),
                ],
              ),
              duration: AppConstants.snackBarDuration,
            ),
          );
        }
      },
      child: AetherCard(
        accentColor: AppTheme.accentCyan,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            BlocSelector<RaidBloc, RaidState, int>(
              selector: (RaidState state) =>
                  state.raid?.slotsFilled ?? 0,
              builder: (BuildContext context, int slotsFilled) {
                return SectionHeader(
                  title: 'Geo-Raid',
                  subtitle: 'Dragon\'s Lair — Active',
                  accentColor: AppTheme.accentCyan,
                  trailing: _SlotBadge(slotsFilled: slotsFilled),
                );
              },
            ),
            const SizedBox(height: 20),
            BlocBuilder<RaidBloc, RaidState>(
              buildWhen: (RaidState previous, RaidState current) =>
                  previous.raid != current.raid ||
                  previous.status != current.status,
              builder: (BuildContext context, RaidState state) {
                if (state.status == RaidStatus.loading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: CircularProgressIndicator(
                        color: AppTheme.accentCyan,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                }

                final Raid? raid = state.raid;
                if (raid == null) {
                  return const Text('No raid data available.');
                }

                return _RaidSlotGrid(raid: raid);
              },
            ),
            const SizedBox(height: 20),
            BlocBuilder<RaidBloc, RaidState>(
              buildWhen: (RaidState previous, RaidState current) =>
                  previous.status != current.status ||
                  previous.raid?.isFull != current.raid?.isFull ||
                  previous.isJoining != current.isJoining,
              builder: (BuildContext context, RaidState state) {
                final bool isFull = state.raid?.isFull ?? false;
                final bool isJoining = state.isJoining;

                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (isFull || isJoining)
                        ? null
                        : () => _handleJoin(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFull
                          ? AppTheme.borderActive
                          : AppTheme.accentCyan,
                      disabledBackgroundColor: AppTheme.borderActive,
                    ),
                    child: isJoining
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.textPrimary,
                            ),
                          )
                        : Text(
                            isFull ? 'RAID FULL' : 'JOIN RAID',
                            style: TextStyle(
                              color: isFull
                                  ? AppTheme.textMuted
                                  : AppTheme.backgroundDeep,
                            ),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotBadge extends StatelessWidget {
  const _SlotBadge({required this.slotsFilled});

  final int slotsFilled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.accentCyan.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$slotsFilled/${AppConstants.defaultMaxSlots}',
        style: const TextStyle(
          color: AppTheme.accentCyan,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

class _RaidSlotGrid extends StatelessWidget {
  const _RaidSlotGrid({required this.raid});

  final Raid raid;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              '${raid.slotsFilled} adventurers joined',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '${raid.availableSlots} slots remaining',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: raid.isFull
                        ? AppTheme.accentRed
                        : AppTheme.accentGreen,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: 1.8,
          ),
          itemCount: raid.maxSlots,
          itemBuilder: (BuildContext context, int index) {
            final bool filled = index < raid.slotsFilled;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: filled
                    ? AppTheme.accentCyan.withValues(alpha: 0.2)
                    : AppTheme.backgroundElevated,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: filled
                      ? AppTheme.accentCyan.withValues(alpha: 0.5)
                      : AppTheme.borderSubtle,
                ),
              ),
              child: filled
                  ? const Center(
                      child: Icon(
                        Icons.person,
                        size: 14,
                        color: AppTheme.accentCyan,
                      ),
                    )
                  : null,
            );
          },
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: raid.fillFraction,
            backgroundColor: AppTheme.borderSubtle,
            valueColor: AlwaysStoppedAnimation<Color>(
              raid.isFull ? AppTheme.accentRed : AppTheme.accentCyan,
            ),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}
