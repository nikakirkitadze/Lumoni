import 'package:equatable/equatable.dart';

import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_enums.dart';

class LeaderboardPrivacySettings extends Equatable {
  const LeaderboardPrivacySettings({
    required this.displayName,
    this.publicAlias,
    this.countryCode,
    this.anonymousMode = false,
    this.hideProfile = false,
    this.shareInCountry = true,
    this.visibilityScope = LeaderboardVisibilityScope.global,
  });

  final String displayName;
  final String? publicAlias;
  final String? countryCode;
  final bool anonymousMode;
  final bool hideProfile;
  final bool shareInCountry;
  final LeaderboardVisibilityScope visibilityScope;

  LeaderboardPrivacySettings copyWith({
    String? displayName,
    String? publicAlias,
    String? countryCode,
    bool? anonymousMode,
    bool? hideProfile,
    bool? shareInCountry,
    LeaderboardVisibilityScope? visibilityScope,
  }) {
    return LeaderboardPrivacySettings(
      displayName: displayName ?? this.displayName,
      publicAlias: publicAlias ?? this.publicAlias,
      countryCode: countryCode ?? this.countryCode,
      anonymousMode: anonymousMode ?? this.anonymousMode,
      hideProfile: hideProfile ?? this.hideProfile,
      shareInCountry: shareInCountry ?? this.shareInCountry,
      visibilityScope: visibilityScope ?? this.visibilityScope,
    );
  }

  @override
  List<Object?> get props => [
    displayName,
    publicAlias,
    countryCode,
    anonymousMode,
    hideProfile,
    shareInCountry,
    visibilityScope,
  ];
}
