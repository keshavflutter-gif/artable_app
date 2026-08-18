import 'package:artable_app/core/utils/mock_helpers.dart';
import 'package:artable_app/data/datasources/mock_data.dart';
import 'package:artable_app/features/leaderboard/data/models/leaderboard_response.dart';

class LeaderboardState {
  const LeaderboardState({
    this.selectedTab = 'Global',
    this.selectedCategory = 'All Categories',
    this.selectedCategoryId,
    this.challengeId,
    this.isLoading = false,
    this.hasLoaded = false,
    this.errorMessage,
    this.response,
    this.podium = const [],
    this.rankings = const [],
    this.yourRank,
    this.tabs = defaultTabs,
    this.categories = const [],
  });

  static const List<String> defaultTabs = [
    'Global',
    'Challenge',
    'Weekly',
    'Monthly',
  ];

  static const List<String> defaultCategories = [
    'All Categories',
    'Dance',
    'Singing',
    'Comedy',
    'Fitness',
    'Magic',
    'Art',
    'Sports',
  ];

  final String selectedTab;
  final String selectedCategory;
  final String? selectedCategoryId;
  final String? challengeId;
  final bool isLoading;
  final bool hasLoaded;
  final String? errorMessage;
  final LeaderboardResponse? response;
  final List<LeaderboardRankItem> podium;
  final List<LeaderboardRankItem> rankings;
  final LeaderboardRankItem? yourRank;
  final List<String> tabs;
  final List<LeaderboardCategoryItem> categories;

  List<String> get availableTabs => tabs.isNotEmpty ? tabs : defaultTabs;

  List<String> get availableCategoryNames {
    if (categories.isNotEmpty) {
      final list = categories.map((c) => c.name).toList();
      if (!list.contains('All Categories')) {
        list.insert(0, 'All Categories');
      }
      return list;
    }
    return defaultCategories;
  }

  String get mockSortKey {
    switch (selectedTab) {
      case 'Challenge':
        return 'challenge';
      case 'Weekly':
        return 'weekly';
      case 'Monthly':
        return 'monthly';
      default:
        return 'global';
    }
  }

  List<Map<String, dynamic>> get fallbackRankedCreators {
    var list = List<Map<String, dynamic>>.from(MockData.CREATORS)
      ..sort((a, b) => MockHelpers.sortValue(b, mockSortKey)
          .compareTo(MockHelpers.sortValue(a, mockSortKey)));
    if (selectedCategory != 'All Categories') {
      list = list.where((u) => u['category'] == selectedCategory).toList();
    }
    return list;
  }

  List<Map<String, dynamic>> get top3PodiumAsUiMaps {
    if (podium.isNotEmpty) {
      return podium.map((p) => p.toUiMap()).toList();
    }
    return fallbackRankedCreators.take(3).toList();
  }

  List<Map<String, dynamic>> get restRankingsAsUiMaps {
    if (rankings.isNotEmpty) {
      if (podium.isNotEmpty) {
        final podiumIds = podium.map((p) => p.user?.id ?? p.id).toSet();
        final nonPodium = rankings
            .where((r) => !podiumIds.contains(r.user?.id ?? r.id))
            .toList();
        if (nonPodium.isNotEmpty) {
          return nonPodium.map((r) => r.toUiMap()).toList();
        }
      }
      if (rankings.length > 3) {
        return rankings.skip(3).map((r) => r.toUiMap()).toList();
      }
      return const [];
    }
    return fallbackRankedCreators.skip(3).toList();
  }

  LeaderboardState copyWith({
    String? selectedTab,
    String? selectedCategory,
    String? selectedCategoryId,
    String? challengeId,
    bool? isLoading,
    bool? hasLoaded,
    String? errorMessage,
    LeaderboardResponse? response,
    List<LeaderboardRankItem>? podium,
    List<LeaderboardRankItem>? rankings,
    LeaderboardRankItem? yourRank,
    List<String>? tabs,
    List<LeaderboardCategoryItem>? categories,
    bool clearError = false,
  }) {
    return LeaderboardState(
      selectedTab: selectedTab ?? this.selectedTab,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      challengeId: challengeId ?? this.challengeId,
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      response: response ?? this.response,
      podium: podium ?? this.podium,
      rankings: rankings ?? this.rankings,
      yourRank: yourRank ?? this.yourRank,
      tabs: tabs ?? this.tabs,
      categories: categories ?? this.categories,
    );
  }
}
