import 'package:flutter/material.dart';

import 'package:lumoni/design_system/design_system.dart';

/// A selectable subscription plan card for the paywall.
///
/// Displays the plan name, price, per-month breakdown for annual plans,
/// a savings badge, and a selected state with gradient border.
class SubscriptionOptionCard extends StatelessWidget {
  const SubscriptionOptionCard({
    super.key,
    required this.planName,
    required this.price,
    this.pricePerMonth,
    this.savingsPercent,
    this.tag,
    this.isSelected = false,
    this.onTap,
  });

  /// Name of the plan (e.g., "Monthly", "Annual").
  final String planName;

  /// Full price display (e.g., "\$9.99/mo", "\$59.99/yr").
  final String price;

  /// Per-month price for annual plans (e.g., "\$4.99/mo").
  final String? pricePerMonth;

  /// Savings percentage for annual plans (e.g., 50).
  final int? savingsPercent;

  /// Optional tag (e.g., "Best Value", "Most Popular").
  final String? tag;

  /// Whether this card is currently selected.
  final bool isSelected;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              children: [
                // Radio indicator.
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.primaryGradient,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.sm),

                // Plan details.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        planName,
                        style: AppTypography.heading6.copyWith(
                          color: isSelected
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                      if (pricePerMonth != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '$pricePerMonth per month',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Price and savings.
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: AppTypography.heading5.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (savingsPercent != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: AppSpacing.borderRadiusFull,
                        ),
                        child: Text(
                          'Save $savingsPercent%',
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            // Tag badge (positioned above the card).
            if (tag != null)
              Positioned(
                top: -AppSpacing.md - 10,
                right: AppSpacing.md,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: AppSpacing.borderRadiusFull,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    tag!,
                    style: AppTypography.captionSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
