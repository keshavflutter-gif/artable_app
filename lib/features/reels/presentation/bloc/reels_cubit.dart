import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:artable_app/core/network/api_exception.dart';
import 'package:artable_app/core/utils/comment_permissions.dart';
import 'package:artable_app/core/utils/reel_helpers.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:artable_app/features/trending/data/models/trending_videos_response.dart';
import 'package:artable_app/features/trending/data/repositories/videos_repository.dart';
import 'reels_state.dart';

class ReelsCubit extends Cubit<ReelsState> {
  ReelsCubit({
    AuthCubit? authCubit,
    VideosRepository? videosRepository,
  })  : _authCubit = authCubit,
        _videosRepository = videosRepository ??
            VideosRepository(
              onTokensRefreshed: authCubit?.applyRefreshedTokens,
              onSessionRefreshFailed: authCubit?.handleSessionRefreshFailed,
            ),
        super(ReelsState());

  AuthCubit? _authCubit;
  final VideosRepository _videosRepository;

  void updateAuth(AuthCubit authCubit) {
    _authCubit = authCubit;
  }

  String get currentUserId => (_authCubit?.userId?.isNotEmpty == true)
      ? _authCubit!.userId!
      : 'default_user';

  List<Map<String, dynamic>> get videos => state.videos;
  bool isLiked(String videoId, {Map<String, dynamic>? fallbackVideo}) =>
      state.isLiked(videoId, currentUserId, fallbackVideo);
  bool isDisliked(String videoId) => state.isDisliked(videoId, currentUserId);
  String? getReaction(String videoId) => state.getReaction(videoId, currentUserId);

  bool isBookmarked(String videoId) => state.isBookmarked(videoId);
  double? getUserRating(String videoId) => state.getUserRating(videoId);
  List<Map<String, dynamic>> getComments(String videoId) =>
      state.getComments(videoId);
  int getCommentsCount(String videoId, [int fallback = 0]) =>
      state.getCommentsCount(videoId, fallback);
  Map<String, dynamic>? getVideo(String videoId) {
    final cleanId = videoId.trim();
    final matches = state.videos.where((v) =>
        (v['id']?.toString() ?? v['_id']?.toString() ?? '') == cleanId);
    if (matches.isNotEmpty) return matches.first;
    return null;
  }

  void syncVideos(List<Map<String, dynamic>> newVideos) {
    if (newVideos.isEmpty) return;
    final currentVideos = List<Map<String, dynamic>>.from(
      state.videos.map((v) => Map<String, dynamic>.from(v)),
    );
    final bookmarked = Set<String>.from(state.bookmarkedVideoIds);
    bool changed = false;
    bool bookmarkChanged = false;

    for (final nv in newVideos) {
      final nid = nv['id']?.toString() ?? nv['_id']?.toString() ?? '';
      if (nid.isEmpty) continue;

      final statusStr = nv['status']?.toString().toLowerCase().trim();
      final isDraftVal = nv['canContinueDraft'] == true ||
          nv['isDraft'] == true ||
          nv['draft'] == true ||
          nv['type']?.toString().toLowerCase() == 'draft' ||
          (statusStr != null && (statusStr == 'draft' || statusStr.contains('draft'))) ||
          (nv['statusLabel']?.toString().toLowerCase().contains('draft') ?? false);

      final isNonLive = isDraftVal ||
          statusStr == 'rejected' ||
          statusStr == 'deleted' ||
          statusStr == 'inactive' ||
          statusStr == 'under_review' ||
          statusStr == 'pending_review' ||
          statusStr == 'archived';

      if (isNonLive) {
        final existingIdx = currentVideos.indexWhere((v) =>
            (v['id']?.toString() ?? v['_id']?.toString() ?? '') == nid);
        if (existingIdx != -1) {
          currentVideos.removeAt(existingIdx);
          changed = true;
        }
        continue;
      }

      final isSavedVal = nv['isSaved'] == true ||
          nv['saved'] == true ||
          nv['isBookmarked'] == true;
      if (isSavedVal && !bookmarked.contains(nid)) {
        bookmarked.add(nid);
        bookmarkChanged = true;
      }

      final idx = currentVideos.indexWhere((v) =>
          (v['id']?.toString() ?? v['_id']?.toString() ?? '') == nid);
      if (idx == -1) {
        // Newest uploads first so post-submit playback finds them quickly.
        currentVideos.insert(0, Map<String, dynamic>.from(nv));
        changed = true;
        final musicUrl = nv['musicUrl']?.toString() ?? nv['music_url']?.toString();
        if (musicUrl != null && musicUrl.trim().isNotEmpty) {
          ReelHelpers.cacheMusic(
            nid,
            ReelMusicMeta(
              url: musicUrl.trim(),
              name: nv['musicName']?.toString() ?? nv['music']?.toString() ?? '',
              startSeconds:
                  (nv['musicStartSeconds'] as num?)?.toDouble() ?? 0,
              durationSeconds:
                  (nv['musicCropDuration'] as num?)?.toDouble() ?? 0,
            ),
          );
        }
      } else {
        final existing = currentVideos[idx];
        bool isBlank(dynamic v) {
          final s = v?.toString().trim() ?? '';
          return s.isEmpty || s == 'null';
        }
        bool looksPlayable(dynamic v) {
          if (isBlank(v)) return false;
          final s = v.toString();
          final lower = s.toLowerCase().split('?').first;
          if (lower.endsWith('.jpg') ||
              lower.endsWith('.jpeg') ||
              lower.endsWith('.png') ||
              lower.endsWith('.webp') ||
              lower.endsWith('.gif') ||
              lower.endsWith('.bmp')) {
            return false;
          }
          return true;
        }

        void fillIfMissing(String key) {
          if (!isBlank(nv[key]) && isBlank(existing[key])) {
            existing[key] = nv[key];
            changed = true;
          }
        }

        void preferBetter(String key, {bool overwrite = false}) {
          if (isBlank(nv[key])) return;
          if (isBlank(existing[key]) || existing[key] != nv[key]) {
            // Always take a playable video URL when existing is blank/image.
            if (key == 'videoUrl' || key == 'videoPath') {
              if (looksPlayable(nv[key]) &&
                  (overwrite ||
                      isBlank(existing[key]) ||
                      !looksPlayable(existing[key]))) {
                existing[key] = nv[key];
                changed = true;
              }
              return;
            }
            if (overwrite || isBlank(existing[key])) {
              existing[key] = nv[key];
              changed = true;
            }
          }
        }

        // Media fields were previously never updated on existing entries, so
        // profile → Full Reel kept a stub without videoUrl → Tap to reload.
        preferBetter('videoUrl', overwrite: true);
        preferBetter('videoPath', overwrite: true);
        // Always take latest music from upload/API — old draft song must not stick.
        preferBetter('musicUrl', overwrite: true);
        preferBetter('musicName', overwrite: true);
        preferBetter('musicStartSeconds', overwrite: true);
        preferBetter('musicCropDuration', overwrite: true);
        final syncedMusicUrl =
            existing['musicUrl']?.toString() ?? existing['music_url']?.toString();
        if (syncedMusicUrl != null && syncedMusicUrl.trim().isNotEmpty) {
          ReelHelpers.cacheMusic(
            nid,
            ReelMusicMeta(
              url: syncedMusicUrl.trim(),
              name: existing['musicName']?.toString() ??
                  existing['music']?.toString() ??
                  '',
              startSeconds:
                  (existing['musicStartSeconds'] as num?)?.toDouble() ?? 0,
              durationSeconds:
                  (existing['musicCropDuration'] as num?)?.toDouble() ?? 0,
            ),
          );
        }
        preferBetter('imageUrl');
        preferBetter('thumbnailUrl');
        preferBetter('description');
        preferBetter('caption');
        preferBetter('title');
        if (nv['mergedClipPaths'] is List &&
            (nv['mergedClipPaths'] as List).isNotEmpty &&
            (existing['mergedClipPaths'] == null ||
                existing['mergedClipPaths'] is! List ||
                (existing['mergedClipPaths'] as List).isEmpty)) {
          existing['mergedClipPaths'] =
              List<String>.from((nv['mergedClipPaths'] as List).map((e) => e.toString()));
          changed = true;
        }
        fillIfMissing('filterId');
        if (nv.containsKey('beautyOn')) {
          existing['beautyOn'] = nv['beautyOn'];
          changed = true;
        }
        if (nv.containsKey('beautyIntensity')) {
          existing['beautyIntensity'] = nv['beautyIntensity'];
          changed = true;
        }
        if (nv.containsKey('status') && !isBlank(nv['status'])) {
          existing['status'] = nv['status'];
          changed = true;
        }
        if (nv.containsKey('isLive')) {
          existing['isLive'] = nv['isLive'];
          existing['is_live'] = nv['isLive'];
          changed = true;
        }

        if (existing['isLiked'] != nv['isLiked'] || existing['liked'] != nv['liked']) {
          existing['isLiked'] = nv['isLiked'] ?? nv['liked'];
          existing['liked'] = nv['liked'] ?? nv['isLiked'];
          changed = true;
        }
        // Prefer the higher engagement totals so sparse API payloads don't wipe UI.
        void mergeEngagement(String labelKey, String countKey) {
          final a = TrendingVideoItem.parseCount(
            existing[countKey] ?? existing[labelKey],
          );
          final b = TrendingVideoItem.parseCount(nv[countKey] ?? nv[labelKey]);
          final best = a > b ? a : b;
          final formatted = TrendingVideoItem.formatCount(best);
          if (existing[countKey] != best || existing[labelKey]?.toString() != formatted) {
            existing[countKey] = best;
            existing[labelKey] = formatted;
            changed = true;
          }
        }
        mergeEngagement('views', 'viewsCount');
        mergeEngagement('likes', 'likesCount');
        mergeEngagement('comments', 'commentsCount');
        mergeEngagement('shares', 'sharesCount');
        mergeEngagement('saves', 'savesCount');
        if (nv.containsKey('saves') || nv.containsKey('savesCount') || nv.containsKey('isSaved')) {
          if (nv.containsKey('isSaved')) {
            existing['isSaved'] = nv['isSaved'];
            existing['saved'] = nv['isSaved'];
            existing['isBookmarked'] = nv['isSaved'];
          }
          changed = true;
        }
        if (nv['handle'] != null && nv['handle'] != '@user' && (existing['handle'] == null || existing['handle'] == '@user')) {
          existing['handle'] = nv['handle'];
          changed = true;
        }
        if (nv['username'] != null && (nv['username'] as String).isNotEmpty && (existing['username'] == null || (existing['username'] as String).isEmpty)) {
          existing['username'] = nv['username'];
          changed = true;
        }
        if (nv['creator'] != null && nv['creator'] != 'You' && (existing['creator'] == null || existing['creator'] == 'You')) {
          existing['creator'] = nv['creator'];
          changed = true;
        }
        if (nv['user'] != null && existing['user'] == null) {
          existing['user'] = nv['user'];
          changed = true;
        }
        if (nv['avatarUrl'] != null && (nv['avatarUrl'] as String).isNotEmpty && (existing['avatarUrl'] == null || (existing['avatarUrl'] as String).isEmpty)) {
          existing['avatarUrl'] = nv['avatarUrl'];
          changed = true;
        }
      }
    }

    if (changed || bookmarkChanged) {
      emit(state.copyWith(
        videos: currentVideos,
        bookmarkedVideoIds: bookmarked,
      ));
    }
  }

  final Set<String> _pendingLikeCalls = {};
  final Set<String> _pendingCommentLikeCalls = {};

  static const int _commentsPageSize = 20;
  final Map<String, int> _commentsPage = {};
  final Map<String, bool> _commentsHasMore = {};
  final Set<String> _commentsLoading = {};
  final Map<String, int> _commentsFetchGen = {};
  final Map<String, int> _repliesPage = {};
  final Map<String, bool> _repliesHasMore = {};
  final Set<String> _repliesLoading = {};

  bool hasMoreComments(String videoId) =>
      _commentsHasMore[videoId.trim()] == true;
  bool isLoadingComments(String videoId) =>
      _commentsLoading.contains(videoId.trim());
  bool hasMoreReplies(String parentCommentId) =>
      _repliesHasMore[parentCommentId.trim()] == true;
  bool isLoadingReplies(String parentCommentId) =>
      _repliesLoading.contains(parentCommentId.trim());

  int _parsePaginationTotal(Map<String, dynamic> res, int fallback) {
    final pagination = res['pagination'];
    if (pagination is Map) {
      final total = pagination['total'] ?? pagination['totalCount'];
      if (total is int) return total;
      final parsed = int.tryParse(total?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  bool _parsePaginationHasMore(
    Map<String, dynamic> res, {
    required int page,
    required int fetchedCount,
    required int pageSize,
  }) {
    final pagination = res['pagination'];
    if (pagination is Map) {
      if (pagination['hasMore'] == true || pagination['has_more'] == true) {
        return true;
      }
      if (pagination['hasMore'] == false || pagination['has_more'] == false) {
        return false;
      }
      final totalPages = pagination['totalPages'] ?? pagination['total_pages'];
      final pages = totalPages is int
          ? totalPages
          : int.tryParse(totalPages?.toString() ?? '');
      if (pages != null) return page < pages;
      final total = pagination['total'] ?? pagination['totalCount'];
      final totalInt =
          total is int ? total : int.tryParse(total?.toString() ?? '');
      if (totalInt != null) return page * pageSize < totalInt;
    }
    return fetchedCount >= pageSize;
  }

  Future<void> toggleLike(String videoId, {Map<String, dynamic>? fallbackVideo}) async {
    final vId = videoId.trim();
    if (vId.isEmpty) return;

    if (_pendingLikeCalls.contains(vId)) return;
    _pendingLikeCalls.add(vId);

    final uid = currentUserId;
    final prevReaction = state.getReaction(vId, uid);
    final bool wasLiked = isLiked(vId, fallbackVideo: fallbackVideo);
    final isLiking = !wasLiked;

    Map<String, dynamic>? prevVideoSnapshot;
    int prevLikesCount = 0;

    try {
      final userMap = Map<String, Map<String, String>>.from(
        state.userReactions.map((k, v) => MapEntry(k, Map<String, String>.from(v))),
      );
      final currentUserReactions = Map<String, String>.from(userMap[uid] ?? {});
      if (isLiking) {
        currentUserReactions[vId] = 'like';
      } else {
        currentUserReactions.remove(vId);
      }
      userMap[uid] = currentUserReactions;

      final videos = List<Map<String, dynamic>>.from(
        state.videos.map((v) => Map<String, dynamic>.from(v)),
      );

      int idx = videos.indexWhere(
        (v) => (v['id']?.toString() ?? v['_id']?.toString()) == vId,
      );
      if (idx == -1 && fallbackVideo != null) {
        videos.add(Map<String, dynamic>.from(fallbackVideo));
        idx = videos.length - 1;
      }

      int newLikes = 0;
      if (idx != -1) {
        final v = videos[idx];
        prevVideoSnapshot = Map<String, dynamic>.from(v);
        prevLikesCount =
            TrendingVideoItem.parseCount(v['likesCount'] ?? v['likes']);
        newLikes =
            (prevLikesCount + (isLiking ? 1 : -1)).clamp(0, 9999999);

        v['likesCount'] = newLikes;
        v['likes'] = TrendingVideoItem.formatCount(newLikes);
        v['likesLabel'] = TrendingVideoItem.formatCount(newLikes);
        v['isLiked'] = isLiking;
        v['liked'] = isLiking;
      }

      emit(state.copyWith(
        userReactions: userMap,
        videos: videos,
      ));

      final token = _authCubit?.sessionToken;
      final refresh = _authCubit?.refreshToken;
      if (token == null || token.isEmpty || token == 'design_preview') {
        return;
      }

      final res = await _videosRepository.likeVideo(
        videoId: vId,
        isLiked: isLiking,
        sessionToken: token,
        refreshToken: refresh != 'design_preview' ? refresh : null,
      );

      if (res['success'] == false) {
        _rollbackVideoLike(
          videoId: vId,
          uid: uid,
          prevReaction: prevReaction,
          prevVideoSnapshot: prevVideoSnapshot,
        );
        return;
      }

      if (res['data'] is Map) {
        final data = Map<String, dynamic>.from(res['data'] as Map);
        final serverLiked = data.containsKey('isLiked')
            ? data['isLiked'] == true
            : (data.containsKey('liked') ? data['liked'] == true : isLiking);
        final rawLikes =
            data['likeCount'] ?? data['likes'] ?? data['likesCount'];
        final serverLikes = rawLikes == null
            ? null
            : TrendingVideoItem.parseCount(rawLikes);

        final updatedUserMap = Map<String, Map<String, String>>.from(
          state.userReactions
              .map((k, v) => MapEntry(k, Map<String, String>.from(v))),
        );
        final reactions =
            Map<String, String>.from(updatedUserMap[uid] ?? {});
        if (serverLiked) {
          reactions[vId] = 'like';
        } else {
          reactions.remove(vId);
        }
        updatedUserMap[uid] = reactions;

        final updatedVideos = List<Map<String, dynamic>>.from(
          state.videos.map((v) => Map<String, dynamic>.from(v)),
        );
        for (final v in updatedVideos) {
          final id = v['id']?.toString() ?? v['_id']?.toString() ?? '';
          if (id == vId) {
            v['isLiked'] = serverLiked;
            v['liked'] = serverLiked;
            if (serverLikes != null) {
              final formatted = TrendingVideoItem.formatCount(serverLikes);
              v['likesCount'] = serverLikes;
              v['likes'] = formatted;
              v['likesLabel'] = formatted;
            }
            break;
          }
        }
        emit(state.copyWith(
          userReactions: updatedUserMap,
          videos: updatedVideos,
        ));
      }
    } catch (e) {
      debugPrint('toggleLike error: $e');
      _rollbackVideoLike(
        videoId: vId,
        uid: uid,
        prevReaction: prevReaction,
        prevVideoSnapshot: prevVideoSnapshot,
      );
    } finally {
      _pendingLikeCalls.remove(vId);
    }
  }

  void _rollbackVideoLike({
    required String videoId,
    required String uid,
    required String? prevReaction,
    required Map<String, dynamic>? prevVideoSnapshot,
  }) {
    final userMap = Map<String, Map<String, String>>.from(
      state.userReactions.map((k, v) => MapEntry(k, Map<String, String>.from(v))),
    );
    final reactions = Map<String, String>.from(userMap[uid] ?? {});
    if (prevReaction == null || prevReaction.isEmpty) {
      reactions.remove(videoId);
    } else {
      reactions[videoId] = prevReaction;
    }
    userMap[uid] = reactions;

    final videos = List<Map<String, dynamic>>.from(
      state.videos.map((v) => Map<String, dynamic>.from(v)),
    );
    if (prevVideoSnapshot != null) {
      final idx = videos.indexWhere(
        (v) =>
            (v['id']?.toString() ?? v['_id']?.toString() ?? '') == videoId,
      );
      if (idx >= 0) {
        videos[idx] = Map<String, dynamic>.from(prevVideoSnapshot);
      }
    }
    emit(state.copyWith(userReactions: userMap, videos: videos));
  }

  Future<void> toggleDislike(String videoId, {Map<String, dynamic>? fallbackVideo}) async {
    final vId = videoId.trim();
    if (vId.isEmpty) return;

    if (_pendingLikeCalls.contains(vId)) return;
    _pendingLikeCalls.add(vId);

    try {
      final uid = currentUserId;
      final userMap = Map<String, Map<String, String>>.from(
        state.userReactions.map((k, v) => MapEntry(k, Map<String, String>.from(v))),
      );

      final currentUserReactions = Map<String, String>.from(userMap[uid] ?? {});
      final currentReaction = currentUserReactions[vId];

      int likesDelta = 0;
      int dislikesDelta = 0;

      if (currentReaction == 'dislike') {
        currentUserReactions.remove(vId);
        dislikesDelta = -1;
      } else if (currentReaction == 'like') {
        currentUserReactions[vId] = 'dislike';
        likesDelta = -1;
        dislikesDelta = 1;
      } else {
        currentUserReactions[vId] = 'dislike';
        dislikesDelta = 1;
      }

      userMap[uid] = currentUserReactions;

      final videos = List<Map<String, dynamic>>.from(
        state.videos.map((v) => Map<String, dynamic>.from(v)),
      );

      int idx = videos.indexWhere((v) => v['id'] == vId);
      if (idx == -1 && fallbackVideo != null) {
        videos.add(Map<String, dynamic>.from(fallbackVideo));
        idx = videos.length - 1;
      }

      if (idx != -1) {
        final v = videos[idx];
        final currentLikes = TrendingVideoItem.parseCount(v['likesCount'] ?? v['likes']);
        final currentDislikes = TrendingVideoItem.parseCount(v['dislikesCount'] ?? v['dislikes']);

        final newLikes = (currentLikes + likesDelta).clamp(0, 9999999);
        final newDislikes = (currentDislikes + dislikesDelta).clamp(0, 9999999);

        v['likesCount'] = newLikes;
        v['likes'] = TrendingVideoItem.formatCount(newLikes);
        v['dislikesCount'] = newDislikes;
        v['dislikes'] = newDislikes;
      }

      emit(state.copyWith(
        userReactions: userMap,
        videos: videos,
      ));
    } catch (_) {
      // Keep optimistic UI state
    } finally {
      _pendingLikeCalls.remove(vId);
    }
  }

  Future<void> toggleBookmark(String videoId) async {
    final vId = videoId.trim();
    if (vId.isEmpty) return;

    final bookmarked = Set<String>.from(state.bookmarkedVideoIds);
    final isNowBookmarked = !bookmarked.contains(vId);
    if (isNowBookmarked) {
      bookmarked.add(vId);
    } else {
      bookmarked.remove(vId);
    }

    final videos = List<Map<String, dynamic>>.from(
      state.videos.map((v) => Map<String, dynamic>.from(v)),
    );
    for (final v in videos) {
      final curId = v['id']?.toString() ?? v['_id']?.toString() ?? '';
      if (curId == vId) {
        final int currentSaves = TrendingVideoItem.parseCount(
          v['savesCount'] ?? v['saveCount'] ?? v['saves'],
        );
        final int newSaves = isNowBookmarked
            ? currentSaves + 1
            : (currentSaves > 0 ? currentSaves - 1 : 0);
        v['saves'] = TrendingVideoItem.formatCount(newSaves);
        v['savesCount'] = newSaves;
        v['saveCount'] = newSaves;
        v['isSaved'] = isNowBookmarked;
        v['saved'] = isNowBookmarked;
        v['isBookmarked'] = isNowBookmarked;
        break;
      }
    }

    emit(state.copyWith(bookmarkedVideoIds: bookmarked, videos: videos));

    try {
      final token = _authCubit?.sessionToken;
      final refresh = _authCubit?.refreshToken;
      final res = await _videosRepository.saveVideo(
        videoId: vId,
        sessionToken: (token != null && token != 'design_preview') ? token : null,
        refreshToken: (refresh != null && refresh != 'design_preview') ? refresh : null,
      );

      final data = res['data'];
      if (data is Map<String, dynamic>) {
        final updatedVideos = List<Map<String, dynamic>>.from(
          state.videos.map((v) => Map<String, dynamic>.from(v)),
        );
        for (final v in updatedVideos) {
          final curId = v['id']?.toString() ?? v['_id']?.toString() ?? '';
          if (curId == vId) {
            if (data.containsKey('saves')) {
              final sCount = TrendingVideoItem.parseCount(data['saves']);
              v['saves'] = TrendingVideoItem.formatCount(sCount);
              v['savesCount'] = sCount;
              v['saveCount'] = sCount;
            } else if (data.containsKey('savesCount')) {
              final sCount = TrendingVideoItem.parseCount(data['savesCount']);
              v['saves'] = TrendingVideoItem.formatCount(sCount);
              v['savesCount'] = sCount;
              v['saveCount'] = sCount;
            }
            if (data.containsKey('isSaved')) {
              final isS = data['isSaved'] == true ||
                  data['isSaved']?.toString().toLowerCase() == 'true';
              v['isSaved'] = isS;
              v['saved'] = isS;
              v['isBookmarked'] = isS;
            }
            break;
          }
        }
        emit(state.copyWith(videos: updatedVideos));
      }
    } catch (e) {
      debugPrint('saveVideo API error: $e');
    }
  }

  Future<Map<String, dynamic>> recordShare(
    String videoId, {
    Map<String, dynamic>? fallbackVideo,
  }) async {
    final vId = videoId.trim();
    if (vId.isEmpty) return {'success': false};

    final videos = List<Map<String, dynamic>>.from(
      state.videos.map((v) => Map<String, dynamic>.from(v)),
    );
    var idx = videos.indexWhere((v) {
      final curId = v['id']?.toString() ?? v['_id']?.toString() ?? '';
      return curId == vId;
    });
    if (idx == -1 && fallbackVideo != null) {
      videos.add(Map<String, dynamic>.from(fallbackVideo));
      idx = videos.length - 1;
    }
    if (idx != -1) {
      final v = videos[idx];
      final int currentShares = TrendingVideoItem.parseCount(
        v['sharesCount'] ?? v['shareCount'] ?? v['shares'],
      );
      final int newShares = currentShares + 1;
      v['shares'] = TrendingVideoItem.formatCount(newShares);
      v['sharesCount'] = newShares;
      v['shareCount'] = newShares;
    }
    emit(state.copyWith(videos: videos));

    try {
      final token = _authCubit?.sessionToken;
      final refresh = _authCubit?.refreshToken;
      final res = await _videosRepository.shareVideo(
        videoId: vId,
        sessionToken: (token != null && token != 'design_preview') ? token : null,
        refreshToken: (refresh != null && refresh != 'design_preview') ? refresh : null,
      );
      debugPrint('Share Video API response: $res');

      final data = res['data'];
      if (data is Map<String, dynamic>) {
        final updatedVideos = List<Map<String, dynamic>>.from(
          state.videos.map((v) => Map<String, dynamic>.from(v)),
        );
        var uIdx = updatedVideos.indexWhere((v) {
          final curId = v['id']?.toString() ?? v['_id']?.toString() ?? '';
          return curId == vId || curId == data['id']?.toString();
        });
        if (uIdx == -1) {
          updatedVideos.add({
            ...?fallbackVideo,
            ...data,
            'id': data['id'] ?? vId,
          });
          uIdx = updatedVideos.length - 1;
        }
        final v = updatedVideos[uIdx];
        v['id'] = data['id'] ?? v['id'] ?? vId;
        final apiUrl = data['videoUrl']?.toString();
        if (apiUrl != null && apiUrl.trim().isNotEmpty) {
          v['videoUrl'] = apiUrl.trim();
        }
        if (data['title'] != null) v['title'] = data['title'];
        if (data['description'] != null) {
          v['description'] = data['description'];
          v['caption'] = data['description'];
        }
        final shareFilter = ReelHelpers.resolveFilter(
          filterId: data['filterId']?.toString() ?? v['filterId']?.toString(),
          beautyOn: data['beautyOn'] == true || v['beautyOn'] == true,
          beautyIntensity: (data['beautyIntensity'] as num?)?.toDouble() ??
              (v['beautyIntensity'] as num?)?.toDouble(),
          description: (data['description'] ?? v['description'])?.toString(),
          videoId: vId,
          videoUrl: v['videoUrl']?.toString(),
        );
        if (shareFilter != null) {
          v['filterId'] = shareFilter.filterId;
          v['beautyOn'] = shareFilter.beautyOn;
          v['beautyIntensity'] = shareFilter.beautyIntensity;
        }
        final rawS = data['shares'] ?? data['shareCount'] ?? data['sharesCount'];
        if (rawS != null) {
          final int sCount = TrendingVideoItem.parseCount(rawS);
          v['shares'] = TrendingVideoItem.formatCount(sCount);
          v['sharesCount'] = sCount;
          v['shareCount'] = sCount;
        }
        emit(state.copyWith(videos: updatedVideos));
      }
      return res;
    } catch (e) {
      debugPrint('recordShare API error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<bool> reportVideo({
    required String videoId,
    required String reason,
  }) async {
    final vId = videoId.trim();
    final reasonClean = reason.trim();
    if (vId.isEmpty || reasonClean.isEmpty) return false;

    try {
      final token = _authCubit?.sessionToken;
      final refresh = _authCubit?.refreshToken;
      if (token == null || token.isEmpty || token == 'design_preview') {
        return false;
      }

      final res = await _videosRepository.reportVideo(
        videoId: vId,
        reason: reasonClean,
        sessionToken: token,
        refreshToken: refresh != 'design_preview' ? refresh : null,
      );
      return res['success'] != false;
    } catch (e) {
      debugPrint('reportVideo API error: $e');
      return false;
    }
  }

  Future<bool> rateVideo(String videoId, double rating) async {
    final vId = videoId.trim();
    if (vId.isEmpty) return false;

    final ratings = Map<String, double>.from(state.userRatings);
    ratings[vId] = rating;

    final videos = List<Map<String, dynamic>>.from(
      state.videos.map((v) => Map<String, dynamic>.from(v)),
    );
    for (final v in videos) {
      if (v['id'] == vId || v['_id'] == vId) {
        v['rating'] = rating;
        v['userRating'] = rating;
        break;
      }
    }

    emit(state.copyWith(
      userRatings: ratings,
      videos: videos,
    ));

    try {
      final token = _authCubit?.sessionToken;
      final refresh = _authCubit?.refreshToken;
      final res = await _videosRepository.rateVideo(
        videoId: vId,
        score: rating,
        sessionToken: token != 'design_preview' ? token : null,
        refreshToken: refresh != 'design_preview' ? refresh : null,
      );

      if (res['success'] == true) {
        return true;
      }
    } catch (_) {
      // Keep optimistic rating
    }
    return false;
  }

  Map<String, dynamic> _commentItemFromApiJson(Map<String, dynamic> item) {
    final user = item['user'] is Map ? Map<String, dynamic>.from(item['user'] as Map) : null;
    final fullName = user?['fullName']?.toString().trim() ?? '';
    final firstName = user?['firstName']?.toString().trim() ?? '';
    final lastName = user?['lastName']?.toString().trim() ?? '';
    final username = user?['username']?.toString().trim() ?? '';

    String displayName = fullName;
    if (displayName.isEmpty && (firstName.isNotEmpty || lastName.isNotEmpty)) {
      displayName = '$firstName $lastName'.trim();
    }
    if (displayName.isEmpty) {
      displayName = username.isNotEmpty ? username : 'User';
    }

    final avatar = user?['profilePhotoUrl']?.toString() ??
        user?['avatarUrl']?.toString() ??
        user?['profile_photo_url']?.toString() ??
        '';

    final createdAtStr = item['createdAt']?.toString() ?? item['created_at']?.toString();
    final timeAgo = _formatTimeAgo(createdAtStr);

    return {
      'id': item['id']?.toString() ?? '',
      'userId': item['userId']?.toString() ?? user?['id']?.toString() ?? '',
      'videoId': item['videoId']?.toString() ?? '',
      'userName': displayName,
      'username': username.isNotEmpty ? username : displayName,
      'userAvatar': avatar,
      'avatarUrl': avatar,
      'text': item['text']?.toString() ?? item['comment']?.toString() ?? '',
      'timeAgo': timeAgo,
      'time': timeAgo,
      'createdAt': createdAtStr,
      'user': user,
      'likes': item['likes'] is int
          ? item['likes'] as int
          : (item['likeCount'] is int
              ? item['likeCount'] as int
              : (int.tryParse(
                      (item['likes'] ?? item['likeCount'] ?? item['likesCount'])
                          ?.toString() ??
                          '') ??
                  0)),
      'liked': item['isLiked'] == true ||
          item['liked'] == true ||
          item['is_liked'] == true,
      'parentCommentId': item['parentCommentId']?.toString() ??
          item['parent_comment_id']?.toString(),
      'replyCount': item['replyCount'] is int
          ? item['replyCount'] as int
          : (item['repliesCount'] is int
              ? item['repliesCount'] as int
              : (int.tryParse(
                      (item['replyCount'] ??
                              item['repliesCount'] ??
                              item['replies'] ??
                              item['childrenCount'])
                          ?.toString() ??
                          '') ??
                  0)),
      'isBlueTick': user?['isBlueTick'] == true || user?['is_blue_tick'] == true,
    };
  }

  String _formatTimeAgo(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) return 'Just now';
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays > 365) {
        return '${(diff.inDays / 365).floor()}y ago';
      }
      if (diff.inDays > 30) {
        return '${(diff.inDays / 30).floor()}mo ago';
      }
      if (diff.inDays > 0) {
        return '${diff.inDays}d ago';
      }
      if (diff.inHours > 0) {
        return '${diff.inHours}h ago';
      }
      if (diff.inMinutes > 0) {
        return '${diff.inMinutes}m ago';
      }
      return 'Just now';
    } catch (_) {
      return 'Just now';
    }
  }

  Future<void> fetchComments(String videoId, {bool refresh = true}) async {
    final vId = videoId.trim();
    if (vId.isEmpty) return;
    if (_commentsLoading.contains(vId)) return;

    final nextPage = refresh ? 1 : ((_commentsPage[vId] ?? 1) + 1);
    if (!refresh && _commentsHasMore[vId] != true) return;

    _commentsLoading.add(vId);
    final gen = (_commentsFetchGen[vId] ?? 0) + (refresh ? 1 : 0);
    if (refresh) _commentsFetchGen[vId] = gen;
    // Notify listeners so UI can show loading footer.
    emit(state.copyWith());

    try {
      final token = _authCubit?.sessionToken;
      final refreshToken = _authCubit?.refreshToken;
      final res = await _videosRepository.getComments(
        videoId: vId,
        page: nextPage,
        limit: _commentsPageSize,
        sessionToken: token != 'design_preview' ? token : null,
        refreshToken: refreshToken != 'design_preview' ? refreshToken : null,
      );

      if (refresh && (_commentsFetchGen[vId] ?? 0) != gen) return;

      if (res['success'] == true && res['data'] is List) {
        final roots = (res['data'] as List)
            .whereType<Map>()
            .map((item) =>
                _commentItemFromApiJson(Map<String, dynamic>.from(item)))
            .toList();

        final previous = state.commentsMap[vId] ?? const [];
        late final List<Map<String, dynamic>> merged;

        if (refresh) {
          final rootIds = roots
              .map((c) =>
                  (c['id']?.toString() ?? c['_id']?.toString() ?? '').trim())
              .where((id) => id.isNotEmpty)
              .toSet();
          // Keep optimistic temp roots + already-loaded replies for present parents.
          final keptTemps = previous.where((c) {
            final id =
                (c['id']?.toString() ?? c['_id']?.toString() ?? '').trim();
            final parent = (c['parentCommentId']?.toString() ??
                    c['parent_comment_id']?.toString() ??
                    '')
                .trim();
            return parent.isEmpty && id.startsWith('cm_');
          }).toList();
          final keptReplies = previous.where((c) {
            final parent = (c['parentCommentId']?.toString() ??
                    c['parent_comment_id']?.toString() ??
                    '')
                .trim();
            return parent.isNotEmpty && rootIds.contains(parent);
          }).toList();
          merged = [...keptTemps, ...roots, ...keptReplies];
        } else {
          final existingIds = previous
              .map((c) =>
                  (c['id']?.toString() ?? c['_id']?.toString() ?? '').trim())
              .where((id) => id.isNotEmpty)
              .toSet();
          final appended = roots.where((c) {
            final id =
                (c['id']?.toString() ?? c['_id']?.toString() ?? '').trim();
            return id.isNotEmpty && !existingIds.contains(id);
          });
          merged = [...previous, ...appended];
        }

        final commentsMap =
            Map<String, List<Map<String, dynamic>>>.from(state.commentsMap);
        commentsMap[vId] = merged;

        _commentsPage[vId] = nextPage;
        _commentsHasMore[vId] = _parsePaginationHasMore(
          res,
          page: nextPage,
          fetchedCount: roots.length,
          pageSize: _commentsPageSize,
        );

        final rootCount = merged
            .where((c) =>
                (c['parentCommentId']?.toString() ??
                        c['parent_comment_id']?.toString() ??
                        '')
                    .trim()
                    .isEmpty)
            .length;
        final totalCount = _parsePaginationTotal(res, rootCount);

        final updatedVideos = List<Map<String, dynamic>>.from(
          state.videos.map((v) => Map<String, dynamic>.from(v)),
        );
        for (final v in updatedVideos) {
          final id = v['id']?.toString() ?? v['_id']?.toString() ?? '';
          if (id == vId) {
            // Prefer authoritative pagination total on refresh; never shrink on load-more.
            final prev = v['commentsCount'] is int
                ? v['commentsCount'] as int
                : (int.tryParse(v['commentsCount']?.toString() ?? '') ?? 0);
            final nextTotal = refresh
                ? totalCount
                : (totalCount > prev ? totalCount : prev);
            v['commentsCount'] = nextTotal;
            v['comments'] = TrendingVideoItem.formatCount(nextTotal);
            v['commentsLabel'] = TrendingVideoItem.formatCount(nextTotal);
            break;
          }
        }

        emit(state.copyWith(
          commentsMap: commentsMap,
          videos: updatedVideos,
        ));
      }
    } catch (_) {
      // Keep existing comments on error
    } finally {
      _commentsLoading.remove(vId);
      emit(state.copyWith());
    }
  }

  Future<void> loadMoreComments(String videoId) =>
      fetchComments(videoId, refresh: false);

  /// Loads replies via GET `/app/comments?videoId=&parentCommentId=`.
  Future<bool> fetchCommentReplies({
    required String videoId,
    required String parentCommentId,
    bool loadMore = false,
  }) async {
    final vId = videoId.trim();
    final parentId = parentCommentId.trim();
    if (vId.isEmpty || parentId.isEmpty) return false;
    if (_repliesLoading.contains(parentId)) return false;
    if (loadMore && _repliesHasMore[parentId] != true) return true;

    final nextPage = loadMore ? ((_repliesPage[parentId] ?? 1) + 1) : 1;
    _repliesLoading.add(parentId);

    try {
      final token = _authCubit?.sessionToken;
      final refresh = _authCubit?.refreshToken;
      final res = await _videosRepository.getComments(
        videoId: vId,
        parentCommentId: parentId,
        page: nextPage,
        limit: _commentsPageSize,
        sessionToken: token != 'design_preview' ? token : null,
        refreshToken: refresh != 'design_preview' ? refresh : null,
      );

      if (res['success'] == false) return false;
      if (res['data'] is! List) return false;

      final replies = (res['data'] as List).whereType<Map>().map((item) {
        final mapped =
            _commentItemFromApiJson(Map<String, dynamic>.from(item));
        final existingParent =
            (mapped['parentCommentId']?.toString() ?? '').trim();
        if (existingParent.isEmpty) {
          mapped['parentCommentId'] = parentId;
        }
        return mapped;
      }).toList();

      final existing = List<Map<String, dynamic>>.from(
        state.commentsMap[vId] ?? const [],
      );

      List<Map<String, dynamic>> merged;
      if (loadMore) {
        final existingIds = existing
            .map((c) =>
                (c['id']?.toString() ?? c['_id']?.toString() ?? '').trim())
            .where((id) => id.isNotEmpty)
            .toSet();
        final appended = replies.where((c) {
          final id =
              (c['id']?.toString() ?? c['_id']?.toString() ?? '').trim();
          return id.isNotEmpty && !existingIds.contains(id);
        });
        merged = [...existing, ...appended];
      } else {
        final withoutOldReplies = existing.where((c) {
          final parent = (c['parentCommentId']?.toString() ??
                  c['parent_comment_id']?.toString() ??
                  '')
              .trim();
          return parent != parentId;
        });
        merged = [...withoutOldReplies, ...replies];
      }

      // Keep parent replyCount in sync with loaded + server totals.
      final replyTotal = _parsePaginationTotal(res, 0);
      final loadedForParent = merged.where((r) {
        final parent = (r['parentCommentId']?.toString() ??
                r['parent_comment_id']?.toString() ??
                '')
            .trim();
        return parent == parentId;
      }).length;
      final nextList = merged.map((c) {
        final id =
            (c['id']?.toString() ?? c['_id']?.toString() ?? '').trim();
        if (id != parentId) return c;
        final updated = Map<String, dynamic>.from(c);
        final prevCount = updated['replyCount'] is int
            ? updated['replyCount'] as int
            : (int.tryParse(updated['replyCount']?.toString() ?? '') ?? 0);
        updated['replyCount'] = [
          prevCount,
          loadedForParent,
          if (replyTotal > 0) replyTotal,
        ].reduce((a, b) => a > b ? a : b);
        return updated;
      }).toList();

      _repliesPage[parentId] = nextPage;
      _repliesHasMore[parentId] = _parsePaginationHasMore(
        res,
        page: nextPage,
        fetchedCount: replies.length,
        pageSize: _commentsPageSize,
      );

      final commentsMap =
          Map<String, List<Map<String, dynamic>>>.from(state.commentsMap);
      commentsMap[vId] = nextList;
      emit(state.copyWith(commentsMap: commentsMap));
      return true;
    } catch (e) {
      debugPrint('fetchCommentReplies error: $e');
      return false;
    } finally {
      _repliesLoading.remove(parentId);
    }
  }

  Future<bool> loadMoreCommentReplies({
    required String videoId,
    required String parentCommentId,
  }) =>
      fetchCommentReplies(
        videoId: videoId,
        parentCommentId: parentCommentId,
        loadMore: true,
      );

  Future<bool> addComment(
    String videoId,
    String commentText, {
    String? parentCommentId,
  }) async {
    final text = commentText.trim();
    if (text.isEmpty) return false;

    final name = (_authCubit?.userName.isNotEmpty == true)
        ? _authCubit!.userName
        : 'User';
    final avatar = _authCubit?.avatarUrl ?? '';
    final parentId = parentCommentId?.trim() ?? '';

    final tempCommentId = 'cm_${DateTime.now().millisecondsSinceEpoch}';
    final tempComment = {
      'id': tempCommentId,
      'userId': _authCubit?.userId ?? '',
      'userName': name,
      'username': name,
      'userAvatar': avatar,
      'avatarUrl': avatar,
      'text': text,
      'timeAgo': 'Just now',
      'time': 'Just now',
      'likes': 0,
      'liked': false,
      if (parentId.isNotEmpty) 'parentCommentId': parentId,
    };

    final comments = Map<String, List<Map<String, dynamic>>>.from(state.commentsMap);
    final list = comments.putIfAbsent(
      videoId,
      () => <Map<String, dynamic>>[],
    );
    list.insert(0, tempComment);
    if (parentId.isNotEmpty) {
      final parentIdx = list.indexWhere((c) =>
          (c['id']?.toString() ?? c['_id']?.toString() ?? '').trim() ==
          parentId);
      if (parentIdx >= 0) {
        final parent = Map<String, dynamic>.from(list[parentIdx]);
        final prev = parent['replyCount'] is int
            ? parent['replyCount'] as int
            : (int.tryParse(parent['replyCount']?.toString() ?? '') ?? 0);
        parent['replyCount'] = prev + 1;
        list[parentIdx] = parent;
      }
    }

    final videos = List<Map<String, dynamic>>.from(
      state.videos.map((v) => Map<String, dynamic>.from(v)),
    );
    for (final v in videos) {
      if (v['id'] == videoId) {
        final current = v['commentsCount'] as int? ?? 0;
        final newCount = (current + 1).clamp(0, 999999);
        v['commentsCount'] = newCount;
        v['comments'] = TrendingVideoItem.formatCount(newCount);
        break;
      }
    }

    emit(state.copyWith(
      commentsMap: comments,
      videos: videos,
    ));

    try {
      final token = _authCubit?.sessionToken;
      final refresh = _authCubit?.refreshToken;
      final res = await _videosRepository.createComment(
        videoId: videoId,
        text: text,
        parentCommentId: parentId.isNotEmpty ? parentId : null,
        sessionToken: token != 'design_preview' ? token : null,
        refreshToken: refresh != 'design_preview' ? refresh : null,
      );

      if (res['success'] == true && res['data'] is Map) {
        final data = Map<String, dynamic>.from(res['data'] as Map);
        final realId = data['id']?.toString() ?? tempCommentId;
        final realText = data['text']?.toString() ?? text;
        final createdAtStr = data['createdAt']?.toString();
        final timeAgoStr = _formatTimeAgo(createdAtStr);

        final userObj = data['user'] is Map ? Map<String, dynamic>.from(data['user'] as Map) : null;
        final realUserName = userObj?['fullName']?.toString() ??
            userObj?['username']?.toString() ??
            name;
        final realAvatar = userObj?['profilePhotoUrl']?.toString() ??
            userObj?['avatarUrl']?.toString() ??
            avatar;

        final updatedComments = Map<String, List<Map<String, dynamic>>>.from(state.commentsMap);
        final currentList = updatedComments[videoId];
        if (currentList != null) {
          // Check for duplicate realId
          final dupIdx = currentList.indexWhere((c) => c['id'] == realId);
          if (dupIdx != -1 && realId != tempCommentId) {
            currentList.removeWhere((c) => c['id'] == tempCommentId);
          } else {
            final idx = currentList.indexWhere((c) => c['id'] == tempCommentId);
            if (idx != -1) {
              final apiParent = data['parentCommentId']?.toString() ??
                  data['parent_comment_id']?.toString() ??
                  parentId;
              currentList[idx] = {
                'id': realId,
                'userId': data['userId']?.toString() ?? userObj?['id']?.toString() ?? '',
                'videoId': data['videoId']?.toString() ?? videoId,
                'userName': realUserName,
                'username': userObj?['username']?.toString() ?? realUserName,
                'userAvatar': realAvatar,
                'avatarUrl': realAvatar,
                'text': realText,
                'timeAgo': timeAgoStr,
                'time': timeAgoStr,
                'createdAt': createdAtStr,
                'updatedAt': data['updatedAt']?.toString(),
                'user': userObj,
                'likes': data['likes'] is int
                    ? data['likes'] as int
                    : (data['likeCount'] is int ? data['likeCount'] as int : 0),
                'liked': data['isLiked'] == true || data['liked'] == true,
                if (apiParent.trim().isNotEmpty) 'parentCommentId': apiParent.trim(),
              };
            }
          }
          emit(state.copyWith(commentsMap: updatedComments));
        }
        return true;
      } else {
        _rollbackTempComment(videoId, tempCommentId);
        return false;
      }
    } catch (_) {
      _rollbackTempComment(videoId, tempCommentId);
      return false;
    }
  }

  void _rollbackTempComment(String videoId, String tempCommentId) {
    final updatedComments = Map<String, List<Map<String, dynamic>>>.from(state.commentsMap);
    final currentList = updatedComments[videoId];
    if (currentList != null) {
      String? parentId;
      for (final c in currentList) {
        if (c['id'] == tempCommentId) {
          parentId = (c['parentCommentId']?.toString() ??
                  c['parent_comment_id']?.toString() ??
                  '')
              .trim();
          break;
        }
      }
      currentList.removeWhere((c) => c['id'] == tempCommentId);

      if (parentId != null && parentId.isNotEmpty) {
        final parentIdx = currentList.indexWhere((c) =>
            (c['id']?.toString() ?? c['_id']?.toString() ?? '').trim() ==
            parentId);
        if (parentIdx >= 0) {
          final parent = Map<String, dynamic>.from(currentList[parentIdx]);
          final prev = parent['replyCount'] is int
              ? parent['replyCount'] as int
              : (int.tryParse(parent['replyCount']?.toString() ?? '') ?? 0);
          parent['replyCount'] = (prev - 1).clamp(0, 999999);
          currentList[parentIdx] = parent;
        }
      }

      final videos = List<Map<String, dynamic>>.from(
        state.videos.map((v) => Map<String, dynamic>.from(v)),
      );
      for (final v in videos) {
        if (v['id'] == videoId) {
          final current = v['commentsCount'] as int? ?? 0;
          final newCount = (current - 1).clamp(0, 999999);
          v['commentsCount'] = newCount;
          v['comments'] = TrendingVideoItem.formatCount(newCount);
          break;
        }
      }

      emit(state.copyWith(
        commentsMap: updatedComments,
        videos: videos,
      ));
    }
  }

  Future<bool> toggleCommentLike({
    required String videoId,
    required String commentId,
  }) async {
    final cleanVideoId = videoId.trim();
    final cleanCommentId = commentId.trim();
    if (cleanVideoId.isEmpty || cleanCommentId.isEmpty) return false;
    if (_pendingCommentLikeCalls.contains(cleanCommentId)) return false;
    _pendingCommentLikeCalls.add(cleanCommentId);

    final comments =
        Map<String, List<Map<String, dynamic>>>.from(state.commentsMap);
    final list = comments[cleanVideoId];
    if (list == null) {
      _pendingCommentLikeCalls.remove(cleanCommentId);
      return false;
    }

    final idx = list.indexWhere((c) =>
        (c['id']?.toString() ?? c['_id']?.toString() ?? '') == cleanCommentId);
    if (idx < 0) {
      _pendingCommentLikeCalls.remove(cleanCommentId);
      return false;
    }

    final current = Map<String, dynamic>.from(list[idx]);
    final wasLiked = current['liked'] == true;
    final prevLikes = current['likes'] is int
        ? current['likes'] as int
        : (int.tryParse(current['likes']?.toString() ?? '') ?? 0);
    final nextLiked = !wasLiked;
    final nextLikes = (prevLikes + (nextLiked ? 1 : -1)).clamp(0, 999999);

    list[idx] = {
      ...current,
      'liked': nextLiked,
      'likes': nextLikes,
    };
    comments[cleanVideoId] = list;
    emit(state.copyWith(commentsMap: comments));

    try {
      final token = _authCubit?.sessionToken;
      final refresh = _authCubit?.refreshToken;
      if (token == null || token.isEmpty || token == 'design_preview') {
        return true;
      }

      final res = await _videosRepository.likeComment(
        commentId: cleanCommentId,
        isLiked: nextLiked,
        sessionToken: token,
        refreshToken: refresh != 'design_preview' ? refresh : null,
      );

      if (res['success'] == false) {
        final rollback =
            Map<String, List<Map<String, dynamic>>>.from(state.commentsMap);
        final rollbackList = rollback[cleanVideoId];
        if (rollbackList != null) {
          final rIdx = rollbackList.indexWhere((c) =>
              (c['id']?.toString() ?? c['_id']?.toString() ?? '') ==
              cleanCommentId);
          if (rIdx >= 0) {
            rollbackList[rIdx] = {
              ...Map<String, dynamic>.from(rollbackList[rIdx]),
              'liked': wasLiked,
              'likes': prevLikes,
            };
            rollback[cleanVideoId] = rollbackList;
            emit(state.copyWith(commentsMap: rollback));
          }
        }
        return false;
      }

      if (res['data'] is Map) {
        final data = Map<String, dynamic>.from(res['data'] as Map);
        final serverLiked = data.containsKey('isLiked')
            ? data['isLiked'] == true
            : (data['liked'] == true ? true : nextLiked);
        final rawLikes =
            data['likeCount'] ?? data['likes'] ?? data['likesCount'];
        final serverLikes = rawLikes is int
            ? rawLikes
            : int.tryParse(rawLikes?.toString() ?? '');
        final synced =
            Map<String, List<Map<String, dynamic>>>.from(state.commentsMap);
        final syncedList = synced[cleanVideoId];
        if (syncedList != null) {
          final sIdx = syncedList.indexWhere((c) =>
              (c['id']?.toString() ?? c['_id']?.toString() ?? '') ==
              cleanCommentId);
          if (sIdx >= 0) {
            syncedList[sIdx] = {
              ...Map<String, dynamic>.from(syncedList[sIdx]),
              'liked': serverLiked,
              'likes': serverLikes ?? nextLikes,
            };
            synced[cleanVideoId] = syncedList;
            emit(state.copyWith(commentsMap: synced));
          }
        }
      }
      return true;
    } catch (e) {
      debugPrint('toggleCommentLike error: $e');
      final rollback =
          Map<String, List<Map<String, dynamic>>>.from(state.commentsMap);
      final rollbackList = rollback[cleanVideoId];
      if (rollbackList != null) {
        final rIdx = rollbackList.indexWhere((c) =>
            (c['id']?.toString() ?? c['_id']?.toString() ?? '') ==
            cleanCommentId);
        if (rIdx >= 0) {
          rollbackList[rIdx] = {
            ...Map<String, dynamic>.from(rollbackList[rIdx]),
            'liked': wasLiked,
            'likes': prevLikes,
          };
          rollback[cleanVideoId] = rollbackList;
          emit(state.copyWith(commentsMap: rollback));
        }
      }
      return false;
    } finally {
      _pendingCommentLikeCalls.remove(cleanCommentId);
    }
  }

  bool canDeleteComment(String videoId, Map<String, dynamic> comment) {
    return CommentPermissions.canDeleteComment(
      currentUserId: currentUserId,
      comment: comment,
      video: getVideo(videoId.trim()),
    );
  }

  Future<bool> deleteComment({
    required String videoId,
    required String commentId,
  }) async {
    final cleanVideoId = videoId.trim();
    final cleanCommentId = commentId.trim();
    if (cleanCommentId.isEmpty) return false;

    final existing = state.commentsMap[cleanVideoId];
    Map<String, dynamic>? target;
    if (existing != null) {
      for (final item in existing) {
        final id = item['id']?.toString() ?? item['_id']?.toString() ?? '';
        if (id == cleanCommentId) {
          target = item;
          break;
        }
      }
    }

    if (target != null && !canDeleteComment(cleanVideoId, target)) {
      debugPrint('deleteComment blocked: not author or video owner');
      return false;
    }
    if (currentUserId == 'default_user') return false;

    try {
      final token = _authCubit?.sessionToken;
      final refresh = _authCubit?.refreshToken;
      if (token == null || token.isEmpty || token == 'design_preview') {
        return false;
      }

      final res = await _videosRepository.deleteComment(
        commentId: cleanCommentId,
        sessionToken: token,
        refreshToken: refresh != 'design_preview' ? refresh : null,
      );

      if (res['success'] != true) {
        if (cleanVideoId.isNotEmpty) unawaited(fetchComments(cleanVideoId));
        return false;
      }

      final comments =
          Map<String, List<Map<String, dynamic>>>.from(state.commentsMap);
      final list = comments[cleanVideoId];
      var removedCount = 0;
      if (list != null) {
        final parentOfDeleted = (target?['parentCommentId']?.toString() ??
                target?['parent_comment_id']?.toString() ??
                '')
            .trim();
        final before = list.length;
        list.removeWhere((item) {
          final id =
              (item['id']?.toString() ?? item['_id']?.toString() ?? '').trim();
          final parent = (item['parentCommentId']?.toString() ??
                  item['parent_comment_id']?.toString() ??
                  '')
              .trim();
          return id == cleanCommentId || parent == cleanCommentId;
        });
        removedCount = (before - list.length).clamp(0, 999999);

        if (parentOfDeleted.isNotEmpty) {
          final parentIdx = list.indexWhere((c) =>
              (c['id']?.toString() ?? c['_id']?.toString() ?? '').trim() ==
              parentOfDeleted);
          if (parentIdx >= 0) {
            final parent = Map<String, dynamic>.from(list[parentIdx]);
            final prev = parent['replyCount'] is int
                ? parent['replyCount'] as int
                : (int.tryParse(parent['replyCount']?.toString() ?? '') ?? 0);
            parent['replyCount'] = (prev - 1).clamp(0, 999999);
            list[parentIdx] = parent;
          }
        }
        comments[cleanVideoId] = list;
      }

      final videos = List<Map<String, dynamic>>.from(
        state.videos.map((v) => Map<String, dynamic>.from(v)),
      );
      for (final v in videos) {
        final vId = v['id']?.toString() ?? v['_id']?.toString() ?? '';
        if (vId == cleanVideoId) {
          final current = v['commentsCount'] as int? ?? 0;
          final newCount =
              (current - (removedCount > 0 ? removedCount : 1)).clamp(0, 999999);
          v['commentsCount'] = newCount;
          v['comments'] = TrendingVideoItem.formatCount(newCount);
          break;
        }
      }

      emit(state.copyWith(commentsMap: comments, videos: videos));
      return true;
    } on ApiException catch (e) {
      debugPrint('deleteComment denied: ${e.statusCode} ${e.message}');
      if (cleanVideoId.isNotEmpty) unawaited(fetchComments(cleanVideoId));
      return false;
    } catch (e) {
      debugPrint('deleteComment error: $e');
      if (cleanVideoId.isNotEmpty) unawaited(fetchComments(cleanVideoId));
    }
    return false;
  }
}
