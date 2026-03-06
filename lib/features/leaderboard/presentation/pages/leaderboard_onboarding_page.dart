import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:lumoni/app/router.dart';
import 'package:lumoni/design_system/design_system.dart';
import 'package:lumoni/features/leaderboard/presentation/widgets/leaderboard_empty_state.dart';

class LeaderboardOnboardingPage extends StatelessWidget {
  const LeaderboardOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
      ),
      body: LeaderboardEmptyState(
        title: 'Enter Competitive Rankings',
        message:
            'Weekly and monthly boards unlock after minimum validated participation across multiple days.',
        ctaLabel: 'Start IQ Challenge',
        onTap: () => context.push(RoutePaths.iqTestIntro),
      ),
    );
  }
}
