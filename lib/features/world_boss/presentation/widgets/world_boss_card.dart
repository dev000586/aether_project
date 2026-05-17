// lib/features/world_boss/presentation/widgets/world_boss_card.dart

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/duration_extensions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/aether_card.dart';
import '../bloc/world_boss_bloc.dart';
import '../bloc/world_boss_event.dart';
import '../bloc/world_boss_state.dart';

class WorldBossCard extends StatefulWidget {
  const WorldBossCard({super.key});

  @override
  State<WorldBossCard> createState() => _WorldBossCardState();
}

class _WorldBossCardState extends State<WorldBossCard> {
  @override
  void initState() {
    super.initState();
    context.read<WorldBossBloc>().add(const WorldBossStarted());
  }

  @override
  Widget build(BuildContext context) {
    return AetherCard(
      accentColor: AppTheme.accentAmber,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          BlocSelector<WorldBossBloc, WorldBossState, bool>(
            selector: (WorldBossState state) => state.isAlive,
            builder: (BuildContext context, bool isAlive) {
              return SectionHeader(
                title: 'Global Pulse',
                subtitle: AppConstants.bossName,
                accentColor: AppTheme.accentAmber,
                trailing: StatusDot(
                  color: isAlive ? AppTheme.accentRed : AppTheme.accentAmber,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          BlocSelector<WorldBossBloc, WorldBossState, _CountdownData>(
            selector: (WorldBossState state) => _CountdownData(
              remaining: state.remaining,
              isAlive: state.isAlive,
              bossName: state.bossName,
            ),
            builder: (BuildContext context, _CountdownData data) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    data.bossName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.accentAmber,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data.isAlive
                        ? 'ALIVE — RAID NOW'
                        : data.remaining.toCountdownString(),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                      letterSpacing: -1,
                      height: 1,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          BlocSelector<WorldBossBloc, WorldBossState, double>(
            selector: (WorldBossState state) => state.progress,
            builder: (BuildContext context, double progress) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppTheme.borderSubtle,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.accentAmber),
                  minHeight: 6,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          BlocSelector<WorldBossBloc, WorldBossState, bool>(
            selector: (WorldBossState state) => state.isAlive,
            builder: (BuildContext context, bool isAlive) {
              return Row(
                children: <Widget>[
                  StatusDot(
                    color: isAlive ? AppTheme.accentRed : AppTheme.accentGreen,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isAlive ? 'BOSS ACTIVE' : 'SPAWNING SOON',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isAlive
                              ? AppTheme.accentRed
                              : AppTheme.accentGreen,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CountdownData extends Equatable {
  const _CountdownData({
    required this.remaining,
    required this.isAlive,
    required this.bossName,
  });

  final Duration remaining;
  final bool isAlive;
  final String bossName;

  @override
  List<Object?> get props => <Object?>[remaining, isAlive, bossName];
}
