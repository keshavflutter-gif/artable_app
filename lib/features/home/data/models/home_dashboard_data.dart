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
      trendingVideos: _parseMapList(
        json['trendingVideos'] ??
            json['trending_videos'] ??
            json['videos'] ??
            json['trending'],
      ),
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

  static List<Map<String, dynamic>> _parseMapList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
