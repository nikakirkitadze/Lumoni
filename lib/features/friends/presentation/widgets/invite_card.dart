import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'package:lumoni/design_system/design_system.dart';
import 'package:lumoni/features/friends/domain/entities/friend_invite.dart';

class InviteCard extends StatelessWidget {
  const InviteCard({super.key, required this.invite});

  final FriendInvite invite;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: AppColors.accent.withValues(alpha: 0.4),
      gradient: LinearGradient(
        colors: [
          AppColors.primary.withValues(alpha: 0.15),
          AppColors.accent.withValues(alpha: 0.1),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.link_rounded,
                color: AppColors.accent,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Invite Link',
                style: AppTypography.heading6.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.6),
              borderRadius: AppSpacing.borderRadiusMd,
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              invite.code.toUpperCase(),
              style: AppTypography.heading5.copyWith(
                color: AppColors.accent,
                letterSpacing: 4,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${invite.maxUses - invite.useCount} uses remaining  •  '
            'Expires ${_expiresIn(invite.expiresAt)}',
            style: AppTypography.captionSmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Copy Code',
                  variant: AppButtonVariant.outlined,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: invite.code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Invite code copied!',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppSpacing.borderRadiusMd,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: 'Share',
                  variant: AppButtonVariant.primary,
                  onPressed: () {
                    Share.share(
                      'Join me on Lumoni! Use my invite code: '
                      '${invite.code.toUpperCase()}\n'
                      'https://lumoni.app',
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _expiresIn(DateTime expiresAt) {
    final diff = expiresAt.difference(DateTime.now());
    if (diff.isNegative) return 'expired';
    if (diff.inDays > 0) return 'in ${diff.inDays}d';
    if (diff.inHours > 0) return 'in ${diff.inHours}h';
    return 'soon';
  }
}
