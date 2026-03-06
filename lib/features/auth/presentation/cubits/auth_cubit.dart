import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumoni/core/constants/app_constants.dart';
import 'package:lumoni/core/di/injection.dart';
import 'package:lumoni/core/services/auth_service.dart';
import 'package:lumoni/core/services/firebase_service.dart';
import 'package:lumoni/core/services/local_storage_service.dart';
import 'package:lumoni/features/auth/presentation/cubits/auth_state.dart';

/// Manages authentication state and delegates to [AuthService].
class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthInitial());

  /// Lazily resolved so the cubit can be created even when Firebase
  /// is not yet initialised (e.g. missing GoogleService-Info.plist).
  AuthService? _authServiceCache;

  AuthService? get _authService {
    if (_authServiceCache != null) return _authServiceCache;
    if (!FirebaseService.instance.isInitialized) return null;
    try {
      _authServiceCache = getIt<AuthService>();
      return _authServiceCache;
    } catch (e) {
      debugPrint('[AuthCubit] Could not resolve AuthService: $e');
      return null;
    }
  }

  // ──────────────────── Auth Status ────────────────────────────────────────

  /// Checks the current authentication status from the underlying service
  /// and emits the appropriate state.
  Future<void> checkAuthStatus() async {
    emit(const AuthLoading());
    try {
      final service = _authService;
      if (service == null) {
        emit(const AuthUnauthenticated());
        return;
      }
      final user = service.currentUser;
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(_userFriendlyMessage(e)));
    }
  }

  // ──────────────────── Google Sign-In ─────────────────────────────────────

  /// Initiates the Google sign-in flow.
  Future<void> signInWithGoogle() async {
    emit(const AuthLoading());
    try {
      final service = _authService;
      if (service == null) {
        emit(const AuthError('Authentication service is not available.'));
        return;
      }
      final user = await service.signInWithGoogle();
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(_userFriendlyMessage(e)));
    }
  }

  // ──────────────────── Apple Sign-In ──────────────────────────────────────

  /// Initiates the Apple sign-in flow.
  Future<void> signInWithApple() async {
    emit(const AuthLoading());
    try {
      final service = _authService;
      if (service == null) {
        emit(const AuthError('Authentication service is not available.'));
        return;
      }
      final user = await service.signInWithApple();
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(_userFriendlyMessage(e)));
    }
  }

  // ──────────────────── Email Link (Passwordless) ─────────────────────────

  /// Sends a passwordless sign-in link to the given [email].
  Future<void> sendEmailLink({required String email}) async {
    emit(const AuthLoading());
    try {
      final service = _authService;
      if (service == null) {
        emit(const AuthError('Authentication service is not available.'));
        return;
      }
      await service.sendSignInLink(email: email);
      // Store the email so we can complete sign-in when the link is opened.
      try {
        final storage = getIt<LocalStorageService>();
        if (storage.isInitialized) {
          await storage.setPreference(
            AppConstants.keyPendingEmailLink,
            email.trim(),
          );
        }
      } catch (_) {}
      emit(AuthEmailLinkSent(email));
    } catch (e) {
      debugPrint('[AuthCubit] sendEmailLink error: $e');
      emit(AuthError(_userFriendlyMessage(e)));
    }
  }

  /// Handles an incoming deep link. If it's a Firebase email sign-in link,
  /// completes the sign-in using the stored email.
  Future<void> handleIncomingLink(String link) async {
    final service = _authService;
    if (service == null) return;

    if (!service.isSignInLink(link)) return;

    // Retrieve the stored email.
    String? email;
    try {
      final storage = getIt<LocalStorageService>();
      if (storage.isInitialized) {
        email = storage.getPreference<String>(AppConstants.keyPendingEmailLink);
      }
    } catch (_) {}

    if (email == null || email.isEmpty) {
      emit(const AuthError('Could not find the email for this sign-in link. Please try again.'));
      return;
    }

    emit(const AuthLoading());
    try {
      final user = await service.signInWithEmailLink(
        email: email,
        link: link,
      );
      // Clear the stored email after successful sign-in.
      try {
        final storage = getIt<LocalStorageService>();
        if (storage.isInitialized) {
          await storage.setPreference(AppConstants.keyPendingEmailLink, null);
        }
      } catch (_) {}
      emit(AuthAuthenticated(user));
    } catch (e) {
      debugPrint('[AuthCubit] handleIncomingLink error: $e');
      emit(AuthError(_userFriendlyMessage(e)));
    }
  }

  // ──────────────────── Email / Password ───────────────────────────────────

  /// Signs in with email and password.
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());
    try {
      final service = _authService;
      if (service == null) {
        emit(const AuthError('Authentication service is not available.'));
        return;
      }
      final user = await service.signInWithEmail(
        email: email,
        password: password,
      );
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(_userFriendlyMessage(e)));
    }
  }

  /// Creates a new account with email and password.
  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());
    try {
      final service = _authService;
      if (service == null) {
        emit(const AuthError('Authentication service is not available.'));
        return;
      }
      final user = await service.signUp(
        email: email,
        password: password,
      );
      emit(AuthAuthenticated(user));
    } catch (e) {
      debugPrint('[AuthCubit] signUp error: $e');
      emit(AuthError(_userFriendlyMessage(e)));
    }
  }

  // ──────────────────── Sign Out ───────────────────────────────────────────

  /// Signs the current user out and transitions to [AuthUnauthenticated].
  Future<void> signOut() async {
    emit(const AuthLoading());
    try {
      await _authService?.signOut();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(_userFriendlyMessage(e)));
    }
  }

  // ──────────────────── Guest Mode ─────────────────────────────────────────

  /// Continues without an account, emitting [AuthGuest].
  void continueAsGuest() {
    emit(const AuthGuest());
  }

  // ──────────────────── Helpers ────────────────────────────────────────────

  /// Converts raw exceptions to user-friendly messages.
  String _userFriendlyMessage(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('user-not-found') ||
        message.contains('wrong-password') ||
        message.contains('invalid-credential')) {
      return 'Invalid email or password. Please try again.';
    }
    if (message.contains('email-already-in-use')) {
      return 'An account already exists with this email.';
    }
    if (message.contains('weak-password')) {
      return 'Password is too weak. Use at least 6 characters.';
    }
    if (message.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    if (message.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later.';
    }
    if (message.contains('network')) {
      return 'Network error. Check your connection and try again.';
    }
    if (message.contains('cancelled') || message.contains('canceled')) {
      return 'Sign-in was cancelled.';
    }
    return 'Something went wrong. Please try again.';
  }
}
