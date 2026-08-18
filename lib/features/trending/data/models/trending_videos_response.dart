class TrendingVideosResponse {
  const TrendingVideosResponse({
    required this.success,
    this.message,
    this.data,
    this.pagination,
  });

  final bool success;
  final String? message;
  final TrendingVideosData? data;
  final TrendingPagination? pagination;

  factory TrendingVideosResponse.fromJson(Map<String, dynamic> json) {
    return TrendingVideosResponse(
      success: json['success'] == true,
      message: json['message']?.toString(),
      data: json['data'] is Map<String, dynamic>
          ? TrendingVideosData.fromJson(json['data'] as Map<String, dynamic>)
          : (json['data'] is Map
              ? TrendingVideosData.fromJson(
                  Map<String, dynamic>.from(json['data'] as Map))
              : null),
      pagination: json['pagination'] is Map<String, dynamic>
          ? TrendingPagination.fromJson(
              json['pagination'] as Map<String, dynamic>)
          : (json['pagination'] is Map
              ? TrendingPagination.fromJson(
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

class TrendingVideosData {
  const TrendingVideosData({
    this.hero,
    this.videos = const [],
    this.moreTrendingTalent = const [],
    this.tabs = const [],
    this.categories = const [],
    this.filters,
  });

  final TrendingVideoItem? hero;
  final List<TrendingVideoItem> videos;
  final List<TrendingVideoItem> moreTrendingTalent;
  final List<String> tabs;
  final List<TrendingCategoryItem> categories;
  final TrendingFilters? filters;

  List<TrendingVideoItem> get gridVideos {
    if (moreTrendingTalent.isNotEmpty) {
      return moreTrendingTalent;
    }
    return videos;
  }

  factory TrendingVideosData.fromJson(Map<String, dynamic> json) {
    return TrendingVideosData(
      hero: json['hero'] is Map
          ? TrendingVideoItem.fromJson(
              Map<String, dynamic>.from(json['hero'] as Map))
          : null,
      videos: _parseVideoList(json['videos']),
      moreTrendingTalent: _parseVideoList(json['moreTrendingTalent']),
      tabs: json['tabs'] is List
          ? (json['tabs'] as List)
              .map((e) => e?.toString() ?? '')
              .where((e) => e.isNotEmpty)
              .toList()
          : const [],
      categories: json['categories'] is List
          ? (json['categories'] as List)
              .whereType<Map>()
              .map((c) => TrendingCategoryItem.fromJson(
                  Map<String, dynamic>.from(c)))
              .toList()
          : const [],
      filters: json['filters'] is Map
          ? TrendingFilters.fromJson(
              Map<String, dynamic>.from(json['filters'] as Map))
          : null,
    );
  }

  static List<TrendingVideoItem> _parseVideoList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((v) =>
            TrendingVideoItem.fromJson(Map<String, dynamic>.from(v)))
        .toList();
  }

  Map<String, dynamic> toJson() => {
        'hero': hero?.toJson(),
        'videos': videos.map((v) => v.toJson()).toList(),
        'moreTrendingTalent':
            moreTrendingTalent.map((v) => v.toJson()).toList(),
        'tabs': tabs,
        'categories': categories.map((c) => c.toJson()).toList(),
        'filters': filters?.toJson(),
      };
}

class TrendingVideoItem {
  const TrendingVideoItem({
    required this.id,
    required this.title,
    this.description,
    this.videoUrl,
    this.thumbnailUrl,
    this.status,
    this.statusMeta,
    this.statusBadge,
    this.durationSeconds,
    this.views = 0,
    this.viewCount = 0,
    this.viewsLabel,
    this.likes = 0,
    this.likeCount = 0,
    this.likesLabel,
    this.shares = 0,
    this.shareCount = 0,
    this.averageRating,
    this.talentScore,
    this.talentScoreLabel,
    this.ratingCount = 0,
    this.createdAt,
    this.dateLabel,
    this.statusLabel,
    this.isLive = false,
    this.canView = false,
    this.canShare = false,
    this.canContinueDraft = false,
    this.canViewFeedback = false,
    this.primaryAction,
    this.actions = const [],
    this.challenge,
    this.category,
    this.user,
    this.rank,
    this.trendingScore,
    this.badgeLabel,
    this.ratingLabel,
    this.isTrending = false,
  });

  final String id;
  final String title;
  final String? description;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String? status;
  final Map<String, dynamic>? statusMeta;
  final Map<String, dynamic>? statusBadge;
  final int? durationSeconds;
  final int views;
  final int viewCount;
  final String? viewsLabel;
  final int likes;
  final int likeCount;
  final String? likesLabel;
  final int shares;
  final int shareCount;
  final String? averageRating;
  final double? talentScore;
  final String? talentScoreLabel;
  final int ratingCount;
  final String? createdAt;
  final String? dateLabel;
  final String? statusLabel;
  final bool isLive;
  final bool canView;
  final bool canShare;
  final bool canContinueDraft;
  final bool canViewFeedback;
  final String? primaryAction;
  final List<Map<String, dynamic>> actions;
  final TrendingVideoChallenge? challenge;
  final TrendingVideoCategory? category;
  final TrendingVideoUser? user;
  final int? rank;
  final double? trendingScore;
  final String? badgeLabel;
  final String? ratingLabel;
  final bool isTrending;

  String get displayThumbnail {
    if (thumbnailUrl != null &&
        thumbnailUrl!.trim().isNotEmpty &&
        thumbnailUrl!.startsWith('http')) {
      return thumbnailUrl!.trim();
    }
    if (challenge?.bannerUrl != null &&
        challenge!.bannerUrl!.trim().isNotEmpty) {
      return challenge!.bannerUrl!.trim();
    }
    if (category?.imageUrl != null && category!.imageUrl!.trim().isNotEmpty) {
      return category!.imageUrl!.trim();
    }
    return 'https://images.unsplash.com/photo-1518834107812-67b0b7c58434?w=600&q=80';
  }

  String get displayCategoryName {
    if (badgeLabel != null && badgeLabel!.trim().isNotEmpty) {
      return badgeLabel!.trim();
    }
    if (category?.name != null && category!.name.trim().isNotEmpty) {
      return category!.name.trim();
    }
    return 'Talent';
  }

  String get displayRating {
    if (ratingLabel != null && ratingLabel!.trim().isNotEmpty) {
      return ratingLabel!.trim();
    }
    if (talentScoreLabel != null && talentScoreLabel!.trim().isNotEmpty) {
      return talentScoreLabel!.trim();
    }
    if (talentScore != null && talentScore! > 0) {
      return talentScore!.toStringAsFixed(1);
    }
    if (averageRating != null && averageRating!.trim().isNotEmpty) {
      return averageRating!.trim();
    }
    return '8.5';
  }

  String get displayViews {
    if (viewsLabel != null && viewsLabel!.trim().isNotEmpty) {
      return viewsLabel!.trim();
    }
    if (views > 0) {
      if (views >= 1000000) {
        return '${(views / 1000000).toStringAsFixed(1).replaceAll('.0', '')}M';
      }
      if (views >= 1000) {
        return '${(views / 1000).toStringAsFixed(1).replaceAll('.0', '')}K';
      }
      return views.toString();
    }
    if (viewCount > 0) {
      return viewCount.toString();
    }
    return '0';
  }

  String get displayHandle {
    final uname = user?.username?.trim();
    if (uname != null && uname.isNotEmpty) {
      return uname.startsWith('@') ? uname : '@$uname';
    }
    return '@creator';
  }

  String get displayCreatorName {
    if (user?.fullName != null && user!.fullName!.trim().isNotEmpty) {
      return user!.fullName!.trim();
    }
    if (user?.username != null && user!.username!.trim().isNotEmpty) {
      return user!.username!.trim();
    }
    return 'Creator';
  }

  String get displayAvatar {
    if (user?.profilePhotoUrl != null &&
        user!.profilePhotoUrl!.trim().isNotEmpty) {
      return user!.profilePhotoUrl!.trim();
    }
    return 'https://i.pravatar.cc/100?u=$id';
  }

  bool get isVerifiedUser =>
      user?.isBlueTick == true || user?.isVerified == true;

  Map<String, dynamic> toUiMap() {
    return {
      'id': id,
      'title': title,
      'description': description ?? '',
      'category': displayCategoryName,
      'imageUrl': displayThumbnail,
      'videoUrl': videoUrl ?? '',
      'views': displayViews,
      'likes': likesLabel ?? likes.toString(),
      'avatarUrl': displayAvatar,
      'handle': displayHandle,
      'creator': displayCreatorName,
      'talentScore': talentScore ?? 8.5,
      'rating': displayRating,
      'isBlueTick': isVerifiedUser,
      'verified': isVerifiedUser,
      'isTrending': isTrending,
      'challengeId': challenge?.id ?? '',
      'challengeTitle': challenge?.title ?? '',
    };
  }

  factory TrendingVideoItem.fromJson(Map<String, dynamic> json) {
    return TrendingVideoItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      videoUrl: json['videoUrl']?.toString(),
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      status: json['status']?.toString(),
      statusMeta: json['statusMeta'] is Map
          ? Map<String, dynamic>.from(json['statusMeta'] as Map)
          : null,
      statusBadge: json['statusBadge'] is Map
          ? Map<String, dynamic>.from(json['statusBadge'] as Map)
          : null,
      durationSeconds: _parseInt(json['durationSeconds']),
      views: _parseInt(json['views']) ?? 0,
      viewCount: _parseInt(json['viewCount']) ?? 0,
      viewsLabel: json['viewsLabel']?.toString(),
      likes: _parseInt(json['likes']) ?? 0,
      likeCount: _parseInt(json['likeCount']) ?? 0,
      likesLabel: json['likesLabel']?.toString(),
      shares: _parseInt(json['shares']) ?? 0,
      shareCount: _parseInt(json['shareCount']) ?? 0,
      averageRating: json['averageRating']?.toString(),
      talentScore: _parseDouble(json['talentScore']),
      talentScoreLabel: json['talentScoreLabel']?.toString(),
      ratingCount: _parseInt(json['ratingCount']) ?? 0,
      createdAt: json['createdAt']?.toString(),
      dateLabel: json['dateLabel']?.toString(),
      statusLabel: json['statusLabel']?.toString(),
      isLive: json['isLive'] == true,
      canView: json['canView'] == true,
      canShare: json['canShare'] == true,
      canContinueDraft: json['canContinueDraft'] == true,
      canViewFeedback: json['canViewFeedback'] == true,
      primaryAction: json['primaryAction']?.toString(),
      actions: json['actions'] is List
          ? (json['actions'] as List)
              .whereType<Map>()
              .map((a) => Map<String, dynamic>.from(a))
              .toList()
          : const [],
      challenge: json['challenge'] is Map
          ? TrendingVideoChallenge.fromJson(
              Map<String, dynamic>.from(json['challenge'] as Map))
          : null,
      category: json['category'] is Map
          ? TrendingVideoCategory.fromJson(
              Map<String, dynamic>.from(json['category'] as Map))
          : null,
      user: json['user'] is Map
          ? TrendingVideoUser.fromJson(
              Map<String, dynamic>.from(json['user'] as Map))
          : null,
      rank: _parseInt(json['rank']),
      trendingScore: _parseDouble(json['trendingScore']),
      badgeLabel: json['badgeLabel']?.toString(),
      ratingLabel: json['ratingLabel']?.toString(),
      isTrending: json['isTrending'] == true,
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
        'id': id,
        'title': title,
        'description': description,
        'videoUrl': videoUrl,
        'thumbnailUrl': thumbnailUrl,
        'status': status,
        'statusMeta': statusMeta,
        'statusBadge': statusBadge,
        'durationSeconds': durationSeconds,
        'views': views,
        'viewCount': viewCount,
        'viewsLabel': viewsLabel,
        'likes': likes,
        'likeCount': likeCount,
        'likesLabel': likesLabel,
        'shares': shares,
        'shareCount': shareCount,
        'averageRating': averageRating,
        'talentScore': talentScore,
        'talentScoreLabel': talentScoreLabel,
        'ratingCount': ratingCount,
        'createdAt': createdAt,
        'dateLabel': dateLabel,
        'statusLabel': statusLabel,
        'isLive': isLive,
        'canView': canView,
        'canShare': canShare,
        'canContinueDraft': canContinueDraft,
        'canViewFeedback': canViewFeedback,
        'primaryAction': primaryAction,
        'actions': actions,
        'challenge': challenge?.toJson(),
        'category': category?.toJson(),
        'user': user?.toJson(),
        'rank': rank,
        'trendingScore': trendingScore,
        'badgeLabel': badgeLabel,
        'ratingLabel': ratingLabel,
        'isTrending': isTrending,
      };
}

class TrendingVideoChallenge {
  const TrendingVideoChallenge({
    required this.id,
    required this.title,
    this.description,
    this.bannerUrl,
    this.status,
    this.isFeatured = false,
    this.startDate,
    this.endDate,
    this.rewardPool,
    this.participationFee,
    this.categoryId,
  });

  final String id;
  final String title;
  final String? description;
  final String? bannerUrl;
  final String? status;
  final bool isFeatured;
  final String? startDate;
  final String? endDate;
  final String? rewardPool;
  final String? participationFee;
  final String? categoryId;

  factory TrendingVideoChallenge.fromJson(Map<String, dynamic> json) {
    return TrendingVideoChallenge(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      bannerUrl: json['bannerUrl']?.toString(),
      status: json['status']?.toString(),
      isFeatured: json['isFeatured'] == true,
      startDate: json['startDate']?.toString(),
      endDate: json['endDate']?.toString(),
      rewardPool: json['rewardPool']?.toString(),
      participationFee: json['participationFee']?.toString(),
      categoryId: json['categoryId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'bannerUrl': bannerUrl,
        'status': status,
        'isFeatured': isFeatured,
        'startDate': startDate,
        'endDate': endDate,
        'rewardPool': rewardPool,
        'participationFee': participationFee,
        'categoryId': categoryId,
      };
}

class TrendingVideoCategory {
  const TrendingVideoCategory({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final bool isActive;

  factory TrendingVideoCategory.fromJson(Map<String, dynamic> json) {
    return TrendingVideoCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
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

class TrendingVideoUser {
  const TrendingVideoUser({
    required this.id,
    this.fullName,
    this.username,
    this.profilePhotoUrl,
    this.socialLinks = const {},
    this.talentCategory,
    this.isBlueTick = false,
    this.isVerified = false,
  });

  final String id;
  final String? fullName;
  final String? username;
  final String? profilePhotoUrl;
  final Map<String, dynamic> socialLinks;
  final String? talentCategory;
  final bool isBlueTick;
  final bool isVerified;

  factory TrendingVideoUser.fromJson(Map<String, dynamic> json) {
    return TrendingVideoUser(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString(),
      username: json['username']?.toString(),
      profilePhotoUrl: json['profilePhotoUrl']?.toString(),
      socialLinks: json['socialLinks'] is Map
          ? Map<String, dynamic>.from(json['socialLinks'] as Map)
          : const {},
      talentCategory: json['talentCategory']?.toString(),
      isBlueTick: json['isBlueTick'] == true,
      isVerified: json['isVerified'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'username': username,
        'profilePhotoUrl': profilePhotoUrl,
        'socialLinks': socialLinks,
        'talentCategory': talentCategory,
        'isBlueTick': isBlueTick,
        'isVerified': isVerified,
      };
}

class TrendingCategoryItem {
  const TrendingCategoryItem({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory TrendingCategoryItem.fromJson(Map<String, dynamic> json) {
    return TrendingCategoryItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}

class TrendingFilters {
  const TrendingFilters({
    this.tab,
    this.category,
    this.categoryId,
  });

  final String? tab;
  final String? category;
  final String? categoryId;

  factory TrendingFilters.fromJson(Map<String, dynamic> json) {
    return TrendingFilters(
      tab: json['tab']?.toString(),
      category: json['category']?.toString(),
      categoryId: json['categoryId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'tab': tab,
        'category': category,
        'categoryId': categoryId,
      };
}

class TrendingPagination {
  const TrendingPagination({
    this.page = 1,
    this.limit = 20,
    this.total = 0,
  });

  final int page;
  final int limit;
  final int total;

  factory TrendingPagination.fromJson(Map<String, dynamic> json) {
    return TrendingPagination(
      page: json['page'] is num
          ? (json['page'] as num).toInt()
          : (int.tryParse(json['page']?.toString() ?? '') ?? 1),
      limit: json['limit'] is num
          ? (json['limit'] as num).toInt()
          : (int.tryParse(json['limit']?.toString() ?? '') ?? 20),
      total: json['total'] is num
          ? (json['total'] as num).toInt()
          : (int.tryParse(json['total']?.toString() ?? '') ?? 0),
    );
  }

  Map<String, dynamic> toJson() => {
        'page': page,
        'limit': limit,
        'total': total,
      };
}
