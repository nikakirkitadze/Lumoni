import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:lumoni/design_system/design_system.dart';

/// A horizontal row of stat cards displayed on the profile page.
///
/// Shows tests taken, highest IQ, average EQ, and member since date.
class ProfileStatsRow extends StatelessWidget {
  const ProfileStatsRow({
    super.key,
    required this.testsTaken,
    this.highestIQ,
    this.averageEQ,
    required this.memberSince,
  });

  /// Total number of tests completed.
  final int testsTaken;

  /// Highest IQ score achieved.
  final int? highestIQ;

  /// Average EQ score.
  final double? averageEQ;

  /// The date the user joined.
  final DateTime memberSince;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        children: [
          _StatCard(
            icon: Icons.assignment_outlined,
            label: 'Tests Taken',
            value: testsTaken.toString(),
            iconColor: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          _StatCard(
            icon: Icons.psychology_outlined,
            label: 'Highest IQ',
            value: highestIQ?.toString() ?? '--',
            iconColor: AppColors.accent,
          ),
          const SizedBox(width: AppSpacing.sm),
          _StatCard(
            icon: Icons.favorite_outline_rounded,
            label: 'Avg EQ',
            value: averageEQ != null
                ? averageEQ!.toStringAsFixed(0)
                : '--',
            iconColor: AppColors.secondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          _StatCard(
            icon: Icons.calendar_today_outlined,
            label: 'Member Since',
            value: DateFormat('MMM yyyy').format(memberSince),
            iconColor: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      width: 120,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: iconColor,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            style: AppTypography.heading5.copyWith(
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.captionSmall.copyWith(
              color: AppColors.textTertiary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
