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
    this.availableRewards = 0,
    this.totalEarned = 0,
    this.availableCashRewards,
    this.totalCashEarned,
    this.availableCashRewardsLabel,
    this.totalCashEarnedLabel,
    this.tabs = const [],
    this.selectedTab,
    this.featuredReward,
    this.ads = const [],
    this.rewards = const [],
  });

  final RewardsWallet? wallet;
  final dynamic availableRewards;
  final dynamic totalEarned;
  final dynamic availableCashRewards;
  final dynamic totalCashEarned;
  final String? availableCashRewardsLabel;
  final String? totalCashEarnedLabel;
  final List<String> tabs;
  final String? selectedTab;
  final RewardItem? featuredReward;
  final List<dynamic> ads;
  final List<RewardItem> rewards;

  String get displayAvailableBalance {
    if (availableRewards != null) {
      return _formatAmount(availableRewards, allowNegative: false);
    }
    if (availableCashRewardsLabel != null &&
        availableCashRewardsLabel!.isNotEmpty) {
      return _formatAmount(availableCashRewardsLabel, allowNegative: false);
    }
    if (availableCashRewards != null) {
      return _formatAmount(availableCashRewards, allowNegative: false);
    }
    if (wallet?.balance != null && wallet!.balance!.isNotEmpty) {
      return _formatAmount(wallet!.balance, allowNegative: false);
    }
    return '₹0';
  }

  String get displayTotalEarned {
    if (totalEarned != null) {
      return _formatAmount(totalEarned, allowNegative: false);
    }
    if (totalCashEarnedLabel != null && totalCashEarnedLabel!.isNotEmpty) {
      return _formatAmount(totalCashEarnedLabel, allowNegative: false);
    }
    if (totalCashEarned != null) {
      return _formatAmount(totalCashEarned, allowNegative: false);
    }
    return '₹0';
  }

  static String _formatAmount(dynamic val, {bool allowNegative = false}) {
    if (val == null) return '₹0';
    final str = val.toString().trim();
    if (str.isEmpty) return '₹0';

    var clean = str;
    if (clean.startsWith('₹')) {
      clean = clean.substring(1).trim();
    } else if (clean.startsWith('\$')) {
      clean = clean.substring(1).trim();
    }

    final numVal = num.tryParse(clean.replaceAll(',', ''));
    if (numVal != null) {
      if (!allowNegative && numVal < 0) {
        return '₹0';
      }
      if (numVal % 1 == 0) {
        return '₹${numVal.toInt()}';
      }
      return '₹$numVal';
    }
    return '₹$str';
  }

  factory RewardsDashboardData.fromJson(Map<String, dynamic> json) {
    return RewardsDashboardData(
      wallet: json['wallet'] is Map
          ? RewardsWallet.fromJson(
              Map<String, dynamic>.from(json['wallet'] as Map))
          : null,
      availableRewards: json['availableRewards'] ?? json['availableCashRewards'],
      totalEarned: json['totalEarned'] ?? json['totalCashEarned'],
      availableCashRewards: json['availableCashRewards'],
      totalCashEarned: json['totalCashEarned'],
      availableCashRewardsLabel: json['availableCashRewardsLabel']?.toString(),
      totalCashEarnedLabel: json['totalCashEarnedLabel']?.toString(),
      selectedTab: json['selectedTab']?.toString(),
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
        'availableCashRewards': availableCashRewards,
        'totalCashEarned': totalCashEarned,
        'availableCashRewardsLabel': availableCashRewardsLabel,
        'totalCashEarnedLabel': totalCashEarnedLabel,
        'tabs': tabs,
        'selectedTab': selectedTab,
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
    this.subtitle,
    this.description,
    this.type = 'cash',
    this.value = '₹0',
    this.valueLabel,
    this.stock,
    this.sponsorName,
    this.imageUrl,
    this.isActive = true,
    this.status = 'available',
    this.statusLabel,
    this.isClaimed = false,
    this.isAvailable = true,
    this.claim,
    this.featured = false,
    this.expiresAt,
    this.brand,
    this.code,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String? description;
  final String type;
  final String value;
  final String? valueLabel;
  final int? stock;
  final String? sponsorName;
  final String? imageUrl;
  final bool isActive;
  final String status;
  final String? statusLabel;
  final bool isClaimed;
  final bool isAvailable;
  final dynamic claim;
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
      case 'vouchers':
        return 'https://images.unsplash.com/photo-1526304640581-d334cdbbf45e?w=600&q=80';
      case 'product':
      case 'products':
        return 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=600&q=80';
      case 'sponsor':
        return 'https://images.unsplash.com/photo-1511556532299-8f662fc26c06?w=600&q=80';
      case 'cash':
      default:
        return 'https://images.unsplash.com/photo-1553729459-efe14ef6055d?w=600&q=80';
    }
  }

  String _resolveStatus() {
    if (isClaimed) return 'claimed';
    final s = status.trim().toLowerCase();
    if (s == 'claimed') return 'claimed';
    if (s == 'locked' || !isAvailable) return 'locked';
    return 'available';
  }

  String _formatValue() {
    if (valueLabel != null && valueLabel!.trim().isNotEmpty) {
      final vl = valueLabel!.trim();
      if (vl.startsWith('\$')) {
        return '₹${vl.replaceFirst('\$', '').trim()}';
      }
      return vl;
    }
    final v = value.trim();
    if (v.isEmpty) return '₹0';
    if (v.startsWith('₹')) return v;
    if (v.startsWith('\$')) return '₹${v.replaceFirst('\$', '').trim()}';
    final n = num.tryParse(v.replaceAll(',', ''));
    if (n != null) {
      if (n % 1 == 0) return '₹${n.toInt()}';
      return '₹$n';
    }
    return '₹$v';
  }

  Map<String, dynamic> toUiMap() {
    final normStatus = _resolveStatus();
    final formattedValue = _formatValue();
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle ?? '',
      'description': description ?? '',
      'type': type.toLowerCase(),
      'value': formattedValue,
      'valueLabel': valueLabel ?? formattedValue,
      'imageUrl': displayImageUrl,
      'status': normStatus,
      'statusLabel': statusLabel ?? normStatus.toUpperCase(),
      'isClaimed': isClaimed || normStatus == 'claimed',
      'isAvailable': isAvailable && normStatus != 'locked',
      'featured': featured,
      'expiresAt': expiresAt ?? '',
      'brand': brand ?? sponsorName ?? '',
      'sponsorName': sponsorName ?? brand ?? '',
      'code': code ?? '',
    };
  }

  factory RewardItem.fromJson(Map<String, dynamic> json) {
    final rawType = json['type']?.toString().toLowerCase() ?? 'cash';
    final rawStatus = json['status']?.toString().toLowerCase() ?? 'available';
    final claimed = json['isClaimed'] == true || rawStatus == 'claimed';
    final available = json['isAvailable'] == true || (json['isAvailable'] == null && rawStatus == 'available');

    return RewardItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString(),
      description: json['description']?.toString(),
      type: rawType,
      value: json['value']?.toString() ?? '0',
      valueLabel: json['valueLabel']?.toString(),
      stock: json['stock'] is num
          ? (json['stock'] as num).toInt()
          : (int.tryParse(json['stock']?.toString() ?? '')),
      sponsorName: json['sponsorName']?.toString() ?? json['brand']?.toString(),
      imageUrl: json['imageUrl']?.toString() ?? json['bannerUrl']?.toString(),
      isActive: json['isActive'] != false,
      status: claimed ? 'claimed' : (available ? 'available' : 'locked'),
      statusLabel: json['statusLabel']?.toString(),
      isClaimed: claimed,
      isAvailable: available,
      claim: json['claim'],
      featured: json['featured'] == true || json['isFeatured'] == true,
      expiresAt: json['expiresAt']?.toString(),
      brand: json['brand']?.toString() ?? json['sponsorName']?.toString(),
      code: json['code']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'description': description,
        'type': type,
        'value': value,
        'valueLabel': valueLabel,
        'stock': stock,
        'sponsorName': sponsorName,
        'imageUrl': imageUrl,
        'isActive': isActive,
        'status': status,
        'statusLabel': statusLabel,
        'isClaimed': isClaimed,
        'isAvailable': isAvailable,
        'claim': claim,
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
