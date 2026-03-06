import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:lumoni/features/friends/domain/entities/friendship.dart';

class FriendshipModel extends Friendship {
  const FriendshipModel({
    required super.id,
    required super.participants,
    required super.senderUid,
    required super.receiverUid,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    super.blockedBy,
    super.friendDisplayName,
    super.friendUid,
  });

  /// Constructs a deterministic document ID for a friendship between two UIDs.
  /// Always uses alphabetical order to prevent duplicates.
  static String friendshipDocId(String uidA, String uidB) {
    final sorted = [uidA, uidB]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  factory FriendshipModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    String? currentUid,
  }) {
    final data = doc.data()!;
    final participants = List<String>.from(data['participants'] as List);
    final senderUid = data['sender_uid'] as String;
    final receiverUid = data['receiver_uid'] as String;

    // Resolve the friend's UID (the other participant)
    String? friendUid;
    if (currentUid != null) {
      friendUid = participants.firstWhere(
        (uid) => uid != currentUid,
        orElse: () => participants.first,
      );
    }

    return FriendshipModel(
      id: doc.id,
      participants: participants,
      senderUid: senderUid,
      receiverUid: receiverUid,
      status: FriendshipStatus.fromValue(data['status'] as String?),
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
      blockedBy: data['blocked_by'] as String?,
      friendUid: friendUid,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'sender_uid': senderUid,
      'receiver_uid': receiverUid,
      'status': status.value,
      'blocked_by': blockedBy,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  FriendshipModel copyWithDisplayName(String displayName) {
    return FriendshipModel(
      id: id,
      participants: participants,
      senderUid: senderUid,
      receiverUid: receiverUid,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      blockedBy: blockedBy,
      friendDisplayName: displayName,
      friendUid: friendUid,
    );
  }
}
