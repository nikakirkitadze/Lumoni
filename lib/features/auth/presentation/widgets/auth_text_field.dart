import 'package:flutter/material.dart';
import 'package:lumoni/design_system/colors/app_colors.dart';
import 'package:lumoni/design_system/typography/app_typography.dart';
import 'package:lumoni/design_system/spacing.dart';

/// A premium-styled text field with glass-like background, focus animation,
/// and optional password visibility toggle.
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.errorText,
    this.onSubmitted,
    this.autofillHints,
    this.focusNode,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final bool isPassword;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? errorText;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _focusAnimController;
  late final Animation<double> _borderAnimation;
  late final FocusNode _internalFocusNode;

  bool _obscureText = true;
  bool _isFocused = false;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = FocusNode();
    _effectiveFocusNode.addListener(_handleFocusChange);

    _focusAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _borderAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _focusAnimController, curve: Curves.easeOut),
    );
  }

  void _handleFocusChange() {
    final focused = _effectiveFocusNode.hasFocus;
    if (focused == _isFocused) return;
    setState(() => _isFocused = focused);

    if (focused) {
      _focusAnimController.forward();
    } else {
      _focusAnimController.reverse();
    }
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_handleFocusChange);
    if (widget.focusNode == null) _internalFocusNode.dispose();
    _focusAnimController.dispose();
    super.dispose();
  }

  bool get _hasError => widget.errorText != null && widget.errorText!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTypography.label.copyWith(
              color: _isFocused
                  ? AppColors.primary300
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        AnimatedBuilder(
          animation: _borderAnimation,
          builder: (context, child) {
            final borderColor = _hasError
                ? AppColors.error
                : Color.lerp(
                    AppColors.border,
                    AppColors.primary,
                    _borderAnimation.value,
                  )!;

            return Container(
              decoration: BoxDecoration(
                borderRadius: AppSpacing.borderRadiusMd,
                // Glass-like background
                color: Color.lerp(
                  AppColors.glassFill,
                  AppColors.primary.withValues(alpha: 0.06),
                  _borderAnimation.value,
                ),
                border: Border.all(
                  color: borderColor,
                  width: _isFocused ? 1.5 : 1.0,
                ),
                boxShadow: _isFocused
                    ? [
                        BoxShadow(
                          color: (_hasError ? AppColors.error : AppColors.primary)
                              .withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: child,
            );
          },
          child: TextField(
            controller: widget.controller,
            focusNode: _effectiveFocusNode,
            obscureText: widget.isPassword && _obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            autofillHints: widget.autofillHints,
            onSubmitted: widget.onSubmitted,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textPrimary,
            ),
            cursorColor: AppColors.primary,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppTypography.bodyLarge.copyWith(
                color: AppColors.textTertiary,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 16, right: 12),
                      child: Icon(
                        widget.prefixIcon,
                        size: 20,
                        color: _isFocused
                            ? AppColors.primary300
                            : AppColors.textTertiary,
                      ),
                    )
                  : null,
              prefixIconConstraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
              suffixIcon: widget.isPassword
                  ? GestureDetector(
                      onTap: () => setState(() => _obscureText = !_obscureText),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Icon(
                          _obscureText
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          size: 20,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    )
                  : null,
              suffixIconConstraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
            ),
          ),
        ),
        // Error text
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topLeft,
          child: _hasError
              ? Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.xxs,
                    left: AppSpacing.xxs,
                  ),
                  child: Text(
                    widget.errorText!,
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
