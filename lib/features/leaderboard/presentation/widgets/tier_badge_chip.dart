import 'package:flutter/material.dart';

import 'package:lumoni/design_system/design_system.dart';

class TierBadgeChip extends StatelessWidget {
  const TierBadgeChip({super.key, required this.tier});

  final String tier;

  @override
  Widget build(BuildContext context) {
    final color = _tierColor(tier.toLowerCase());

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: AppSpacing.borderRadiusFull,
        border: Border.all(color: color.withValues(alpha: 0.65)),
      ),
      child: Text(
        tier.toUpperCase(),
        style: AppTypography.captionSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Color _tierColor(String id) {
    switch (id) {
      case 'legend':
        return AppColors.warningLight;
      case 'diamond':
        return AppColors.accent;
      case 'platinum':
        return AppColors.primary300;
      case 'gold':
        return AppColors.warning;
      case 'silver':
        return AppColors.textSecondary;
      default:
        return AppColors.secondary300;
    }
  }
}
