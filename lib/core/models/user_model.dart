import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Represents a Lumoni user with their profile data and test statistics.
class UserModel extends Equatable {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final bool isPremium;
  final int totalIQTests;
  final int totalEQTests;
  final int? highestIQ;
  final double? averageEQ;
  final DateTime createdAt;
  final DateTime? lastTestAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.isPremium = false,
    this.totalIQTests = 0,
    this.totalEQTests = 0,
    this.highestIQ,
    this.averageEQ,
    required this.createdAt,
    this.lastTestAt,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        photoUrl,
        isPremium,
        totalIQTests,
        totalEQTests,
        highestIQ,
        averageEQ,
        createdAt,
        lastTestAt,
      ];

  /// Creates a new [UserModel] with default values for a freshly registered user.
  factory UserModel.newUser({
    required String id,
    required String email,
    required String displayName,
    String? photoUrl,
  }) {
    return UserModel(
      id: id,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      isPremium: false,
      totalIQTests: 0,
      totalEQTests: 0,
      highestIQ: null,
      averageEQ: null,
      createdAt: DateTime.now(),
      lastTestAt: null,
    );
  }

  /// Deserializes from a plain JSON map (e.g. local cache).
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      isPremium: json['isPremium'] as bool? ?? false,
      totalIQTests: json['totalIQTests'] as int? ?? 0,
      totalEQTests: json['totalEQTests'] as int? ?? 0,
      highestIQ: json['highestIQ'] as int?,
      averageEQ: (json['averageEQ'] as num?)?.toDouble(),
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      lastTestAt: json['lastTestAt'] != null
          ? json['lastTestAt'] is String
              ? DateTime.parse(json['lastTestAt'] as String)
              : DateTime.fromMillisecondsSinceEpoch(json['lastTestAt'] as int)
          : null,
    );
  }

  /// Deserializes from a Firestore document snapshot.
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserModel(
      id: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      isPremium: data['isPremium'] as bool? ?? false,
      totalIQTests: data['totalIQTests'] as int? ?? 0,
      totalEQTests: data['totalEQTests'] as int? ?? 0,
      highestIQ: data['highestIQ'] as int?,
      averageEQ: (data['averageEQ'] as num?)?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastTestAt: (data['lastTestAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Serializes to a plain JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'isPremium': isPremium,
      'totalIQTests': totalIQTests,
      'totalEQTests': totalEQTests,
      'highestIQ': highestIQ,
      'averageEQ': averageEQ,
      'createdAt': createdAt.toIso8601String(),
      'lastTestAt': lastTestAt?.toIso8601String(),
    };
  }

  /// Serializes to a Firestore-compatible map using [Timestamp].
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'isPremium': isPremium,
      'totalIQTests': totalIQTests,
      'totalEQTests': totalEQTests,
      'highestIQ': highestIQ,
      'averageEQ': averageEQ,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastTestAt':
          lastTestAt != null ? Timestamp.fromDate(lastTestAt!) : null,
    };
  }

  /// Returns a copy with the given fields replaced.
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isPremium,
    int? totalIQTests,
    int? totalEQTests,
    int? highestIQ,
    double? averageEQ,
    DateTime? createdAt,
    DateTime? lastTestAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isPremium: isPremium ?? this.isPremium,
      totalIQTests: totalIQTests ?? this.totalIQTests,
      totalEQTests: totalEQTests ?? this.totalEQTests,
      highestIQ: highestIQ ?? this.highestIQ,
      averageEQ: averageEQ ?? this.averageEQ,
      createdAt: createdAt ?? this.createdAt,
      lastTestAt: lastTestAt ?? this.lastTestAt,
    );
  }

  /// Returns true if the user has completed at least one test.
  bool get hasCompletedTest => totalIQTests > 0 || totalEQTests > 0;

  /// Total number of tests completed across both types.
  int get totalTests => totalIQTests + totalEQTests;
}
