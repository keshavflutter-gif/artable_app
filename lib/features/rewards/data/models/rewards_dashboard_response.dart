class RewardsDashboardResponse {
  const RewardsDashboardResponse({
    required this.success,
    this.message,
    this.data,
    this.pagination,
  });

  final bool success;
  final String? message;
  final RewardsDashboardData? data;
  final RewardsPagination? pagination;

  factory RewardsDashboardResponse.fromJson(Map<String, dynamic> json) {
    return RewardsDashboardResponse(
      success: json['success'] == true,
      message: json['message']?.toString(),
      data: json['data'] is Map<String, dynamic>
          ? RewardsDashboardData.fromJson(
              json['data'] as Map<String, dynamic>)
          : (json['data'] is Map
              ? RewardsDashboardData.fromJson(
                  Map<String, dynamic>.from(json['data'] as Map))
              : null),
      pagination: json['pagination'] is Map<String, dynamic>
          ? RewardsPagination.fromJson(
              json['pagination'] as Map<String, dynamic>)
          : (json['pagination'] is Map
              ? RewardsPagination.fromJson(
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

class RewardsDashboardData {
  const RewardsDashboardData({
    this.wallet,
    this.availableRewards = '0',
    this.totalEarned = '0',
    this.tabs = const [],
    this.featuredReward,
    this.ads = const [],
    this.rewards = const [],
  });

  final RewardsWallet? wallet;
  final dynamic availableRewards;
  final dynamic totalEarned;
  final List<String> tabs;
  final RewardItem? featuredReward;
  final List<dynamic> ads;
  final List<RewardItem> rewards;

  String get displayAvailableBalance {
    if (wallet?.balance != null && wallet!.balance!.isNotEmpty) {
      final bal = wallet!.balance!;
      return bal.startsWith('₹') ? bal : '₹$bal';
    }
    final av = availableRewards?.toString() ?? '0';
    return av.startsWith('₹') ? av : '₹$av';
  }

  String get displayTotalEarned {
    final te = totalEarned?.toString() ?? '0';
    return te.startsWith('₹') ? te : '₹$te';
  }

  factory RewardsDashboardData.fromJson(Map<String, dynamic> json) {
    return RewardsDashboardData(
      wallet: json['wallet'] is Map
          ? RewardsWallet.fromJson(
              Map<String, dynamic>.from(json['wallet'] as Map))
          : null,
      availableRewards: json['availableRewards']?.toString() ?? '0',
      totalEarned: json['totalEarned']?.toString() ?? '0',
      tabs: json['tabs'] is List
          ? (json['tabs'] as List)
              .map((t) => t?.toString() ?? '')
              .where((t) => t.isNotEmpty)
              .toList()
          : const [],
      featuredReward: json['featuredReward'] is Map
          ? RewardItem.fromJson(
              Map<String, dynamic>.from(json['featuredReward'] as Map))
          : null,
      ads: json['ads'] is List ? (json['ads'] as List) : const [],
      rewards: _parseRewardList(json['rewards']),
    );
  }

  static List<RewardItem> _parseRewardList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((r) => RewardItem.fromJson(Map<String, dynamic>.from(r)))
        .toList();
  }

  Map<String, dynamic> toJson() => {
        'wallet': wallet?.toJson(),
        'availableRewards': availableRewards,
        'totalEarned': totalEarned,
        'tabs': tabs,
        'featuredReward': featuredReward?.toJson(),
        'ads': ads,
        'rewards': rewards.map((r) => r.toJson()).toList(),
      };
}

class RewardsWallet {
  const RewardsWallet({
    required this.id,
    required this.userId,
    this.balance = '0',
    this.coins = 0,
    this.points = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String? balance;
  final int coins;
  final int points;
  final String? createdAt;
  final String? updatedAt;

  factory RewardsWallet.fromJson(Map<String, dynamic> json) {
    return RewardsWallet(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      balance: json['balance']?.toString() ?? '0',
      coins: _parseInt(json['coins']) ?? 0,
      points: _parseInt(json['points']) ?? 0,
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'balance': balance,
        'coins': coins,
        'points': points,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}

class RewardItem {
  const RewardItem({
    required this.id,
    required this.title,
    this.description,
    this.type = 'cash',
    this.value = '₹0',
    this.imageUrl,
    this.status = 'available',
    this.featured = false,
    this.expiresAt,
    this.brand,
    this.code,
  });

  final String id;
  final String title;
  final String? description;
  final String type;
  final String value;
  final String? imageUrl;
  final String status;
  final bool featured;
  final String? expiresAt;
  final String? brand;
  final String? code;

  String get displayImageUrl {
    if (imageUrl != null &&
        imageUrl!.trim().isNotEmpty &&
        imageUrl!.startsWith('http')) {
      return imageUrl!.trim();
    }
    switch (type.toLowerCase()) {
      case 'voucher':
        return 'https://images.unsplash.com/photo-1526304640581-d334cdbbf45e?w=600&q=80';
      case 'product':
        return 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=600&q=80';
      case 'sponsor':
        return 'https://images.unsplash.com/photo-1511556532299-8f662fc26c06?w=600&q=80';
      default:
        return 'https://images.unsplash.com/photo-1553729459-efe14ef6055d?w=600&q=80';
    }
  }

  Map<String, dynamic> toUiMap() {
    return {
      'id': id,
      'title': title,
      'description': description ?? '',
      'type': type,
      'value': value,
      'imageUrl': displayImageUrl,
      'status': status,
      'featured': featured,
      'expiresAt': expiresAt ?? '',
      'brand': brand ?? '',
      'code': code ?? '',
    };
  }

  factory RewardItem.fromJson(Map<String, dynamic> json) {
    return RewardItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      type: json['type']?.toString() ?? 'cash',
      value: json['value']?.toString() ?? '₹0',
      imageUrl: json['imageUrl']?.toString() ?? json['bannerUrl']?.toString(),
      status: json['status']?.toString() ?? 'available',
      featured: json['featured'] == true || json['isFeatured'] == true,
      expiresAt: json['expiresAt']?.toString(),
      brand: json['brand']?.toString(),
      code: json['code']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'type': type,
        'value': value,
        'imageUrl': imageUrl,
        'status': status,
        'featured': featured,
        'expiresAt': expiresAt,
        'brand': brand,
        'code': code,
      };
}

class RewardsPagination {
  const RewardsPagination({
    this.page = 1,
    this.limit = 20,
    this.total = 0,
  });

  final int page;
  final int limit;
  final int total;

  factory RewardsPagination.fromJson(Map<String, dynamic> json) {
    return RewardsPagination(
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
