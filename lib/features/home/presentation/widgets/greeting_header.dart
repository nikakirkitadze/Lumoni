import 'package:flutter/material.dart';

import 'package:lumoni/design_system/colors/app_colors.dart';
import 'package:lumoni/design_system/typography/app_typography.dart';
import 'package:lumoni/design_system/spacing.dart';

/// Displays a time-appropriate greeting, the user's name, an optional
/// premium badge, and a notification bell icon.
class GreetingHeader extends StatelessWidget {
  final String displayName;
  final String? photoUrl;
  final bool isPremium;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAvatarTap;

  const GreetingHeader({
    super.key,
    required this.displayName,
    this.photoUrl,
    this.isPremium = false,
    this.onNotificationTap,
    this.onAvatarTap,
  });

  /// Returns a greeting string based on the current hour.
  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// Extracts initials from the display name for the avatar fallback.
  String get _initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          // ── Avatar ──────────────────────────────────────────────
          GestureDetector(
            onTap: onAvatarTap,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: photoUrl != null && photoUrl!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        photoUrl!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _buildInitials(),
                      ),
                    )
                  : _buildInitials(),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // ── Greeting text ───────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _greeting,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        style: AppTypography.heading4.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isPremium) ...[
                      const SizedBox(width: AppSpacing.xs),
                      _buildPremiumBadge(),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // ── Notification bell ───────────────────────────────────
          _buildNotificationButton(),
        ],
      ),
    );
  }

  Widget _buildInitials() {
    return Center(
      child: Text(
        _initials,
        style: AppTypography.button.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildPremiumBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.workspace_premium,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 2),
          Text(
            'PRO',
            style: AppTypography.captionSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationButton() {
    return GestureDetector(
      onTap: onNotificationTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: AppColors.border,
            width: 1,
          ),
        ),
        child: const Icon(
          Icons.notifications_outlined,
          color: AppColors.textSecondary,
          size: 22,
        ),
      ),
    );
  }
}
