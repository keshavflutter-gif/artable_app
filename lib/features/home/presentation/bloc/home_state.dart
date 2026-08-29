import 'package:artable_app/features/home/data/models/home_dashboard_response.dart';
import 'package:artable_app/features/home/data/models/home_ui_mapper.dart';

class HomeState {
  const HomeState({
    this.dashboard,
    this.isLoading = false,
    this.hasLoaded = false,
    this.errorMessage,
  });

  final HomeDashboardResponse? dashboard;
  final bool isLoading;
  final bool hasLoaded;
  final String? errorMessage;

  List<Map<String, dynamic>> get megaPromoBanners {
    if (dashboard != null) {
      return dashboard!.data.banners
          .map(HomeUiMapper.bannerToMegaPromo)
          .where((banner) => (banner['title'] as String).isNotEmpty)
          .toList();
    }
    return const [];
  }

  List<Map<String, dynamic>> get heroBannerSlides {
    if (dashboard != null) {
      return dashboard!.data.banners
          .map(HomeUiMapper.bannerToHeroSlide)
          .where((slide) => (slide['title'] as String).isNotEmpty)
          .toList();
    }
    return const [];
  }

  List<Map<String, dynamic>> get activeChallenges {
    if (dashboard != null) {
      return dashboard!.data.featuredChallenges
          .map(HomeUiMapper.featuredChallengeToUiMap)
          .where((challenge) => (challenge['title'] as String).isNotEmpty)
          .toList();
    }
    return const [];
  }

  List<Map<String, dynamic>> get trendingReels {
    if (dashboard != null) {
      return dashboard!.data.trendingVideos
          .map(HomeUiMapper.trendingVideoToUiMap)
          .where((reel) {
            return (reel['title'] as String).isNotEmpty ||
                (reel['imageUrl'] as String).isNotEmpty;
          })
          .toList();
    }
    return const [];
  }

  List<Map<String, dynamic>> get categories {
    if (dashboard != null) {
      return dashboard!.data.categories;
    }
    return const [];
  }

  HomeState copyWith({
    HomeDashboardResponse? dashboard,
    bool? isLoading,
    bool? hasLoaded,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HomeState(
      dashboard: dashboard ?? this.dashboard,
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
