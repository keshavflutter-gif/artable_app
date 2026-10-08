import 'my_videos_response.dart';

class ProfileResponse {
  const ProfileResponse({
    required this.success,
    this.message,
    required this.data,
  });

  final bool success;
  final String? message;
  final ProfileData data;

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    final dataRaw = json['data'];
    return ProfileResponse(
      success: json['success'] == true,
      message: json['message']?.toString(),
      data: dataRaw is Map<String, dynamic>
          ? ProfileData.fromJson(dataRaw)
          : dataRaw is Map
              ? ProfileData.fromJson(Map<String, dynamic>.from(dataRaw))
              : ProfileData.empty(),
    );
  }

  ProfileResponse copyWith({
    bool? success,
    String? message,
    ProfileData? data,
  }) {
    return ProfileResponse(
      success: success ?? this.success,
      message: message ?? this.message,
      data: data ?? this.data,
    );
  }
}

class ProfileData {
  const ProfileData({
    required this.user,
    required this.stats,
    this.statCards = const [],
    this.recentVideos = const [],
    this.recentVideosTitle = 'Recent Videos',
    this.recentVideosSeeAllRoute = '/app/profile/videos',
    this.badges = const [],
    this.tabs = const ['Videos', 'Achievements', 'Stats'],
  });

  final ProfileUser user;
  final ProfileStats stats;
  final List<ProfileStatCard> statCards;
  final List<MyVideoItem> recentVideos;
  final String recentVideosTitle;
  final String recentVideosSeeAllRoute;
  final List<ProfileBadgeItem> badges;
  final List<String> tabs;

  ProfileData copyWith({
    ProfileUser? user,
    ProfileStats? stats,
    List<ProfileStatCard>? statCards,
    List<MyVideoItem>? recentVideos,
    String? recentVideosTitle,
    String? recentVideosSeeAllRoute,
    List<ProfileBadgeItem>? badges,
    List<String>? tabs,
  }) {
    return ProfileData(
      user: user ?? this.user,
      stats: stats ?? this.stats,
      statCards: statCards ?? this.statCards,
      recentVideos: recentVideos ?? this.recentVideos,
      recentVideosTitle: recentVideosTitle ?? this.recentVideosTitle,
      recentVideosSeeAllRoute: recentVideosSeeAllRoute ?? this.recentVideosSeeAllRoute,
      badges: badges ?? this.badges,
      tabs: tabs ?? this.tabs,
    );
  }


  factory ProfileData.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> root = json;
    if (json['data'] is Map<String, dynamic>) {
      root = Map<String, dynamic>.from(json['data'] as Map);
    } else if (json['data'] is Map) {
      root = Map<String, dynamic>.from(json['data'] as Map);
    }

    final userRaw = root['user'] ?? root;
    final userObj = userRaw is Map<String, dynamic>
        ? ProfileUser.fromJson(userRaw)
        : userRaw is Map
            ? ProfileUser.fromJson(Map<String, dynamic>.from(userRaw))
            : ProfileUser.empty();

    final statsRaw = root['stats'] ?? root;
    final statsObj = statsRaw is Map<String, dynamic>
        ? ProfileStats.fromJson(statsRaw)
        : statsRaw is Map
            ? ProfileStats.fromJson(Map<String, dynamic>.from(statsRaw))
            : ProfileStats.empty();

    final statCardsRaw = root['statCards'];
    final statCardsList = <ProfileStatCard>[];
    if (statCardsRaw is List) {
      for (final item in statCardsRaw) {
        if (item is Map<String, dynamic>) {
          statCardsList.add(ProfileStatCard.fromJson(item));
        } else if (item is Map) {
          statCardsList.add(ProfileStatCard.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final videosRaw = root['recentVideos'] ?? root['videos'];
    final videosList = <MyVideoItem>[];
    if (videosRaw is List) {
      for (final item in videosRaw) {
        if (item is Map<String, dynamic>) {
          videosList.add(MyVideoItem.fromJson(item));
        } else if (item is Map) {
          videosList.add(MyVideoItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final badgesRaw = root['badges'];
    final badgesList = <ProfileBadgeItem>[];
    if (badgesRaw is List) {
      for (final item in badgesRaw) {
        if (item is Map<String, dynamic>) {
          badgesList.add(ProfileBadgeItem.fromJson(item));
        } else if (item is Map) {
          badgesList.add(ProfileBadgeItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final tabsRaw = root['tabs'];
    final tabsList = <String>[];
    if (tabsRaw is List) {
      for (final item in tabsRaw) {
        if (item != null) {
          tabsList.add(item.toString());
        }
      }
    }

    return ProfileData(
      user: userObj,
      stats: statsObj,
      statCards: statCardsList,
      recentVideos: videosList,
      recentVideosTitle: root['recentVideosTitle']?.toString() ?? 'Recent Videos',
      recentVideosSeeAllRoute:
          root['recentVideosSeeAllRoute']?.toString() ?? '/app/profile/videos',
      badges: badgesList,
      tabs: tabsList.isNotEmpty ? tabsList : const ['Videos', 'Achievements', 'Stats'],
    );
  }

  factory ProfileData.empty() {
    return ProfileData(
      user: ProfileUser.empty(),
      stats: ProfileStats.empty(),
    );
  }
}

class ProfileUser {
  const ProfileUser({
    required this.id,
    this.fullName,
    this.username,
    this.email,
    this.profilePhotoUrl,
    this.coverImageUrl,
    this.bio,
    this.socialLinks,
    this.talentCategory,
    this.role = 'DEFAULT',
    this.isBlueTick = false,
    this.isVerified = false,
    this.isPrime = false,
  });

  final String id;
  final String? fullName;
  final String? username;
  final String? email;
  final String? profilePhotoUrl;
  final String? coverImageUrl;
  final String? bio;
  final dynamic socialLinks;
  final String? talentCategory;
  final String role;
  final bool isBlueTick;
  final bool isVerified;
  final bool isPrime;

  factory ProfileUser.fromJson(Map<String, dynamic> json) {
    return ProfileUser(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? json['full_name']?.toString() ?? json['name']?.toString(),
      username: json['username']?.toString() ?? json['user_name']?.toString(),
      email: json['email']?.toString(),
      profilePhotoUrl: json['profilePhotoUrl']?.toString() ?? json['profile_photo_url']?.toString() ?? json['avatarUrl']?.toString(),
      coverImageUrl: json['coverImageUrl']?.toString() ?? json['cover_image_url']?.toString() ?? json['coverUrl']?.toString(),
      bio: json['bio']?.toString(),
      socialLinks: json['socialLinks'],
      talentCategory: json['talentCategory']?.toString() ?? json['talent_category']?.toString() ?? json['category']?.toString(),
      isBlueTick: json['isBlueTick'] == true || json['is_blue_tick'] == true || json['isBlueTick']?.toString() == 'true',
      isVerified: json['isVerified'] == true || json['is_verified'] == true || json['isVerified']?.toString() == 'true',
      isPrime: json['isPrime'] == true || json['is_prime'] == true || json['isPrime']?.toString() == 'true',
    );
  }

  factory ProfileUser.empty() {
    return const ProfileUser(id: '');
  }
}

class ProfileStats {
  const ProfileStats({
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
    this.followers = 0,
    this.following = 0,
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
  final int followers;
  final int following;

  factory ProfileStats.fromJson(Map<String, dynamic> json) {
    num parsedTalentScore = 0;
    final rawScore = json['talentScore'] ?? json['talent_score'];
    if (rawScore is num) {
      parsedTalentScore = rawScore;
    } else if (rawScore != null) {
      parsedTalentScore = double.tryParse(rawScore.toString()) ?? 0;
    }

    num parsedEarnings = 0;
    final rawEarn = json['rewardEarnings'] ?? json['reward_earnings'];
    if (rawEarn is num) {
      parsedEarnings = rawEarn;
    } else if (rawEarn != null) {
      parsedEarnings = double.tryParse(rawEarn.toString()) ?? 0;
    }

    return ProfileStats(
      totalVideos: (json['totalVideos'] as num?)?.toInt() ?? 0,
      approvedVideos: (json['approvedVideos'] as num?)?.toInt() ?? 0,
      totalLikes: (json['totalLikes'] as num?)?.toInt() ?? 0,
      totalViews: (json['totalViews'] as num?)?.toInt() ?? 0,
      talentScore: parsedTalentScore,
      wins: (json['wins'] as num?)?.toInt() ?? (json['challengesWon'] as num?)?.toInt() ?? 0,
      joinedChallenges: (json['joinedChallenges'] as num?)?.toInt() ?? 0,
      topThree: (json['topThree'] as num?)?.toInt() ?? 0,
      rewardEarnings: parsedEarnings,
      referrals: (json['referrals'] as num?)?.toInt() ?? 0,
      maxVideoLikes: (json['maxVideoLikes'] as num?)?.toInt() ?? 0,
      maxRatingCount: (json['maxRatingCount'] as num?)?.toInt() ?? 0,
      followers: (json['followers'] as num?)?.toInt() ?? (json['followersCount'] as num?)?.toInt() ?? 0,
      following: (json['following'] as num?)?.toInt() ?? (json['followingCount'] as num?)?.toInt() ?? 0,
    );
  }

  factory ProfileStats.empty() {
    return const ProfileStats();
  }
}

class ProfileStatCard {
  const ProfileStatCard({
    required this.key,
    required this.label,
    required this.value,
    required this.displayValue,
  });

  final String key;
  final String label;
  final num value;
  final String displayValue;

  factory ProfileStatCard.fromJson(Map<String, dynamic> json) {
    return ProfileStatCard(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      value: (json['value'] as num?) ?? 0,
      displayValue: json['displayValue']?.toString() ?? json['value']?.toString() ?? '0',
    );
  }
}

class ProfileBadgeItem {
  const ProfileBadgeItem({
    required this.id,
    required this.title,
    this.icon,
    this.badgeUrl,
    this.earned = true,
  });

  final String id;
  final String title;
  final String? icon;
  final String? badgeUrl;
  final bool earned;

  factory ProfileBadgeItem.fromJson(Map<String, dynamic> json) {
    return ProfileBadgeItem(
      id: json['id']?.toString() ?? json['key']?.toString() ?? '',
      title: json['title']?.toString() ?? json['label']?.toString() ?? json['name']?.toString() ?? 'Badge',
      icon: json['icon']?.toString(),
      badgeUrl: json['badgeUrl']?.toString() ?? json['imageUrl']?.toString(),
      earned: json['earned'] != false,
    );
  }
}
