import 'package:equatable/equatable.dart';

import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_enums.dart';

class LeaderboardFilter extends Equatable {
  const LeaderboardFilter({
    this.metric = LeaderboardMetric.iq,
    this.scopeType = LeaderboardScopeType.global,
    this.period = LeaderboardPeriod.weekly,
    this.countryCode,
    this.friendsGroupId,
  });

  final LeaderboardMetric metric;
  final LeaderboardScopeType scopeType;
  final LeaderboardPeriod period;
  final String? countryCode;
  final String? friendsGroupId;

  String get scopeValue {
    switch (scopeType) {
      case LeaderboardScopeType.global:
        return 'all';
      case LeaderboardScopeType.country:
        return (countryCode ?? 'unknown').toUpperCase();
      case LeaderboardScopeType.friends:
        return friendsGroupId ?? 'default';
    }
  }

  LeaderboardFilter copyWith({
    LeaderboardMetric? metric,
    LeaderboardScopeType? scopeType,
    LeaderboardPeriod? period,
    String? countryCode,
    String? friendsGroupId,
    bool clearCountryCode = false,
    bool clearFriendsGroupId = false,
  }) {
    return LeaderboardFilter(
      metric: metric ?? this.metric,
      scopeType: scopeType ?? this.scopeType,
      period: period ?? this.period,
      countryCode: clearCountryCode ? null : (countryCode ?? this.countryCode),
      friendsGroupId: clearFriendsGroupId
          ? null
          : (friendsGroupId ?? this.friendsGroupId),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'metric': metric.value,
      'scopeType': scopeType.value,
      'period': period.value,
      'countryCode': countryCode,
      'friendsGroupId': friendsGroupId,
    };
  }

  factory LeaderboardFilter.fromJson(Map<String, dynamic> json) {
    return LeaderboardFilter(
      metric: LeaderboardMetric.fromValue(json['metric'] as String?),
      scopeType: LeaderboardScopeType.fromValue(json['scopeType'] as String?),
      period: LeaderboardPeriod.fromValue(json['period'] as String?),
      countryCode: json['countryCode'] as String?,
      friendsGroupId: json['friendsGroupId'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    metric,
    scopeType,
    period,
    countryCode,
    friendsGroupId,
  ];
}
