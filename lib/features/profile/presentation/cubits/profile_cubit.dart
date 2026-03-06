import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lumoni/core/di/injection.dart';
import 'package:lumoni/core/services/auth_service.dart';
import 'package:lumoni/core/services/firestore_service.dart';
import 'package:lumoni/core/services/subscription_service.dart';
import 'package:lumoni/features/profile/presentation/cubits/profile_state.dart';

/// Manages the profile feature state.
///
/// Loads user profile data from Firestore, handles sign-out,
/// account deletion, and display name updates.
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit() : super(const ProfileInitial());

  final AuthService _authService = getIt<AuthService>();
  final FirestoreService _firestoreService = getIt<FirestoreService>();
  final SubscriptionService _subscriptionService = getIt<SubscriptionService>();

  /// Loads the current user's profile from Firestore.
  ///
  /// Emits [ProfileLoading] immediately, then [ProfileLoaded] on success
  /// or [ProfileError] on failure.
  Future<void> loadProfile() async {
    emit(const ProfileLoading());

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        emit(const ProfileError('No user is currently signed in.'));
        return;
      }

      final user = await _firestoreService.getUser(currentUser.uid);
      if (user == null) {
        emit(const ProfileError('User profile not found.'));
        return;
      }

      final isPremium = _subscriptionService.isPremium;

      emit(ProfileLoaded(
        user: user,
        isPremium: isPremium,
        testCount: user.totalTests,
        memberSince: user.createdAt,
      ));
    } catch (e) {
      debugPrint('[ProfileCubit] Error loading profile: $e');
      emit(ProfileError(_friendlyMessage(e)));
    }
  }

  /// Signs the current user out and emits [ProfileInitial].
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      emit(const ProfileInitial());
    } catch (e) {
      debugPrint('[ProfileCubit] Error signing out: $e');
      emit(ProfileError(_friendlyMessage(e)));
    }
  }

  /// Permanently deletes the current user's account.
  ///
  /// Deletes the Firestore user document first, then the Firebase Auth account.
  Future<void> deleteAccount() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        emit(const ProfileError('No user is currently signed in.'));
        return;
      }

      // Delete Firestore user document.
      await _firestoreService.deleteDocument(
        collection: 'users',
        docId: currentUser.uid,
      );

      // Delete Firebase Auth account.
      await _authService.deleteAccount();

      emit(const ProfileInitial());
    } catch (e) {
      debugPrint('[ProfileCubit] Error deleting account: $e');
      emit(ProfileError(_friendlyMessage(e)));
    }
  }

  /// Updates the user's display name in Firestore and Firebase Auth.
  Future<void> updateDisplayName(String name) async {
    final currentState = state;
    if (currentState is! ProfileLoaded) return;

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      // Update Firebase Auth display name.
      await currentUser.updateDisplayName(name);
      await currentUser.reload();

      // Update Firestore user document.
      await _firestoreService.updateDocument(
        collection: 'users',
        docId: currentUser.uid,
        data: {'displayName': name},
      );

      // Emit updated state.
      emit(currentState.copyWith(
        user: currentState.user.copyWith(displayName: name),
      ));
    } catch (e) {
      debugPrint('[ProfileCubit] Error updating display name: $e');
      emit(ProfileError(_friendlyMessage(e)));
    }
  }

  /// Converts raw exceptions to user-friendly messages.
  String _friendlyMessage(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('network')) {
      return 'Network error. Check your connection and try again.';
    }
    if (message.contains('requires-recent-login')) {
      return 'Please sign in again to complete this action.';
    }
    if (message.contains('permission')) {
      return 'You do not have permission to perform this action.';
    }
    return 'Something went wrong. Please try again.';
  }
}
