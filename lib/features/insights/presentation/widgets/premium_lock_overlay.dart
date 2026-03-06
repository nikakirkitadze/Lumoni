import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:lumoni/design_system/colors/app_colors.dart';
import 'package:lumoni/design_system/components/glass_card.dart';
import 'package:lumoni/design_system/spacing.dart';
import 'package:lumoni/design_system/typography/app_typography.dart';

/// Overlay widget that blurs/fades the content behind it and shows
/// a lock icon with a "Premium Feature" label and an "Unlock" button
/// that navigates to the paywall.
class PremiumLockOverlay extends StatelessWidget {
  const PremiumLockOverlay({
    super.key,
    required this.child,
    this.isLocked = true,
    this.title = 'Premium Feature',
    this.subtitle = 'Unlock detailed insights and analytics',
    this.blurSigma = 6.0,
  });

  /// The content that should be shown behind the lock.
  final Widget child;

  /// Whether the content is locked. When false, the child is shown directly.
  final bool isLocked;

  /// Title shown on the overlay.
  final String title;

  /// Subtitle shown on the overlay.
  final String subtitle;

  /// The blur intensity for the locked content.
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    if (!isLocked) return child;

    return Stack(
      children: [
        // Blurred child content.
        ClipRRect(
          borderRadius: AppSpacing.borderRadiusLg,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: blurSigma,
              sigmaY: blurSigma,
            ),
            child: Opacity(
              opacity: 0.4,
              child: IgnorePointer(child: child),
            ),
          ),
        ),

        // Lock overlay.
        Positioned.fill(
          child: GlassCard(
            blurX: 0,
            blurY: 0,
            fillColor: AppColors.background.withValues(alpha: 0.6),
            borderColor: AppColors.primary.withValues(alpha: 0.2),
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.05),
                AppColors.secondary.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Lock icon with glow.
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Title.
                Text(
                  title,
                  style: AppTypography.heading5.copyWith(
                    foreground: Paint()
                      ..shader = AppColors.primaryGradient.createShader(
                        const Rect.fromLTWH(0, 0, 200, 30),
                      ),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxs),

                // Subtitle.
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Unlock button.
                GestureDetector(
                  onTap: () => context.push('/paywall'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: AppSpacing.borderRadiusFull,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Unlock Premium',
                          style: AppTypography.button.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
