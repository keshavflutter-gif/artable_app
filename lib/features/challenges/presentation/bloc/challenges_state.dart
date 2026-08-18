import 'package:artable_app/data/datasources/mock_data.dart';
import 'package:artable_app/features/challenges/data/models/categories_response.dart';
import 'package:artable_app/features/challenges/data/models/challenge_detail_response.dart';

class ChallengesState {
  ChallengesState({
    this.categoriesResponse,
    this.isLoadingCategories = false,
    this.hasLoadedCategories = false,
    this.categoriesErrorMessage,
    Map<String, ChallengeDetailData>? challengeDetails,
    Map<String, bool>? loadingChallengeDetails,
    Map<String, String>? errorChallengeDetails,
    Map<String, List<ChallengeDetailData>>? tabChallenges,
    Map<String, bool>? loadingTabChallenges,
    Map<String, bool>? loadedTabChallenges,
    Map<String, String>? errorTabChallenges,
    Map<String, List<ChallengeDetailData>>? categoryChallenges,
    Map<String, bool>? loadingCategoryChallenges,
    Map<String, bool>? loadedCategoryChallenges,
    Map<String, String>? errorCategoryChallenges,
    this.categoryQuery = '',
    this.challengeQuery = '',
    this.selectedCategoryId,
    Map<String, bool>? joiningChallenges,
    List<Map<String, dynamic>>? customChallenges,
  })  : challengeDetails = challengeDetails ?? const {},
        loadingChallengeDetails = loadingChallengeDetails ?? const {},
        errorChallengeDetails = errorChallengeDetails ?? const {},
        tabChallenges = tabChallenges ?? const {},
        loadingTabChallenges = loadingTabChallenges ?? const {},
        loadedTabChallenges = loadedTabChallenges ?? const {},
        errorTabChallenges = errorTabChallenges ?? const {},
        categoryChallenges = categoryChallenges ?? const {},
        loadingCategoryChallenges = loadingCategoryChallenges ?? const {},
        loadedCategoryChallenges = loadedCategoryChallenges ?? const {},
        errorCategoryChallenges = errorCategoryChallenges ?? const {},
        joiningChallenges = joiningChallenges ?? const {},
        challenges = customChallenges ?? List<Map<String, dynamic>>.from(MockData.CHALLENGES);

  final CategoriesResponse? categoriesResponse;
  final bool isLoadingCategories;
  final bool hasLoadedCategories;
  final String? categoriesErrorMessage;

  final Map<String, ChallengeDetailData> challengeDetails;
  final Map<String, bool> loadingChallengeDetails;
  final Map<String, String> errorChallengeDetails;

  final Map<String, List<ChallengeDetailData>> tabChallenges;
  final Map<String, bool> loadingTabChallenges;
  final Map<String, bool> loadedTabChallenges;
  final Map<String, String> errorTabChallenges;

  final Map<String, List<ChallengeDetailData>> categoryChallenges;
  final Map<String, bool> loadingCategoryChallenges;
  final Map<String, bool> loadedCategoryChallenges;
  final Map<String, String> errorCategoryChallenges;

  final String categoryQuery;
  final String challengeQuery;
  final String? selectedCategoryId;
  final Map<String, bool> joiningChallenges;
  final List<Map<String, dynamic>> challenges;

  CategorySummary? get categorySummary => categoriesResponse?.summary;

  List<Map<String, dynamic>> get categories {
    if (categoriesResponse != null) {
      return categoriesResponse!.data.map((c) => c.toUiMap()).toList();
    }
    return List<Map<String, dynamic>>.from(MockData.CATEGORIES);
  }

  List<Map<String, dynamic>> get filteredCategories {
    final list = categories;
    if (categoryQuery.isEmpty) return list;
    final q = categoryQuery.toLowerCase();
    return list
        .where((c) => (c['name'] as String? ?? '').toLowerCase().contains(q))
        .toList();
  }

  List<Map<String, dynamic>> get filteredChallenges {
    return getChallengesForTab(
      'ACTIVE',
      categoryId: selectedCategoryId,
      query: challengeQuery,
    );
  }

  ChallengeDetailData? getChallengeDetail(String challengeId) {
    return challengeDetails[challengeId];
  }

  bool isLoadingChallengeDetail(String challengeId) {
    return loadingChallengeDetails[challengeId] == true;
  }

  String? getChallengeDetailError(String challengeId) {
    return errorChallengeDetails[challengeId];
  }

  bool isLoadingTabChallenges(String tab) {
    return loadingTabChallenges[tab.toUpperCase()] == true;
  }

  bool hasLoadedTabChallenges(String tab) {
    return loadedTabChallenges[tab.toUpperCase()] == true;
  }

  String? getTabChallengesError(String tab) {
    return errorTabChallenges[tab.toUpperCase()];
  }

  bool isLoadingCategoryChallenges(String categoryId) {
    return loadingCategoryChallenges[categoryId] == true;
  }

  bool hasLoadedCategoryChallenges(String categoryId) {
    return loadedCategoryChallenges[categoryId] == true;
  }

  String? getCategoryChallengesError(String categoryId) {
    return errorCategoryChallenges[categoryId];
  }

  bool isJoiningChallenge(String challengeId) {
    return joiningChallenges[challengeId] == true;
  }

  List<Map<String, dynamic>> getChallengesForCategory(
    String categoryId, {
    String? query,
  }) {
    List<Map<String, dynamic>> list;
    if (categoryChallenges.containsKey(categoryId)) {
      list = categoryChallenges[categoryId]!.map((c) => c.toUiMap()).toList();
    } else {
      list = const [];
    }

    final activeQuery = query ?? challengeQuery;
    if (activeQuery.isNotEmpty) {
      final q = activeQuery.toLowerCase();
      list = list.where((c) {
        final title = (c['title'] as String? ?? '').toLowerCase();
        final description = (c['description'] as String? ?? '').toLowerCase();
        return title.contains(q) || description.contains(q);
      }).toList();
    }
    return list;
  }

  List<Map<String, dynamic>> getChallengesForTab(
    String tab, {
    String? categoryId,
    String? query,
  }) {
    final normTab = tab.toUpperCase();
    List<Map<String, dynamic>> list;

    if (tabChallenges.containsKey(normTab)) {
      list = tabChallenges[normTab]!.map((c) => c.toUiMap()).toList();
    } else {
      list = const [];
    }

    if (categoryId != null && categoryId.isNotEmpty) {
      final categoryList = categories;
      final category = categoryList.firstWhere(
        (c) => c['id'] == categoryId,
        orElse: () => {'name': ''},
      );
      final catName = category['name'] as String? ?? '';
      if (catName.isNotEmpty) {
        list = list.where((c) => c['category'] == catName).toList();
      }
    }

    final activeQuery = query ?? challengeQuery;
    if (activeQuery.isNotEmpty) {
      final q = activeQuery.toLowerCase();
      list = list
          .where(
            (c) =>
                (c['title'] as String? ?? '').toLowerCase().contains(q) ||
                (c['category'] as String? ?? '').toLowerCase().contains(q),
          )
          .toList();
    }

    return list;
  }

  Map<String, dynamic>? getChallengeById(String id) {
    if (challengeDetails.containsKey(id)) {
      return challengeDetails[id]!.toUiMap();
    }
    for (final c in challenges) {
      if (c['id'] == id) return c;
    }
    return null;
  }

  ChallengesState copyWith({
    CategoriesResponse? categoriesResponse,
    bool? isLoadingCategories,
    bool? hasLoadedCategories,
    String? categoriesErrorMessage,
    Map<String, ChallengeDetailData>? challengeDetails,
    Map<String, bool>? loadingChallengeDetails,
    Map<String, String>? errorChallengeDetails,
    Map<String, List<ChallengeDetailData>>? tabChallenges,
    Map<String, bool>? loadingTabChallenges,
    Map<String, bool>? loadedTabChallenges,
    Map<String, String>? errorTabChallenges,
    Map<String, List<ChallengeDetailData>>? categoryChallenges,
    Map<String, bool>? loadingCategoryChallenges,
    Map<String, bool>? loadedCategoryChallenges,
    Map<String, String>? errorCategoryChallenges,
    String? categoryQuery,
    String? challengeQuery,
    String? selectedCategoryId,
    Map<String, bool>? joiningChallenges,
    List<Map<String, dynamic>>? challenges,
    bool clearCategoryError = false,
  }) {
    return ChallengesState(
      categoriesResponse: categoriesResponse ?? this.categoriesResponse,
      isLoadingCategories: isLoadingCategories ?? this.isLoadingCategories,
      hasLoadedCategories: hasLoadedCategories ?? this.hasLoadedCategories,
      categoriesErrorMessage: clearCategoryError ? null : (categoriesErrorMessage ?? this.categoriesErrorMessage),
      challengeDetails: challengeDetails ?? this.challengeDetails,
      loadingChallengeDetails: loadingChallengeDetails ?? this.loadingChallengeDetails,
      errorChallengeDetails: errorChallengeDetails ?? this.errorChallengeDetails,
      tabChallenges: tabChallenges ?? this.tabChallenges,
      loadingTabChallenges: loadingTabChallenges ?? this.loadingTabChallenges,
      loadedTabChallenges: loadedTabChallenges ?? this.loadedTabChallenges,
      errorTabChallenges: errorTabChallenges ?? this.errorTabChallenges,
      categoryChallenges: categoryChallenges ?? this.categoryChallenges,
      loadingCategoryChallenges: loadingCategoryChallenges ?? this.loadingCategoryChallenges,
      loadedCategoryChallenges: loadedCategoryChallenges ?? this.loadedCategoryChallenges,
      errorCategoryChallenges: errorCategoryChallenges ?? this.errorCategoryChallenges,
      categoryQuery: categoryQuery ?? this.categoryQuery,
      challengeQuery: challengeQuery ?? this.challengeQuery,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      joiningChallenges: joiningChallenges ?? this.joiningChallenges,
      customChallenges: challenges ?? this.challenges,
    );
  }
}
