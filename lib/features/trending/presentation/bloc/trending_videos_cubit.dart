import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:artable_app/core/utils/video_cache_manager.dart';
import 'package:artable_app/features/trending/data/models/trending_videos_response.dart';
import 'package:artable_app/features/trending/data/repositories/videos_repository.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_state.dart';
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
        super(const TrendingVideosState()) {
    _lastSessionToken = authCubit?.sessionToken;
    _authSubscription = authCubit?.stream.listen(_onAuthStateChanged);
  }

  AuthCubit? _authCubit;
  final VideosRepository _videosRepository;
  StreamSubscription<AuthState>? _authSubscription;
  String? _lastSessionToken;
  /// When a forceRefresh arrives while a load is in flight, run it next.
  bool _pendingForceRefresh = false;
  String? _pendingTab;
  String? _pendingCategory;
  String? _pendingCategoryId;

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

  TrendingVideoItem? getVideoById(String videoId) {
    if (state.hero?.id == videoId) {
      return state.hero;
    }
    for (final v in state.videos) {
      if (v.id == videoId) return v;
    }
    return null;
  }

  void _onAuthStateChanged(AuthState authState) {
    final newToken = authState.sessionToken;
    if (newToken != null &&
        newToken.isNotEmpty &&
        newToken != 'design_preview' &&
        _lastSessionToken != newToken) {
      _lastSessionToken = newToken;
      // Home often mounts before the session is ready; refill trending then.
      loadTrendingVideos(forceRefresh: true);
    }
  }

  Future<void> loadTrendingVideos({
    String? tab,
    String? category,
    String? categoryId,
    bool forceRefresh = false,
  }) async {
    if (state.isLoading) {
      // Don't drop forceRefresh from Home/View All while another load runs.
      if (forceRefresh) {
        _pendingForceRefresh = true;
        _pendingTab = tab;
        _pendingCategory = category;
        _pendingCategoryId = categoryId;
      }
      return;
    }
    if (state.hasLoaded &&
        !forceRefresh &&
        tab == null &&
        category == null &&
        state.videos.isNotEmpty) {
      return;
    }

    final targetTab = tab ?? state.selectedTab;
    final isStandardTab = ['Trending', 'Popular', 'Newest'].contains(targetTab);

    final apiTab = isStandardTab ? targetTab.toLowerCase() : 'trending';
    final apiCategory = !isStandardTab ? targetTab : category;
    final apiCategoryId = categoryId;

    // Keep previous hero/videos visible while refreshing (avoids Home flicker).
    emit(state.copyWith(
      isLoading: true,
      selectedTab: targetTab,
      selectedCategory: apiCategory,
      selectedCategoryId: apiCategoryId,
      clearError: true,
    ));

    final token = _authCubit?.sessionToken;
    final refresh = _authCubit?.refreshToken;
    final hasSession = token != null &&
        token.isNotEmpty &&
        token != 'design_preview' &&
        refresh != null &&
        refresh.isNotEmpty &&
        refresh != 'design_preview';

    // Wait for auth instead of caching an empty "loaded" state.
    if (!hasSession) {
      emit(state.copyWith(
        isLoading: false,
        hasLoaded: false,
        clearError: true,
      ));
      _drainPendingRefresh();
      return;
    }

    try {
      final res = await _videosRepository.getTrendingVideos(
        tab: apiTab,
        category: apiCategory,
        categoryId: apiCategoryId,
        sessionToken: token,
        refreshToken: refresh,
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
        clearHero: res.data?.hero == null,
      ));

      // Precache only the hero — full-file downloads of 5 videos starve Home images.
      final heroUrl = res.data?.hero?.playableVideoUrl;
      if (heroUrl != null && heroUrl.isNotEmpty) {
        VideoCacheManager.precacheBatch([heroUrl], maxCount: 1, parallelism: 1);
      }
    } catch (e) {
      final message = e.toString().replaceAll('Exception:', '').trim();
      emit(state.copyWith(
        isLoading: false,
        hasLoaded: true,
        errorMessage: message.isNotEmpty
            ? message
            : 'Failed to load trending videos',
      ));
    }
    _drainPendingRefresh();
  }

  void _drainPendingRefresh() {
    if (!_pendingForceRefresh) return;
    _pendingForceRefresh = false;
    final tab = _pendingTab;
    final category = _pendingCategory;
    final categoryId = _pendingCategoryId;
    _pendingTab = null;
    _pendingCategory = null;
    _pendingCategoryId = null;
    unawaited(
      loadTrendingVideos(
        tab: tab,
        category: category,
        categoryId: categoryId,
        forceRefresh: true,
      ),
    );
  }

  void selectTab(String tab) {
    if (state.selectedTab == tab) return;
    emit(state.copyWith(selectedTab: tab));
    loadTrendingVideos(tab: tab, forceRefresh: true);
  }

  void updateAuth(AuthCubit authCubit) {
    _authCubit = authCubit;
    _authSubscription?.cancel();
    _lastSessionToken = authCubit.sessionToken;
    _authSubscription = authCubit.stream.listen(_onAuthStateChanged);
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
