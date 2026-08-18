import 'categories_response.dart';

class ChallengesListResponse {
  const ChallengesListResponse({
    required this.success,
    this.message,
    required this.data,
    this.ads = const [],
    this.pagination,
  });

  final bool success;
  final String? message;
  final List<ChallengeDetailData> data;
  final List<dynamic> ads;
  final Map<String, dynamic>? pagination;

  factory ChallengesListResponse.fromJson(Map<String, dynamic> json) {
    return ChallengesListResponse(
      success: json['success'] == true,
      message: json['message']?.toString(),
      data: _parseChallenges(json['data']),
      ads: json['ads'] is List ? (json['ads'] as List) : const [],
      pagination: json['pagination'] is Map
          ? Map<String, dynamic>.from(json['pagination'] as Map)
          : null,
    );
  }

  static List<ChallengeDetailData> _parseChallenges(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) =>
            ChallengeDetailData.fromJson(Map<String, dynamic>.from(item)))
        .where((challenge) => challenge.id.isNotEmpty && challenge.title.isNotEmpty)
        .toList();
  }
}

class ChallengeDetailResponse {
  const ChallengeDetailResponse({
    required this.success,
    this.message,
    this.data,
    this.ads = const [],
    this.pagination,
  });

  final bool success;
  final String? message;
  final ChallengeDetailData? data;
  final List<dynamic> ads;
  final Map<String, dynamic>? pagination;

  factory ChallengeDetailResponse.fromJson(Map<String, dynamic> json) {
    return ChallengeDetailResponse(
      success: json['success'] == true,
      message: json['message']?.toString(),
      data: _parseChallengeData(json['data']),
      ads: json['ads'] is List ? (json['ads'] as List) : const [],
      pagination: json['pagination'] is Map
          ? Map<String, dynamic>.from(json['pagination'] as Map)
          : null,
    );
  }

  static ChallengeDetailData? _parseChallengeData(dynamic raw) {
    if (raw == null) return null;
    if (raw is List && raw.isNotEmpty) {
      final first = raw.first;
      if (first is Map) {
        return ChallengeDetailData.fromJson(Map<String, dynamic>.from(first));
      }
    }
    if (raw is Map) {
      return ChallengeDetailData.fromJson(Map<String, dynamic>.from(raw));
    }
    return null;
  }
}

class ChallengeDetailData {
  const ChallengeDetailData({
    required this.id,
    required this.title,
    this.description = '',
    this.rules = const [],
    this.prizeBreakdown = const [],
    this.rewardPool = '',
    this.prizePoolLabel = '',
    this.participationFee = '0',
    this.bannerUrl = '',
    this.category,
    this.categoryName = '',
    this.status = 'ACTIVE',
    this.isFeatured = false,
    this.maxVideoDuration = 60,
    this.startDate = '',
    this.endDate = '',
    this.endDateLabel = '',
    this.daysLeft = 0,
    this.daysLeftLabel = '',
    this.joinedCount = 0,
    this.joinedLabel = '',
    this.approvedVideosCount = 0,
    this.averageRating = 0,
  });

  final String id;
  final String title;
  final String description;
  final List<String> rules;
  final List<PrizeBreakdownItem> prizeBreakdown;
  final String rewardPool;
  final String prizePoolLabel;
  final String participationFee;
  final String bannerUrl;
  final CategoryDetailItem? category;
  final String categoryName;
  final String status;
  final bool isFeatured;
  final int maxVideoDuration;
  final String startDate;
  final String endDate;
  final String endDateLabel;
  final int daysLeft;
  final String daysLeftLabel;
  final int joinedCount;
  final String joinedLabel;
  final int approvedVideosCount;
  final num averageRating;

  factory ChallengeDetailData.fromJson(Map<String, dynamic> json) {
    return ChallengeDetailData(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      rules: _parseRules(json['rules']),
      prizeBreakdown: _parsePrizeBreakdown(json['prizeBreakdown']),
      rewardPool: json['rewardPool']?.toString() ?? '',
      prizePoolLabel: json['prizePoolLabel']?.toString() ?? '',
      participationFee: json['participationFee']?.toString() ?? '0',
      bannerUrl: json['bannerUrl']?.toString() ??
          json['imageUrl']?.toString() ??
          '',
      category: json['category'] is Map
          ? CategoryDetailItem.fromJson(
              Map<String, dynamic>.from(json['category'] as Map))
          : null,
      categoryName: json['categoryName']?.toString() ??
          (json['category'] is Map ? json['category']['name']?.toString() ?? '' : ''),
      status: json['status']?.toString() ?? 'ACTIVE',
      isFeatured: json['isFeatured'] == true,
      maxVideoDuration: _parseInt(json['maxVideoDuration'], 60),
      startDate: json['startDate']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? '',
      endDateLabel: json['endDateLabel']?.toString() ?? '',
      daysLeft: _parseInt(json['daysLeft'], 0),
      daysLeftLabel: json['daysLeftLabel']?.toString() ?? '',
      joinedCount: _parseInt(json['joinedCount'], 0),
      joinedLabel: json['joinedLabel']?.toString() ?? '',
      approvedVideosCount: _parseInt(json['approvedVideosCount'], 0),
      averageRating: json['averageRating'] is num
          ? (json['averageRating'] as num)
          : (num.tryParse(json['averageRating']?.toString() ?? '0') ?? 0),
    );
  }

  static List<String> _parseRules(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
  }

  static List<PrizeBreakdownItem> _parsePrizeBreakdown(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => PrizeBreakdownItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static int _parseInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  String get formattedPrizePool {
    if (rewardPool.isNotEmpty) {
      final numVal = num.tryParse(rewardPool.replaceAll(RegExp(r'[^0-9.]'), ''));
      if (numVal != null) {
        return '₹${_formatCurrency(numVal.toInt())}';
      }
    }
    if (prizePoolLabel.isNotEmpty) {
      final cleaned = prizePoolLabel.replaceAll('\$', '₹');
      return cleaned;
    }
    return '₹5,000';
  }

  static String _formatCurrency(int amount) {
    final str = amount.toString();
    if (str.length <= 3) return str;
    final lastThree = str.substring(str.length - 3);
    final rest = str.substring(0, str.length - 3);
    final formattedRest = rest.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{2})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$formattedRest,$lastThree';
  }

  Map<String, dynamic> toUiMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'rules': rules,
      'prizeBreakdown': prizeBreakdown.map((p) => p.toUiMap()).toList(),
      'prize': formattedPrizePool,
      'participants': joinedCount,
      'joinedCount': joinedCount,
      'joinedLabel': joinedLabel.isNotEmpty ? joinedLabel : '$joinedCount joined',
      'daysLeft': daysLeft,
      'daysLeftLabel': daysLeftLabel.isNotEmpty ? daysLeftLabel : '$daysLeft days left',
      'endDate': endDate,
      'endDateLabel': endDateLabel,
      'imageUrl': bannerUrl,
      'bannerUrl': bannerUrl,
      'category': categoryName.isNotEmpty ? categoryName : 'Dance',
      'status': status.toLowerCase(),
      'isFeatured': isFeatured,
      'maxVideoDuration': maxVideoDuration,
    };
  }
}

class PrizeBreakdownItem {
  const PrizeBreakdownItem({
    required this.position,
    required this.title,
    required this.prize,
    this.badge,
  });

  final int position;
  final String title;
  final String prize;
  final String? badge;

  factory PrizeBreakdownItem.fromJson(Map<String, dynamic> json) {
    return PrizeBreakdownItem(
      position: _parseInt(json['position'], 1),
      title: json['title']?.toString() ?? '1st Place',
      prize: json['prize']?.toString() ?? '',
      badge: json['badge']?.toString(),
    );
  }

  static int _parseInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  String get formattedPrize {
    final numVal = num.tryParse(prize.replaceAll(RegExp(r'[^0-9.]'), ''));
    if (numVal != null) {
      return '₹${_formatCurrency(numVal.toInt())}';
    }
    if (prize.isNotEmpty) {
      if (!prize.startsWith('₹') && !prize.startsWith('\$')) {
        return '₹$prize';
      }
      return prize.replaceAll('\$', '₹');
    }
    return '₹0';
  }

  static String _formatCurrency(int amount) {
    final str = amount.toString();
    if (str.length <= 3) return str;
    final lastThree = str.substring(str.length - 3);
    final rest = str.substring(0, str.length - 3);
    final formattedRest = rest.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{2})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$formattedRest,$lastThree';
  }

  Map<String, dynamic> toUiMap() {
    return {
      'place': title.isNotEmpty ? title : '${position}st Place',
      'reward': badge != null && badge!.isNotEmpty
          ? '$formattedPrize + $badge'
          : formattedPrize,
      'amount': formattedPrize,
      'badge': badge,
      'position': position,
    };
  }
}

class JoinChallengeResponse {
  const JoinChallengeResponse({
    required this.success,
    this.message,
    this.data,
  });

  final bool success;
  final String? message;
  final JoinChallengeData? data;

  factory JoinChallengeResponse.fromJson(Map<String, dynamic> json) {
    return JoinChallengeResponse(
      success: json['success'] == true,
      message: json['message']?.toString(),
      data: json['data'] is Map
          ? JoinChallengeData.fromJson(
              Map<String, dynamic>.from(json['data'] as Map))
          : null,
    );
  }
}

class JoinChallengeData {
  const JoinChallengeData({
    required this.id,
    required this.userId,
    required this.challengeId,
    this.videoId,
    this.status = 'DRAFT',
    this.submittedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String challengeId;
  final String? videoId;
  final String status;
  final String? submittedAt;
  final String? createdAt;
  final String? updatedAt;

  factory JoinChallengeData.fromJson(Map<String, dynamic> json) {
    return JoinChallengeData(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      challengeId: json['challengeId']?.toString() ?? '',
      videoId: json['videoId']?.toString(),
      status: json['status']?.toString() ?? 'DRAFT',
      submittedAt: json['submittedAt']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }
}

