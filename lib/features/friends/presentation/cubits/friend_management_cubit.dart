import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lumoni/features/friends/domain/repositories/friend_repository.dart';
import 'package:lumoni/features/friends/presentation/cubits/friend_management_state.dart';

class FriendManagementCubit extends Cubit<FriendManagementState> {
  FriendManagementCubit({required FriendRepository repository})
      : _repository = repository,
        super(const FriendManagementState());

  final FriendRepository _repository;

  Future<void> loadFriends() async {
    emit(state.copyWith(
      status: FriendManagementStatus.loading,
      clearError: true,
    ));

    try {
      final results = await Future.wait([
        _repository.getAcceptedFriends(),
        _repository.getIncomingRequests(),
        _repository.getOutgoingRequests(),
      ]);

      emit(state.copyWith(
        status: FriendManagementStatus.loaded,
        friends: results[0],
        incomingRequests: results[1],
        outgoingRequests: results[2],
      ));
    } catch (e) {
      debugPrint('[FriendManagementCubit] loadFriends failed: $e');
      emit(state.copyWith(
        status: FriendManagementStatus.error,
        errorMessage: 'Failed to load friends.',
      ));
    }
  }

  Future<void> searchUsers(String query) async {
    if (query.trim().length < 2) {
      emit(state.copyWith(searchResults: const [], isSearching: false));
      return;
    }

    emit(state.copyWith(isSearching: true));

    try {
      final results = await _repository.searchUsers(query);
      emit(state.copyWith(searchResults: results, isSearching: false));
    } catch (e) {
      debugPrint('[FriendManagementCubit] searchUsers failed: $e');
      emit(state.copyWith(searchResults: const [], isSearching: false));
    }
  }

  Future<void> sendRequest(String uid) async {
    try {
      await _repository.sendFriendRequest(uid);
      emit(state.copyWith(
        actionMessage: 'Friend request sent!',
        clearError: true,
      ));
      await loadFriends();
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> acceptRequest(String friendshipId) async {
    try {
      await _repository.acceptFriendRequest(friendshipId);
      emit(state.copyWith(
        actionMessage: 'Friend request accepted!',
        clearError: true,
      ));
      await loadFriends();
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to accept request.'));
    }
  }

  Future<void> declineRequest(String friendshipId) async {
    try {
      await _repository.declineFriendRequest(friendshipId);
      await loadFriends();
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to decline request.'));
    }
  }

  Future<void> blockUser(String friendshipId) async {
    try {
      await _repository.blockUser(friendshipId);
      emit(state.copyWith(actionMessage: 'User blocked.'));
      await loadFriends();
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to block user.'));
    }
  }

  Future<void> removeFriend(String friendshipId) async {
    try {
      await _repository.removeFriend(friendshipId);
      emit(state.copyWith(actionMessage: 'Friend removed.'));
      await loadFriends();
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to remove friend.'));
    }
  }

  Future<void> loadInvite() async {
    try {
      final invite = await _repository.getOrCreateInvite();
      emit(state.copyWith(myInvite: invite));
    } catch (e) {
      debugPrint('[FriendManagementCubit] loadInvite failed: $e');
    }
  }

  Future<void> redeemInvite(String code) async {
    try {
      await _repository.redeemInvite(code);
      emit(state.copyWith(
        actionMessage: 'Invite redeemed! You are now friends.',
        clearError: true,
      ));
      await loadFriends();
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  void clearMessages() {
    emit(state.copyWith(clearError: true, clearAction: true));
  }
}
