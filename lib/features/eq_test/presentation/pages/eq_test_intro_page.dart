import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:lumoni/core/constants/app_constants.dart';
import 'package:lumoni/design_system/colors/app_colors.dart';
import 'package:lumoni/design_system/components/app_button.dart';
import 'package:lumoni/design_system/components/glass_card.dart';
import 'package:lumoni/design_system/spacing.dart';
import 'package:lumoni/design_system/typography/app_typography.dart';
import 'package:lumoni/features/eq_test/presentation/cubits/eq_test_cubit.dart';

/// Pre-test introduction page for the EQ Assessment.
///
/// Displays the title, description, the five EQ categories being measured,
/// instructions, and a "Begin Assessment" button.
class EQTestIntroPage extends StatelessWidget {
  const EQTestIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar with back button ──
            _TopBar(onBack: () => context.pop()),

            // ── Scrollable content ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                ),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: AppSpacing.lg),

                    // Heart icon with glow.
                    _HeroIcon(),

                    const SizedBox(height: AppSpacing.xl),

                    // Title.
                    Text(
                      'EQ Assessment',
                      style: AppTypography.heading1.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // Description.
                    Text(
                      'Emotional intelligence is the ability to recognize, '
                      'understand, and manage your own emotions, as well as '
                      'to perceive, interpret, and influence the emotions of '
                      'others. It plays a vital role in personal well-being, '
                      'relationships, and professional success.',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // Section label.
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'WHAT WE MEASURE',
                        style: AppTypography.overline.copyWith(
                          color: AppColors.accent,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Category cards.
                    ..._kCategories.map((cat) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.sm,
                          ),
                          child: _CategoryCard(
                            icon: cat.icon,
                            label: cat.label,
                            description: cat.description,
                            color: cat.color,
                          ),
                        )),

                    const SizedBox(height: AppSpacing.xxl),

                    // Instructions card.
                    _InstructionsCard(),

                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ),

            // ── Bottom action ──
            _BottomAction(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────── Top Bar ─────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onBack();
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.5),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const Spacer(),
          // Estimated time badge.
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs + 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppSpacing.borderRadiusFull,
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: AppSpacing.xxs),
                Text(
                  '~10 min',
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── Hero Icon ──────────────────────────────────────

class _HeroIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.secondary.withValues(alpha: 0.3),
            const Color(0xFFEC4899).withValues(alpha: 0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.2),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.favorite_rounded,
          size: 40,
          color: Color(0xFFEC4899),
        ),
      ),
    );
  }
}

// ─────────────────────── Category Card ──────────────────────────────────

class _CategoryInfo {
  final IconData icon;
  final String label;
  final String description;
  final Color color;

  const _CategoryInfo({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
  });
}

const List<_CategoryInfo> _kCategories = [
  _CategoryInfo(
    icon: Icons.visibility_rounded,
    label: 'Self-Awareness',
    description: 'Recognizing your emotions and their impact on thoughts and behavior',
    color: AppColors.accent,
  ),
  _CategoryInfo(
    icon: Icons.shield_rounded,
    label: 'Self-Regulation',
    description: 'Managing disruptive impulses and adapting to changing circumstances',
    color: AppColors.success,
  ),
  _CategoryInfo(
    icon: Icons.bolt_rounded,
    label: 'Motivation',
    description: 'Inner drive to achieve, optimism, and commitment to goals',
    color: AppColors.warning,
  ),
  _CategoryInfo(
    icon: Icons.favorite_rounded,
    label: 'Empathy',
    description: 'Understanding the emotional makeup of others and treating them accordingly',
    color: Color(0xFFEC4899),
  ),
  _CategoryInfo(
    icon: Icons.people_rounded,
    label: 'Social Skills',
    description: 'Building rapport, managing relationships, and inspiring others',
    color: AppColors.info,
  ),
];

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // Icon container.
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppSpacing.borderRadiusMd,
              border: Border.all(
                color: color.withValues(alpha: 0.2),
              ),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          // Text content.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.heading6.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── Instructions Card ──────────────────────────────

class _InstructionsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: AppColors.accent.withValues(alpha: 0.8),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'How it works',
                style: AppTypography.heading6.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _InstructionItem(
            number: '1',
            text: 'Read each statement carefully and honestly',
          ),
          const SizedBox(height: AppSpacing.sm),
          _InstructionItem(
            number: '2',
            text: 'Rate how much you agree on a scale of 1 to 5',
          ),
          const SizedBox(height: AppSpacing.sm),
          _InstructionItem(
            number: '3',
            text: 'There are no right or wrong answers',
          ),
          const SizedBox(height: AppSpacing.sm),
          _InstructionItem(
            number: '4',
            text: 'Take your time - this assessment is not timed',
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              borderRadius: AppSpacing.borderRadiusSm,
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.format_list_numbered_rounded,
                  size: 16,
                  color: AppColors.accent.withValues(alpha: 0.8),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    '${AppConstants.maxEQQuestions} statements across 5 categories',
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionItem extends StatelessWidget {
  const _InstructionItem({
    required this.number,
    required this.text,
  });

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.12),
          ),
          child: Center(
            child: Text(
              number,
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────── Bottom Action ──────────────────────────────────

class _BottomAction extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(
            color: AppColors.border.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: AppButton(
        label: 'Begin Assessment',
        icon: Icons.play_arrow_rounded,
        onPressed: () {
          HapticFeedback.mediumImpact();
          context.read<EQTestCubit>().startTest();
          context.push('/eq-test');
        },
      ),
    );
  }
}
