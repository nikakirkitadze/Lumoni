import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:lumoni/features/friends/domain/entities/friend_invite.dart';

class FriendInviteModel extends FriendInvite {
  const FriendInviteModel({
    required super.code,
    required super.ownerUid,
    required super.createdAt,
    required super.expiresAt,
    required super.maxUses,
    required super.useCount,
    required super.active,
  });

  factory FriendInviteModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return FriendInviteModel(
      code: doc.id,
      ownerUid: data['owner_uid'] as String,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      expiresAt: (data['expires_at'] as Timestamp).toDate(),
      maxUses: (data['max_uses'] as num?)?.toInt() ?? 50,
      useCount: (data['use_count'] as num?)?.toInt() ?? 0,
      active: data['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'owner_uid': ownerUid,
      'created_at': Timestamp.fromDate(createdAt),
      'expires_at': Timestamp.fromDate(expiresAt),
      'max_uses': maxUses,
      'use_count': useCount,
      'active': active,
    };
  }
}
