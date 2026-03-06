enum LeaderboardMetric {
  iq('iq', 'IQ'),
  eq('eq', 'EQ');

  const LeaderboardMetric(this.value, this.label);

  final String value;
  final String label;

  static LeaderboardMetric fromValue(String? value) {
    return LeaderboardMetric.values.firstWhere(
      (metric) => metric.value == value,
      orElse: () => LeaderboardMetric.iq,
    );
  }
}

enum LeaderboardScopeType {
  global('global', 'Global'),
  country('country', 'Country'),
  friends('friends', 'Friends');

  const LeaderboardScopeType(this.value, this.label);

  final String value;
  final String label;

  static LeaderboardScopeType fromValue(String? value) {
    return LeaderboardScopeType.values.firstWhere(
      (scope) => scope.value == value,
      orElse: () => LeaderboardScopeType.global,
    );
  }
}

enum LeaderboardPeriod {
  weekly('weekly', 'Weekly'),
  monthly('monthly', 'Monthly'),
  allTime('all_time', 'All-Time');

  const LeaderboardPeriod(this.value, this.label);

  final String value;
  final String label;

  static LeaderboardPeriod fromValue(String? value) {
    return LeaderboardPeriod.values.firstWhere(
      (period) => period.value == value,
      orElse: () => LeaderboardPeriod.weekly,
    );
  }
}

enum LeaderboardVisibilityScope {
  global('global'),
  country('country'),
  friendsOnly('friends_only'),
  privateMode('private');

  const LeaderboardVisibilityScope(this.value);

  final String value;

  static LeaderboardVisibilityScope fromValue(String? value) {
    return LeaderboardVisibilityScope.values.firstWhere(
      (scope) => scope.value == value,
      orElse: () => LeaderboardVisibilityScope.global,
    );
  }
}
