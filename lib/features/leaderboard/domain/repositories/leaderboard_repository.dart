import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_entry.dart';
import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_filter.dart';
import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_privacy_settings.dart';
import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_snapshot.dart';
import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_tier.dart';
import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_user_rank.dart';

abstract class LeaderboardRepository {
  Future<LeaderboardSnapshot?> getLatestSnapshot(LeaderboardFilter filter);

  Future<List<LeaderboardEntry>> getLeaderboardPage({
    required String snapshotId,
    required int page,
  });

  Future<LeaderboardUserRank?> getUserRank({
    required String snapshotId,
    required String userId,
  });

  Future<LeaderboardPrivacySettings> getPrivacySettings({
    required String userId,
  });

  Future<void> updatePrivacySettings({
    required String userId,
    required LeaderboardPrivacySettings settings,
  });

  Future<List<LeaderboardTier>> getTierCatalog();

  Future<void> recomputeUserRank(LeaderboardFilter filter);
}
