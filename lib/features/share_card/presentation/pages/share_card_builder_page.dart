import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

import 'package:lumoni/design_system/colors/app_colors.dart';
import 'package:lumoni/design_system/spacing.dart';
import 'package:lumoni/design_system/typography/app_typography.dart';
import 'package:lumoni/features/share_card/data/models/share_card_config.dart';
import 'package:lumoni/features/share_card/presentation/cubits/share_card_cubit.dart';
import 'package:lumoni/features/share_card/presentation/cubits/share_card_state.dart';
import 'package:lumoni/features/share_card/presentation/widgets/share_card_template.dart';

/// Full-screen builder page for customizing and exporting share cards.
class ShareCardBuilderPage extends StatelessWidget {
  const ShareCardBuilderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Share Card',
          style: AppTypography.heading5.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<ShareCardCubit, ShareCardState>(
        builder: (context, state) {
          if (state is ShareCardLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state is ShareCardError && state.results == null) {
            return Center(
              child: Padding(
                padding: AppSpacing.paddingAllXl,
                child: Text(
                  state.message,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (state is! ShareCardReady) {
            return const SizedBox.shrink();
          }

          return Column(
            children: [
              // Live card preview (scrollable for tall cards)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                  child: Center(
                    child: RepaintBoundary(
                      key: context.read<ShareCardCubit>().repaintBoundaryKey,
                      child: ShareCardTemplate(
                        results: state.results,
                        config: state.config,
                      ),
                    ),
                  ),
                ),
              ),

              // Customization controls
              _ControlsPanel(config: state.config),

              // Action bar
              _ActionBar(isExporting: state is ShareCardExporting),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────── Controls Panel ─────────────────────────────────────────

class _ControlsPanel extends StatelessWidget {
  const _ControlsPanel({required this.config});

  final ShareCardConfig config;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Aspect ratio selector
          _AspectRatioSelector(selected: config.aspectRatio),
          const SizedBox(height: AppSpacing.sm),

          // Style selector (horizontal scroll)
          _StyleSelector(selected: config.style),
          const SizedBox(height: AppSpacing.sm),

          // Toggle row
          _ToggleRow(config: config),
        ],
      ),
    );
  }
}

// ─────────────────── Aspect Ratio Selector ──────────────────────────────────

class _AspectRatioSelector extends StatelessWidget {
  const _AspectRatioSelector({required this.selected});

  final ShareCardAspectRatio selected;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ShareCardCubit>();

    return Row(
      children: ShareCardAspectRatio.values.map((ratio) {
        final isSelected = ratio == selected;
        return Padding(
          padding: const EdgeInsets.only(right: AppSpacing.xs),
          child: GestureDetector(
            onTap: () => cubit.setAspectRatio(ratio),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: AppSpacing.borderRadiusFull,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.5)
                      : AppColors.border,
                ),
              ),
              child: Text(
                ratio.label,
                style: AppTypography.buttonSmall.copyWith(
                  color: isSelected ? AppColors.primary300 : AppColors.textTertiary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────── Style Selector ─────────────────────────────────────────

class _StyleSelector extends StatelessWidget {
  const _StyleSelector({required this.selected});

  final ShareCardStyle selected;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ShareCardCubit>();

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ShareCardStyle.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final style = ShareCardStyle.values[index];
          final isSelected = style == selected;
          final isAccessible = cubit.isStyleAccessible(style);

          return GestureDetector(
            onTap: () {
              if (isAccessible) {
                cubit.setStyle(style);
              } else {
                _showPremiumHint(context);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 72,
              decoration: BoxDecoration(
                gradient: style.backgroundGradient,
                borderRadius: AppSpacing.borderRadiusMd,
                border: Border.all(
                  color: isSelected
                      ? style.accentColor
                      : style.borderColor.withValues(alpha: 0.5),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    style.label,
                    style: AppTypography.captionSmall.copyWith(
                      color: isSelected
                          ? style.accentColor
                          : Colors.white.withValues(alpha: 0.7),
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 10,
                    ),
                  ),
                  if (!isAccessible)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Icon(
                        Icons.lock_rounded,
                        size: 10,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPremiumHint(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Upgrade to Lumoni Pro to unlock this style',
          style: AppTypography.bodySmall.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        action: SnackBarAction(
          label: 'Upgrade',
          textColor: AppColors.primary300,
          onPressed: () => context.push('/paywall'),
        ),
      ),
    );
  }
}

// ─────────────────── Toggle Row ─────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.config});

  final ShareCardConfig config;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ShareCardCubit>();

    return Row(
      children: [
        _ToggleChip(
          label: 'Categories',
          isActive: config.showCategoryBreakdown,
          onTap: cubit.toggleCategoryBreakdown,
        ),
        const SizedBox(width: AppSpacing.xs),
        _ToggleChip(
          label: 'Percentile',
          isActive: config.showPercentile,
          onTap: cubit.togglePercentile,
        ),
      ],
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: AppSpacing.borderRadiusFull,
          border: Border.all(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 14,
              color: isActive ? AppColors.primary300 : AppColors.textTertiary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.captionSmall.copyWith(
                color: isActive ? AppColors.primary300 : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────── Action Bar ──────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.isExporting});

  final bool isExporting;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ShareCardCubit>();

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        MediaQuery.of(context).padding.bottom + AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
      ),
      child: Row(
        children: [
          // Save to gallery
          Expanded(
            child: _ActionButton(
              icon: Icons.save_alt_rounded,
              label: 'Save',
              isLoading: isExporting,
              onTap: () => _saveToGallery(context, cubit),
              isPrimary: false,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Share
          Expanded(
            flex: 2,
            child: _ActionButton(
              icon: Icons.share_rounded,
              label: 'Share',
              isLoading: isExporting,
              onTap: () => cubit.shareCard(),
              isPrimary: true,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveToGallery(
      BuildContext context, ShareCardCubit cubit) async {
    final bytes = await cubit.saveToGallery();
    if (bytes == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to capture image')),
        );
      }
      return;
    }

    try {
      await ImageGallerySaverPlus.saveImage(bytes, quality: 95);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Card saved to gallery',
              style: AppTypography.bodySmall.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.borderRadiusMd,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not save to gallery. Check photo permissions.',
              style: AppTypography.bodySmall.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isLoading,
    required this.onTap,
    required this.isPrimary,
  });

  final IconData icon;
  final String label;
  final bool isLoading;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48,
        decoration: BoxDecoration(
          gradient: isPrimary ? AppColors.primaryGradient : null,
          color: isPrimary ? null : AppColors.surfaceElevated,
          borderRadius: AppSpacing.borderRadiusMd,
          border: isPrimary
              ? null
              : Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else ...[
              Icon(
                icon,
                size: 18,
                color: isPrimary ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: AppTypography.button.copyWith(
                  color: isPrimary ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
