import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lumoni/design_system/colors/app_colors.dart';
import 'package:lumoni/design_system/spacing.dart';
import 'package:lumoni/design_system/typography/app_typography.dart';

/// A single option within the Likert scale.
class _LikertOption {
  final int value;
  final String label;
  final String shortLabel;

  const _LikertOption({
    required this.value,
    required this.label,
    required this.shortLabel,
  });
}

/// The five standard Likert-scale options.
const List<_LikertOption> _kLikertOptions = [
  _LikertOption(value: 1, label: 'Strongly Disagree', shortLabel: 'SD'),
  _LikertOption(value: 2, label: 'Disagree', shortLabel: 'D'),
  _LikertOption(value: 3, label: 'Neutral', shortLabel: 'N'),
  _LikertOption(value: 4, label: 'Agree', shortLabel: 'A'),
  _LikertOption(value: 5, label: 'Strongly Agree', shortLabel: 'SA'),
];

/// A beautiful Likert scale widget with animated pill options.
///
/// Each of the 5 options is displayed as a tappable pill with a label.
/// The selected option animates with a gradient fill.
class LikertScale extends StatelessWidget {
  const LikertScale({
    super.key,
    required this.onSelected,
    this.selectedValue,
    this.layout = LikertLayout.vertical,
  });

  /// Callback when the user selects a value (1-5).
  final ValueChanged<int> onSelected;

  /// The currently selected Likert value, or null if none selected.
  final int? selectedValue;

  /// Whether to display the options in a row or column.
  final LikertLayout layout;

  @override
  Widget build(BuildContext context) {
    final options = _kLikertOptions.map((option) {
      return _LikertPill(
        option: option,
        isSelected: selectedValue == option.value,
        onTap: () {
          HapticFeedback.lightImpact();
          onSelected(option.value);
        },
        layout: layout,
      );
    }).toList();

    if (layout == LikertLayout.horizontal) {
      return Row(
        children: options
            .expand((pill) => [
                  Expanded(child: pill),
                  const SizedBox(width: AppSpacing.xs),
                ])
            .toList()
          ..removeLast(), // Remove trailing spacer.
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: options
          .expand((pill) => [
                pill,
                const SizedBox(height: AppSpacing.sm),
              ])
          .toList()
        ..removeLast(), // Remove trailing spacer.
    );
  }
}

/// Layout direction for the Likert scale.
enum LikertLayout {
  horizontal,
  vertical,
}

/// An individual selectable pill for one Likert value.
class _LikertPill extends StatefulWidget {
  const _LikertPill({
    required this.option,
    required this.isSelected,
    required this.onTap,
    required this.layout,
  });

  final _LikertOption option;
  final bool isSelected;
  final VoidCallback onTap;
  final LikertLayout layout;

  @override
  State<_LikertPill> createState() => _LikertPillState();
}

class _LikertPillState extends State<_LikertPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) => _controller.forward();
  void _handleTapUp(TapUpDetails _) => _controller.reverse();
  void _handleTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: widget.layout == LikertLayout.vertical
              ? const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                )
              : const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.sm,
                ),
          decoration: BoxDecoration(
            gradient: isSelected ? _selectedGradient : null,
            color: isSelected ? null : AppColors.surface,
            borderRadius: AppSpacing.borderRadiusMd,
            border: Border.all(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.6)
                  : AppColors.border.withValues(alpha: 0.4),
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: widget.layout == LikertLayout.vertical
              ? _buildVerticalContent(isSelected)
              : _buildHorizontalContent(isSelected),
        ),
      ),
    );
  }

  Widget _buildVerticalContent(bool isSelected) {
    return Row(
      children: [
        // Numbered circle indicator.
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected
                ? Colors.white.withValues(alpha: 0.2)
                : AppColors.surfaceElevated,
            border: Border.all(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.3)
                  : AppColors.border,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              '${widget.option.value}',
              style: AppTypography.labelSmall.copyWith(
                color: isSelected
                    ? Colors.white
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Label text.
        Expanded(
          child: Text(
            widget.option.label,
            style: AppTypography.bodyMedium.copyWith(
              color: isSelected
                  ? Colors.white
                  : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
        // Check indicator for selected state.
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isSelected ? 1.0 : 0.0,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalContent(bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${widget.option.value}',
          style: AppTypography.heading6.copyWith(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          widget.option.shortLabel,
          style: AppTypography.captionSmall.copyWith(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.8)
                : AppColors.textTertiary,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Gradient applied to the selected pill.
  LinearGradient get _selectedGradient {
    return LinearGradient(
      colors: [
        AppColors.primary.withValues(alpha: 0.8),
        AppColors.secondary.withValues(alpha: 0.7),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
