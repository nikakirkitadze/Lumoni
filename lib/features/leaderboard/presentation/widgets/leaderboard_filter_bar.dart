import 'package:flutter/material.dart';

import 'package:lumoni/design_system/design_system.dart';
import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_enums.dart';
import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_filter.dart';

class LeaderboardFilterBar extends StatelessWidget {
  const LeaderboardFilterBar({
    super.key,
    required this.filter,
    required this.onMetricChanged,
    required this.onPeriodChanged,
    required this.onScopeChanged,
  });

  final LeaderboardFilter filter;
  final ValueChanged<LeaderboardMetric> onMetricChanged;
  final ValueChanged<LeaderboardPeriod> onPeriodChanged;
  final ValueChanged<LeaderboardScopeType> onScopeChanged;

  @override
  Widget build(BuildContext context) {
    const availableScopes = <LeaderboardScopeType>[
      LeaderboardScopeType.global,
      LeaderboardScopeType.country,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: LeaderboardMetric.values
              .map(
                (metric) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: metric == LeaderboardMetric.iq ? AppSpacing.xs : 0,
                    ),
                    child: _FilterPill(
                      label: metric.label,
                      selected: filter.metric == metric,
                      onTap: () => onMetricChanged(metric),
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final period = LeaderboardPeriod.values[index];
              return _FilterChip(
                label: period.label,
                selected: filter.period == period,
                onTap: () => onPeriodChanged(period),
              );
            },
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSpacing.xs),
            itemCount: LeaderboardPeriod.values.length,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final scope = availableScopes[index];
              return _FilterChip(
                label: scope.label,
                selected: filter.scopeType == scope,
                onTap: () => onScopeChanged(scope),
              );
            },
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSpacing.xs),
            itemCount: availableScopes.length,
          ),
        ),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGradient : null,
          color: selected ? null : AppColors.surface,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.border,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.button.copyWith(
              color: selected
                  ? AppColors.textOnPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.18)
              : AppColors.surface,
          borderRadius: AppSpacing.borderRadiusFull,
          border: Border.all(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.6)
                : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: selected ? AppColors.accent : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
