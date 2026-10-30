import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:artable_app/core/utils/formatters.dart';
import 'package:artable_app/core/utils/media_url_utils.dart';
import 'package:artable_app/features/profile/data/models/my_videos_response.dart';
import 'package:artable_app/features/profile/data/repositories/profile_videos_repository.dart';
import 'package:artable_app/features/studio/data/models/save_studio_draft_response.dart';
import 'package:artable_app/features/studio/data/repositories/studio_repository.dart';
import 'package:artable_app/features/studio/presentation/bloc/studio_cubit.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:artable_app/features/reels/presentation/bloc/reels_cubit.dart';
import 'my_videos_state.dart';

class MyVideosCubit extends Cubit<MyVideosState> {
  MyVideosCubit({
    required AuthCubit authCubit,
    ReelsCubit? reelsCubit,
    StudioCubit? studioCubit,
    ProfileVideosRepository? repository,
    StudioRepository? studioRepository,
  })  : _authCubit = authCubit,
        // ignore: prefer_initializing_formals
        _reelsCubit = reelsCubit,
        _studioCubit = studioCubit,
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
  final StudioCubit? _studioCubit;
  final ProfileVideosRepository _repository;
  final StudioRepository _studioRepository;
  StreamSubscription<AuthState>? _authSubscription;
  String? _lastSessionToken;
  int _loadRequestId = 0;

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
    if (state.hasLoaded && !forceRefresh && tab == null) return;

    final requestId = ++_loadRequestId;
    final token = _authCubit.sessionToken;
    final refresh = _authCubit.refreshToken;
    final sessionToken = (token != null && token != 'design_preview') ? token : null;
    final refreshToken = (refresh != null && refresh != 'design_preview') ? refresh : null;

    emit(state.copyWith(
      isLoading: true,
      activeTab: targetTab,
      clearError: true,
      clearResponse: forceRefresh,
    ));

    debugPrint('====================================================');
    debugPrint('[MY_VIDEOS_CUBIT] Fetching videos - Target Tab: $targetTab');

    try {
      var response = await _repository.getMyVideos(
        tab: targetTab,
        page: 1,
        limit: 50,
        sessionToken: sessionToken,
        refreshToken: refreshToken,
      );
      if (requestId != _loadRequestId) return;

      final isAllTab = targetTab.toUpperCase() == 'ALL';
      final isDraftsTab = targetTab.toUpperCase() == 'DRAFTS' || targetTab.toUpperCase() == 'DRAFT';
      final isSavedTab = targetTab.toUpperCase() == 'SAVED' || targetTab.toUpperCase() == 'SAVED_VIDEOS';
      final isLiveTab = targetTab.toUpperCase() == 'LIVE' || targetTab.toUpperCase() == 'APPROVED';
      final isUnderReviewTab = targetTab.toUpperCase() == 'UNDER_REVIEW' ||
          targetTab.toUpperCase() == 'PENDING' ||
          targetTab.toUpperCase() == 'PENDING_REVIEW';
      final isRejectedTab = targetTab.toUpperCase() == 'REJECTED';

      List<MyVideoItem> items = List<MyVideoItem>.from(response.data);

      if (isLiveTab) {
        items = items.where((v) => v.isVideoLive && !v.isDraft).toList();
        if (items.isEmpty && targetTab.toUpperCase() != 'APPROVED') {
          try {
            final approved = await _repository.getMyVideos(
              tab: 'APPROVED',
              page: 1,
              limit: 50,
              sessionToken: sessionToken,
              refreshToken: refreshToken,
            );
            if (requestId != _loadRequestId) return;
            items = approved.data.where((v) => v.isVideoLive && !v.isDraft).toList();
          } catch (e) {
            debugPrint('[MY_VIDEOS_CUBIT] APPROVED tab fallback failed: $e');
          }
        }
      } else if (isDraftsTab) {
        items = items
            .where((v) => v.isDraft || v.status.toLowerCase().contains('draft') || v.canContinueDraft)
            .toList();
        items = await _mergeStudioDrafts(
          items,
          sessionToken: sessionToken,
          refreshToken: refreshToken,
        );
        if (requestId != _loadRequestId) return;
      } else if (isAllTab) {
        items = await _mergeStudioDrafts(
          items,
          sessionToken: sessionToken,
          refreshToken: refreshToken,
        );
        if (requestId != _loadRequestId) return;
        final liveCount = items.where((v) => v.isVideoLive && !v.isDraft).length;
        if (liveCount == 0) {
          for (final alt in ['LIVE', 'APPROVED']) {
            try {
              final extra = await _repository.getMyVideos(
                tab: alt,
                page: 1,
                limit: 50,
                sessionToken: sessionToken,
                refreshToken: refreshToken,
              );
              if (requestId != _loadRequestId) return;
              final existingIds = items.map((v) => v.id).toSet();
              for (final v in extra.data) {
                if (v.id.isNotEmpty && !existingIds.contains(v.id)) {
                  existingIds.add(v.id);
                  items.add(v);
                }
              }
            } catch (e) {
              debugPrint('[MY_VIDEOS_CUBIT] $alt fallback failed: $e');
            }
          }
        }
      } else if (isUnderReviewTab) {
        items = items.where((v) =>
            v.status.toLowerCase() == 'under_review' ||
            v.status.toLowerCase() == 'pending_review' ||
            v.status.toLowerCase() == 'pending').toList();
      } else if (isRejectedTab) {
        items = items.where((v) => v.status.toLowerCase() == 'rejected').toList();
      }

      final currentReelsCubit = _reelsCubit;
      if (isSavedTab && items.isEmpty && currentReelsCubit != null) {
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
                thumbnailUrl: MediaUrlUtils.extractThumbnail(v) ?? '',
                videoUrl: MediaUrlUtils.resolve(
                  v['videoUrl']?.toString() ?? v['video_url']?.toString() ?? '',
                ),
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
            items = fallbackItems;
          }
        }
      }

      response = MyVideosResponse(
        success: response.success,
        message: response.message,
        data: items,
        tabs: response.tabs,
        activeTab: targetTab,
        emptyState: response.emptyState,
        pagination: response.pagination,
      );

      debugPrint('[MY_VIDEOS_CUBIT] Response Success: ${response.success}');
      debugPrint('[MY_VIDEOS_CUBIT] Active Tab: ${response.activeTab}');
      debugPrint('[MY_VIDEOS_CUBIT] Total Saved/Filtered Videos Count: ${response.data.length}');
      for (var i = 0; i < response.data.length; i++) {
        final item = response.data[i];
        debugPrint('   -> Video #$i: id="${item.id}", title="${item.title}", status="${item.status}"');
      }
      debugPrint('====================================================');

      if (requestId != _loadRequestId) return;
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
      if (requestId != _loadRequestId) return;
      final tabKey = targetTab.toUpperCase();
      if (tabKey == 'ALL' || tabKey == 'DRAFTS' || tabKey == 'DRAFT') {
        try {
          final drafts = await _mergeStudioDrafts(
            const [],
            sessionToken: sessionToken,
            refreshToken: refreshToken,
          );
          if (requestId != _loadRequestId) return;
          if (drafts.isNotEmpty) {
            emit(state.copyWith(
              response: MyVideosResponse(
                success: true,
                message: 'Showing saved drafts',
                data: drafts,
                tabs: const [],
                activeTab: targetTab,
              ),
              activeTab: targetTab,
              isLoading: false,
              hasLoaded: true,
              clearError: true,
            ));
            return;
          }
        } catch (_) {}
      }
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

  void removeVideoOptimistically(String videoId) {
    final updatedList = state.videos.where((v) => v.id != videoId).toList();
    if (state.response != null) {
      emit(state.copyWith(
        response: state.response!.copyWith(
          data: updatedList,
        ),
      ));
    }
  }

  Future<bool> deleteVideo(String videoId) async {
    final token = _authCubit.sessionToken;
    final refresh = _authCubit.refreshToken;

    // Optimistically update state
    removeVideoOptimistically(videoId);

    try {
      await _repository.deleteVideo(
        videoId: videoId,
        sessionToken: (token != null && token != 'design_preview') ? token : null,
        refreshToken: (refresh != null && refresh != 'design_preview') ? refresh : null,
      );
      await loadMyVideos(tab: state.activeTab, forceRefresh: true);
      return true;
    } catch (e) {
      debugPrint('Error executing deleteVideo in MyVideosCubit: $e');
      await loadMyVideos(tab: state.activeTab, forceRefresh: true);
      return false;
    }
  }

  Future<List<MyVideoItem>> _mergeStudioDrafts(
    List<MyVideoItem> current, {
    String? sessionToken,
    String? refreshToken,
  }) async {
    final merged = List<MyVideoItem>.from(current);
    final existingIds = merged.map((v) => v.id).toSet();

    void addDraft(MyVideoItem draft) {
      if (draft.id.isEmpty) return;
      if (existingIds.contains(draft.id)) {
        final index = merged.indexWhere((v) => v.id == draft.id);
        if (index >= 0 && merged[index].thumbnailUrl.isEmpty && draft.thumbnailUrl.isNotEmpty) {
          merged[index] = draft;
        }
        return;
      }
      existingIds.add(draft.id);
      merged.add(draft);
    }

    final localDrafts = _studioCubit?.state.drafts ?? const <Map<String, dynamic>>[];
    for (final draft in localDrafts) {
      addDraft(_draftMapToMyVideo(draft));
    }

    try {
      final studioRes = await _studioRepository.getDraftsList(
        sessionToken: sessionToken,
        refreshToken: refreshToken,
      );
      if (studioRes.success) {
        for (final d in studioRes.data) {
          addDraft(_studioItemToMyVideo(d));
        }
      }
    } catch (e) {
      debugPrint('[MY_VIDEOS_CUBIT] Error merging studio drafts: $e');
    }

    return merged;
  }

  MyVideoItem _studioItemToMyVideo(StudioDraftItem draft) {
    final challengeObj = draft.challengeId != null
        ? {'id': draft.challengeId, 'title': draft.title}
        : null;
    final formattedDate = (draft.createdAt != null && draft.createdAt!.isNotEmpty)
        ? AppFormatters.formatDate(draft.createdAt!)
        : '';
    return MyVideoItem(
      id: draft.id,
      title: draft.title.isNotEmpty ? draft.title : 'Draft Entry',
      description: draft.description,
      thumbnailUrl: draft.thumbnailUrl,
      videoUrl: draft.videoUrl,
      status: 'DRAFT',
      statusLabel: 'DRAFT',
      durationSeconds: draft.durationSeconds,
      viewsLabel: '${draft.views}',
      likesLabel: '${draft.likes}',
      talentScoreLabel: draft.averageRating,
      dateLabel: formattedDate,
      isLive: false,
      canContinueDraft: true,
      challenge: challengeObj,
      filterId: draft.filterId,
      beautyOn: draft.beautyOn,
      beautyIntensity: draft.beautyIntensity,
    );
  }

  MyVideoItem _draftMapToMyVideo(Map<String, dynamic> draft) {
    final challengeId = draft['challengeId']?.toString() ?? '';
    final title = (draft['title']?.toString() ?? '').trim();
    final createdAt = draft['createdAt']?.toString() ?? draft['recordedAt']?.toString() ?? '';
    return MyVideoItem(
      id: draft['id']?.toString() ?? '',
      title: title.isNotEmpty ? title : 'Draft Entry',
      description: draft['description']?.toString(),
      thumbnailUrl: draft['thumbnailUrl']?.toString() ?? draft['imageUrl']?.toString() ?? '',
      videoUrl: draft['videoUrl']?.toString() ?? draft['videoPath']?.toString(),
      status: 'DRAFT',
      statusLabel: 'DRAFT',
      durationSeconds: draft['durationSeconds'] as num?,
      viewsLabel: draft['views']?.toString() ?? '0',
      likesLabel: draft['likes']?.toString() ?? '0',
      talentScoreLabel: draft['averageRating']?.toString() ?? '0.0',
      dateLabel: createdAt.isNotEmpty ? AppFormatters.formatDate(createdAt) : '',
      isLive: false,
      canContinueDraft: true,
      challenge: challengeId.isNotEmpty
          ? {'id': challengeId, 'title': title}
          : (draft['challenge'] is Map
              ? Map<String, dynamic>.from(draft['challenge'] as Map)
              : null),
      filterId: draft['filterId']?.toString(),
      beautyOn: draft['beautyOn'] == true,
      beautyIntensity: (draft['beautyIntensity'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}

