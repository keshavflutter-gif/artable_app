import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:artable_app/features/leaderboard/data/models/leaderboard_response.dart';
import 'package:artable_app/features/leaderboard/data/repositories/leaderboard_repository.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'leaderboard_state.dart';

class LeaderboardCubit extends Cubit<LeaderboardState> {
  LeaderboardCubit({
    AuthCubit? authCubit,
    LeaderboardRepository? leaderboardRepository,
  })  : _authCubit = authCubit,
        _leaderboardRepository = leaderboardRepository ??
            LeaderboardRepository(
              onTokensRefreshed: authCubit?.applyRefreshedTokens,
              onSessionRefreshFailed: authCubit?.handleSessionRefreshFailed,
            ),
        super(const LeaderboardState());

  AuthCubit? _authCubit;
  final LeaderboardRepository _leaderboardRepository;

  String get selectedTab => state.selectedTab;
  String get selectedCategory => state.selectedCategory;
  String? get selectedCategoryId => state.selectedCategoryId;
  String? get challengeId => state.challengeId;
  bool get isLoading => state.isLoading;
  bool get hasLoaded => state.hasLoaded;
  String? get errorMessage => state.errorMessage;
  LeaderboardResponse? get response => state.response;
  List<LeaderboardRankItem> get podium => state.podium;
  List<LeaderboardRankItem> get rankings => state.rankings;
  LeaderboardRankItem? get yourRank => state.yourRank;
  List<String> get availableTabs => state.availableTabs;
  List<String> get availableCategoryNames => state.availableCategoryNames;
  List<Map<String, dynamic>> get fallbackRankedCreators =>
      state.fallbackRankedCreators;
  List<Map<String, dynamic>> get top3PodiumAsUiMaps => state.top3PodiumAsUiMaps;
  List<Map<String, dynamic>> get restRankingsAsUiMaps =>
      state.restRankingsAsUiMaps;

  Future<void> loadLeaderboard({
    String? scope,
    String? category,
    String? categoryId,
    String? challengeId,
    bool forceRefresh = false,
  }) async {
    if (state.isLoading) return;
    if (state.hasLoaded &&
        !forceRefresh &&
        scope == null &&
        category == null &&
        challengeId == null) {
      return;
    }

    final targetScope = scope ?? state.selectedTab;
    final targetCategory = category ?? state.selectedCategory;
    final targetCategoryId = categoryId ?? state.selectedCategoryId;
    final targetChallengeId = challengeId ?? state.challengeId;

    emit(state.copyWith(
      isLoading: true,
      selectedTab: targetScope,
      selectedCategory: targetCategory,
      selectedCategoryId: targetCategoryId,
      challengeId: targetChallengeId,
      clearError: true,
    ));

    final token = _authCubit?.sessionToken;
    final refresh = _authCubit?.refreshToken;

    try {
      final res = await _leaderboardRepository.getLeaderboard(
        scope: targetScope,
        category: targetCategory,
        categoryId: targetCategoryId,
        challengeId: targetChallengeId,
        sessionToken: token != 'design_preview' ? token : null,
        refreshToken: refresh != 'design_preview' ? refresh : null,
      );

      List<String> tabs = state.tabs;
      List<LeaderboardCategoryItem> categories = state.categories;

      if (res.data != null) {
        if (res.data!.tabs.isNotEmpty) {
          final merged = <String>[...res.data!.tabs];
          for (final dTab in LeaderboardState.defaultTabs) {
            if (!merged.contains(dTab)) {
              merged.add(dTab);
            }
          }
          tabs = merged;
        }

        if (res.data!.categories.isNotEmpty) {
          categories = res.data!.categories;
        }
      }

      emit(state.copyWith(
        response: res,
        podium: res.data?.podium ?? const [],
        rankings: res.data?.allRankings ?? const [],
        yourRank: res.data?.yourRank ?? res.data?.currentUserRank,
        tabs: tabs,
        categories: categories,
        isLoading: false,
        hasLoaded: true,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        hasLoaded: true,
        errorMessage: e.toString(),
      ));
    }
  }

  void selectTab(String tab) {
    if (state.selectedTab == tab) return;
    emit(state.copyWith(selectedTab: tab));
    loadLeaderboard(scope: tab, forceRefresh: true);
  }

  void selectCategory(String category, {String? categoryId}) {
    if (state.selectedCategory == category &&
        state.selectedCategoryId == categoryId) {
      return;
    }
    emit(state.copyWith(
      selectedCategory: category,
      selectedCategoryId: categoryId,
    ));
    loadLeaderboard(
      category: category,
      categoryId: categoryId,
      forceRefresh: true,
    );
  }

  void setChallengeId(String? challengeId) {
    final newTab =
        (challengeId != null && challengeId.isNotEmpty) ? 'Challenge' : state.selectedTab;
    emit(state.copyWith(
      challengeId: challengeId,
      selectedTab: newTab,
    ));
    loadLeaderboard(challengeId: challengeId, forceRefresh: true);
  }

  void updateAuth(AuthCubit authCubit) {
    _authCubit = authCubit;
  }
}
