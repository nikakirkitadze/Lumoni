import 'package:equatable/equatable.dart';

import 'package:lumoni/features/friends/domain/entities/friend_invite.dart';
import 'package:lumoni/features/friends/domain/entities/friendship.dart';
import 'package:lumoni/features/friends/domain/repositories/friend_repository.dart';

enum FriendManagementStatus { initial, loading, loaded, error }

class FriendManagementState extends Equatable {
  const FriendManagementState({
    this.status = FriendManagementStatus.initial,
    this.friends = const [],
    this.incomingRequests = const [],
    this.outgoingRequests = const [],
    this.searchResults = const [],
    this.myInvite,
    this.errorMessage,
    this.isSearching = false,
    this.actionMessage,
  });

  final FriendManagementStatus status;
  final List<Friendship> friends;
  final List<Friendship> incomingRequests;
  final List<Friendship> outgoingRequests;
  final List<UserSearchResult> searchResults;
  final FriendInvite? myInvite;
  final String? errorMessage;
  final bool isSearching;
  final String? actionMessage;

  FriendManagementState copyWith({
    FriendManagementStatus? status,
    List<Friendship>? friends,
    List<Friendship>? incomingRequests,
    List<Friendship>? outgoingRequests,
    List<UserSearchResult>? searchResults,
    FriendInvite? myInvite,
    String? errorMessage,
    bool? isSearching,
    String? actionMessage,
    bool clearError = false,
    bool clearAction = false,
  }) {
    return FriendManagementState(
      status: status ?? this.status,
      friends: friends ?? this.friends,
      incomingRequests: incomingRequests ?? this.incomingRequests,
      outgoingRequests: outgoingRequests ?? this.outgoingRequests,
      searchResults: searchResults ?? this.searchResults,
      myInvite: myInvite ?? this.myInvite,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSearching: isSearching ?? this.isSearching,
      actionMessage: clearAction ? null : (actionMessage ?? this.actionMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        friends,
        incomingRequests,
        outgoingRequests,
        searchResults,
        myInvite,
        errorMessage,
        isSearching,
        actionMessage,
      ];
}
