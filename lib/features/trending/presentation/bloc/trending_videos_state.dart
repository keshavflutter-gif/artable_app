import 'package:artable_app/features/trending/data/models/trending_videos_response.dart';

class TrendingVideosState {
  const TrendingVideosState({
    this.selectedTab = 'Trending',
    this.selectedCategory,
    this.selectedCategoryId,
    this.isLoading = false,
    this.hasLoaded = false,
    this.errorMessage,
    this.response,
    this.hero,
    this.videos = const [],
    this.tabs = defaultTabs,
    this.categories = const [],
  });

  static const List<String> defaultTabs = [
    'Trending',
    'Popular',
    'Newest',
    'Dance',
    'Singing',
    'Comedy',
    'Fitness',
    'Magic',
    'Art',
  ];

  final String selectedTab;
  final String? selectedCategory;
  final String? selectedCategoryId;
  final bool isLoading;
  final bool hasLoaded;
  final String? errorMessage;
  final TrendingVideosResponse? response;
  final TrendingVideoItem? hero;
  final List<TrendingVideoItem> videos;
  final List<String> tabs;
  final List<TrendingCategoryItem> categories;

  List<String> get availableTabs => tabs.isNotEmpty ? tabs : defaultTabs;

  List<Map<String, dynamic>> get heroAsUiMap {
    if (hero != null) {
      return [hero!.toUiMap()];
    }
    return const [];
  }

  List<Map<String, dynamic>> get gridVideosAsUiMaps {
    if (videos.isNotEmpty) {
      return videos.map((v) => v.toUiMap()).toList();
    }
    return const [];
  }

  TrendingVideosState copyWith({
    String? selectedTab,
    String? selectedCategory,
    String? selectedCategoryId,
    bool? isLoading,
    bool? hasLoaded,
    String? errorMessage,
    TrendingVideosResponse? response,
    TrendingVideoItem? hero,
    List<TrendingVideoItem>? videos,
    List<String>? tabs,
    List<TrendingCategoryItem>? categories,
    bool clearError = false,
  }) {
    return TrendingVideosState(
      selectedTab: selectedTab ?? this.selectedTab,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      response: response ?? this.response,
      hero: hero ?? this.hero,
      videos: videos ?? this.videos,
      tabs: tabs ?? this.tabs,
      categories: categories ?? this.categories,
    );
  }
}
