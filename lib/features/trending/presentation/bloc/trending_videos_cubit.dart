import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:artable_app/features/trending/data/models/trending_videos_response.dart';
import 'package:artable_app/features/trending/data/repositories/videos_repository.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'trending_videos_state.dart';

class TrendingVideosCubit extends Cubit<TrendingVideosState> {
  TrendingVideosCubit({
    AuthCubit? authCubit,
    VideosRepository? videosRepository,
  })  : _authCubit = authCubit,
        _videosRepository = videosRepository ??
            VideosRepository(
              onTokensRefreshed: authCubit?.applyRefreshedTokens,
              onSessionRefreshFailed: authCubit?.handleSessionRefreshFailed,
            ),
        super(const TrendingVideosState());

  AuthCubit? _authCubit;
  final VideosRepository _videosRepository;

  String get selectedTab => state.selectedTab;
  String? get selectedCategory => state.selectedCategory;
  String? get selectedCategoryId => state.selectedCategoryId;
  bool get isLoading => state.isLoading;
  bool get hasLoaded => state.hasLoaded;
  String? get errorMessage => state.errorMessage;
  TrendingVideosResponse? get response => state.response;
  TrendingVideoItem? get hero => state.hero;
  List<TrendingVideoItem> get videos => state.videos;
  List<String> get availableTabs => state.availableTabs;
  List<TrendingCategoryItem> get categories => state.categories;
  List<Map<String, dynamic>> get heroAsUiMap => state.heroAsUiMap;
  List<Map<String, dynamic>> get gridVideosAsUiMaps => state.gridVideosAsUiMaps;

  Future<void> loadTrendingVideos({
    String? tab,
    String? category,
    String? categoryId,
    bool forceRefresh = false,
  }) async {
    if (state.isLoading) return;
    if (state.hasLoaded && !forceRefresh && tab == null && category == null) {
      return;
    }

    final targetTab = tab ?? state.selectedTab;
    final isStandardTab = ['Trending', 'Popular', 'Newest'].contains(targetTab);

    final apiTab = isStandardTab ? targetTab.toLowerCase() : 'trending';
    final apiCategory = !isStandardTab ? targetTab : category;
    final apiCategoryId = categoryId;

    emit(state.copyWith(
      isLoading: true,
      selectedTab: targetTab,
      selectedCategory: apiCategory,
      selectedCategoryId: apiCategoryId,
      clearError: true,
    ));

    final token = _authCubit?.sessionToken;
    final refresh = _authCubit?.refreshToken;

    try {
      final res = await _videosRepository.getTrendingVideos(
        tab: apiTab,
        category: apiCategory,
        categoryId: apiCategoryId,
        sessionToken: token != 'design_preview' ? token : null,
        refreshToken: refresh != 'design_preview' ? refresh : null,
      );

      List<String> tabs = state.tabs;
      List<TrendingCategoryItem> categories = state.categories;

      if (res.data != null) {
        if (res.data!.tabs.isNotEmpty) {
          tabs = res.data!.tabs;
        }
        categories = res.data!.categories;
      }

      emit(state.copyWith(
        response: res,
        hero: res.data?.hero,
        videos: res.data?.gridVideos ?? const [],
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
    loadTrendingVideos(tab: tab, forceRefresh: true);
  }

  void updateAuth(AuthCubit authCubit) {
    _authCubit = authCubit;
  }
}
