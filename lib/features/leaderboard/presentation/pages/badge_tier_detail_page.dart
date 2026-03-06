import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lumoni/design_system/design_system.dart';
import 'package:lumoni/features/leaderboard/presentation/cubits/tier_badge/tier_badge_cubit.dart';
import 'package:lumoni/features/leaderboard/presentation/cubits/tier_badge/tier_badge_state.dart';

class BadgeTierDetailPage extends StatefulWidget {
  const BadgeTierDetailPage({super.key});

  @override
  State<BadgeTierDetailPage> createState() => _BadgeTierDetailPageState();
}

class _BadgeTierDetailPageState extends State<BadgeTierDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TierBadgeCubit>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Badge & Tier System'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
      ),
      body: BlocBuilder<TierBadgeCubit, TierBadgeState>(
        builder: (context, state) {
          return switch (state) {
            TierBadgeInitial() || TierBadgeLoading() => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            TierBadgeError(:final message) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            TierBadgeLoaded(:final tiers, :final currentTierId) => ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                Text(
                  'Climb the ladder with validated performance and consistency.',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ...tiers.map(
                  (tier) => GlassCard(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    gradient: LinearGradient(
                      colors: [
                        _hexToColor(tier.colorHex).withValues(alpha: 0.22),
                        AppColors.primary.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderColor: tier.id == currentTierId
                        ? AppColors.accent
                        : _hexToColor(tier.colorHex).withValues(alpha: 0.45),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: _hexToColor(
                              tier.colorHex,
                            ).withValues(alpha: 0.2),
                            borderRadius: AppSpacing.borderRadiusMd,
                            border: Border.all(
                              color: _hexToColor(
                                tier.colorHex,
                              ).withValues(alpha: 0.6),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            tier.label.characters.first,
                            style: AppTypography.heading6.copyWith(
                              color: _hexToColor(tier.colorHex),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    tier.label,
                                    style: AppTypography.heading6.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (tier.id == currentTierId)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: AppSpacing.xs,
                                      ),
                                      child: Text(
                                        '(Current)',
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.accent,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${tier.minPercentile.toStringAsFixed(1)} - ${tier.maxPercentile.toStringAsFixed(1)} percentile',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tier.benefitText,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          };
        },
      ),
    );
  }

  Color _hexToColor(String hex) {
    final normalized = hex.replaceAll('0x', '');
    return Color(int.parse(normalized));
  }
}
