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
    this.comments = 0,
    this.commentCount = 0,
    this.commentsLabel,
    this.shares = 0,
    this.shareCount = 0,
    this.sharesLabel,
    this.saves = 0,
    this.saveCount = 0,
    this.savesLabel,
    this.musicName,
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
    this.categoryBadge,
    this.ratingLabel,
    this.isTrending = false,
    this.isLiked = false,
    this.isSaved = false,
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
  final int comments;
  final int commentCount;
  final String? commentsLabel;
  final int shares;
  final int shareCount;
  final String? sharesLabel;
  final int saves;
  final int saveCount;
  final String? savesLabel;
  final String? musicName;
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
  final String? categoryBadge;
  final String? ratingLabel;
  final bool isTrending;
  final bool isLiked;
  final bool isSaved;
  final List<String> hashtags;

  static String formatCount(int count) {
    if (count >= 1000000) {
      final val = count / 1000000;
      return '${val.toStringAsFixed(1).replaceAll('.0', '')}M';
    }
    if (count >= 1000) {
      final val = count / 1000;
      return '${val.toStringAsFixed(1).replaceAll('.0', '')}K';
    }
    return count.toString();
  }

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
    return '';
  }

  String get displayCategoryName {
    if (categoryBadge != null && categoryBadge!.trim().isNotEmpty) {
      return categoryBadge!.trim();
    }
    if (badgeLabel != null && badgeLabel!.trim().isNotEmpty) {
      return badgeLabel!.trim();
    }
    if (category?.name != null && category!.name.trim().isNotEmpty) {
      return category!.name.trim();
    }
    if (statusBadge != null &&
        statusBadge!['label'] != null &&
        statusBadge!['label'].toString().trim().isNotEmpty) {
      return statusBadge!['label'].toString().trim();
    }
    if (statusLabel != null && statusLabel!.trim().isNotEmpty) {
      return statusLabel!.trim();
    }
    return 'TALENT';
  }

  String get displayRating {
    if (ratingLabel != null &&
        ratingLabel!.trim().isNotEmpty &&
        ratingLabel!.trim() != '0.0' &&
        ratingLabel!.trim() != '0') {
      final p = double.tryParse(ratingLabel!.trim());
      if (p != null && p > 0) return p.toStringAsFixed(1);
      return ratingLabel!.trim();
    }
    if (talentScoreLabel != null &&
        talentScoreLabel!.trim().isNotEmpty &&
        talentScoreLabel!.trim() != '0.0' &&
        talentScoreLabel!.trim() != '0') {
      final p = double.tryParse(talentScoreLabel!.trim());
      if (p != null && p > 0) return p.toStringAsFixed(1);
      return talentScoreLabel!.trim();
    }
    if (talentScore != null && talentScore! > 0) {
      return talentScore!.toStringAsFixed(1);
    }
    if (averageRating != null && averageRating!.trim().isNotEmpty) {
      final p = double.tryParse(averageRating!.trim());
      if (p != null && p > 0) return p.toStringAsFixed(1);
      if (averageRating!.trim() != '0.0' && averageRating!.trim() != '0') {
        return averageRating!.trim();
      }
    }
    return '0.0';
  }

  String get displayViews {
    if (viewsLabel != null && viewsLabel!.trim().isNotEmpty) {
      return viewsLabel!.trim();
    }
    final count = views > 0 ? views : (viewCount > 0 ? viewCount : 0);
    return formatCount(count);
  }

  String get displayHandle {
    final uname = user?.username?.trim();
    if (uname != null && uname.isNotEmpty) {
      return uname.startsWith('@') ? uname : '@$uname';
    }
    return '';
  }

  String get displayCreatorName {
    if (user?.fullName != null && user!.fullName!.trim().isNotEmpty) {
      return user!.fullName!.trim();
    }
    if (user?.username != null && user!.username!.trim().isNotEmpty) {
      return user!.username!.trim();
    }
    return '';
  }

  String get displayAvatar {
    if (user?.profilePhotoUrl != null && user!.profilePhotoUrl!.trim().isNotEmpty) {
      return user!.profilePhotoUrl!.trim();
    }
    return '';
  }

  bool get isVerifiedUser =>
      user?.isBlueTick == true || user?.isVerified == true;

  static int parseCount(dynamic raw) {
    if (raw == null) return 0;
    if (raw is num) return raw.toInt();
    final str = raw.toString().trim().toUpperCase();
    if (str.isEmpty) return 0;

    final parsed = int.tryParse(str);
    if (parsed != null) return parsed;

    final doubleParsed = double.tryParse(str);
    if (doubleParsed != null) return doubleParsed.toInt();

    if (str.endsWith('K')) {
      final numPart = double.tryParse(str.replaceAll('K', '').trim());
      if (numPart != null) return (numPart * 1000).round();
    }
    if (str.endsWith('M')) {
      final numPart = double.tryParse(str.replaceAll('M', '').trim());
      if (numPart != null) return (numPart * 1000000).round();
    }
    if (str.endsWith('B')) {
      final numPart = double.tryParse(str.replaceAll('B', '').trim());
      if (numPart != null) return (numPart * 1000000000).round();
    }
    return 0;
  }

  String get displayLikes {
    final count = likes > 0 ? likes : (likeCount > 0 ? likeCount : parseCount(likesLabel));
    return formatCount(count);
  }

  String get displayComments {
    if (commentsLabel != null && commentsLabel!.trim().isNotEmpty) {
      return commentsLabel!.trim();
    }
    final count = comments > 0 ? comments : (commentCount > 0 ? commentCount : 0);
    return formatCount(count);
  }

  String get displayShares {
    if (sharesLabel != null && sharesLabel!.trim().isNotEmpty) {
      return sharesLabel!.trim();
    }
    final count = shares > 0 ? shares : (shareCount > 0 ? shareCount : 0);
    return formatCount(count);
  }

  String get displaySaves {
    if (savesLabel != null && savesLabel!.trim().isNotEmpty) {
      return savesLabel!.trim();
    }
    final count = saves > 0 ? saves : (saveCount > 0 ? saveCount : 0);
    return formatCount(count);
  }

  String get displayMusicName {
    if (musicName != null && musicName!.trim().isNotEmpty) {
      return musicName!.trim();
    }
    final creatorName = displayCreatorName;
    if (creatorName.isNotEmpty) {
      return 'Original Sound — $creatorName';
    }
    final handle = displayHandle;
    if (handle.isNotEmpty) {
      return 'Original Sound — $handle';
    }
    return 'Original Sound';
  }

  String get displayCaption {
    final desc = (description != null && description!.trim().isNotEmpty)
        ? description!.trim()
        : title.trim();

    final cleanDesc = desc.replaceAll(RegExp(r'#+'), '#');

    final cleanTags = hashtags
        .map((e) => e.trim().replaceAll(RegExp(r'^#+'), ''))
        .where((e) => e.isNotEmpty)
        .map((e) => '#$e')
        .toList();

    final tagsStr = cleanTags.isNotEmpty ? cleanTags.join(' ') : '';

    if (cleanDesc.isNotEmpty && tagsStr.isNotEmpty) {
      if (cleanDesc.contains('#')) return cleanDesc;
      return '$cleanDesc $tagsStr';
    }
    if (cleanDesc.isNotEmpty) return cleanDesc;
    if (tagsStr.isNotEmpty) return tagsStr;
    return '';
  }

  Map<String, dynamic> toUiMap() {
    final resolvedHandle = displayHandle;
    final resolvedCreator = displayCreatorName.isNotEmpty
        ? displayCreatorName
        : (resolvedHandle.isNotEmpty ? resolvedHandle : '');

    final resolvedViewsCount = views > 0 ? views : viewCount;
    final resolvedLikesCount = likes > 0 ? likes : likeCount;
    final resolvedCommentsCount = comments > 0 ? comments : commentCount;
    final resolvedSharesCount = shares > 0 ? shares : shareCount;
    final resolvedSavesCount = saves > 0 ? saves : saveCount;

    return {
      'id': id,
      'title': title,
      'description': description ?? '',
      'caption': displayCaption,
      'hashtags': hashtags,
      'category': displayCategoryName,
      'imageUrl': displayThumbnail,
      'thumbnailUrl': displayThumbnail,
      'videoUrl': playableVideoUrl,
      'views': displayViews,
      'viewsCount': resolvedViewsCount,
      'likes': displayLikes,
      'likesCount': resolvedLikesCount,
      'isLiked': isLiked,
      'liked': isLiked,
      'comments': displayComments,
      'commentsCount': resolvedCommentsCount,
      'shares': displayShares,
      'sharesCount': resolvedSharesCount,
      'saves': displaySaves,
      'savesCount': resolvedSavesCount,
      'saveCount': resolvedSavesCount,
      'isSaved': isSaved,
      'saved': isSaved,
      'isBookmarked': isSaved,
      'musicName': displayMusicName,
      'avatarUrl': displayAvatar,
      'handle': resolvedHandle,
      'creator': resolvedCreator,
      'talentScore': talentScore ?? 0.0,
      'userRating': talentScore ?? 0.0,
      'score': talentScore != null ? talentScore!.toStringAsFixed(1) : displayRating,
      'rating': displayRating,
      'isBlueTick': isVerifiedUser,
      'verified': isVerifiedUser,
      'isTrending': isTrending,
      'challengeId': challenge?.id ?? '',
      'challengeTitle': challenge?.title ?? '',
    };
  }

  static bool _extractIsLiked(Map<String, dynamic> json) {
    final keys = [
      'isLiked',
      'is_liked',
      'liked',
      'hasLiked',
      'has_liked',
      'userLiked',
      'user_liked',
      'isUserLiked',
      'is_user_liked',
    ];
    for (final k in keys) {
      final val = json[k];
      if (val == true || val == 1 || val?.toString().toLowerCase() == 'true' || val?.toString() == '1') {
        return true;
      }
    }
    if (json['hero'] is Map) {
      final hero = Map<String, dynamic>.from(json['hero'] as Map);
      if (_extractIsLiked(hero)) return true;
    }
    if (json['userReaction']?.toString().toLowerCase() == 'like' ||
        json['user_reaction']?.toString().toLowerCase() == 'like') {
      return true;
    }
    return false;
  }

  static bool _extractIsSaved(Map<String, dynamic> json) {
    final keys = [
      'isSaved',
      'is_saved',
      'saved',
      'hasSaved',
      'has_saved',
      'userSaved',
      'user_saved',
      'isUserSaved',
      'is_user_saved',
      'isBookmarked',
      'is_bookmarked',
      'bookmarked',
    ];
    for (final k in keys) {
      final val = json[k];
      if (val == true || val == 1 || val?.toString().toLowerCase() == 'true' || val?.toString() == '1') {
        return true;
      }
    }
    if (json['hero'] is Map) {
      final hero = Map<String, dynamic>.from(json['hero'] as Map);
      if (_extractIsSaved(hero)) return true;
    }
    return false;
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
          .map((e) => e.toString().trim().replaceAll(RegExp(r'^#+'), ''))
          .where((e) => e.isNotEmpty)
          .map((e) => '#$e')
          .toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return raw
          .split(RegExp(r'[\s,\n]+'))
          .map((e) => e.trim().replaceAll(RegExp(r'^#+'), ''))
          .where((e) => e.isNotEmpty)
          .map((e) => '#$e')
          .toList();
    }
    return const [];
  }

  static double? _extractTalentScore(Map<String, dynamic> json) {
    final keys = [
      'talentScore',
      'talent_score',
      'userRating',
      'user_rating',
      'averageRating',
      'average_rating',
      'avgRating',
      'avg_rating',
      'talentRating',
      'talent_rating',
      'rating',
      'score',
    ];
    for (final k in keys) {
      final v = json[k];
      if (v != null) {
        final parsed = _parseDouble(v);
        if (parsed != null && parsed > 0) return parsed;
      }
    }

    if (json['ratings'] is List && (json['ratings'] as List).isNotEmpty) {
      final list = json['ratings'] as List;
      for (final item in list) {
        if (item is Map) {
          final score = item['score'] ?? item['rating'] ?? item['userRating'] ?? item['averageRating'];
          if (score != null) {
            final parsed = _parseDouble(score);
            if (parsed != null && parsed > 0) return parsed;
          }
        }
      }
    }
    return null;
  }

  static TrendingVideoUser? _parseUser(Map<String, dynamic> json) {
    Map<String, dynamic>? userMap;
    if (json['user'] is Map) {
      userMap = Map<String, dynamic>.from(json['user'] as Map);
    }

    final id = userMap?['id']?.toString() ??
        json['userId']?.toString() ??
        json['user_id']?.toString() ??
        '';

    final fullName = _firstNonEmptyStr([
      userMap?['fullName'],
      userMap?['name'],
      userMap?['creator'],
      json['fullName'],
      json['creator'],
      json['authorName'],
      json['name'],
    ]);

    final username = _firstNonEmptyStr([
      userMap?['username'],
      userMap?['handle'],
      userMap?['name'],
      json['username'],
      json['handle'],
      json['creator'],
      json['authorName'],
      json['name'],
      json['user_name'],
      json['userHandle'],
    ]);

    final avatar = _firstNonEmptyStr([
      userMap?['profilePhotoUrl'],
      userMap?['avatarUrl'],
      userMap?['avatar'],
      userMap?['imageUrl'],
      json['profilePhotoUrl'],
      json['avatarUrl'],
      json['avatar'],
      json['userAvatar'],
      json['imageUrl'],
    ]);

    final isBlueTick = userMap?['isBlueTick'] == true ||
        userMap?['isVerified'] == true ||
        json['isBlueTick'] == true ||
        json['isVerified'] == true ||
        json['verified'] == true;

    if ((username != null && username.isNotEmpty) || (fullName != null && fullName.isNotEmpty)) {
      return TrendingVideoUser(
        id: id,
        username: username ?? fullName,
        fullName: fullName ?? username,
        profilePhotoUrl: avatar,
        isBlueTick: isBlueTick,
        isVerified: isBlueTick,
      );
    }
    return null;
  }

  static String? _firstNonEmptyStr(List<dynamic> candidates) {
    for (final c in candidates) {
      if (c != null) {
        final str = c.toString().trim();
        if (str.isNotEmpty && str != 'null') return str;
      }
    }
    return null;
  }

  factory TrendingVideoItem.fromJson(Map<String, dynamic> json) {
    final parsedLikes = _extractLikes(json);
    final parsedComments = _extractComments(json);
    final parsedShares = _extractShares(json);
    final parsedViews = _extractViews(json);
    final parsedSaves = _extractSaves(json);
    final parsedIsSaved = _extractIsSaved(json);
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
      views: parsedViews,
      viewCount: parsedViews,
      viewsLabel: json['viewsLabel']?.toString(),
      likes: parsedLikes,
      likeCount: parsedLikes,
      likesLabel: json['likesLabel']?.toString() ?? (json['likesCount'] is String ? json['likesCount'] as String : null),
      comments: parsedComments,
      commentCount: parsedComments,
      commentsLabel: json['commentsLabel']?.toString() ?? (json['commentsCount'] is String ? json['commentsCount'] as String : null),
      shares: parsedShares,
      shareCount: parsedShares,
      sharesLabel: json['sharesLabel']?.toString() ?? (json['sharesCount'] is String ? json['sharesCount'] as String : null),
      saves: parsedSaves,
      saveCount: parsedSaves,
      savesLabel: json['savesLabel']?.toString() ?? (json['savesCount'] is String ? json['savesCount'] as String : null),
      musicName: _extractMusicName(json),
      averageRating: json['averageRating']?.toString() ?? json['rating']?.toString(),
      talentScore: _extractTalentScore(json),
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
      category: _parseCategory(json),
      user: _parseUser(json),
      rank: _parseInt(json['rank']),
      trendingScore: _parseDouble(json['trendingScore']),
      badgeLabel: json['badgeLabel']?.toString(),
      categoryBadge: json['categoryBadge']?.toString() ?? json['category_badge']?.toString(),
      ratingLabel: json['ratingLabel']?.toString(),
      isTrending: json['isTrending'] == true,
      isLiked: _extractIsLiked(json),
      isSaved: parsedIsSaved,
    );
  }

  static int _extractLikes(Map<String, dynamic> json) {
    final directKeys = [
      'likesCount',
      'likes_count',
      'likeCount',
      'like_count',
      'totalLikes',
      'total_likes',
      'likes',
    ];
    for (final key in directKeys) {
      final val = _parseInt(json[key]);
      if (val != null) return val;
    }
    if (json['hero'] is Map) {
      final val = _extractLikes(Map<String, dynamic>.from(json['hero'] as Map));
      if (val > 0) return val;
    }
    if (json['_count'] is Map) {
      final map = Map<String, dynamic>.from(json['_count'] as Map);
      for (final key in ['likes', 'like', 'likesCount', 'likes_count', 'totalLikes']) {
        final val = _parseInt(map[key]);
        if (val != null) return val;
      }
    }
    if (json['count'] is Map) {
      final map = Map<String, dynamic>.from(json['count'] as Map);
      for (final key in ['likes', 'like', 'likesCount', 'likes_count', 'totalLikes']) {
        final val = _parseInt(map[key]);
        if (val != null) return val;
      }
    }
    return 0;
  }

  static int _extractComments(Map<String, dynamic> json) {
    final directKeys = [
      'commentsCount',
      'comments_count',
      'commentCount',
      'comment_count',
      'totalComments',
      'total_comments',
      'comments',
    ];
    for (final key in directKeys) {
      final val = _parseInt(json[key]);
      if (val != null) return val;
    }
    if (json['hero'] is Map) {
      final val = _extractComments(Map<String, dynamic>.from(json['hero'] as Map));
      if (val > 0) return val;
    }
    if (json['comments'] is List) {
      return (json['comments'] as List).length;
    }
    if (json['_count'] is Map) {
      final map = Map<String, dynamic>.from(json['_count'] as Map);
      for (final key in ['comments', 'comment', 'commentsCount', 'comments_count', 'totalComments']) {
        final val = _parseInt(map[key]);
        if (val != null) return val;
      }
    }
    if (json['count'] is Map) {
      final map = Map<String, dynamic>.from(json['count'] as Map);
      for (final key in ['comments', 'comment', 'commentsCount', 'comments_count', 'totalComments']) {
        final val = _parseInt(map[key]);
        if (val != null) return val;
      }
    }
    return 0;
  }

  static int _extractShares(Map<String, dynamic> json) {
    final directKeys = [
      'sharesCount',
      'shares_count',
      'shareCount',
      'share_count',
      'totalShares',
      'total_shares',
      'shares',
    ];
    for (final key in directKeys) {
      final val = _parseInt(json[key]);
      if (val != null) return val;
    }
    if (json['_count'] is Map) {
      final map = Map<String, dynamic>.from(json['_count'] as Map);
      for (final key in ['shares', 'share', 'sharesCount', 'shares_count', 'totalShares']) {
        final val = _parseInt(map[key]);
        if (val != null) return val;
      }
    }
    if (json['count'] is Map) {
      final map = Map<String, dynamic>.from(json['count'] as Map);
      for (final key in ['shares', 'share', 'sharesCount', 'shares_count', 'totalShares']) {
        final val = _parseInt(map[key]);
        if (val != null) return val;
      }
    }
    return 0;
  }

  static int _extractSaves(Map<String, dynamic> json) {
    final directKeys = [
      'savesCount',
      'saves_count',
      'saveCount',
      'save_count',
      'totalSaves',
      'total_saves',
      'saves',
    ];
    for (final key in directKeys) {
      final val = _parseInt(json[key]);
      if (val != null) return val;
    }
    if (json['hero'] is Map) {
      final val = _extractSaves(Map<String, dynamic>.from(json['hero'] as Map));
      if (val > 0) return val;
    }
    if (json['_count'] is Map) {
      final map = Map<String, dynamic>.from(json['_count'] as Map);
      for (final key in ['saves', 'save', 'savesCount', 'saves_count', 'totalSaves', 'saveCount']) {
        final val = _parseInt(map[key]);
        if (val != null) return val;
      }
    }
    if (json['count'] is Map) {
      final map = Map<String, dynamic>.from(json['count'] as Map);
      for (final key in ['saves', 'save', 'savesCount', 'saves_count', 'totalSaves', 'saveCount']) {
        final val = _parseInt(map[key]);
        if (val != null) return val;
      }
    }
    return 0;
  }

  static TrendingVideoCategory? _parseCategory(Map<String, dynamic> json) {
    if (json['category'] is Map) {
      return TrendingVideoCategory.fromJson(
          Map<String, dynamic>.from(json['category'] as Map));
    }
    if (json['category'] is String &&
        (json['category'] as String).trim().isNotEmpty) {
      final str = (json['category'] as String).trim();
      return TrendingVideoCategory(id: str, name: str);
    }
    if (json['categoryName'] != null &&
        json['categoryName'].toString().trim().isNotEmpty) {
      final str = json['categoryName'].toString().trim();
      return TrendingVideoCategory(id: str, name: str);
    }
    if (json['categoryId'] is String &&
        (json['categoryId'] as String).trim().isNotEmpty) {
      final str = (json['categoryId'] as String).trim();
      return TrendingVideoCategory(id: str, name: str);
    }
    return null;
  }

  static int _extractViews(Map<String, dynamic> json) {
    final directKeys = ['views', 'viewCount', 'viewsCount', 'totalViews'];
    for (final key in directKeys) {
      final val = _parseInt(json[key]);
      if (val != null) return val;
    }
    if (json['_count'] is Map) {
      final val = _parseInt(json['_count']['views']);
      if (val != null) return val;
    }
    if (json['count'] is Map) {
      final val = _parseInt(json['count']['views']);
      if (val != null) return val;
    }
    return 0;
  }

  static String? _extractMusicName(Map<String, dynamic> json) {
    final directKeys = ['musicName', 'music_name', 'music', 'soundName', 'sound_name', 'audioTitle'];
    for (final key in directKeys) {
      final val = json[key]?.toString().trim();
      if (val != null && val.isNotEmpty && val != 'null') return val;
    }
    if (json['audio'] is Map) {
      final name = json['audio']['title']?.toString().trim() ?? json['audio']['name']?.toString().trim();
      if (name != null && name.isNotEmpty && name != 'null') return name;
    }
    return null;
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
    final fullName = json['fullName']?.toString() ?? json['name']?.toString() ?? json['creator']?.toString();
    final username = json['username']?.toString() ?? json['handle']?.toString() ?? json['name']?.toString() ?? json['creator']?.toString() ?? json['authorName']?.toString();
    final avatar = json['profilePhotoUrl']?.toString() ?? json['avatarUrl']?.toString() ?? json['avatar']?.toString() ?? json['imageUrl']?.toString();

    return TrendingVideoUser(
      id: json['id']?.toString() ?? '',
      fullName: fullName ?? username,
      username: username ?? fullName,
      profilePhotoUrl: avatar,
      socialLinks: json['socialLinks'] is Map
          ? Map<String, dynamic>.from(json['socialLinks'] as Map)
          : const {},
      talentCategory: json['talentCategory']?.toString(),
      isBlueTick: json['isBlueTick'] == true || json['isVerified'] == true || json['verified'] == true,
      isVerified: json['isVerified'] == true || json['isBlueTick'] == true || json['verified'] == true,
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
