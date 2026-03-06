import 'package:flutter/material.dart';

import 'package:lumoni/design_system/colors/app_colors.dart';
import 'package:lumoni/design_system/typography/app_typography.dart';
import 'package:lumoni/design_system/spacing.dart';

/// The type of test this card represents, which determines its visual style.
enum TestCardType { iq, eq }

/// A large, tappable action card that invites the user to start an IQ or EQ
/// test. Features a gradient background, icon, title, subtitle, and a
/// press-scale animation.
class TestActionCard extends StatefulWidget {
  final TestCardType type;
  final VoidCallback onTap;

  const TestActionCard({
    super.key,
    required this.type,
    required this.onTap,
  });

  @override
  State<TestActionCard> createState() => _TestActionCardState();
}

class _TestActionCardState extends State<TestActionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0,
      upperBound: 1,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isIQ => widget.type == TestCardType.iq;

  LinearGradient get _gradient => _isIQ
      ? const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
      : const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

  IconData get _icon => _isIQ ? Icons.psychology : Icons.favorite;

  String get _title => _isIQ ? 'IQ Test' : 'EQ Test';

  String get _subtitle =>
      _isIQ ? '30 questions \u2022 15 min' : '40 statements \u2022 10 min';

  Color get _iconBackgroundColor =>
      Colors.white.withValues(alpha: 0.2);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: _gradient,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            boxShadow: [
              BoxShadow(
                color: (_isIQ ? AppColors.primary : AppColors.secondary)
                    .withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ── Icon circle ─────────────────────────────────────
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _iconBackgroundColor,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  _icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Title ───────────────────────────────────────────
              Text(
                _title,
                style: AppTypography.heading4.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),

              // ── Subtitle ────────────────────────────────────────
              Text(
                _subtitle,
                style: AppTypography.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // ── Start arrow row ─────────────────────────────────
              Row(
                children: [
                  Text(
                    'Start',
                    style: AppTypography.button.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
