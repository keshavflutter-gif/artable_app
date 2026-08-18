class AchievementsResponse {
  const AchievementsResponse({
    required this.success,
    this.message,
    required this.data,
  });

  final bool success;
  final String? message;
  final AchievementsData data;

  factory AchievementsResponse.fromJson(Map<String, dynamic> json) {
    final dataRaw = json['data'];
    return AchievementsResponse(
      success: json['success'] == true,
      message: json['message']?.toString(),
      data: dataRaw is Map<String, dynamic>
          ? AchievementsData.fromJson(dataRaw)
          : dataRaw is Map
              ? AchievementsData.fromJson(Map<String, dynamic>.from(dataRaw))
              : AchievementsData.empty(),
    );
  }
}

class AchievementsData {
  const AchievementsData({
    required this.currentLevel,
    required this.earnedCount,
    required this.totalCount,
    required this.earnedLabel,
    this.nextMilestone = '',
    this.levelCard,
    required this.groups,
    this.awardedBadges = const [],
  });

  final String currentLevel;
  final int earnedCount;
  final int totalCount;
  final String earnedLabel;
  final String nextMilestone;
  final AchievementLevelCard? levelCard;
  final List<AchievementGroup> groups;
  final List<dynamic> awardedBadges;

  factory AchievementsData.fromJson(Map<String, dynamic> json) {
    AchievementLevelCard? card;
    if (json['levelCard'] is Map) {
      card = AchievementLevelCard.fromJson(
        Map<String, dynamic>.from(json['levelCard'] as Map),
      );
    }

    final rawGroups = json['groups'];
    final groupList = <AchievementGroup>[];
    if (rawGroups is List) {
      for (final g in rawGroups) {
        if (g is Map<String, dynamic>) {
          groupList.add(AchievementGroup.fromJson(g));
        } else if (g is Map) {
          groupList.add(AchievementGroup.fromJson(Map<String, dynamic>.from(g)));
        }
      }
    }

    return AchievementsData(
      currentLevel: json['currentLevel']?.toString() ?? card?.value ?? 'Starter',
      earnedCount: (json['earnedCount'] as num?)?.toInt() ?? 0,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      earnedLabel: json['earnedLabel']?.toString() ?? card?.earnedLabel ?? '0/0',
      nextMilestone: json['nextMilestone']?.toString() ?? card?.nextMilestone ?? '',
      levelCard: card,
      groups: groupList,
      awardedBadges: (json['awardedBadges'] as List?) ?? const [],
    );
  }

  factory AchievementsData.empty() {
    return const AchievementsData(
      currentLevel: 'Starter',
      earnedCount: 0,
      totalCount: 0,
      earnedLabel: '0/0',
      nextMilestone: '',
      groups: [],
    );
  }
}

class AchievementLevelCard {
  const AchievementLevelCard({
    this.title = 'Current Level',
    this.value = 'Starter',
    this.earnedLabel = '0/1',
    this.earnedText = 'Badges Earned',
    this.nextMilestone = '',
    this.nextMilestoneText = 'Next Milestone',
  });

  final String title;
  final String value;
  final String earnedLabel;
  final String earnedText;
  final String nextMilestone;
  final String nextMilestoneText;

  factory AchievementLevelCard.fromJson(Map<String, dynamic> json) {
    return AchievementLevelCard(
      title: json['title']?.toString() ?? 'Current Level',
      value: json['value']?.toString() ?? 'Starter',
      earnedLabel: json['earnedLabel']?.toString() ??
          json['earned_label']?.toString() ??
          '0/0',
      earnedText: json['earnedText']?.toString() ??
          json['earned_text']?.toString() ??
          'Badges Earned',
      nextMilestone: json['nextMilestone']?.toString() ??
          json['next_milestone']?.toString() ??
          '',
      nextMilestoneText: json['nextMilestoneText']?.toString() ??
          json['next_milestone_text']?.toString() ??
          'Next Milestone',
    );
  }
}

class AchievementGroup {
  const AchievementGroup({
    required this.title,
    required this.items,
  });

  final String title;
  final List<AchievementBadgeItem> items;

  factory AchievementGroup.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final itemsList = <AchievementBadgeItem>[];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map<String, dynamic>) {
          itemsList.add(AchievementBadgeItem.fromJson(item));
        } else if (item is Map) {
          itemsList.add(
            AchievementBadgeItem.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return AchievementGroup(
      title: json['title']?.toString() ?? 'Badges',
      items: itemsList,
    );
  }
}

class AchievementBadgeItem {
  const AchievementBadgeItem({
    required this.key,
    required this.title,
    this.description = '',
    this.icon = 'lock',
    this.imageUrl,
    this.unlocked = false,
    this.locked = true,
    this.progress = 0,
    this.target = 1,
    this.progressPercent = 0,
    this.awardedAt,
  });

  final String key;
  final String title;
  final String description;
  final String icon;
  final String? imageUrl;
  final bool unlocked;
  final bool locked;
  final num progress;
  final num target;
  final num progressPercent;
  final String? awardedAt;

  bool get isEarned => unlocked || !locked || (target > 0 && progress >= target);

  factory AchievementBadgeItem.fromJson(Map<String, dynamic> json) {
    final isUnlocked = json['unlocked'] == true;
    final isLockedExplicit = json['locked'] as bool?;
    final isLocked = isLockedExplicit ?? (!isUnlocked);

    return AchievementBadgeItem(
      key: json['key']?.toString() ??
          json['id']?.toString() ??
          json['_id']?.toString() ??
          '',
      title: json['title']?.toString() ?? json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'lock',
      imageUrl: json['imageUrl']?.toString() ?? json['image_url']?.toString(),
      unlocked: isUnlocked,
      locked: isLocked,
      progress: (json['progress'] as num?) ?? 0,
      target: (json['target'] as num?) ?? 1,
      progressPercent: (json['progressPercent'] as num?) ??
          (json['progress_percent'] as num?) ??
          0,
      awardedAt: json['awardedAt']?.toString() ?? json['awarded_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'title': title,
        'description': description,
        'icon': icon,
        'imageUrl': imageUrl,
        'unlocked': unlocked,
        'locked': locked,
        'progress': progress,
        'target': target,
        'progressPercent': progressPercent,
        'awardedAt': awardedAt,
      };
}
