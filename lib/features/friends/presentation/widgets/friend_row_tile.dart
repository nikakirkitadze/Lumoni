import 'package:flutter/material.dart';

import 'package:lumoni/design_system/design_system.dart';
import 'package:lumoni/features/friends/domain/entities/friendship.dart';

/// A tile for displaying a friend in lists with contextual actions.
class FriendRowTile extends StatelessWidget {
  const FriendRowTile({
    super.key,
    required this.friendship,
    this.onAccept,
    this.onDecline,
    this.onRemove,
    this.onBlock,
    this.onCancel,
  });

  final Friendship friendship;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onRemove;
  final VoidCallback? onBlock;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: AppSpacing.borderRadiusFull,
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(friendship.friendDisplayName ?? '?'),
              style: AppTypography.buttonSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friendship.friendDisplayName ?? 'Lumoni User',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _statusLabel(),
                  style: AppTypography.caption.copyWith(
                    color: _statusColor(),
                  ),
                ),
              ],
            ),
          ),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildActions() {
    if (friendship.isPending) {
      if (onAccept != null && onDecline != null) {
        // Incoming request
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ActionButton(
              icon: Icons.check_rounded,
              color: AppColors.success,
              onTap: onAccept!,
            ),
            const SizedBox(width: AppSpacing.xs),
            _ActionButton(
              icon: Icons.close_rounded,
              color: AppColors.error,
              onTap: onDecline!,
            ),
          ],
        );
      }
      // Outgoing request
      if (onCancel != null) {
        return _ActionButton(
          icon: Icons.close_rounded,
          color: AppColors.textTertiary,
          onTap: onCancel!,
        );
      }
    }

    // Accepted friend: popup menu
    if (friendship.isAccepted && (onRemove != null || onBlock != null)) {
      return PopupMenuButton<String>(
        icon: const Icon(
          Icons.more_vert_rounded,
          color: AppColors.textSecondary,
          size: 20,
        ),
        color: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusMd),
        itemBuilder: (_) => [
          if (onRemove != null)
            PopupMenuItem(
              value: 'remove',
              child: Text(
                'Remove Friend',
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          if (onBlock != null)
            PopupMenuItem(
              value: 'block',
              child: Text(
                'Block User',
                style: AppTypography.body.copyWith(color: AppColors.error),
              ),
            ),
        ],
        onSelected: (value) {
          if (value == 'remove') onRemove?.call();
          if (value == 'block') onBlock?.call();
        },
      );
    }

    return const SizedBox.shrink();
  }

  String _statusLabel() {
    return switch (friendship.status) {
      FriendshipStatus.pending => 'Request pending',
      FriendshipStatus.accepted => 'Friend',
      FriendshipStatus.blocked => 'Blocked',
      FriendshipStatus.declined => 'Declined',
    };
  }

  Color _statusColor() {
    return switch (friendship.status) {
      FriendshipStatus.pending => AppColors.warning,
      FriendshipStatus.accepted => AppColors.success,
      FriendshipStatus.blocked => AppColors.error,
      FriendshipStatus.declined => AppColors.textTertiary,
    };
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: AppSpacing.borderRadiusFull,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
