class LeaderboardResponse {
  const LeaderboardResponse({
    required this.success,
    this.message,
    this.data,
    this.pagination,
  });

  final bool success;
  final String? message;
  final LeaderboardData? data;
  final LeaderboardPagination? pagination;

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) {
    return LeaderboardResponse(
      success: json['success'] == true,
      message: json['message']?.toString(),
      data: json['data'] is Map<String, dynamic>
          ? LeaderboardData.fromJson(json['data'] as Map<String, dynamic>)
          : (json['data'] is Map
              ? LeaderboardData.fromJson(
                  Map<String, dynamic>.from(json['data'] as Map))
              : null),
      pagination: json['pagination'] is Map<String, dynamic>
          ? LeaderboardPagination.fromJson(
              json['pagination'] as Map<String, dynamic>)
          : (json['pagination'] is Map
              ? LeaderboardPagination.fromJson(
                  Map<String, dynamic>.from(json['pagination'] as Map))
              : null),
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'data': data?.toJson(),
        'pagination': pagination?.toJson(),
      };
}

class LeaderboardData {
  const LeaderboardData({
    this.podium = const [],
    this.yourRank,
    this.currentUserRank,
    this.rankings = const [],
    this.fullRankings = const [],
    this.tabs = const [],
    this.categories = const [],
    this.filters,
  });

  final List<LeaderboardRankItem> podium;
  final LeaderboardRankItem? yourRank;
  final LeaderboardRankItem? currentUserRank;
  final List<LeaderboardRankItem> rankings;
  final List<LeaderboardRankItem> fullRankings;
  final List<String> tabs;
  final List<LeaderboardCategoryItem> categories;
  final LeaderboardFilters? filters;

  List<LeaderboardRankItem> get allRankings {
    if (fullRankings.isNotEmpty) {
      return fullRankings;
    }
    if (rankings.isNotEmpty) {
      return rankings;
    }
    return podium;
  }

  List<LeaderboardRankItem> get nonPodiumRankings {
    final list = allRankings;
    if (podium.isNotEmpty) {
      final podiumIds = podium.map((p) => p.user?.id ?? p.id).toSet();
      final filtered = list
          .where((item) => !podiumIds.contains(item.user?.id ?? item.id))
          .toList();
      if (filtered.isNotEmpty) return filtered;
    }
    if (list.length > 3) {
      return list.skip(3).toList();
    }
    return const [];
  }

  factory LeaderboardData.fromJson(Map<String, dynamic> json) {
    return LeaderboardData(
      podium: _parseRankItemList(json['podium']),
      yourRank: _parseRankItem(json['yourRank']),
      currentUserRank: _parseRankItem(json['currentUserRank']),
      rankings: _parseRankItemList(json['rankings']),
      fullRankings: _parseRankItemList(json['fullRankings']),
      tabs: json['tabs'] is List
          ? (json['tabs'] as List)
              .map((t) => t?.toString() ?? '')
              .where((t) => t.isNotEmpty)
              .toList()
          : const [],
      categories: json['categories'] is List
          ? (json['categories'] as List)
              .whereType<Map>()
              .map((c) => LeaderboardCategoryItem.fromJson(
                  Map<String, dynamic>.from(c)))
              .toList()
          : const [],
      filters: json['filters'] is Map
          ? LeaderboardFilters.fromJson(
              Map<String, dynamic>.from(json['filters'] as Map))
          : null,
    );
  }

  static List<LeaderboardRankItem> _parseRankItemList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) =>
            LeaderboardRankItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static LeaderboardRankItem? _parseRankItem(dynamic raw) {
    if (raw is Map) {
      return LeaderboardRankItem.fromJson(Map<String, dynamic>.from(raw));
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'podium': podium.map((p) => p.toJson()).toList(),
        'yourRank': yourRank?.toJson(),
        'currentUserRank': currentUserRank?.toJson(),
        'rankings': rankings.map((r) => r.toJson()).toList(),
        'fullRankings': fullRankings.map((r) => r.toJson()).toList(),
        'tabs': tabs,
        'categories': categories.map((c) => c.toJson()).toList(),
        'filters': filters?.toJson(),
      };
}

class LeaderboardRankItem {
  const LeaderboardRankItem({
    required this.rank,
    this.user,
    this.fullName,
    this.username,
    this.talentScore,
    this.talentScoreLabel,
    this.leaderboardScore,
    this.votes,
    this.votesLabel,
    this.likes = 0,
    this.views = 0,
    this.shares = 0,
    this.videosCount = 0,
    this.category,
    this.categoryName,
    this.bestVideo,
  });

  final int rank;
  final LeaderboardUser? user;
  final String? fullName;
  final String? username;
  final double? talentScore;
  final String? talentScoreLabel;
  final int? leaderboardScore;
  final int? votes;
  final String? votesLabel;
  final int likes;
  final int views;
  final int shares;
  final int videosCount;
  final LeaderboardCategory? category;
  final String? categoryName;
  final LeaderboardBestVideo? bestVideo;

  String get id => user?.id ?? '';

  String get displayName {
    if (fullName != null && fullName!.trim().isNotEmpty) {
      return fullName!.trim();
    }
    if (user?.fullName != null && user!.fullName!.trim().isNotEmpty) {
      return user!.fullName!.trim();
    }
    if (username != null && username!.trim().isNotEmpty) {
      return username!.trim();
    }
    if (user?.username != null && user!.username!.trim().isNotEmpty) {
      return user!.username!.trim();
    }
    return 'Creator';
  }

  String get displayHandle {
    final uname = username ?? user?.username;
    if (uname != null && uname.trim().isNotEmpty) {
      return uname.startsWith('@') ? uname.trim() : '@${uname.trim()}';
    }
    return '@creator';
  }

  String get displayAvatar {
    if (user?.profilePhotoUrl != null &&
        user!.profilePhotoUrl!.trim().isNotEmpty) {
      return user!.profilePhotoUrl!.trim();
    }
    return 'https://i.pravatar.cc/100?u=${user?.id ?? rank}';
  }

  String get displayCategory {
    if (categoryName != null && categoryName!.trim().isNotEmpty) {
      return categoryName!.trim();
    }
    if (category?.name != null && category!.name!.trim().isNotEmpty) {
      return category!.name!.trim();
    }
    if (user?.talentCategory != null &&
        user!.talentCategory!.trim().isNotEmpty) {
      return user!.talentCategory!.trim();
    }
    return 'General';
  }

  String get displayScore {
    if (talentScoreLabel != null && talentScoreLabel!.trim().isNotEmpty) {
      return talentScoreLabel!.trim();
    }
    if (talentScore != null && talentScore! > 0) {
      return talentScore!.toStringAsFixed(1);
    }
    return '8.5';
  }

  String get displayVotes {
    if (votesLabel != null && votesLabel!.trim().isNotEmpty) {
      return votesLabel!.trim();
    }
    final v = votes ?? 0;
    return '$v ${v == 1 ? 'vote' : 'votes'}';
  }

  bool get isVerifiedUser =>
      user?.isBlueTick == true || user?.isVerified == true;

  Map<String, dynamic> toUiMap() {
    return {
      'id': user?.id ?? '',
      'name': displayName,
      'handle': displayHandle,
      'category': displayCategory,
      'talentScore': talentScore ?? 8.5,
      'score': displayScore,
      'votes': votes ?? 0,
      'votesLabel': displayVotes,
      'avatarUrl': displayAvatar,
      'verified': isVerifiedUser,
      'rank': rank,
      'bestVideo': bestVideo?.toJson(),
    };
  }

  factory LeaderboardRankItem.fromJson(Map<String, dynamic> json) {
    return LeaderboardRankItem(
      rank: _parseInt(json['rank']) ?? 1,
      user: json['user'] is Map
          ? LeaderboardUser.fromJson(
              Map<String, dynamic>.from(json['user'] as Map))
          : null,
      fullName: json['fullName']?.toString(),
      username: json['username']?.toString(),
      talentScore: _parseDouble(json['talentScore']),
      talentScoreLabel: json['talentScoreLabel']?.toString(),
      leaderboardScore: _parseInt(json['leaderboardScore']),
      votes: _parseInt(json['votes']),
      votesLabel: json['votesLabel']?.toString(),
      likes: _parseInt(json['likes']) ?? 0,
      views: _parseInt(json['views']) ?? 0,
      shares: _parseInt(json['shares']) ?? 0,
      videosCount: _parseInt(json['videosCount']) ?? 0,
      category: json['category'] is Map
          ? LeaderboardCategory.fromJson(
              Map<String, dynamic>.from(json['category'] as Map))
          : null,
      categoryName: json['categoryName']?.toString(),
      bestVideo: json['bestVideo'] is Map
          ? LeaderboardBestVideo.fromJson(
              Map<String, dynamic>.from(json['bestVideo'] as Map))
          : null,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() => {
        'rank': rank,
        'user': user?.toJson(),
        'fullName': fullName,
        'username': username,
        'talentScore': talentScore,
        'talentScoreLabel': talentScoreLabel,
        'leaderboardScore': leaderboardScore,
        'votes': votes,
        'votesLabel': votesLabel,
        'likes': likes,
        'views': views,
        'shares': shares,
        'videosCount': videosCount,
        'category': category?.toJson(),
        'categoryName': categoryName,
        'bestVideo': bestVideo?.toJson(),
      };
}

class LeaderboardUser {
  const LeaderboardUser({
    required this.id,
    this.fullName,
    this.username,
    this.email,
    this.profilePhotoUrl,
    this.coverImageUrl,
    this.bio,
    this.socialLinks = const {},
    this.talentCategory,
    this.role,
    this.isBlueTick = false,
    this.isVerified = false,
  });

  final String id;
  final String? fullName;
  final String? username;
  final String? email;
  final String? profilePhotoUrl;
  final String? coverImageUrl;
  final String? bio;
  final Map<String, dynamic> socialLinks;
  final String? talentCategory;
  final String? role;
  final bool isBlueTick;
  final bool isVerified;

  factory LeaderboardUser.fromJson(Map<String, dynamic> json) {
    return LeaderboardUser(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString(),
      username: json['username']?.toString(),
      email: json['email']?.toString(),
      profilePhotoUrl: json['profilePhotoUrl']?.toString(),
      coverImageUrl: json['coverImageUrl']?.toString(),
      bio: json['bio']?.toString(),
      socialLinks: json['socialLinks'] is Map
          ? Map<String, dynamic>.from(json['socialLinks'] as Map)
          : const {},
      talentCategory: json['talentCategory']?.toString(),
      role: json['role']?.toString(),
      isBlueTick: json['isBlueTick'] == true,
      isVerified: json['isVerified'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'username': username,
        'email': email,
        'profilePhotoUrl': profilePhotoUrl,
        'coverImageUrl': coverImageUrl,
        'bio': bio,
        'socialLinks': socialLinks,
        'talentCategory': talentCategory,
        'role': role,
        'isBlueTick': isBlueTick,
        'isVerified': isVerified,
      };
}

class LeaderboardCategory {
  const LeaderboardCategory({
    this.id,
    this.name,
    this.description,
    this.imageUrl,
    this.isActive = true,
  });

  final String? id;
  final String? name;
  final String? description;
  final String? imageUrl;
  final bool isActive;

  factory LeaderboardCategory.fromJson(Map<String, dynamic> json) {
    return LeaderboardCategory(
      id: json['id']?.toString(),
      name: json['name']?.toString(),
      description: json['description']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      isActive: json['isActive'] != false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'isActive': isActive,
      };
}

class LeaderboardCategoryItem {
  const LeaderboardCategoryItem({
    this.id,
    required this.name,
  });

  final String? id;
  final String name;

  factory LeaderboardCategoryItem.fromJson(Map<String, dynamic> json) {
    return LeaderboardCategoryItem(
      id: json['id']?.toString(),
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}

class LeaderboardBestVideo {
  const LeaderboardBestVideo({
    required this.id,
    required this.title,
    this.description,
    this.videoUrl,
    this.thumbnailUrl,
    this.status,
    this.durationSeconds,
    this.views = 0,
    this.likes = 0,
    this.shares = 0,
    this.averageRating,
    this.talentScore,
  });

  final String id;
  final String title;
  final String? description;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String? status;
  final int? durationSeconds;
  final int views;
  final int likes;
  final int shares;
  final String? averageRating;
  final double? talentScore;

  factory LeaderboardBestVideo.fromJson(Map<String, dynamic> json) {
    return LeaderboardBestVideo(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      videoUrl: json['videoUrl']?.toString(),
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      status: json['status']?.toString(),
      durationSeconds: json['durationSeconds'] is num
          ? (json['durationSeconds'] as num).toInt()
          : int.tryParse(json['durationSeconds']?.toString() ?? ''),
      views: json['views'] is num
          ? (json['views'] as num).toInt()
          : (int.tryParse(json['views']?.toString() ?? '') ?? 0),
      likes: json['likes'] is num
          ? (json['likes'] as num).toInt()
          : (int.tryParse(json['likes']?.toString() ?? '') ?? 0),
      shares: json['shares'] is num
          ? (json['shares'] as num).toInt()
          : (int.tryParse(json['shares']?.toString() ?? '') ?? 0),
      averageRating: json['averageRating']?.toString(),
      talentScore: json['talentScore'] is num
          ? (json['talentScore'] as num).toDouble()
          : double.tryParse(json['talentScore']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'videoUrl': videoUrl,
        'thumbnailUrl': thumbnailUrl,
        'status': status,
        'durationSeconds': durationSeconds,
        'views': views,
        'likes': likes,
        'shares': shares,
        'averageRating': averageRating,
        'talentScore': talentScore,
      };
}

class LeaderboardFilters {
  const LeaderboardFilters({
    this.scope,
    this.category,
    this.categoryId,
    this.challengeId,
  });

  final String? scope;
  final String? category;
  final String? categoryId;
  final String? challengeId;

  factory LeaderboardFilters.fromJson(Map<String, dynamic> json) {
    return LeaderboardFilters(
      scope: json['scope']?.toString(),
      category: json['category']?.toString(),
      categoryId: json['categoryId']?.toString(),
      challengeId: json['challengeId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'scope': scope,
        'category': category,
        'categoryId': categoryId,
        'challengeId': challengeId,
      };
}

class LeaderboardPagination {
  const LeaderboardPagination({
    this.page = 1,
    this.limit = 20,
    this.total = 0,
    this.totalVideos = 0,
  });

  final int page;
  final int limit;
  final int total;
  final int totalVideos;

  factory LeaderboardPagination.fromJson(Map<String, dynamic> json) {
    return LeaderboardPagination(
      page: json['page'] is num
          ? (json['page'] as num).toInt()
          : (int.tryParse(json['page']?.toString() ?? '') ?? 1),
      limit: json['limit'] is num
          ? (json['limit'] as num).toInt()
          : (int.tryParse(json['limit']?.toString() ?? '') ?? 20),
      total: json['total'] is num
          ? (json['total'] as num).toInt()
          : (int.tryParse(json['total']?.toString() ?? '') ?? 0),
      totalVideos: json['totalVideos'] is num
          ? (json['totalVideos'] as num).toInt()
          : (int.tryParse(json['totalVideos']?.toString() ?? '') ?? 0),
    );
  }

  Map<String, dynamic> toJson() => {
        'page': page,
        'limit': limit,
        'total': total,
        'totalVideos': totalVideos,
      };
}
