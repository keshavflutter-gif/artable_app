import 'home_banner.dart';

class HomeDashboardData {
  const HomeDashboardData({
    required this.banners,
    required this.featuredChallenges,
    required this.trendingVideos,
    required this.categories,
    required this.announcements,
  });

  final List<HomeBanner> banners;
  final List<Map<String, dynamic>> featuredChallenges;
  final List<Map<String, dynamic>> trendingVideos;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> announcements;

  factory HomeDashboardData.fromJson(Map<String, dynamic> json) {
    return HomeDashboardData(
      banners: _parseBanners(json['banners']),
      featuredChallenges: _parseMapList(json['featuredChallenges']),
      trendingVideos: _parseTrendingVideos(json),
      categories: _parseMapList(json['categories']),
      announcements: _parseMapList(json['announcements']),
    );
  }

  factory HomeDashboardData.empty() {
    return const HomeDashboardData(
      banners: [],
      featuredChallenges: [],
      trendingVideos: [],
      categories: [],
      announcements: [],
    );
  }

  static List<HomeBanner> _parseBanners(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => HomeBanner.fromJson(Map<String, dynamic>.from(item)))
        .where((banner) => banner.id.isNotEmpty)
        .toList();
  }

  static List<Map<String, dynamic>> _parseTrendingVideos(Map<String, dynamic> json) {
    final list = <Map<String, dynamic>>[];
    Map<String, dynamic>? dataMap;
    if (json['data'] is Map) {
      dataMap = Map<String, dynamic>.from(json['data'] as Map);
    } else {
      dataMap = json;
    }

    if (dataMap['hero'] is Map) {
      list.add(Map<String, dynamic>.from(dataMap['hero'] as Map));
    }

    final raw = json['trendingVideos'] ??
        json['trending_videos'] ??
        json['videos'] ??
        json['trending'] ??
        dataMap['videos'] ??
        dataMap['trendingVideos'] ??
        dataMap['items'];

    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          final m = Map<String, dynamic>.from(item);
          final id = m['id']?.toString() ?? '';
          if (id.isNotEmpty && !list.any((existing) => existing['id']?.toString() == id)) {
            list.add(m);
          }
        }
      }
    }

    return list;
  }

  static List<Map<String, dynamic>> _parseMapList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
