import 'package:equatable/equatable.dart';

enum FriendshipStatus {
  pending('pending'),
  accepted('accepted'),
  blocked('blocked'),
  declined('declined');

  const FriendshipStatus(this.value);
  final String value;

  static FriendshipStatus fromValue(String? value) {
    return FriendshipStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => FriendshipStatus.pending,
    );
  }
}

class Friendship extends Equatable {
  const Friendship({
    required this.id,
    required this.participants,
    required this.senderUid,
    required this.receiverUid,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.blockedBy,
    this.friendDisplayName,
    this.friendUid,
  });

  final String id;
  final List<String> participants;
  final String senderUid;
  final String receiverUid;
  final FriendshipStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? blockedBy;

  /// Resolved display name of the other participant.
  final String? friendDisplayName;

  /// UID of the other participant (resolved from participants).
  final String? friendUid;

  bool get isPending => status == FriendshipStatus.pending;
  bool get isAccepted => status == FriendshipStatus.accepted;
  bool get isBlocked => status == FriendshipStatus.blocked;

  @override
  List<Object?> get props => [
        id,
        participants,
        senderUid,
        receiverUid,
        status,
        createdAt,
        updatedAt,
        blockedBy,
        friendDisplayName,
        friendUid,
      ];
}
