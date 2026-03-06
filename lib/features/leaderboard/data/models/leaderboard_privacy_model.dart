import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_enums.dart';
import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_privacy_settings.dart';

class LeaderboardPrivacyModel extends LeaderboardPrivacySettings {
  const LeaderboardPrivacyModel({
    required super.displayName,
    super.publicAlias,
    super.countryCode,
    super.anonymousMode,
    super.hideProfile,
    super.shareInCountry,
    super.visibilityScope,
  });

  factory LeaderboardPrivacyModel.fromMap(
    Map<String, dynamic> map, {
    required String fallbackDisplayName,
  }) {
    return LeaderboardPrivacyModel(
      displayName: (map['display_name'] ?? fallbackDisplayName) as String,
      publicAlias: map['public_alias'] as String?,
      countryCode: map['country_code'] as String?,
      anonymousMode: (map['anonymous_mode'] as bool?) ?? false,
      hideProfile: (map['hide_profile'] as bool?) ?? false,
      shareInCountry: (map['share_in_country'] as bool?) ?? true,
      visibilityScope: LeaderboardVisibilityScope.fromValue(
        map['visibility_scope'] as String?,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'display_name': displayName,
      'public_alias': publicAlias,
      'country_code': countryCode,
      'anonymous_mode': anonymousMode,
      'hide_profile': hideProfile,
      'share_in_country': shareInCountry,
      'visibility_scope': visibilityScope.value,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }
}
