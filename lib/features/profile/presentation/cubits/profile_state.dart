import 'package:equatable/equatable.dart';

import 'package:lumoni/core/models/user_model.dart';

/// Represents every possible state for the profile feature.
sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any profile data has been loaded.
final class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

/// Profile data is currently being fetched.
final class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

/// Profile data loaded successfully.
final class ProfileLoaded extends ProfileState {
  /// The current user's profile data.
  final UserModel user;

  /// Whether the user has an active premium subscription.
  final bool isPremium;

  /// Total number of completed tests across both types.
  final int testCount;

  /// The date the user joined Lumoni.
  final DateTime memberSince;

  const ProfileLoaded({
    required this.user,
    required this.isPremium,
    required this.testCount,
    required this.memberSince,
  });

  @override
  List<Object?> get props => [user, isPremium, testCount, memberSince];

  /// Returns a copy with optional field overrides.
  ProfileLoaded copyWith({
    UserModel? user,
    bool? isPremium,
    int? testCount,
    DateTime? memberSince,
  }) {
    return ProfileLoaded(
      user: user ?? this.user,
      isPremium: isPremium ?? this.isPremium,
      testCount: testCount ?? this.testCount,
      memberSince: memberSince ?? this.memberSince,
    );
  }
}

/// An error occurred while loading or updating profile data.
final class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}
