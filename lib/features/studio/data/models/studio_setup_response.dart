class StudioSetupResponse {
  const StudioSetupResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool success;
  final String message;
  final StudioSetupData data;

  factory StudioSetupResponse.fromJson(Map<String, dynamic> json) {
    return StudioSetupResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: json['data'] is Map
          ? StudioSetupData.fromJson(Map<String, dynamic>.from(json['data'] as Map))
          : const StudioSetupData.empty(),
    );
  }
}

class StudioSetupData {
  const StudioSetupData({
    required this.challenge,
    this.entry,
    required this.policy,
    this.steps = const ['Challenge', 'Record', 'Details', 'Preview'],
    this.recordingTips = const [
      'Good lighting',
      'Clear sound',
      'Keep talent centered',
      'Follow challenge rules',
    ],
  });

  const StudioSetupData.empty()
      : challenge = const StudioSetupChallenge.empty(),
        entry = null,
        policy = const StudioSetupPolicy.empty(),
        steps = const ['Challenge', 'Record', 'Details', 'Preview'],
        recordingTips = const [
          'Good lighting',
          'Clear sound',
          'Keep talent centered',
          'Follow challenge rules',
        ];

  final StudioSetupChallenge challenge;
  final StudioSetupEntry? entry;
  final StudioSetupPolicy policy;
  final List<String> steps;
  final List<String> recordingTips;

  factory StudioSetupData.fromJson(Map<String, dynamic> json) {
    return StudioSetupData(
      challenge: json['challenge'] is Map
          ? StudioSetupChallenge.fromJson(Map<String, dynamic>.from(json['challenge'] as Map))
          : const StudioSetupChallenge.empty(),
      entry: json['entry'] is Map
          ? StudioSetupEntry.fromJson(Map<String, dynamic>.from(json['entry'] as Map))
          : null,
      policy: json['policy'] is Map
          ? StudioSetupPolicy.fromJson(Map<String, dynamic>.from(json['policy'] as Map))
          : const StudioSetupPolicy.empty(),
      steps: json['steps'] is List
          ? (json['steps'] as List).map((e) => e.toString()).toList()
          : const ['Challenge', 'Record', 'Details', 'Preview'],
      recordingTips: json['recordingTips'] is List
          ? (json['recordingTips'] as List).map((e) => e.toString()).toList()
          : const [
              'Good lighting',
              'Clear sound',
              'Keep talent centered',
              'Follow challenge rules',
            ],
    );
  }
}

class StudioSetupChallenge {
  const StudioSetupChallenge({
    required this.id,
    required this.title,
    this.description,
    this.bannerUrl,
    this.category,
    this.rewardPool,
    this.endDate,
    this.maxVideoDuration = 60,
    this.daysLeft = 0,
  });

  const StudioSetupChallenge.empty()
      : id = '',
        title = '',
        description = null,
        bannerUrl = null,
        category = null,
        rewardPool = null,
        endDate = null,
        maxVideoDuration = 60,
        daysLeft = 0;

  final String id;
  final String title;
  final String? description;
  final String? bannerUrl;
  final StudioSetupCategory? category;
  final String? rewardPool;
  final String? endDate;
  final int maxVideoDuration;
  final int daysLeft;

  factory StudioSetupChallenge.fromJson(Map<String, dynamic> json) {
    int parsedDuration = 60;
    if (json['maxVideoDuration'] != null) {
      parsedDuration = int.tryParse(json['maxVideoDuration'].toString()) ?? 60;
    }
    int parsedDays = 0;
    if (json['daysLeft'] != null) {
      parsedDays = int.tryParse(json['daysLeft'].toString()) ?? 0;
    }

    return StudioSetupChallenge(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      bannerUrl: json['bannerUrl']?.toString() ?? json['banner_url']?.toString(),
      category: json['category'] is Map
          ? StudioSetupCategory.fromJson(Map<String, dynamic>.from(json['category'] as Map))
          : (json['category'] is String
              ? StudioSetupCategory(id: '', name: json['category'].toString())
              : null),
      rewardPool: json['rewardPool']?.toString() ?? json['reward_pool']?.toString(),
      endDate: json['endDate']?.toString() ?? json['end_date']?.toString(),
      maxVideoDuration: parsedDuration,
      daysLeft: parsedDays,
    );
  }

  Map<String, dynamic> toUiMap() {
    final rawReward = rewardPool?.trim() ?? '';
    String prize = '';
    if (rawReward.isNotEmpty) {
      if (rawReward.startsWith('\$')) {
        prize = '$rawReward Prize Pool';
      } else {
        final numVal = int.tryParse(rawReward);
        if (numVal != null) {
          final formatted = numVal >= 1000
              ? '${(numVal / 1000).toStringAsFixed(numVal % 1000 == 0 ? 0 : 1)}k'
              : numVal.toString();
          prize = '\$$formatted Prize Pool';
        } else {
          prize = '\$$rawReward Prize Pool';
        }
      }
    }

    return {
      'id': id,
      'title': title,
      'description': description ?? '',
      'category': category?.name ?? '',
      'imageUrl': bannerUrl ?? category?.imageUrl ?? '',
      'bannerUrl': bannerUrl ?? category?.imageUrl ?? '',
      'prize': prize,
      'rewardPool': rewardPool ?? '',
      'endDate': endDate ?? '',
      'maxVideoDuration': maxVideoDuration,
      'daysLeft': daysLeft,
    };
  }
}

class StudioSetupCategory {
  const StudioSetupCategory({
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

  factory StudioSetupCategory.fromJson(Map<String, dynamic> json) {
    return StudioSetupCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      imageUrl: json['imageUrl']?.toString() ?? json['image_url']?.toString(),
      isActive: json['isActive'] == true || json['is_active'] == true,
    );
  }
}

class StudioSetupEntry {
  const StudioSetupEntry({
    required this.id,
    required this.userId,
    required this.challengeId,
    this.videoId,
    this.status,
    this.submittedAt,
    this.video,
  });

  final String id;
  final String userId;
  final String challengeId;
  final String? videoId;
  final String? status;
  final String? submittedAt;
  final Map<String, dynamic>? video;

  factory StudioSetupEntry.fromJson(Map<String, dynamic> json) {
    return StudioSetupEntry(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      challengeId: json['challengeId']?.toString() ?? '',
      videoId: json['videoId']?.toString(),
      status: json['status']?.toString(),
      submittedAt: json['submittedAt']?.toString(),
      video: json['video'] is Map ? Map<String, dynamic>.from(json['video'] as Map) : null,
    );
  }
}

class StudioSetupPolicy {
  const StudioSetupPolicy({
    this.galleryUploadAllowed = false,
    this.requiresInAppRecording = true,
    this.oneEntryPerUser = true,
    this.winnerBasis,
  });

  const StudioSetupPolicy.empty()
      : galleryUploadAllowed = false,
        requiresInAppRecording = true,
        oneEntryPerUser = true,
        winnerBasis = null;

  final bool galleryUploadAllowed;
  final bool requiresInAppRecording;
  final bool oneEntryPerUser;
  final String? winnerBasis;

  factory StudioSetupPolicy.fromJson(Map<String, dynamic> json) {
    return StudioSetupPolicy(
      galleryUploadAllowed: json['galleryUploadAllowed'] == true,
      requiresInAppRecording: json['requiresInAppRecording'] == true,
      oneEntryPerUser: json['oneEntryPerUser'] == true,
      winnerBasis: json['winnerBasis']?.toString(),
    );
  }
}
