import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart' show RevenueCatUI;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:lumoni/core/constants/app_constants.dart';
import 'package:lumoni/design_system/design_system.dart';
import 'package:lumoni/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:lumoni/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:lumoni/features/profile/presentation/cubits/profile_state.dart';
import 'package:lumoni/features/profile/presentation/widgets/profile_header.dart';
import 'package:lumoni/features/profile/presentation/widgets/profile_stats_row.dart';
import 'package:lumoni/features/profile/presentation/widgets/settings_tile.dart';

/// Elegant profile page with avatar, stats, settings, and account actions.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    context.read<ProfileCubit>().loadProfile();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = '${info.version} (${info.buildNumber})';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _appVersion = '1.0.0';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
          if (state is ProfileInitial) {
            // User signed out or deleted account.
            context.read<AuthCubit>().signOut();
            context.go('/login');
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state is ProfileLoaded) {
            return _buildProfileContent(context, state);
          }

          if (state is ProfileError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    state.message,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: 'Retry',
                    variant: AppButtonVariant.outlined,
                    size: AppButtonSize.medium,
                    width: 140,
                    onPressed: () =>
                        context.read<ProfileCubit>().loadProfile(),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, ProfileLoaded state) {
    return CustomScrollView(
      slivers: [
        // App bar.
        SliverAppBar(
          floating: true,
          backgroundColor: Colors.transparent,
          title: Text(
            'Profile',
            style: AppTypography.heading4.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: true,
        ),

        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile header.
              FadeSlideTransition(
                child: ProfileHeader(
                  displayName: state.user.displayName,
                  email: state.user.email,
                  photoUrl: state.user.photoUrl,
                  isPremium: state.isPremium,
                  onEditPhoto: () {
                    // TODO: Implement photo editing.
                  },
                  onUpgradeTap: () => context.push('/paywall'),
                ),
              ),

              // Stats row.
              FadeSlideTransition(
                delay: const Duration(milliseconds: 100),
                child: ProfileStatsRow(
                  testsTaken: state.testCount,
                  highestIQ: state.user.highestIQ,
                  averageEQ: state.user.averageEQ,
                  memberSince: state.memberSince,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Upgrade card (if not premium).
              if (!state.isPremium)
                FadeSlideTransition(
                  delay: const Duration(milliseconds: 150),
                  child: _buildUpgradeCard(context),
                ),

              // Account section.
              FadeSlideTransition(
                delay: const Duration(milliseconds: 200),
                child: _buildSection(
                  title: 'Account',
                  children: [
                    SettingsTile(
                      icon: Icons.person_outline_rounded,
                      title: 'Account Settings',
                      subtitle: 'Name, email, password',
                      onTap: () => _showEditNameDialog(context, state),
                    ),
                    if (state.isPremium)
                      SettingsTile(
                        icon: Icons.credit_card_outlined,
                        title: 'Manage Subscription',
                        subtitle: 'View plan, cancel, or change',
                        onTap: () => _presentCustomerCenter(context),
                      ),
                    SettingsTile(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      subtitle: 'Push notification preferences',
                      isToggle: true,
                      toggleValue: true,
                      onToggleChanged: (value) {
                        // TODO: Implement notification toggle.
                      },
                      showDivider: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // About section.
              FadeSlideTransition(
                delay: const Duration(milliseconds: 250),
                child: _buildSection(
                  title: 'About',
                  children: [
                    SettingsTile(
                      icon: Icons.shield_outlined,
                      title: 'Privacy Policy',
                      onTap: () => _launchUrl(AppConstants.privacyPolicyUrl),
                    ),
                    SettingsTile(
                      icon: Icons.description_outlined,
                      title: 'Terms of Service',
                      onTap: () => _launchUrl(AppConstants.termsOfServiceUrl),
                    ),
                    SettingsTile(
                      icon: Icons.star_outline_rounded,
                      title: 'Rate the App',
                      onTap: () {
                        // TODO: Implement app rating.
                      },
                    ),
                    SettingsTile(
                      icon: Icons.share_outlined,
                      title: 'Share with Friends',
                      onTap: () {
                        Share.share(
                          'Check out Lumoni - the premium intelligence platform! https://lumoni.app',
                        );
                      },
                    ),
                    SettingsTile(
                      icon: Icons.info_outline_rounded,
                      title: 'App Version',
                      subtitle: _appVersion.isNotEmpty ? _appVersion : null,
                      showArrow: false,
                      showDivider: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Sign Out button.
              FadeSlideTransition(
                delay: const Duration(milliseconds: 300),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: OutlinedButton(
                    onPressed: () => _showSignOutDialog(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(
                        color: AppColors.error,
                        width: 1.5,
                      ),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSpacing.borderRadiusMd,
                      ),
                    ),
                    child: Text(
                      'Sign Out',
                      style: AppTypography.button.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Delete Account.
              FadeSlideTransition(
                delay: const Duration(milliseconds: 350),
                child: Center(
                  child: TextButton(
                    onPressed: () => _showDeleteAccountDialog(context),
                    child: Text(
                      'Delete Account',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom safe area padding.
              SizedBox(
                height: MediaQuery.of(context).padding.bottom + AppSpacing.xxxl,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpgradeCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: GlassCard(
        onTap: () => context.push('/paywall'),
        gradient: AppColors.primaryGradient,
        borderColor: AppColors.primary.withValues(alpha: 0.3),
        padding: const EdgeInsets.all(AppSpacing.lg),
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upgrade to Premium',
                    style: AppTypography.heading6.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Unlock unlimited tests, deep analytics, and AI insights',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTypography.overline.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          GlassCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _presentCustomerCenter(BuildContext context) async {
    await RevenueCatUI.presentCustomerCenter();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Sign Out',
          style: AppTypography.heading5.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: AppTypography.body.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: AppTypography.button.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<ProfileCubit>().signOut();
            },
            child: Text(
              'Sign Out',
              style: AppTypography.button.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Delete Account',
          style: AppTypography.heading5.copyWith(
            color: AppColors.error,
          ),
        ),
        content: Text(
          'This action is permanent and cannot be undone. '
          'All your data, test results, and progress will be permanently deleted.',
          style: AppTypography.body.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: AppTypography.button.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<ProfileCubit>().deleteAccount();
            },
            child: Text(
              'Delete',
              style: AppTypography.button.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog(BuildContext context, ProfileLoaded state) {
    final controller = TextEditingController(text: state.user.displayName);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Edit Name',
          style: AppTypography.heading5.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTypography.body.copyWith(
            color: AppColors.textPrimary,
          ),
          decoration: const InputDecoration(
            hintText: 'Enter your name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: AppTypography.button.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty && name != state.user.displayName) {
                context.read<ProfileCubit>().updateDisplayName(name);
              }
              Navigator.of(dialogContext).pop();
            },
            child: Text(
              'Save',
              style: AppTypography.button.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
