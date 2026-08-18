class ProfileStatsResponse {
  const ProfileStatsResponse({
    required this.success,
    this.message,
    required this.data,
  });

  final bool success;
  final String? message;
  final ProfileStatsData data;

  factory ProfileStatsResponse.fromJson(Map<String, dynamic> json) {
    final dataRaw = json['data'];
    return ProfileStatsResponse(
      success: json['success'] == true,
      message: json['message']?.toString(),
      data: dataRaw is Map<String, dynamic>
          ? ProfileStatsData.fromJson(dataRaw)
          : dataRaw is Map
              ? ProfileStatsData.fromJson(Map<String, dynamic>.from(dataRaw))
              : ProfileStatsData.empty(),
    );
  }
}

class ProfileStatsData {
  const ProfileStatsData({
    required this.overallTalentScore,
    required this.overallTalentScoreLabel,
    required this.avgRating,
    required this.avgRatingLabel,
    required this.totalVotes,
    required this.totalVotesLabel,
    required this.ratingTrend,
    required this.winRate,
    this.heroMetrics = const [],
    this.statTiles = const [],
    required this.stats,
    this.ratingBreakdown = const [],
    this.recentChallengePerformance = const [],
    this.note,
    this.screenConfig = const {},
  });

  final num overallTalentScore;
  final String overallTalentScoreLabel;
  final num avgRating;
  final String avgRatingLabel;
  final num totalVotes;
  final String totalVotesLabel;
  final String ratingTrend;
  final num winRate;
  final List<dynamic> heroMetrics;
  final List<dynamic> statTiles;
  final UserCoreStats stats;
  final List<RatingBreakdownItem> ratingBreakdown;
  final List<RecentChallengePerformanceItem> recentChallengePerformance;
  final String? note;
  final Map<String, dynamic> screenConfig;

  factory ProfileStatsData.fromJson(Map<String, dynamic> json) {
    final statsRaw = json['stats'];
    final coreStats = statsRaw is Map<String, dynamic>
        ? UserCoreStats.fromJson(statsRaw)
        : statsRaw is Map
            ? UserCoreStats.fromJson(Map<String, dynamic>.from(statsRaw))
            : UserCoreStats.empty();

    final rawBreakdown = json['ratingBreakdown'] ?? json['rating_breakdown'];
    final breakdownList = <RatingBreakdownItem>[];
    if (rawBreakdown is List) {
      for (final item in rawBreakdown) {
        if (item is Map<String, dynamic>) {
          breakdownList.add(RatingBreakdownItem.fromJson(item));
        } else if (item is Map) {
          breakdownList.add(
            RatingBreakdownItem.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    final rawRecent = json['recentChallengePerformance'] ??
        json['recent_challenge_performance'];
    final recentList = <RecentChallengePerformanceItem>[];
    if (rawRecent is List) {
      for (final item in rawRecent) {
        if (item is Map<String, dynamic>) {
          recentList.add(RecentChallengePerformanceItem.fromJson(item));
        } else if (item is Map) {
          recentList.add(
            RecentChallengePerformanceItem.fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    return ProfileStatsData(
      overallTalentScore: (json['overallTalentScore'] as num?) ?? 0,
      overallTalentScoreLabel:
          json['overallTalentScoreLabel']?.toString() ?? '0.0',
      avgRating: (json['avgRating'] as num?) ?? 0,
      avgRatingLabel: json['avgRatingLabel']?.toString() ?? '0.0',
      totalVotes: (json['totalVotes'] as num?) ?? 0,
      totalVotesLabel: json['totalVotesLabel']?.toString() ?? '0',
      ratingTrend: json['ratingTrend']?.toString() ?? 'NO_RECENT_RATINGS',
      winRate: (json['winRate'] as num?) ?? 0,
      heroMetrics: (json['heroMetrics'] as List?) ?? const [],
      statTiles: (json['statTiles'] as List?) ?? const [],
      stats: coreStats,
      ratingBreakdown: breakdownList,
      recentChallengePerformance: recentList,
      note: json['note']?.toString(),
      screenConfig: json['screenConfig'] is Map
          ? Map<String, dynamic>.from(json['screenConfig'] as Map)
          : const {},
    );
  }

  factory ProfileStatsData.empty() {
    return ProfileStatsData(
      overallTalentScore: 0,
      overallTalentScoreLabel: '0.0',
      avgRating: 0,
      avgRatingLabel: '0.0',
      totalVotes: 0,
      totalVotesLabel: '0',
      ratingTrend: 'NO_RECENT_RATINGS',
      winRate: 0,
      stats: UserCoreStats.empty(),
    );
  }
}

class UserCoreStats {
  const UserCoreStats({
    this.totalVideos = 0,
    this.approvedVideos = 0,
    this.totalLikes = 0,
    this.totalViews = 0,
    this.talentScore = 0,
    this.wins = 0,
    this.joinedChallenges = 0,
    this.topThree = 0,
    this.rewardEarnings = 0,
    this.referrals = 0,
    this.maxVideoLikes = 0,
    this.maxRatingCount = 0,
  });

  final int totalVideos;
  final int approvedVideos;
  final int totalLikes;
  final int totalViews;
  final num talentScore;
  final int wins;
  final int joinedChallenges;
  final int topThree;
  final num rewardEarnings;
  final int referrals;
  final int maxVideoLikes;
  final int maxRatingCount;

  factory UserCoreStats.fromJson(Map<String, dynamic> json) {
    return UserCoreStats(
      totalVideos: (json['totalVideos'] as num?)?.toInt() ?? 0,
      approvedVideos: (json['approvedVideos'] as num?)?.toInt() ?? 0,
      totalLikes: (json['totalLikes'] as num?)?.toInt() ?? 0,
      totalViews: (json['totalViews'] as num?)?.toInt() ?? 0,
      talentScore: (json['talentScore'] as num?) ?? 0,
      wins: (json['wins'] as num?)?.toInt() ?? 0,
      joinedChallenges: (json['joinedChallenges'] as num?)?.toInt() ?? 0,
      topThree: (json['topThree'] as num?)?.toInt() ?? 0,
      rewardEarnings: (json['rewardEarnings'] as num?) ?? 0,
      referrals: (json['referrals'] as num?)?.toInt() ?? 0,
      maxVideoLikes: (json['maxVideoLikes'] as num?)?.toInt() ?? 0,
      maxRatingCount: (json['maxRatingCount'] as num?)?.toInt() ?? 0,
    );
  }

  factory UserCoreStats.empty() {
    return const UserCoreStats();
  }
}

class RatingBreakdownItem {
  const RatingBreakdownItem({
    required this.score,
    this.count = 0,
    this.percent = 0,
    this.barPercent = 0,
  });

  final int score;
  final int count;
  final num percent;
  final num barPercent;

  factory RatingBreakdownItem.fromJson(Map<String, dynamic> json) {
    return RatingBreakdownItem(
      score: (json['score'] as num?)?.toInt() ?? 1,
      count: (json['count'] as num?)?.toInt() ?? 0,
      percent: (json['percent'] as num?) ?? 0,
      barPercent: (json['barPercent'] as num?) ??
          (json['bar_percent'] as num?) ??
          0,
    );
  }
}

class RecentChallengePerformanceItem {
  const RecentChallengePerformanceItem({
    this.id,
    this.challengeId,
    required this.title,
    required this.result,
    required this.date,
    this.score,
    this.isPlaced = false,
  });

  final String? id;
  final String? challengeId;
  final String title;
  final String result;
  final String date;
  final num? score;
  final bool isPlaced;

  factory RecentChallengePerformanceItem.fromJson(Map<String, dynamic> json) {
    final res = json['result']?.toString() ?? 'Participated';
    final hasScore = json['score'] != null;
    final isPlaced = json['isPlaced'] == true ||
        hasScore ||
        res.toLowerCase().contains('top') ||
        res.toLowerCase().contains('winner') ||
        res.toLowerCase().contains('place');

    return RecentChallengePerformanceItem(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      challengeId: json['challengeId']?.toString() ??
          json['challenge_id']?.toString() ??
          json['id']?.toString(),
      title: json['title']?.toString() ?? json['challengeTitle']?.toString() ?? 'Challenge',
      result: res,
      date: json['date']?.toString() ?? json['createdAt']?.toString() ?? '',
      score: json['score'] as num?,
      isPlaced: isPlaced,
    );
  }
}
