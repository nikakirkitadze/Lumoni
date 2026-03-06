import 'package:equatable/equatable.dart';

class FriendInvite extends Equatable {
  const FriendInvite({
    required this.code,
    required this.ownerUid,
    required this.createdAt,
    required this.expiresAt,
    required this.maxUses,
    required this.useCount,
    required this.active,
  });

  final String code;
  final String ownerUid;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int maxUses;
  final int useCount;
  final bool active;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isUsable => active && !isExpired && useCount < maxUses;

  @override
  List<Object?> get props => [
        code,
        ownerUid,
        createdAt,
        expiresAt,
        maxUses,
        useCount,
        active,
      ];
}
