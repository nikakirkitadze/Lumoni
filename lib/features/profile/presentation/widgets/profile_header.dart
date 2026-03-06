import 'package:flutter/material.dart';

import 'package:lumoni/design_system/design_system.dart';

/// Profile header widget displaying avatar, name, email, and premium badge.
///
/// Features a large circular avatar with a gradient border, display name,
/// email address, and either a premium badge or an upgrade button.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.isPremium = false,
    this.onEditPhoto,
    this.onUpgradeTap,
  });

  /// The user's display name.
  final String displayName;

  /// The user's email address.
  final String email;

  /// URL of the user's profile photo.
  final String? photoUrl;

  /// Whether the user has an active premium subscription.
  final bool isPremium;

  /// Callback when the edit photo button is tapped.
  final VoidCallback? onEditPhoto;

  /// Callback when the upgrade button is tapped.
  final VoidCallback? onUpgradeTap;

  /// Extracts initials from the display name.
  String get _initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.lg),

        // Avatar with gradient border and edit icon.
        Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(3),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.background,
                ),
                padding: const EdgeInsets.all(3),
                child: ClipOval(
                  child: _buildAvatarContent(),
                ),
              ),
            ),

            // Edit icon overlay.
            if (onEditPhoto != null)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onEditPhoto,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                      border: Border.all(
                        color: AppColors.background,
                        width: 2.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Display name.
        Text(
          displayName,
          style: AppTypography.heading3.copyWith(
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xxs),

        // Email.
        Text(
          email,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.sm),

        // Premium badge or upgrade button.
        if (isPremium)
          _buildPremiumBadge()
        else if (onUpgradeTap != null)
          _buildUpgradeButton(),

        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _buildAvatarContent() {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return Image.network(
        photoUrl!,
        width: 88,
        height: 88,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildInitialsAvatar(),
      );
    }
    return _buildInitialsAvatar();
  }

  Widget _buildInitialsAvatar() {
    return Container(
      width: 88,
      height: 88,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
      ),
      child: Center(
        child: Text(
          _initials,
          style: AppTypography.heading1.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppSpacing.borderRadiusFull,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.3),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.workspace_premium,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            'Premium',
            style: AppTypography.button.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeButton() {
    return ScaleTap(
      onTap: onUpgradeTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: AppSpacing.borderRadiusFull,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              'Upgrade to Premium',
              style: AppTypography.buttonSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
