import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:artable_app/core/utils/formatters.dart';
import 'package:artable_app/features/profile/data/models/my_videos_response.dart';
import 'package:artable_app/features/profile/data/repositories/profile_videos_repository.dart';
import 'package:artable_app/features/studio/data/repositories/studio_repository.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:artable_app/features/reels/presentation/bloc/reels_cubit.dart';
import 'my_videos_state.dart';

class MyVideosCubit extends Cubit<MyVideosState> {
  MyVideosCubit({
    required AuthCubit authCubit,
    ReelsCubit? reelsCubit,
    ProfileVideosRepository? repository,
    StudioRepository? studioRepository,
  })  : _authCubit = authCubit,
        // ignore: prefer_initializing_formals
        _reelsCubit = reelsCubit,
        _repository = repository ??
            ProfileVideosRepository(
              onTokensRefreshed: authCubit.applyRefreshedTokens,
              onSessionRefreshFailed: authCubit.handleSessionRefreshFailed,
            ),
        _studioRepository = studioRepository ??
            StudioRepository(
              onTokensRefreshed: authCubit.applyRefreshedTokens,
              onSessionRefreshFailed: authCubit.handleSessionRefreshFailed,
            ),
        super(const MyVideosState()) {
    _authSubscription = _authCubit.stream.listen(_onAuthStateChanged);
  }

  final AuthCubit _authCubit;
  final ReelsCubit? _reelsCubit;
  final ProfileVideosRepository _repository;
  final StudioRepository _studioRepository;
  StreamSubscription<AuthState>? _authSubscription;
  String? _lastSessionToken;

  MyVideosResponse? get response => state.response;
  List<MyVideoItem> get videos => state.videos;
  List<MyVideoTabItem> get tabs => state.tabs;
  String get activeTab => state.activeTab;
  bool get isLoading => state.isLoading;
  bool get hasLoaded => state.hasLoaded;
  String? get errorMessage => state.errorMessage;

  void _onAuthStateChanged(AuthState authState) {
    final newToken = authState.sessionToken;
    if (newToken != null &&
        newToken.isNotEmpty &&
        newToken != 'design_preview' &&
        _lastSessionToken != newToken) {
      _lastSessionToken = newToken;
      emit(state.copyWith(hasLoaded: false));
      loadMyVideos(forceRefresh: true);
    }
  }

  Future<void> loadMyVideos({
    String? tab,
    bool forceRefresh = false,
  }) async {
    final targetTab = tab ?? state.activeTab;
    if (state.isLoading) return;
    if (state.hasLoaded && !forceRefresh && tab == null) return;

    final token = _authCubit.sessionToken;
    final refresh = _authCubit.refreshToken;

    emit(state.copyWith(
      isLoading: true,
      activeTab: targetTab,
      clearError: true,
    ));

    debugPrint('====================================================');
    debugPrint('[MY_VIDEOS_CUBIT] Fetching videos - Target Tab: $targetTab');

    try {
      var response = await _repository.getMyVideos(
        tab: targetTab,
        page: 1,
        limit: 20,
        sessionToken: (token != null && token != 'design_preview') ? token : null,
        refreshToken: (refresh != null && refresh != 'design_preview') ? refresh : null,
      );

      final isDraftsTab = targetTab.toUpperCase() == 'DRAFTS' || targetTab.toUpperCase() == 'DRAFT';
      final isSavedTab = targetTab.toUpperCase() == 'SAVED' || targetTab.toUpperCase() == 'SAVED_VIDEOS';

      if (isDraftsTab && response.data.isEmpty) {
        try {
          final studioRes = await _studioRepository.getDraftsList(
            sessionToken: (token != null && token != 'design_preview') ? token : null,
            refreshToken: (refresh != null && refresh != 'design_preview') ? refresh : null,
          );

          if (studioRes.success && studioRes.data.isNotEmpty) {
            final draftItems = studioRes.data.map((d) {
              final challengeObj = d.challengeId != null
                  ? {'id': d.challengeId, 'title': d.title}
                  : null;
              final formattedDate = (d.createdAt != null && d.createdAt!.isNotEmpty)
                  ? AppFormatters.formatDate(d.createdAt!)
                  : '';
              return MyVideoItem(
                id: d.id,
                title: d.title.isNotEmpty ? d.title : 'Draft Entry',
                description: d.description,
                thumbnailUrl: d.thumbnailUrl,
                videoUrl: d.videoUrl,
                status: 'DRAFT',
                statusLabel: 'DRAFT',
                durationSeconds: d.durationSeconds,
                viewsLabel: '${d.views}',
                likesLabel: '${d.likes}',
                talentScoreLabel: d.averageRating,
                dateLabel: formattedDate,
                isLive: false,
                canContinueDraft: true,
                challenge: challengeObj,
              );
            }).toList();

            response = MyVideosResponse(
              success: true,
              message: 'Loaded drafts',
              data: draftItems,
              tabs: response.tabs,
              activeTab: targetTab,
              emptyState: response.emptyState,
              pagination: response.pagination,
            );
          }
        } catch (e) {
          debugPrint('[MY_VIDEOS_CUBIT] Error fetching studio drafts fallback: $e');
        }
      }

      final currentReelsCubit = _reelsCubit;
      if (isSavedTab && response.data.isEmpty && currentReelsCubit != null) {
        final bookmarkedIds = currentReelsCubit.state.bookmarkedVideoIds;
        if (bookmarkedIds.isNotEmpty) {
          final fallbackItems = <MyVideoItem>[];
          for (final v in currentReelsCubit.state.videos) {
            final vId = v['id']?.toString() ?? v['_id']?.toString() ?? '';
            if (vId.isNotEmpty && bookmarkedIds.contains(vId)) {
              fallbackItems.add(MyVideoItem(
                id: vId,
                title: v['title']?.toString() ?? 'Saved Video',
                description: v['description']?.toString(),
                thumbnailUrl: v['thumbnailUrl']?.toString() ??
                    v['thumbnail']?.toString() ??
                    '',
                videoUrl: v['videoUrl']?.toString() ?? v['video_url']?.toString(),
                status: 'SAVED',
                statusLabel: 'SAVED',
                viewsLabel: v['views']?.toString() ?? '0',
                likesLabel: v['likes']?.toString() ?? '0',
                talentScoreLabel: v['score']?.toString() ?? v['talentScore']?.toString() ?? '0.0',
                dateLabel: v['date']?.toString() ?? '',
                isLive: true,
              ));
            }
          }

          if (fallbackItems.isNotEmpty) {
            response = MyVideosResponse(
              success: true,
              message: 'Loaded local saved videos',
              data: fallbackItems,
              tabs: response.tabs,
              activeTab: targetTab,
              emptyState: response.emptyState,
              pagination: response.pagination,
            );
          }
        }
      }

      debugPrint('[MY_VIDEOS_CUBIT] Response Success: ${response.success}');
      debugPrint('[MY_VIDEOS_CUBIT] Active Tab: ${response.activeTab}');
      debugPrint('[MY_VIDEOS_CUBIT] Total Saved/Filtered Videos Count: ${response.data.length}');
      for (var i = 0; i < response.data.length; i++) {
        final item = response.data[i];
        debugPrint('   -> Video #$i: id="${item.id}", title="${item.title}", status="${item.status}"');
      }
      debugPrint('====================================================');

      emit(state.copyWith(
        response: response,
        activeTab: response.activeTab.isNotEmpty ? response.activeTab : targetTab,
        isLoading: false,
        hasLoaded: true,
        clearError: true,
      ));
    } catch (e) {
      debugPrint('[MY_VIDEOS_CUBIT] Error fetching videos: $e');
      debugPrint('====================================================');
      emit(state.copyWith(
        isLoading: false,
        hasLoaded: true,
        errorMessage: e.toString(),
      ));
    }
  }

  void selectTab(String tabKey) {
    if (tabKey == state.activeTab && state.hasLoaded) return;
    loadMyVideos(tab: tabKey, forceRefresh: true);
  }

  Future<bool> deleteVideo(String videoId) async {
    final token = _authCubit.sessionToken;
    final refresh = _authCubit.refreshToken;

    // Optimistically update state
    final updatedList = state.videos.where((v) => v.id != videoId).toList();
    emit(state.copyWith(
      response: state.response != null
          ? MyVideosResponse(
              success: state.response!.success,
              message: state.response!.message,
              data: updatedList,
              tabs: state.response!.tabs,
              activeTab: state.response!.activeTab,
              emptyState: state.response!.emptyState,
              pagination: state.response!.pagination,
            )
          : null,
    ));

    try {
      await _repository.deleteVideo(
        videoId: videoId,
        sessionToken: (token != null && token != 'design_preview') ? token : null,
        refreshToken: (refresh != null && refresh != 'design_preview') ? refresh : null,
      );
      return true;
    } catch (e) {
      debugPrint('Error executing deleteVideo in MyVideosCubit: $e');
      return true;
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}

