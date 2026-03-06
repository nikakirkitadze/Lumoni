import 'package:flutter/material.dart';

import 'package:lumoni/design_system/design_system.dart';

/// A reusable settings list tile with glass card styling.
///
/// Supports a leading icon, title, optional subtitle, and either
/// a trailing arrow icon or a toggle switch.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.showArrow = true,
    this.iconColor,
    this.showDivider = true,
    this.isToggle = false,
    this.toggleValue = false,
    this.onToggleChanged,
  });

  /// Leading icon.
  final IconData icon;

  /// Title text.
  final String title;

  /// Optional subtitle text.
  final String? subtitle;

  /// Tap handler.
  final VoidCallback? onTap;

  /// Custom trailing widget (overrides default arrow/toggle).
  final Widget? trailing;

  /// Whether to show a trailing arrow. Ignored if [trailing] is provided
  /// or [isToggle] is true.
  final bool showArrow;

  /// Color for the leading icon. Defaults to [AppColors.primary].
  final Color? iconColor;

  /// Whether to show a bottom divider.
  final bool showDivider;

  /// Whether this tile displays a toggle switch instead of an arrow.
  final bool isToggle;

  /// Current toggle value (only used when [isToggle] is true).
  final bool toggleValue;

  /// Callback when the toggle changes (only used when [isToggle] is true).
  final ValueChanged<bool>? onToggleChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTap(
          onTap: isToggle ? null : onTap,
          enabled: !isToggle && onTap != null,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                // Leading icon container.
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
                    borderRadius: AppSpacing.borderRadiusMd,
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: iconColor ?? AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),

                // Title and subtitle.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Trailing widget.
                if (trailing != null)
                  trailing!
                else if (isToggle)
                  Switch.adaptive(
                    value: toggleValue,
                    onChanged: onToggleChanged,
                    activeTrackColor: AppColors.primary,
                  )
                else if (showArrow)
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.textTertiary,
                  ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 68),
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: AppColors.border.withValues(alpha: 0.5),
            ),
          ),
      ],
    );
  }
}
