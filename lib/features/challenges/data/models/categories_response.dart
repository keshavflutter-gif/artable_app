class CategoriesResponse {
  const CategoriesResponse({
    required this.success,
    this.message,
    required this.data,
    this.summary,
  });

  final bool success;
  final String? message;
  final List<CategoryDetailItem> data;
  final CategorySummary? summary;

  factory CategoriesResponse.fromJson(Map<String, dynamic> json) {
    return CategoriesResponse(
      success: json['success'] == true,
      message: json['message']?.toString(),
      data: _parseCategories(json['data']),
      summary: json['summary'] is Map
          ? CategorySummary.fromJson(
              Map<String, dynamic>.from(json['summary'] as Map))
          : null,
    );
  }

  static List<CategoryDetailItem> _parseCategories(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) =>
            CategoryDetailItem.fromJson(Map<String, dynamic>.from(item)))
        .where((category) => category.id.isNotEmpty && category.name.isNotEmpty)
        .toList();
  }
}

class CategorySummary {
  const CategorySummary({
    required this.totalCategories,
    required this.activeChallenges,
    required this.updatedFrequency,
  });

  final int totalCategories;
  final int activeChallenges;
  final String updatedFrequency;

  factory CategorySummary.fromJson(Map<String, dynamic> json) {
    return CategorySummary(
      totalCategories: _parseInt(json['totalCategories']),
      activeChallenges: _parseInt(json['activeChallenges']),
      updatedFrequency: json['updatedFrequency']?.toString() ?? 'Daily',
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class CategoryDetailItem {
  const CategoryDetailItem({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.isActive = true,
    this.liveChallenges = 0,
    this.approvedVideos = 0,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final bool isActive;
  final int liveChallenges;
  final int approvedVideos;
  final String? updatedAt;

  factory CategoryDetailItem.fromJson(Map<String, dynamic> json) {
    return CategoryDetailItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      isActive: json['isActive'] == null ? true : json['isActive'] == true,
      liveChallenges: _parseInt(json['liveChallenges']),
      approvedVideos: _parseInt(json['approvedVideos']),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toUiMap() {
    return {
      'id': id,
      'name': name,
      'description': description ?? '',
      'imageUrl': imageUrl ?? '',
      'isActive': isActive,
      'count': liveChallenges,
      'liveChallenges': liveChallenges,
      'approvedVideos': approvedVideos,
      'updatedAt': updatedAt ?? '',
      'icon': _deriveIcon(name),
    };
  }

  static String _deriveIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('dance')) return 'dance';
    if (lower.contains('sing') || lower.contains('music') || lower.contains('song')) {
      return 'mic';
    }
    if (lower.contains('comedy') || lower.contains('joke') || lower.contains('standup')) {
      return 'mask';
    }
    if (lower.contains('fitness') || lower.contains('gym') || lower.contains('sport')) {
      return 'dumbbell';
    }
    if (lower.contains('magic') || lower.contains('trick')) return 'wand';
    if (lower.contains('art') || lower.contains('paint') || lower.contains('draw')) {
      return 'brush';
    }
    if (lower.contains('acting') || lower.contains('drama') || lower.contains('theatre')) {
      return 'drama';
    }
    if (lower.contains('trophy') || lower.contains('contest')) return 'trophy';
    return 'sparkle';
  }
}
