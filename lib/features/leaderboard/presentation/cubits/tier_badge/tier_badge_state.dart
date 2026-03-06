import 'package:equatable/equatable.dart';

import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_tier.dart';

sealed class TierBadgeState extends Equatable {
  const TierBadgeState();

  @override
  List<Object?> get props => [];
}

final class TierBadgeInitial extends TierBadgeState {
  const TierBadgeInitial();
}

final class TierBadgeLoading extends TierBadgeState {
  const TierBadgeLoading();
}

final class TierBadgeLoaded extends TierBadgeState {
  const TierBadgeLoaded({required this.tiers, this.currentTierId});

  final List<LeaderboardTier> tiers;
  final String? currentTierId;

  @override
  List<Object?> get props => [tiers, currentTierId];
}

final class TierBadgeError extends TierBadgeState {
  const TierBadgeError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
