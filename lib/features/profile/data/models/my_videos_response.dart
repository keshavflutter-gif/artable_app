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

    String rawThumb = json['thumbnailUrl']?.toString() ??
        json['thumbnail']?.toString() ??
        json['imageUrl']?.toString() ??
        '';

    String thumb = rawThumb;
    if (thumb.isEmpty || thumb.contains('storage.example')) {
      if (bannerUrl.isNotEmpty && !bannerUrl.contains('storage.example')) {
        thumb = bannerUrl;
      } else {
        thumb = json['videoUrl']?.toString() ?? json['video_url']?.toString() ?? '';
      }
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

    return MyVideoItem(
      id: json['id']?.toString() ?? '',
      title: titleStr,
      description: json['description']?.toString(),
      thumbnailUrl: thumb,
      videoUrl: json['videoUrl']?.toString() ?? json['video_url']?.toString(),
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
    );
  }

  Map<String, dynamic> toUiMap() {
    final challengeObj = challenge;
    final challengeId = challengeObj?['id']?.toString() ?? '';
    final challengeTitle = challengeObj?['title']?.toString() ?? title;

    return {
      'id': id,
      'title': title,
      'description': description ?? '',
      'challengeId': challengeId,
      'challengeTitle': challengeTitle,
      'imageUrl': thumbnailUrl,
      'thumbnailUrl': thumbnailUrl,
      'videoUrl': videoUrl ?? '',
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
