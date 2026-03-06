import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Custom exception for authentication errors.
class AuthException implements Exception {
  final String message;
  final String? code;

  const AuthException(this.message, {this.code});

  @override
  String toString() => 'AuthException($code): $message';
}

/// Service wrapping [FirebaseAuth] with Google, Apple, and email sign-in.
class AuthService {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              clientId:
                  '396928377391-fakscqo8upiq4udh0h857evubg26eviq.apps.googleusercontent.com',
            );

  // ──────────────────────── Streams ────────────────────────────────────

  /// Stream of [User] changes (sign-in, sign-out, token refresh).
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Stream that also fires on ID token changes.
  Stream<User?> get idTokenChanges => _firebaseAuth.idTokenChanges();

  // ──────────────────────── Current User ───────────────────────────────

  /// The currently signed-in user, or null.
  User? get currentUser => _firebaseAuth.currentUser;

  /// Whether a user is currently signed in.
  bool get isSignedIn => currentUser != null;

  // ──────────────────────── Google Sign-In ─────────────────────────────

  /// Signs in with a Google account.
  ///
  /// Returns the signed-in [User]. Throws [AuthException] on failure.
  Future<User> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthException(
          'Google sign-in was cancelled by the user.',
          code: 'google-sign-in-cancelled',
        );
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        throw const AuthException(
          'Failed to retrieve user after Google sign-in.',
          code: 'google-sign-in-no-user',
        );
      }

      return user;
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        e.message ?? 'Google sign-in failed.',
        code: e.code,
      );
    } catch (e) {
      throw AuthException('Google sign-in failed: $e');
    }
  }

  // ──────────────────────── Apple Sign-In ──────────────────────────────

  /// Signs in with Apple. Only available on iOS/macOS.
  ///
  /// Returns the signed-in [User]. Throws [AuthException] on failure.
  Future<User> signInWithApple() async {
    try {
      if (!Platform.isIOS && !Platform.isMacOS) {
        throw const AuthException(
          'Apple sign-in is only available on iOS and macOS.',
          code: 'apple-sign-in-unsupported',
        );
      }

      final rawNonce = generateNonce();
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256ofString(rawNonce),
      );

      final oAuthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(oAuthCredential);
      final user = userCredential.user;

      if (user == null) {
        throw const AuthException(
          'Failed to retrieve user after Apple sign-in.',
          code: 'apple-sign-in-no-user',
        );
      }

      // Apple only provides the name on the first sign-in. Persist it.
      final givenName = appleCredential.givenName;
      if (givenName != null && givenName.isNotEmpty) {
        final fullName =
            '$givenName ${appleCredential.familyName ?? ''}'.trim();
        if (fullName.isNotEmpty) {
          await user.updateDisplayName(fullName);
          await user.reload();
        }
      }

      return _firebaseAuth.currentUser ?? user;
    } on AuthException {
      rethrow;
    } on SignInWithAppleAuthorizationException catch (e) {
      throw AuthException(
        'Apple sign-in failed: ${e.message}',
        code: 'apple-sign-in-authorization-error',
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        e.message ?? 'Apple sign-in failed.',
        code: e.code,
      );
    } catch (e) {
      throw AuthException('Apple sign-in failed: $e');
    }
  }

  // ──────────────────────── Email Link (Passwordless) ──────────────────

  /// Sends a sign-in link to the given [email].
  ///
  /// The user taps the link in their inbox to authenticate — no password needed.
  Future<void> sendSignInLink({required String email}) async {
    try {
      final actionCodeSettings = ActionCodeSettings(
        url: 'https://build-x-36c66.firebaseapp.com/emailSignIn',
        handleCodeInApp: true,
        iOSBundleId: 'ge.grich.lumoni',
        androidPackageName: 'ge.grich.lumoni',
        androidInstallApp: true,
        androidMinimumVersion: '21',
      );

      await _firebaseAuth.sendSignInLinkToEmail(
        email: email.trim(),
        actionCodeSettings: actionCodeSettings,
      );
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to send sign-in link: $e');
    }
  }

  /// Returns `true` if [link] is a valid Firebase email sign-in link.
  bool isSignInLink(String link) {
    return _firebaseAuth.isSignInWithEmailLink(link);
  }

  /// Completes the sign-in using the [email] and the magic [link].
  Future<User> signInWithEmailLink({
    required String email,
    required String link,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailLink(
        email: email.trim(),
        emailLink: link,
      );
      final user = userCredential.user;

      if (user == null) {
        throw const AuthException(
          'Failed to retrieve user after email link sign-in.',
          code: 'email-link-no-user',
        );
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Email link sign-in failed: $e');
    }
  }

  // ──────────────────────── Email/Password Sign-In ─────────────────────

  /// Signs in with email and password.
  ///
  /// Returns the signed-in [User]. Throws [AuthException] on failure.
  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = userCredential.user;

      if (user == null) {
        throw const AuthException(
          'Failed to retrieve user after email sign-in.',
          code: 'email-sign-in-no-user',
        );
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Email sign-in failed: $e');
    }
  }

  // ──────────────────────── Sign-Up ────────────────────────────────────

  /// Creates a new account with email, password, and optional display name.
  ///
  /// Returns the newly created [User]. Throws [AuthException] on failure.
  Future<User> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = userCredential.user;

      if (user == null) {
        throw const AuthException(
          'Failed to create user account.',
          code: 'sign-up-no-user',
        );
      }

      if (displayName != null && displayName.isNotEmpty) {
        await user.updateDisplayName(displayName);
        await user.reload();
      }

      return _firebaseAuth.currentUser ?? user;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Sign-up failed: $e');
    }
  }

  // ──────────────────────── Password Reset ─────────────────────────────

  /// Sends a password-reset email to [email].
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      throw AuthException('Password reset failed: $e');
    }
  }

  // ──────────────────────── Sign-Out ───────────────────────────────────

  /// Signs the current user out of all providers.
  Future<void> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      debugPrint('[AuthService] Error during sign-out: $e');
      // Ensure Firebase sign-out even if Google fails.
      await _firebaseAuth.signOut();
    }
  }

  // ──────────────────────── Delete Account ─────────────────────────────

  /// Permanently deletes the current user's account.
  ///
  /// The user may need to re-authenticate first if their session is stale.
  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) {
      throw const AuthException(
        'No user is currently signed in.',
        code: 'no-current-user',
      );
    }

    try {
      await user.delete();
      await _googleSignIn.signOut();
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Account deletion failed: $e');
    }
  }

  // ──────────────────────── Helpers ────────────────────────────────────

  /// Maps [FirebaseAuthException] to a user-friendly [AuthException].
  AuthException _mapFirebaseAuthException(FirebaseAuthException e) {
    final String message;
    switch (e.code) {
      case 'user-not-found':
        message = 'No account found with this email address.';
      case 'wrong-password':
        message = 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        message = 'An account with this email already exists.';
      case 'invalid-email':
        message = 'Please enter a valid email address.';
      case 'weak-password':
        message = 'Password is too weak. Use at least 6 characters.';
      case 'user-disabled':
        message = 'This account has been disabled.';
      case 'too-many-requests':
        message = 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        message = 'This sign-in method is not enabled.';
      case 'network-request-failed':
        message = 'Network error. Please check your connection.';
      case 'requires-recent-login':
        message = 'Please sign in again to complete this action.';
      case 'invalid-credential':
        message = 'Invalid credentials. Please try again.';
      default:
        message = e.message ?? 'An authentication error occurred.';
    }
    return AuthException(message, code: e.code);
  }
}

/// Generates a cryptographically secure random nonce.
String generateNonce([int length = 32]) {
  const charset =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  final random = Random.secure();
  return List.generate(length, (_) => charset[random.nextInt(charset.length)])
      .join();
}

/// Returns the SHA-256 hash of [input] as a hex string.
String sha256ofString(String input) {
  final bytes = utf8.encode(input);
  final digest = sha256.convert(bytes);
  return digest.toString();
}
