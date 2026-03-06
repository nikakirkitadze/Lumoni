import 'package:flutter/material.dart';

import 'package:lumoni/design_system/colors/app_colors.dart';
import 'package:lumoni/design_system/typography/app_typography.dart';
import 'package:lumoni/design_system/spacing.dart';

/// An attractive dismissible banner that encourages free-tier users to
/// upgrade to Lumoni Premium.
class PremiumBanner extends StatefulWidget {
  final VoidCallback onUpgrade;
  final VoidCallback? onDismiss;

  const PremiumBanner({
    super.key,
    required this.onUpgrade,
    this.onDismiss,
  });

  @override
  State<PremiumBanner> createState() => _PremiumBannerState();
}

class _PremiumBannerState extends State<PremiumBanner>
    with SingleTickerProviderStateMixin {
  bool _dismissed = false;
  late final AnimationController _dismissController;
  late final Animation<double> _fadeOut;
  late final Animation<double> _slideOut;

  @override
  void initState() {
    super.initState();
    _dismissController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _dismissController, curve: Curves.easeOut),
    );
    _slideOut = Tween<double>(begin: 0.0, end: -30.0).animate(
      CurvedAnimation(parent: _dismissController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _dismissController.dispose();
    super.dispose();
  }

  void _handleDismiss() {
    _dismissController.forward().then((_) {
      setState(() => _dismissed = true);
      widget.onDismiss?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _dismissController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeOut.value,
          child: Transform.translate(
            offset: Offset(0, _slideOut.value),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF4F46E5),
              Color(0xFF7C3AED),
              Color(0xFFEC4899),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // ── Decorative background circles ──────────────────
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -10,
              left: -10,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),

            // ── Content ────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // ── Crown icon ─────────────────────────────
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: const Icon(
                        Icons.workspace_premium,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Unlock Premium',
                            style: AppTypography.heading5.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Elevate your intelligence journey',
                            style: AppTypography.caption.copyWith(
                              color:
                                  Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ── Dismiss button ─────────────────────────
                    GestureDetector(
                      onTap: _handleDismiss,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color:
                              Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Benefits ────────────────────────────────────
                _buildBenefit(Icons.all_inclusive, 'Unlimited IQ & EQ tests'),
                const SizedBox(height: AppSpacing.xs),
                _buildBenefit(Icons.insights, 'Detailed score analytics'),
                const SizedBox(height: AppSpacing.xs),
                _buildBenefit(
                    Icons.auto_graph, 'Personalized improvement plans'),
                const SizedBox(height: AppSpacing.md),

                // ── Upgrade button ──────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onUpgrade,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                    child: Text(
                      'Upgrade Now',
                      style: AppTypography.button.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefit(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.white.withValues(alpha: 0.9),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          text,
          style: AppTypography.bodySmall.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}
