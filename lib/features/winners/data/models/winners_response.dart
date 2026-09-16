import 'package:artable_app/core/utils/mock_helpers.dart';

class WinnerChallenge {
  const WinnerChallenge({
    this.id,
    this.title,
    this.bannerUrl,
  });

  final String? id;
  final String? title;
  final String? bannerUrl;

  factory WinnerChallenge.fromJson(Map<String, dynamic> json) {
    return WinnerChallenge(
      id: json['id']?.toString(),
      title: json['title']?.toString(),
      bannerUrl: json['bannerUrl']?.toString(),
    );
  }
}

class WinnerUser {
  const WinnerUser({
    this.id,
    this.name,
    this.username,
    this.profilePhotoUrl,
    this.isVerified,
  });

  final String? id;
  final String? name;
  final String? username;
  final String? profilePhotoUrl;
  final bool? isVerified;

  factory WinnerUser.fromJson(Map<String, dynamic> json) {
    return WinnerUser(
      id: json['id']?.toString(),
      name: json['name']?.toString(),
      username: json['username']?.toString(),
      profilePhotoUrl: json['profilePhotoUrl']?.toString(),
      isVerified: json['isVerified'] == true,
    );
  }
}

class WinnerEntry {
  const WinnerEntry({
    this.id,
    this.title,
    this.thumbnailUrl,
    this.videoUrl,
  });

  final String? id;
  final String? title;
  final String? thumbnailUrl;
  final String? videoUrl;

  factory WinnerEntry.fromJson(Map<String, dynamic> json) {
    return WinnerEntry(
      id: json['id']?.toString(),
      title: json['title']?.toString(),
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      videoUrl: json['videoUrl']?.toString(),
    );
  }
}

class WinnerStats {
  const WinnerStats({
    this.rating,
    this.ratingLabel,
    this.ratingCount,
    this.likes,
    this.isLiked,
    this.views,
  });

  final double? rating;
  final String? ratingLabel;
  final int? ratingCount;
  final int? likes;
  final bool? isLiked;
  final int? views;

  factory WinnerStats.fromJson(Map<String, dynamic> json) {
    return WinnerStats(
      rating: (json['rating'] as num?)?.toDouble(),
      ratingLabel: json['ratingLabel']?.toString(),
      ratingCount: (json['ratingCount'] as num?)?.toInt(),
      likes: (json['likes'] as num?)?.toInt(),
      isLiked: json['isLiked'] == true,
      views: (json['views'] as num?)?.toInt(),
    );
  }
}

class WinnerItem {
  const WinnerItem({
    required this.id,
    this.position,
    this.rankLabel,
    this.prizeWon,
    this.wonOn,
    this.challenge,
    this.winner,
    this.entry,
    this.stats,
    // Legacy fallback parameters
    this.rank,
    this.userId,
    this.challengeId,
    this.reelId,
    this.prize,
    this.talentScore,
    this.avgRating,
    this.totalVotes,
    this.winDate,
    this.period,
    this.featured = false,
    this.challengeTitle,
    this.userName,
    this.userHandle,
    this.userAvatar,
    this.bannerUrl,
  });

  final String id;
  final int? position;
  final String? rankLabel;
  final String? prizeWon;
  final String? wonOn;
  final WinnerChallenge? challenge;
  final WinnerUser? winner;
  final WinnerEntry? entry;
  final WinnerStats? stats;

  // Legacy fallback fields
  final int? rank;
  final String? userId;
  final String? challengeId;
  final String? reelId;
  final String? prize;
  final double? talentScore;
  final double? avgRating;
  final int? totalVotes;
  final String? winDate;
  final String? period;
  final bool featured;
  final String? challengeTitle;
  final String? userName;
  final String? userHandle;
  final String? userAvatar;
  final String? bannerUrl;

  int get displayRank => position ?? rank ?? 1;

  String get displayName {
    if (winner?.name != null && winner!.name!.trim().isNotEmpty) return winner!.name!.trim();
    if (winner?.username != null && winner!.username!.trim().isNotEmpty) return winner!.username!.trim();
    if (userName != null && userName!.trim().isNotEmpty) return userName!.trim();
    if (userId != null) {
      final userMap = MockHelpers.creatorById(userId);
      if (userMap != null && userMap['name'] != null) return userMap['name'].toString();
    }
    return 'Winner';
  }

  String get displayHandle {
    if (winner?.username != null && winner!.username!.trim().isNotEmpty) {
      final handle = winner!.username!.trim();
      return handle.startsWith('@') ? handle : '@$handle';
    }
    if (userHandle != null && userHandle!.trim().isNotEmpty) return userHandle!.trim();
    if (userId != null) {
      final userMap = MockHelpers.creatorById(userId);
      if (userMap != null && userMap['handle'] != null) return userMap['handle'].toString();
    }
    return '';
  }

  String get displayAvatar {
    if (winner?.profilePhotoUrl != null &&
        winner!.profilePhotoUrl!.trim().isNotEmpty &&
        winner!.profilePhotoUrl!.trim() != 'null') {
      return winner!.profilePhotoUrl!.trim();
    }
    if (userAvatar != null && userAvatar!.trim().isNotEmpty && userAvatar!.trim() != 'null') {
      return userAvatar!.trim();
    }
    return 'https://i.pravatar.cc/150?u=$id';
  }

  String get displayRating {
    if (stats?.ratingLabel != null && stats!.ratingLabel!.trim().isNotEmpty) {
      return stats!.ratingLabel!.trim();
    }
    if (stats?.rating != null) {
      return stats!.rating!.toStringAsFixed(1);
    }
    final r = avgRating ?? talentScore ?? 9.0;
    return r.toStringAsFixed(1);
  }

  String get displayPrize {
    if (prizeWon != null && prizeWon!.trim().isNotEmpty) {
      final p = prizeWon!.trim();
      return p.startsWith('₹') || p.startsWith(r'$') ? p : '₹$p';
    }
    return prize ?? 'Prize Awarded';
  }

  String get displayBannerUrl {
    if (challenge?.bannerUrl != null &&
        challenge!.bannerUrl!.trim().isNotEmpty &&
        challenge!.bannerUrl!.trim() != 'null') {
      return challenge!.bannerUrl!.trim();
    }
    if (entry?.thumbnailUrl != null &&
        entry!.thumbnailUrl!.trim().isNotEmpty &&
        entry!.thumbnailUrl!.trim() != 'null') {
      return entry!.thumbnailUrl!.trim();
    }
    if (bannerUrl != null && bannerUrl!.trim().isNotEmpty) return bannerUrl!.trim();
    return 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600&auto=format&fit=crop&q=80';
  }

  String get displayRankLabel {
    if (rankLabel != null && rankLabel!.trim().isNotEmpty) {
      return rankLabel!.trim();
    }
    final r = displayRank;
    if (r == 1) return '#1';
    if (r == 2) return '#2';
    if (r == 3) return '#3';
    return '#$r';
  }

  String get displayChallengeTitle {
    if (challenge?.title != null && challenge!.title!.trim().isNotEmpty) {
      return challenge!.title!.trim();
    }
    if (challengeTitle != null && challengeTitle!.trim().isNotEmpty) return challengeTitle!.trim();
    return 'Monthly Challenge';
  }

  Map<String, dynamic> toUiMap() {
    return {
      'id': id,
      'rank': displayRank,
      'rankLabel': displayRankLabel,
      'userId': winner?.id ?? userId,
      'challengeId': challenge?.id ?? challengeId,
      'reelId': entry?.id ?? reelId,
      'prize': displayPrize,
      'talentScore': stats?.rating ?? talentScore ?? 9.0,
      'avgRating': stats?.rating ?? avgRating ?? 9.0,
      'totalVotes': stats?.ratingCount ?? totalVotes ?? 0,
      'winDate': wonOn ?? winDate,
      'period': period ?? 'Monthly',
      'featured': featured,
      'challengeTitle': displayChallengeTitle,
      'userName': displayName,
      'userHandle': displayHandle,
      'userAvatar': displayAvatar,
      'bannerUrl': displayBannerUrl,
      'videoUrl': entry?.videoUrl,
      'thumbnailUrl': entry?.thumbnailUrl ?? displayBannerUrl,
    };
  }

  factory WinnerItem.fromJson(Map<String, dynamic> json) {
    return WinnerItem(
      id: json['id']?.toString() ?? '',
      position: (json['position'] as num?)?.toInt(),
      rankLabel: json['rankLabel']?.toString(),
      prizeWon: json['prizeWon']?.toString(),
      wonOn: json['wonOn']?.toString(),
      challenge: json['challenge'] is Map
          ? WinnerChallenge.fromJson(Map<String, dynamic>.from(json['challenge'] as Map))
          : null,
      winner: json['winner'] is Map
          ? WinnerUser.fromJson(Map<String, dynamic>.from(json['winner'] as Map))
          : null,
      entry: json['entry'] is Map
          ? WinnerEntry.fromJson(Map<String, dynamic>.from(json['entry'] as Map))
          : null,
      stats: json['stats'] is Map
          ? WinnerStats.fromJson(Map<String, dynamic>.from(json['stats'] as Map))
          : null,
      // Legacy fallback
      rank: (json['rank'] as num?)?.toInt(),
      userId: json['userId']?.toString() ?? (json['winner'] is Map ? (json['winner'] as Map)['id']?.toString() : null),
      challengeId: json['challengeId']?.toString() ?? (json['challenge'] is Map ? (json['challenge'] as Map)['id']?.toString() : null),
      reelId: json['reelId']?.toString() ?? (json['entry'] is Map ? (json['entry'] as Map)['id']?.toString() : null),
      prize: json['prize']?.toString() ?? json['prizeWon']?.toString(),
      talentScore: (json['talentScore'] as num?)?.toDouble() ?? (json['stats'] is Map ? (json['stats']['rating'] as num?)?.toDouble() : null),
      avgRating: (json['avgRating'] as num?)?.toDouble() ?? (json['stats'] is Map ? (json['stats']['rating'] as num?)?.toDouble() : null),
      totalVotes: (json['totalVotes'] as num?)?.toInt() ?? (json['stats'] is Map ? (json['stats']['ratingCount'] as num?)?.toInt() : null),
      winDate: json['winDate']?.toString() ?? json['wonOn']?.toString(),
      period: json['period']?.toString(),
      featured: json['featured'] == true,
      challengeTitle: json['challengeTitle']?.toString() ?? (json['challenge'] is Map ? (json['challenge'] as Map)['title']?.toString() : null),
      userName: json['userName']?.toString() ?? (json['winner'] is Map ? (json['winner'] as Map)['name']?.toString() : null),
      userHandle: json['userHandle']?.toString() ?? (json['winner'] is Map ? (json['winner'] as Map)['username']?.toString() : null),
      userAvatar: json['userAvatar']?.toString() ?? (json['winner'] is Map ? (json['winner'] as Map)['profilePhotoUrl']?.toString() : null),
      bannerUrl: json['bannerUrl']?.toString() ?? (json['challenge'] is Map ? (json['challenge'] as Map)['bannerUrl']?.toString() : null),
    );
  }
}

class WinnersResponse {
  const WinnersResponse({
    required this.success,
    required this.message,
    this.scope,
    this.tabs = const ['Challenge', 'Weekly', 'Monthly'],
    this.winners = const [],
    this.moreWinners = const [],
    this.featuredWinner,
    this.totalWinners = 0,
  });

  final bool success;
  final String message;
  final String? scope;
  final List<String> tabs;
  final List<WinnerItem> winners;
  final List<WinnerItem> moreWinners;
  final WinnerItem? featuredWinner;
  final int totalWinners;

  factory WinnersResponse.fromJson(Map<String, dynamic> json) {
    final dataObj = json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : json;

    final rawWinners = dataObj['winners'] as List? ?? [];
    final parsedWinners = rawWinners
        .whereType<Map>()
        .map((e) => WinnerItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final rawMore = dataObj['moreWinners'] as List? ?? [];
    final parsedMore = rawMore
        .whereType<Map>()
        .map((e) => WinnerItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    WinnerItem? featured;
    if (dataObj['featuredWinner'] != null && dataObj['featuredWinner'] is Map) {
      featured = WinnerItem.fromJson(
          Map<String, dynamic>.from(dataObj['featuredWinner'] as Map));
    }

    final rawTabs = (dataObj['tabs'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        (json['availableTabs'] as List?)?.map((e) => e.toString()).toList() ??
        ['Challenge', 'Weekly', 'Monthly'];

    return WinnersResponse(
      success: json['success'] == true || json['status'] == 200,
      message: json['message']?.toString() ?? 'Successfully',
      scope: dataObj['scope']?.toString(),
      tabs: rawTabs,
      winners: parsedWinners,
      moreWinners: parsedMore,
      featuredWinner: featured,
      totalWinners: (dataObj['totalWinners'] as num?)?.toInt() ?? (parsedWinners.length + parsedMore.length),
    );
  }
}
