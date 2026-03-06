import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Represents every possible state the authentication layer can be in.
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any authentication check has been performed.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// An authentication operation is in progress.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// The user has been successfully authenticated.
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final User user;

  @override
  List<Object?> get props => [user.uid];
}

/// The user is not authenticated.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// The user chose to continue without signing in.
class AuthGuest extends AuthState {
  const AuthGuest();
}

/// A sign-in link was sent to the user's email.
class AuthEmailLinkSent extends AuthState {
  const AuthEmailLinkSent(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}

/// An error occurred during an authentication operation.
class AuthError extends AuthState {
  const AuthError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
