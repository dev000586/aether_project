// lib/features/raid/presentation/pages/main_dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../injection_container.dart';
import '../../../chat/presentation/bloc/chat_cubit.dart';
import '../../../chat/presentation/widgets/chat_card.dart';
import '../../../raid/presentation/bloc/raid_bloc.dart';
import '../../../raid/presentation/widgets/raid_card.dart';
import '../../../world_boss/presentation/bloc/world_boss_bloc.dart';
import '../../../world_boss/presentation/widgets/world_boss_card.dart';

/// The single app screen.
/// Provides all BLoCs to the subtree via MultiRepositoryProvider-style
/// BlocProvider. Each BLoC is created from the service locator (get_it),
/// keeping the widget tree decoupled from dependency construction.
class MainDashboard extends StatelessWidget {
  const MainDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<WorldBossBloc>(
          create: (_) => sl<WorldBossBloc>(),
        ),
        BlocProvider<RaidBloc>(
          create: (_) => sl<RaidBloc>(),
        ),
        BlocProvider<ChatCubit>(
          create: (_) => sl<ChatCubit>(),
        ),
      ],
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDeep,
      body: SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: _DashboardHeader(),
            ),
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed(
                  <Widget>[
                    WorldBossCard(),
                    SizedBox(height: 16),
                    RaidCard(),
                    SizedBox(height: 16),
                    ChatCard(),
                    SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        children: <Widget>[
          // Logo mark
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.accentCyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.accentCyan.withValues(alpha: 0.3),
              ),
            ),
            child: const Center(
              child: Text(
                'Æ',
                style: TextStyle(
                  color: AppTheme.accentCyan,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'PROJECT AETHER',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.accentCyan,
                      fontSize: 10,
                      letterSpacing: 3,
                    ),
              ),
              Text(
                'World Event Dashboard',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 16,
                    ),
              ),
            ],
          ),
          const Spacer(),
          _LiveIndicator(),
        ],
      ),
    );
  }
}

class _LiveIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.accentRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.accentRed.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.accentRed,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'LIVE',
            style: TextStyle(
              color: AppTheme.accentRed,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
