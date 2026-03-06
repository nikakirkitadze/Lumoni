import 'package:lumoni/features/friends/domain/entities/friend_invite.dart';
import 'package:lumoni/features/friends/domain/entities/friendship.dart';

/// Repository interface for friend graph operations.
abstract class FriendRepository {
  /// Returns accepted friends only.
  Future<List<Friendship>> getAcceptedFriends();

  /// Returns pending incoming requests (where current user is receiver).
  Future<List<Friendship>> getIncomingRequests();

  /// Returns pending outgoing requests (where current user is sender).
  Future<List<Friendship>> getOutgoingRequests();

  /// Sends a friend request to [receiverUid].
  Future<Friendship> sendFriendRequest(String receiverUid);

  /// Accepts an incoming friend request.
  Future<void> acceptFriendRequest(String friendshipId);

  /// Declines an incoming friend request.
  Future<void> declineFriendRequest(String friendshipId);

  /// Blocks a user in an existing friendship.
  Future<void> blockUser(String friendshipId);

  /// Removes an accepted friend (deletes the friendship doc).
  Future<void> removeFriend(String friendshipId);

  /// Searches users by display name prefix.
  Future<List<UserSearchResult>> searchUsers(String query);

  /// Creates or retrieves a shareable invite link for the current user.
  Future<FriendInvite> getOrCreateInvite();

  /// Redeems an invite code, creating a pending friendship.
  Future<Friendship> redeemInvite(String code);

  /// Returns the count of accepted friends.
  Future<int> getFriendCount();
}

/// Search result for user lookup.
class UserSearchResult {
  const UserSearchResult({
    required this.uid,
    required this.displayName,
    this.countryCode,
    this.existingFriendshipStatus,
  });

  final String uid;
  final String displayName;
  final String? countryCode;
  final FriendshipStatus? existingFriendshipStatus;
}
