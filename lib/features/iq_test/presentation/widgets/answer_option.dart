import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lumoni/design_system/colors/app_colors.dart';
import 'package:lumoni/design_system/spacing.dart';
import 'package:lumoni/design_system/typography/app_typography.dart';

/// Visual state of an answer option.
enum AnswerOptionState {
  /// Default unselected state.
  idle,

  /// User has selected this answer.
  selected,

  /// Revealed as the correct answer.
  correct,

  /// Revealed as an incorrect answer (selected by the user).
  wrong,
}

/// A selectable answer card with letter label (A/B/C/D), glassmorphism style,
/// and animated state transitions.
class AnswerOption extends StatefulWidget {
  const AnswerOption({
    super.key,
    required this.index,
    required this.text,
    required this.onTap,
    this.optionState = AnswerOptionState.idle,
    this.isEnabled = true,
  });

  /// Zero-based index (0 = A, 1 = B, 2 = C, 3 = D).
  final int index;

  /// Answer text.
  final String text;

  /// Tap callback.
  final VoidCallback onTap;

  /// Current visual state.
  final AnswerOptionState optionState;

  /// Whether the option can be tapped.
  final bool isEnabled;

  @override
  State<AnswerOption> createState() => _AnswerOptionState();
}

class _AnswerOptionState extends State<AnswerOption>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  static const _letters = ['A', 'B', 'C', 'D', 'E', 'F'];

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  String get _letter =>
      widget.index < _letters.length ? _letters[widget.index] : '?';

  Color get _borderColor {
    switch (widget.optionState) {
      case AnswerOptionState.idle:
        return AppColors.glassBorder;
      case AnswerOptionState.selected:
        return AppColors.primary;
      case AnswerOptionState.correct:
        return AppColors.success;
      case AnswerOptionState.wrong:
        return AppColors.error;
    }
  }

  Color get _backgroundColor {
    switch (widget.optionState) {
      case AnswerOptionState.idle:
        return AppColors.glassFill;
      case AnswerOptionState.selected:
        return AppColors.primary.withValues(alpha: 0.12);
      case AnswerOptionState.correct:
        return AppColors.success.withValues(alpha: 0.12);
      case AnswerOptionState.wrong:
        return AppColors.error.withValues(alpha: 0.12);
    }
  }

  Color get _letterBackgroundColor {
    switch (widget.optionState) {
      case AnswerOptionState.idle:
        return AppColors.surface;
      case AnswerOptionState.selected:
        return AppColors.primary;
      case AnswerOptionState.correct:
        return AppColors.success;
      case AnswerOptionState.wrong:
        return AppColors.error;
    }
  }

  Color get _letterTextColor {
    switch (widget.optionState) {
      case AnswerOptionState.idle:
        return AppColors.textSecondary;
      case AnswerOptionState.selected:
      case AnswerOptionState.correct:
      case AnswerOptionState.wrong:
        return AppColors.textOnPrimary;
    }
  }

  Color get _textColor {
    switch (widget.optionState) {
      case AnswerOptionState.idle:
        return AppColors.textPrimary;
      case AnswerOptionState.selected:
        return AppColors.textPrimary;
      case AnswerOptionState.correct:
        return AppColors.success;
      case AnswerOptionState.wrong:
        return AppColors.error;
    }
  }

  IconData? get _trailingIcon {
    switch (widget.optionState) {
      case AnswerOptionState.correct:
        return Icons.check_circle_rounded;
      case AnswerOptionState.wrong:
        return Icons.cancel_rounded;
      default:
        return null;
    }
  }

  void _handleTapDown(TapDownDetails _) {
    if (!widget.isEnabled) return;
    _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    _scaleController.reverse();
  }

  void _handleTapCancel() {
    _scaleController.reverse();
  }

  void _handleTap() {
    if (!widget.isEnabled) return;
    HapticFeedback.selectionClick();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
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
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: AppSpacing.borderRadiusMd,
            border: Border.all(
              color: _borderColor,
              width: widget.optionState == AnswerOptionState.idle ? 1 : 1.5,
            ),
            boxShadow: widget.optionState == AnswerOptionState.selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Letter badge
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _letterBackgroundColor,
                  shape: BoxShape.circle,
                  border: widget.optionState == AnswerOptionState.idle
                      ? Border.all(color: AppColors.border, width: 1)
                      : null,
                ),
                child: Center(
                  child: Text(
                    _letter,
                    style: AppTypography.button.copyWith(
                      color: _letterTextColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Answer text
              Expanded(
                child: Text(
                  widget.text,
                  style: AppTypography.body.copyWith(
                    color: _textColor,
                    fontWeight:
                        widget.optionState != AnswerOptionState.idle
                            ? FontWeight.w500
                            : FontWeight.w400,
                  ),
                ),
              ),

              // Trailing icon for correct/wrong states
              if (_trailingIcon != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  _trailingIcon,
                  color: widget.optionState == AnswerOptionState.correct
                      ? AppColors.success
                      : AppColors.error,
                  size: 22,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
