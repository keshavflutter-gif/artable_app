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
    TrendingVideosData? data;
    if (json['data'] is Map) {
      data = TrendingVideosData.fromJson(
          Map<String, dynamic>.from(json['data'] as Map));
    } else if (json['data'] is List) {
      data = TrendingVideosData(
          videos: TrendingVideosData._parseVideoList(json['data']));
    } else if (json['videos'] is List || json['trendingVideos'] is List) {
      data = TrendingVideosData.fromJson(json);
    }

    return TrendingVideosResponse(
      success: json['success'] == true || json['status'] == 200 || data != null,
      message: json['message']?.toString(),
      data: data,
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
    final list = <TrendingVideoItem>[];
    if (hero != null) list.add(hero!);
    for (final v in videos) {
      if (!list.any((item) => item.id == v.id)) {
        list.add(v);
      }
    }
    for (final v in moreTrendingTalent) {
      if (!list.any((item) => item.id == v.id)) {
        list.add(v);
      }
    }
    return list;
  }

  factory TrendingVideosData.fromJson(Map<String, dynamic> json) {
    final rawVideos = json['videos'] ??
        json['trendingVideos'] ??
        json['trending_videos'] ??
        json['trending'] ??
        json['items'];
    final rawMore = json['moreTrendingTalent'] ??
        json['moreVideos'] ??
        json['more'];

    return TrendingVideosData(
      hero: json['hero'] is Map
          ? TrendingVideoItem.fromJson(
              Map<String, dynamic>.from(json['hero'] as Map))
          : null,
      videos: _parseVideoList(rawVideos),
      moreTrendingTalent: _parseVideoList(rawMore),
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
    this.hashtags = const [],
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
  final List<String> hashtags;

  String get playableVideoUrl {
    if (videoUrl != null && videoUrl!.trim().isNotEmpty && videoUrl!.trim() != 'null') {
      return videoUrl!.trim();
    }
    return '';
  }

  String get displayThumbnail {
    if (thumbnailUrl != null && thumbnailUrl!.trim().isNotEmpty && thumbnailUrl!.trim() != 'null') {
      return thumbnailUrl!.trim();
    }
    if (challenge?.bannerUrl != null && challenge!.bannerUrl!.trim().isNotEmpty) {
      return challenge!.bannerUrl!.trim();
    }
    if (category?.imageUrl != null && category!.imageUrl!.trim().isNotEmpty) {
      return category!.imageUrl!.trim();
    }
    return 'https://images.unsplash.com/photo-1547153760-18fc86324498?w=600&q=80';
  }

  String get displayCategoryName {
    if (badgeLabel != null && badgeLabel!.trim().isNotEmpty) {
      return badgeLabel!.trim();
    }
    if (category?.name != null && category!.name.trim().isNotEmpty) {
      return category!.name.trim();
    }
    return 'Dance';
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
    return '8.7';
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
    return '1.2M';
  }

  String get displayHandle {
    final uname = user?.username?.trim();
    if (uname != null && uname.isNotEmpty && uname != 'demouser7314') {
      return uname.startsWith('@') ? uname : '@$uname';
    }
    return '@dance_hero';
  }

  String get displayCreatorName {
    if (user?.fullName != null && user!.fullName!.trim().isNotEmpty) {
      return user!.fullName!.trim();
    }
    if (user?.username != null && user!.username!.trim().isNotEmpty && user!.username != 'demouser7314') {
      return user!.username!.trim();
    }
    return 'Maya R.';
  }

  String get displayAvatar {
    if (user?.profilePhotoUrl != null && user!.profilePhotoUrl!.trim().isNotEmpty) {
      return user!.profilePhotoUrl!.trim();
    }
    return 'https://i.pravatar.cc/100?u=${id.isNotEmpty ? id : 'user'}';
  }

  bool get isVerifiedUser =>
      user?.isBlueTick == true || user?.isVerified == true;

  String get displayLikes {
    if (likesLabel != null && likesLabel!.trim().isNotEmpty) {
      return likesLabel!.trim();
    }
    final count = likes > 0 ? likes : (likeCount > 0 ? likeCount : 0);
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1).replaceAll('.0', '')}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1).replaceAll('.0', '')}K';
    }
    return count.toString();
  }

  String get displayComments {
    return '2.4K';
  }

  String get displayShares {
    final count = shares > 0 ? shares : (shareCount > 0 ? shareCount : 0);
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1).replaceAll('.0', '')}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1).replaceAll('.0', '')}K';
    }
    return count > 0 ? count.toString() : '8.1K';
  }

  String get displayMusicName {
    final creatorName = displayCreatorName;
    return 'Original Sound — $creatorName';
  }

  String get displayCaption {
    final desc = (description != null && description!.trim().isNotEmpty)
        ? description!.trim()
        : (title.trim().isNotEmpty && title.trim() != 'Freestyle finale'
            ? title.trim()
            : '');

    final tagsStr = hashtags.isNotEmpty ? hashtags.join(' ') : '';

    if (desc.isNotEmpty && tagsStr.isNotEmpty) {
      if (desc.contains('#')) return desc;
      return '$desc $tagsStr';
    }
    if (desc.isNotEmpty) return desc;
    if (tagsStr.isNotEmpty) return tagsStr;
    return '';
  }

  Map<String, dynamic> toUiMap() {
    return {
      'id': id.isNotEmpty ? id : 'r1',
      'title': title.isNotEmpty ? title : 'Freestyle finale',
      'description': description ?? '',
      'caption': displayCaption,
      'hashtags': hashtags,
      'category': displayCategoryName,
      'imageUrl': displayThumbnail,
      'thumbnailUrl': displayThumbnail,
      'videoUrl': playableVideoUrl,
      'views': displayViews,
      'likes': displayLikes,
      'likesCount': likes > 0 ? likes : likeCount,
      'comments': displayComments,
      'shares': displayShares,
      'musicName': displayMusicName,
      'avatarUrl': displayAvatar,
      'handle': displayHandle,
      'creator': displayCreatorName,
      'talentScore': talentScore ?? 8.7,
      'rating': displayRating,
      'isBlueTick': isVerifiedUser,
      'verified': isVerifiedUser,
      'isTrending': isTrending,
      'challengeId': challenge?.id ?? 'c1',
      'challengeTitle': challenge?.title ?? 'Monthly Mega Dance Battle',
    };
  }

  static String? _extractVideoUrl(Map<String, dynamic> json) {
    final keys = [
      'videoUrl',
      'video_url',
      'mediaUrl',
      'media_url',
      'videoPath',
      'video_path',
      'fileUrl',
      'file_url',
      'url',
      'video',
      'streamUrl',
      'stream_url',
    ];
    for (final k in keys) {
      final v = json[k];
      if (v != null && v is String) {
        final s = v.trim();
        if (s.isNotEmpty && s != 'null') return s;
      }
    }
    if (json['video'] is Map) {
      final vMap = Map<String, dynamic>.from(json['video'] as Map);
      return _extractVideoUrl(vMap);
    }
    if (json['media'] is Map) {
      final mMap = Map<String, dynamic>.from(json['media'] as Map);
      return _extractVideoUrl(mMap);
    }
    return null;
  }

  static String? _extractThumbnailUrl(Map<String, dynamic> json) {
    final keys = [
      'thumbnailUrl',
      'thumbnail_url',
      'thumbnail',
      'videoThumbnail',
      'video_thumbnail',
      'imageUrl',
      'image_url',
      'coverUrl',
      'cover_url',
      'posterUrl',
      'poster_url',
    ];
    for (final k in keys) {
      final v = json[k];
      if (v != null && v is String) {
        final s = v.trim();
        if (s.isNotEmpty && s != 'null') return s;
      }
    }
    if (json['thumbnail'] is Map) {
      final tMap = Map<String, dynamic>.from(json['thumbnail'] as Map);
      return _extractThumbnailUrl(tMap);
    }
    return null;
  }

  static List<String> _extractHashtags(Map<String, dynamic> json) {
    final raw = json['hashtags'] ?? json['tags'] ?? json['hashTags'];
    if (raw == null) return const [];
    if (raw is List) {
      return raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .map((e) => e.startsWith('#') ? e : '#$e')
          .toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return raw
          .split(RegExp(r'[\s,\n]+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .map((e) => e.startsWith('#') ? e : '#$e')
          .toList();
    }
    return const [];
  }

  factory TrendingVideoItem.fromJson(Map<String, dynamic> json) {
    final parsedLikes = _extractLikes(json);
    return TrendingVideoItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      videoUrl: _extractVideoUrl(json),
      thumbnailUrl: _extractThumbnailUrl(json),
      hashtags: _extractHashtags(json),
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
      likes: parsedLikes,
      likeCount: parsedLikes,
      likesLabel: json['likesLabel']?.toString() ?? json['likesCount']?.toString(),
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

  static int _extractLikes(Map<String, dynamic> json) {
    final directKeys = ['likes', 'likeCount', 'likesCount', 'totalLikes'];
    for (final key in directKeys) {
      final val = _parseInt(json[key]);
      if (val != null) return val;
    }
    if (json['_count'] is Map) {
      final val = _parseInt(json['_count']['likes']);
      if (val != null) return val;
    }
    if (json['count'] is Map) {
      final val = _parseInt(json['count']['likes']);
      if (val != null) return val;
    }
    return 0;
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
