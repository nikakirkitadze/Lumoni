import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:lumoni/core/constants/app_constants.dart';
import 'package:lumoni/core/services/auth_service.dart';
import 'package:lumoni/features/friends/data/models/friend_invite_model.dart';
import 'package:lumoni/features/friends/data/models/friendship_model.dart';
import 'package:lumoni/features/friends/domain/entities/friend_invite.dart';
import 'package:lumoni/features/friends/domain/entities/friendship.dart';
import 'package:lumoni/features/friends/domain/repositories/friend_repository.dart';

class FirestoreFriendRepository implements FriendRepository {
  FirestoreFriendRepository({
    required FirebaseFirestore firestore,
    required AuthService authService,
  })  : _firestore = firestore,
        _authService = authService;

  final FirebaseFirestore _firestore;
  final AuthService _authService;

  String get _currentUid => _authService.currentUser?.uid ?? '';

  CollectionReference<Map<String, dynamic>> get _friendships =>
      _firestore.collection(AppConstants.friendshipsCollection);

  CollectionReference<Map<String, dynamic>> get _invites =>
      _firestore.collection(AppConstants.friendInvitesCollection);

  CollectionReference<Map<String, dynamic>> get _profiles =>
      _firestore.collection(AppConstants.leaderboardProfilesCollection);

  // ──────────────────────── Queries ────────────────────────────────────────

  @override
  Future<List<Friendship>> getAcceptedFriends() async {
    return _queryFriendships('accepted');
  }

  @override
  Future<List<Friendship>> getIncomingRequests() async {
    final all = await _queryFriendships('pending');
    return all.where((f) => f.receiverUid == _currentUid).toList();
  }

  @override
  Future<List<Friendship>> getOutgoingRequests() async {
    final all = await _queryFriendships('pending');
    return all.where((f) => f.senderUid == _currentUid).toList();
  }

  Future<List<Friendship>> _queryFriendships(String status) async {
    try {
      final snap = await _friendships
          .where('participants', arrayContains: _currentUid)
          .where('status', isEqualTo: status)
          .orderBy('updated_at', descending: true)
          .limit(500)
          .get();

      final friendships = snap.docs
          .map((doc) =>
              FriendshipModel.fromDocument(doc, currentUid: _currentUid))
          .toList();

      // Resolve display names for friends
      return _resolveDisplayNames(friendships);
    } catch (e) {
      debugPrint('[FriendRepo] _queryFriendships($status) failed: $e');
      return const [];
    }
  }

  Future<List<Friendship>> _resolveDisplayNames(
      List<FriendshipModel> friendships) async {
    if (friendships.isEmpty) return friendships;

    final uids = friendships
        .map((f) => f.friendUid)
        .whereType<String>()
        .toSet()
        .toList();

    if (uids.isEmpty) return friendships;

    // Batch load display names from leaderboard_profiles
    final nameMap = <String, String>{};
    final chunks = _chunk(uids, 30);
    for (final chunk in chunks) {
      final snap = await _profiles
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snap.docs) {
        final data = doc.data();
        final name = data['display_name'] as String? ?? 'Lumoni User';
        nameMap[doc.id] = name;
      }
    }

    // Fallback: load from users collection for any missing names
    final missingUids = uids.where((uid) => !nameMap.containsKey(uid)).toList();
    if (missingUids.isNotEmpty) {
      final missingChunks = _chunk(missingUids, 30);
      for (final chunk in missingChunks) {
        final snap = await _firestore
            .collection(AppConstants.usersCollection)
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (final doc in snap.docs) {
          final data = doc.data();
          nameMap[doc.id] = data['displayName'] as String? ?? 'Lumoni User';
        }
      }
    }

    return friendships.map((f) {
      final name = f.friendUid != null
          ? (nameMap[f.friendUid!] ?? 'Lumoni User')
          : 'Lumoni User';
      return f.copyWithDisplayName(name);
    }).toList();
  }

  // ──────────────────────── Mutations ──────────────────────────────────────

  @override
  Future<Friendship> sendFriendRequest(String receiverUid) async {
    if (receiverUid == _currentUid) {
      throw StateError('Cannot send a friend request to yourself.');
    }

    final docId = FriendshipModel.friendshipDocId(_currentUid, receiverUid);
    final existingDoc = await _friendships.doc(docId).get();

    if (existingDoc.exists) {
      final existing = FriendshipModel.fromDocument(existingDoc,
          currentUid: _currentUid);

      if (existing.isAccepted) {
        throw StateError('You are already friends with this user.');
      }
      if (existing.isPending) {
        throw StateError('A friend request already exists.');
      }
      if (existing.isBlocked) {
        throw StateError('This user is blocked.');
      }
    }

    final now = DateTime.now();
    final model = FriendshipModel(
      id: docId,
      participants: [_currentUid, receiverUid],
      senderUid: _currentUid,
      receiverUid: receiverUid,
      status: FriendshipStatus.pending,
      createdAt: now,
      updatedAt: now,
    );

    await _friendships.doc(docId).set(model.toMap());
    return model;
  }

  @override
  Future<void> acceptFriendRequest(String friendshipId) async {
    await _friendships.doc(friendshipId).update({
      'status': FriendshipStatus.accepted.value,
      'updated_at': Timestamp.now(),
    });
  }

  @override
  Future<void> declineFriendRequest(String friendshipId) async {
    await _friendships.doc(friendshipId).update({
      'status': FriendshipStatus.declined.value,
      'updated_at': Timestamp.now(),
    });
  }

  @override
  Future<void> blockUser(String friendshipId) async {
    await _friendships.doc(friendshipId).update({
      'status': FriendshipStatus.blocked.value,
      'blocked_by': _currentUid,
      'updated_at': Timestamp.now(),
    });
  }

  @override
  Future<void> removeFriend(String friendshipId) async {
    await _friendships.doc(friendshipId).delete();
  }

  // ──────────────────────── Search ─────────────────────────────────────────

  @override
  Future<List<UserSearchResult>> searchUsers(String query) async {
    if (query.trim().length < 2) return const [];

    try {
      final trimmed = query.trim();
      final snap = await _profiles
          .where('display_name', isGreaterThanOrEqualTo: trimmed)
          .where('display_name', isLessThanOrEqualTo: '$trimmed\uf8ff')
          .limit(20)
          .get();

      // Load existing friendships to show status
      final existingSnap = await _friendships
          .where('participants', arrayContains: _currentUid)
          .get();

      final existingMap = <String, FriendshipStatus>{};
      for (final doc in existingSnap.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] as List);
        final otherUid = participants.firstWhere(
          (uid) => uid != _currentUid,
          orElse: () => '',
        );
        if (otherUid.isNotEmpty) {
          existingMap[otherUid] =
              FriendshipStatus.fromValue(data['status'] as String?);
        }
      }

      return snap.docs
          .where((doc) => doc.id != _currentUid)
          .map((doc) {
            final data = doc.data();
            return UserSearchResult(
              uid: doc.id,
              displayName: data['display_name'] as String? ?? 'Lumoni User',
              countryCode: data['country_code'] as String?,
              existingFriendshipStatus: existingMap[doc.id],
            );
          })
          .toList();
    } catch (e) {
      debugPrint('[FriendRepo] searchUsers failed: $e');
      return const [];
    }
  }

  // ──────────────────────── Invites ────────────────────────────────────────

  @override
  Future<FriendInvite> getOrCreateInvite() async {
    // Check for existing active invite
    final existingSnap = await _invites
        .where('owner_uid', isEqualTo: _currentUid)
        .where('active', isEqualTo: true)
        .limit(1)
        .get();

    if (existingSnap.docs.isNotEmpty) {
      final invite = FriendInviteModel.fromDocument(existingSnap.docs.first);
      if (!invite.isExpired) return invite;

      // Deactivate expired invite
      await _invites.doc(invite.code).update({'active': false});
    }

    // Create new invite with random 8-char alphanumeric code
    final code = _generateInviteCode();
    final now = DateTime.now();
    final model = FriendInviteModel(
      code: code,
      ownerUid: _currentUid,
      createdAt: now,
      expiresAt: now.add(const Duration(days: 7)),
      maxUses: 50,
      useCount: 0,
      active: true,
    );

    await _invites.doc(code).set(model.toMap());
    return model;
  }

  @override
  Future<Friendship> redeemInvite(String code) async {
    return _firestore.runTransaction((transaction) async {
      final inviteRef = _invites.doc(code);
      final inviteDoc = await transaction.get(inviteRef);

      if (!inviteDoc.exists) {
        throw StateError('Invalid invite code.');
      }

      final invite = FriendInviteModel.fromDocument(inviteDoc);

      if (!invite.isUsable) {
        throw StateError('This invite has expired or reached its limit.');
      }

      if (invite.ownerUid == _currentUid) {
        throw StateError('You cannot redeem your own invite.');
      }

      // Check for existing friendship
      final docId =
          FriendshipModel.friendshipDocId(_currentUid, invite.ownerUid);
      final existingDoc = await transaction.get(_friendships.doc(docId));

      if (existingDoc.exists) {
        final existing = FriendshipModel.fromDocument(existingDoc,
            currentUid: _currentUid);
        if (existing.isAccepted) {
          throw StateError('You are already friends with this user.');
        }
        if (existing.isPending) {
          // Auto-accept if there's a pending request
          transaction.update(_friendships.doc(docId), {
            'status': FriendshipStatus.accepted.value,
            'updated_at': Timestamp.now(),
          });
          transaction.update(inviteRef, {
            'use_count': FieldValue.increment(1),
          });
          return FriendshipModel(
            id: docId,
            participants: existing.participants,
            senderUid: existing.senderUid,
            receiverUid: existing.receiverUid,
            status: FriendshipStatus.accepted,
            createdAt: existing.createdAt,
            updatedAt: DateTime.now(),
          );
        }
      }

      // Create new accepted friendship (via invite = auto-accept)
      final now = DateTime.now();
      final model = FriendshipModel(
        id: docId,
        participants: [_currentUid, invite.ownerUid],
        senderUid: _currentUid,
        receiverUid: invite.ownerUid,
        status: FriendshipStatus.accepted,
        createdAt: now,
        updatedAt: now,
      );

      transaction.set(_friendships.doc(docId), model.toMap());
      transaction.update(inviteRef, {
        'use_count': FieldValue.increment(1),
      });

      return model;
    });
  }

  @override
  Future<int> getFriendCount() async {
    try {
      final snap = await _friendships
          .where('participants', arrayContains: _currentUid)
          .where('status', isEqualTo: 'accepted')
          .count()
          .get();
      return snap.count ?? 0;
    } catch (e) {
      debugPrint('[FriendRepo] getFriendCount failed: $e');
      return 0;
    }
  }

  // ──────────────────────── Helpers ────────────────────────────────────────

  String _generateInviteCode() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }

  List<List<T>> _chunk<T>(List<T> list, int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += size) {
      chunks.add(list.sublist(i, (i + size).clamp(0, list.length)));
    }
    return chunks;
  }
}
