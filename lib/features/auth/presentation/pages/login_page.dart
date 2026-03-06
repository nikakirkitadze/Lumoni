import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lumoni/design_system/colors/app_colors.dart';
import 'package:lumoni/design_system/typography/app_typography.dart';
import 'package:lumoni/design_system/spacing.dart';
import 'package:lumoni/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:lumoni/features/auth/presentation/cubits/auth_state.dart';
import 'package:lumoni/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:lumoni/features/auth/presentation/widgets/social_sign_in_button.dart';

/// Login page with social providers (Apple/Google), email magic link, and
/// guest mode. Fully passwordless.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();

  String? _emailError;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  bool _validateEmail() {
    setState(() => _emailError = null);

    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _emailError = 'Email is required');
      return false;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      setState(() => _emailError = 'Please enter a valid email');
      return false;
    }

    return true;
  }

  void _onSendLink() {
    if (!_validateEmail()) return;

    final email = _emailController.text.trim();
    context.read<AuthCubit>().sendEmailLink(email: email);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated || state is AuthGuest) {
          context.go('/home');
        } else if (state is AuthEmailLinkSent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sign-in link sent to ${state.email}. Check your inbox!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
              shape: RoundedRectangleBorder(
                borderRadius: AppSpacing.borderRadiusSm,
              ),
              margin: const EdgeInsets.all(AppSpacing.md),
            ),
          );
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: AppSpacing.borderRadiusSm,
              ),
              margin: const EdgeInsets.all(AppSpacing.md),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // Background gradient decoration
            _LoginBackground(size: size),

            // Content
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: AppSpacing.xl,
                    right: AppSpacing.xl,
                    top: size.height * 0.06,
                    bottom: padding.bottom + AppSpacing.xl,
                  ),
                  child: Column(
                    children: [
                      // Logo & tagline
                      const _LogoSection(),
                      SizedBox(height: size.height * 0.06),

                      // Social sign-in buttons
                      _SocialSection(disabled: _isLoadingState),

                      const SizedBox(height: AppSpacing.xxl),

                      // Divider
                      const _OrDivider(),

                      const SizedBox(height: AppSpacing.xxl),

                      // Email field for magic link
                      AuthTextField(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        label: 'Email',
                        hint: 'you@example.com',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        errorText: _emailError,
                        autofillHints: const [AutofillHints.email],
                        onSubmitted: (_) => _onSendLink(),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Send link button
                      _SendLinkButton(
                        isLoading: _isLoadingState,
                        onTap: _onSendLink,
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      // Helper text
                      Text(
                        "We'll send you a sign-in link. No password needed.",
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // Continue as guest
                      _GuestLink(
                        onTap: () {
                          context.read<AuthCubit>().continueAsGuest();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _isLoadingState {
    final state = context.watch<AuthCubit>().state;
    return state is AuthLoading;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logo section with gradient text
// ─────────────────────────────────────────────────────────────────────────────

class _LogoSection extends StatelessWidget {
  const _LogoSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Custom logo using gradient text
        ShaderMask(
          shaderCallback: (bounds) => AppColors.primaryGradient.createShader(
            Rect.fromLTWH(0, 0, bounds.width, bounds.height),
          ),
          blendMode: BlendMode.srcIn,
          child: Text(
            'Lumoni',
            style: AppTypography.display.copyWith(
              fontSize: 52,
              color: Colors.white,
              letterSpacing: -2,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Discover your intelligence',
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Social sign-in section
// ─────────────────────────────────────────────────────────────────────────────

class _SocialSection extends StatelessWidget {
  const _SocialSection({required this.disabled});

  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SocialSignInButton(
          provider: SocialProvider.apple,
          onPressed: disabled
              ? null
              : () => context.read<AuthCubit>().signInWithApple(),
        ),
        const SizedBox(height: AppSpacing.sm),
        SocialSignInButton(
          provider: SocialProvider.google,
          onPressed: disabled
              ? null
              : () => context.read<AuthCubit>().signInWithGoogle(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// "or" divider
// ─────────────────────────────────────────────────────────────────────────────

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.border.withValues(alpha: 0.0),
                  AppColors.border,
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'or continue with email',
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.border,
                  AppColors.border.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Send link button
// ─────────────────────────────────────────────────────────────────────────────

class _SendLinkButton extends StatefulWidget {
  const _SendLinkButton({
    required this.isLoading,
    required this.onTap,
  });

  final bool isLoading;
  final VoidCallback onTap;

  @override
  State<_SendLinkButton> createState() => _SendLinkButtonState();
}

class _SendLinkButtonState extends State<_SendLinkButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: widget.isLoading ? null : (_) => _pressController.forward(),
        onTapUp: widget.isLoading
            ? null
            : (_) {
                _pressController.reverse();
                widget.onTap();
              },
        onTapCancel: () => _pressController.reverse(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: widget.isLoading ? null : AppColors.primaryGradient,
            color: widget.isLoading
                ? AppColors.primary.withValues(alpha: 0.5)
                : null,
            borderRadius: AppSpacing.borderRadiusMd,
            boxShadow: widget.isLoading
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: widget.isLoading
                ? const SizedBox(
                    key: ValueKey('loading'),
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Row(
                    key: const ValueKey('sendlink'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.mail_outline_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Send Sign-in Link',
                        style: AppTypography.buttonLarge.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Guest link
// ─────────────────────────────────────────────────────────────────────────────

class _GuestLink extends StatelessWidget {
  const _GuestLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Text(
          'Continue as Guest',
          style: AppTypography.button.copyWith(
            color: AppColors.textTertiary,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.textTertiary.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Background decoration
// ─────────────────────────────────────────────────────────────────────────────

class _LoginBackground extends StatelessWidget {
  const _LoginBackground({required this.size});

  final Size size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top-left gradient circle
        Positioned(
          top: -size.height * 0.1,
          left: -size.width * 0.2,
          child: Container(
            width: size.width * 0.7,
            height: size.width * 0.7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.12),
                  AppColors.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        // Bottom-right gradient circle
        Positioned(
          bottom: -size.height * 0.05,
          right: -size.width * 0.15,
          child: Container(
            width: size.width * 0.6,
            height: size.width * 0.6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.secondary.withValues(alpha: 0.08),
                  AppColors.secondary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        // Small accent glow
        Positioned(
          top: size.height * 0.3,
          right: size.width * 0.1,
          child: Container(
            width: size.width * 0.3,
            height: size.width * 0.3,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.accent.withValues(alpha: 0.06),
                  AppColors.accent.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
