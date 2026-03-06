import 'package:flutter/material.dart';

import 'package:lumoni/design_system/design_system.dart';

class LeaderboardEmptyState extends StatelessWidget {
  const LeaderboardEmptyState({
    super.key,
    this.title = 'Leaderboard Locked',
    this.message =
        'Complete validated sessions across multiple days to enter competitive rankings.',
    this.ctaLabel = 'Take IQ Test',
    this.onTap,
  });

  final String title;
  final String message;
  final String ctaLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: GlassCard(
          borderColor: AppColors.accent.withValues(alpha: 0.4),
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.15),
              AppColors.accent.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emoji_events_outlined,
                size: 44,
                color: AppColors.warningLight,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.heading5.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: ctaLabel,
                variant: AppButtonVariant.primary,
                width: double.infinity,
                onPressed: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
