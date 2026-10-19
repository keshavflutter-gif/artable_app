import 'package:artable_app/core/utils/media_url_utils.dart';
import 'package:artable_app/core/utils/reel_helpers.dart';

class MyVideosResponse {
  const MyVideosResponse({
    required this.success,
    this.message,
    required this.data,
    required this.tabs,
    this.activeTab = 'ALL',
    this.emptyState,
    this.pagination,
  });

  final bool success;
  final String? message;
  final List<MyVideoItem> data;
  final List<MyVideoTabItem> tabs;
  final String activeTab;
  final MyVideoEmptyState? emptyState;
  final MyVideoPagination? pagination;

  factory MyVideosResponse.fromJson(Map<String, dynamic> json) {
    final listRaw = json['data'];
    final dataList = <MyVideoItem>[];
    if (listRaw is List) {
      for (final item in listRaw) {
        if (item is Map<String, dynamic>) {
          dataList.add(MyVideoItem.fromJson(item));
        } else if (item is Map) {
          dataList.add(MyVideoItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final tabsRaw = json['tabs'];
    final tabsList = <MyVideoTabItem>[];
    if (tabsRaw is List) {
      for (final item in tabsRaw) {
        if (item is Map<String, dynamic>) {
          tabsList.add(MyVideoTabItem.fromJson(item));
        } else if (item is Map) {
          tabsList.add(MyVideoTabItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return MyVideosResponse(
      success: json['success'] == true,
      message: json['message']?.toString(),
      data: dataList,
      tabs: tabsList,
      activeTab: json['activeTab']?.toString() ?? 'ALL',
      emptyState: json['emptyState'] is Map
          ? MyVideoEmptyState.fromJson(Map<String, dynamic>.from(json['emptyState'] as Map))
          : null,
      pagination: json['pagination'] is Map
          ? MyVideoPagination.fromJson(Map<String, dynamic>.from(json['pagination'] as Map))
          : null,
    );
  }
}

class MyVideoItem {
  const MyVideoItem({
    required this.id,
    required this.title,
    this.description,
    required this.thumbnailUrl,
    this.videoUrl,
    required this.status,
    this.statusBadge,
    this.statusLabel,
    this.rejectionReason,
    this.durationSeconds,
    this.viewsLabel = '0',
    this.likesLabel = '0',
    this.talentScoreLabel = '0.0',
    this.dateLabel = '',
    this.isLive = false,
    this.canView = true,
    this.canShare = false,
    this.canContinueDraft = false,
    this.actions = const [],
    this.challenge,
    this.category,
    this.mergedClipPaths,
  });

  final String id;
  final String title;
  final String? description;
  final String thumbnailUrl;
  final String? videoUrl;
  final String status;
  final MyVideoStatusBadge? statusBadge;
  final String? statusLabel;
  final String? rejectionReason;
  final num? durationSeconds;
  final String viewsLabel;
  final String likesLabel;
  final String talentScoreLabel;
  final String dateLabel;
  final bool isLive;
  final bool canView;
  final bool canShare;
  final bool canContinueDraft;
  final List<MyVideoAction> actions;
  final Map<String, dynamic>? challenge;
  final Map<String, dynamic>? category;
  final List<String>? mergedClipPaths;

  factory MyVideoItem.fromJson(Map<String, dynamic> json) {
    final actionsRaw = json['actions'];
    final actionsList = <MyVideoAction>[];
    if (actionsRaw is List) {
      for (final item in actionsRaw) {
        if (item is Map<String, dynamic>) {
          actionsList.add(MyVideoAction.fromJson(item));
        } else if (item is Map) {
          actionsList.add(MyVideoAction.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final challengeObj = json['challenge'] is Map
        ? Map<String, dynamic>.from(json['challenge'] as Map)
        : null;

    final categoryObj = json['category'] is Map
        ? Map<String, dynamic>.from(json['category'] as Map)
        : null;

    final titleStr = (json['title']?.toString() ?? '').trim().isNotEmpty
        ? json['title'].toString().trim()
        : (challengeObj?['title']?.toString() ?? '').trim().isNotEmpty
            ? challengeObj!['title'].toString().trim()
            : 'Draft Video';

    final bannerUrl = challengeObj?['bannerUrl']?.toString() ??
        challengeObj?['imageUrl']?.toString() ??
        '';

    final videoUrlStr = MediaUrlUtils.extractVideoUrl(json) ??
        json['videoUrl']?.toString() ??
        json['video_url']?.toString();

    // Determine effective video URL (checking direct fields and clips)
    String? resolvedVideoUrl;
    if (videoUrlStr != null && videoUrlStr.trim().isNotEmpty && videoUrlStr != 'null') {
      resolvedVideoUrl = MediaUrlUtils.resolve(videoUrlStr);
    }

    // 1. Try static image thumbnail first
    String thumb = MediaUrlUtils.extractThumbnail(json) ?? '';
    if (thumb.isEmpty && bannerUrl.isNotEmpty && !bannerUrl.contains('storage.example')) {
      thumb = MediaUrlUtils.resolve(bannerUrl);
    }
    // 2. If no image thumbnail or if thumb is a dummy placeholder, check raw thumbnail fields
    if (thumb.isEmpty || MediaUrlUtils.isDummyThumbnail(thumb)) {
      final rawThumb = json['thumbnailUrl']?.toString() ??
          json['thumbnail_url']?.toString() ??
          json['videoThumbnail']?.toString() ??
          json['thumbnail']?.toString();
      if (rawThumb != null && rawThumb.trim().isNotEmpty && rawThumb != 'null') {
        final resThumb = MediaUrlUtils.resolve(rawThumb);
        if (!MediaUrlUtils.isDummyThumbnail(resThumb)) {
          thumb = resThumb;
        }
      }
    }
    // 3. Fall back to videoUrl if available (AppImage will render the video thumbnail)
    if ((thumb.isEmpty || MediaUrlUtils.isDummyThumbnail(thumb)) &&
        resolvedVideoUrl != null &&
        resolvedVideoUrl.trim().isNotEmpty) {
      thumb = resolvedVideoUrl;
    }

    String dateStr = json['dateLabel']?.toString() ?? json['date']?.toString() ?? '';
    if (dateStr.isEmpty) {
      final rawCreated = json['createdAt']?.toString() ?? json['updatedAt']?.toString() ?? '';
      if (rawCreated.isNotEmpty) {
        final d = DateTime.tryParse(rawCreated);
        if (d != null) {
          const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          dateStr = '${months[d.month - 1]} ${d.day}, ${d.year}';
        } else {
          dateStr = rawCreated;
        }
      }
    }

    final statusStr = json['status']?.toString() ?? 'APPROVED';
    final isDraftStatus = statusStr.toLowerCase().contains('draft');

    final rawDesc = json['description']?.toString();
    final parsedClipsDesc = ReelHelpers.parseDescriptionClips(rawDesc);
    final effectiveDesc = parsedClipsDesc.cleanDescription.isNotEmpty
        ? parsedClipsDesc.cleanDescription
        : rawDesc;

    final idStr = json['id']?.toString() ?? json['_id']?.toString() ?? '';

    List<String>? effectiveMergedClips = json['mergedClipPaths'] is List
        ? List<String>.from((json['mergedClipPaths'] as List).map((e) => e.toString()))
        : (json['merged_clip_paths'] is List
            ? List<String>.from((json['merged_clip_paths'] as List).map((e) => e.toString()))
            : parsedClipsDesc.clips);

    if (effectiveMergedClips == null || effectiveMergedClips.isEmpty) {
      effectiveMergedClips = ReelHelpers.getCachedMergedClips(idStr) ??
          ReelHelpers.getCachedMergedClips(videoUrlStr);
    }

    if (effectiveMergedClips != null && effectiveMergedClips.length > 1) {
      if (idStr.isNotEmpty) ReelHelpers.cacheMergedClips(idStr, effectiveMergedClips);
      if (videoUrlStr != null && videoUrlStr.isNotEmpty) {
        ReelHelpers.cacheMergedClips(videoUrlStr, effectiveMergedClips);
      }
    }

    final finalVideoUrl = (resolvedVideoUrl != null && resolvedVideoUrl.isNotEmpty)
        ? resolvedVideoUrl
        : (effectiveMergedClips != null && effectiveMergedClips.isNotEmpty
            ? MediaUrlUtils.resolve(effectiveMergedClips.first)
            : videoUrlStr);

    if ((thumb.isEmpty || MediaUrlUtils.isDummyThumbnail(thumb)) &&
        finalVideoUrl != null &&
        finalVideoUrl.trim().isNotEmpty) {
      thumb = finalVideoUrl;
    }

    return MyVideoItem(
      id: idStr,
      title: titleStr,
      description: effectiveDesc,
      thumbnailUrl: thumb,
      videoUrl: finalVideoUrl,
      status: statusStr,
      statusBadge: json['statusBadge'] is Map
          ? MyVideoStatusBadge.fromJson(Map<String, dynamic>.from(json['statusBadge'] as Map))
          : null,
      statusLabel: json['statusLabel']?.toString(),
      rejectionReason: json['rejectionReason']?.toString(),
      durationSeconds: json['durationSeconds'] as num?,
      viewsLabel: json['viewsLabel']?.toString() ?? json['views']?.toString() ?? '0',
      likesLabel: json['likesLabel']?.toString() ?? json['likes']?.toString() ?? '0',
      talentScoreLabel: json['talentScoreLabel']?.toString() ?? json['talentScore']?.toString() ?? '0.0',
      dateLabel: dateStr,
      isLive: json['isLive'] == true,
      canView: json['canView'] != false,
      canShare: json['canShare'] == true,
      canContinueDraft: json['canContinueDraft'] == true || isDraftStatus,
      actions: actionsList,
      challenge: challengeObj,
      category: categoryObj,
      mergedClipPaths: effectiveMergedClips,
    );
  }

  Map<String, dynamic> toUiMap() {
    final challengeObj = challenge;
    final challengeId = challengeObj?['id']?.toString() ?? '';
    final challengeTitle = challengeObj?['title']?.toString() ?? title;

    final resolvedClips = (mergedClipPaths != null && mergedClipPaths!.isNotEmpty)
        ? mergedClipPaths
        : (ReelHelpers.getCachedMergedClips(id) ?? ReelHelpers.getCachedMergedClips(videoUrl));

    return {
      'id': id,
      'title': title,
      'description': description ?? '',
      'caption': (description != null && description!.trim().isNotEmpty) ? description! : title,
      'challengeId': challengeId,
      'challengeTitle': challengeTitle,
      'imageUrl': thumbnailUrl,
      'thumbnailUrl': thumbnailUrl,
      'videoUrl': videoUrl ?? '',
      if (resolvedClips != null && resolvedClips.isNotEmpty)
        'mergedClipPaths': resolvedClips,
      'status': status.toLowerCase(),
      'statusLabel': statusLabel ?? statusBadge?.label ?? status,
      'statusTone': statusBadge?.tone ?? 'success',
      'rejectionReason': rejectionReason ?? '',
      'views': viewsLabel,
      'viewsLabel': viewsLabel,
      'likes': likesLabel,
      'likesLabel': likesLabel,
      'score': talentScoreLabel,
      'talentScoreLabel': talentScoreLabel,
      'date': dateLabel,
      'dateLabel': dateLabel,
      'isLive': isLive,
      'canView': canView,
      'canShare': canShare,
      'canContinueDraft': canContinueDraft,
      'actions': actions.map((a) => {'key': a.key, 'label': a.label}).toList(),
    };
  }
}

class MyVideoStatusBadge {
  const MyVideoStatusBadge({
    required this.label,
    required this.tone,
  });

  final String label;
  final String tone;

  factory MyVideoStatusBadge.fromJson(Map<String, dynamic> json) {
    return MyVideoStatusBadge(
      label: json['label']?.toString() ?? 'Live',
      tone: json['tone']?.toString() ?? 'success',
    );
  }
}

class MyVideoAction {
  const MyVideoAction({
    required this.key,
    required this.label,
  });

  final String key;
  final String label;

  factory MyVideoAction.fromJson(Map<String, dynamic> json) {
    return MyVideoAction(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}

class MyVideoTabItem {
  const MyVideoTabItem({
    required this.key,
    required this.label,
    this.status,
    this.count = 0,
  });

  final String key;
  final String label;
  final String? status;
  final int count;

  factory MyVideoTabItem.fromJson(Map<String, dynamic> json) {
    return MyVideoTabItem(
      key: json['key']?.toString() ?? 'ALL',
      label: json['label']?.toString() ?? 'All',
      status: json['status']?.toString(),
      count: json['count'] is num ? (json['count'] as num).toInt() : 0,
    );
  }
}

class MyVideoEmptyState {
  const MyVideoEmptyState({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  factory MyVideoEmptyState.fromJson(Map<String, dynamic> json) {
    return MyVideoEmptyState(
      title: json['title']?.toString() ?? 'No videos found',
      message: json['message']?.toString() ?? 'Upload or save a draft to see videos here.',
    );
  }
}

class MyVideoPagination {
  const MyVideoPagination({
    this.page = 1,
    this.limit = 20,
    this.total = 0,
  });

  final int page;
  final int limit;
  final int total;

  factory MyVideoPagination.fromJson(Map<String, dynamic> json) {
    return MyVideoPagination(
      page: json['page'] is num ? (json['page'] as num).toInt() : 1,
      limit: json['limit'] is num ? (json['limit'] as num).toInt() : 20,
      total: json['total'] is num ? (json['total'] as num).toInt() : 0,
    );
  }
}
