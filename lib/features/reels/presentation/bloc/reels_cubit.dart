import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
        currentVideos.add(Map<String, dynamic>.from(nv));
        changed = true;
      } else {
        final existing = currentVideos[idx];
        if (existing['isLiked'] != nv['isLiked'] || existing['liked'] != nv['liked']) {
          existing['isLiked'] = nv['isLiked'] ?? nv['liked'];
          existing['liked'] = nv['liked'] ?? nv['isLiked'];
          changed = true;
        }
        if (nv.containsKey('saves') || nv.containsKey('savesCount') || nv.containsKey('isSaved')) {
          if (nv.containsKey('saves')) existing['saves'] = nv['saves'];
          if (nv.containsKey('savesCount')) existing['savesCount'] = nv['savesCount'];
          if (nv.containsKey('isSaved')) {
            existing['isSaved'] = nv['isSaved'];
            existing['saved'] = nv['isSaved'];
            existing['isBookmarked'] = nv['isSaved'];
          }
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

  Future<void> toggleLike(String videoId, {Map<String, dynamic>? fallbackVideo}) async {
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
      final bool isCurrentlyLiked = isLiked(vId, fallbackVideo: fallbackVideo);

      int likesDelta = 0;
      int dislikesDelta = 0;
      bool isLiking = false;

      if (isCurrentlyLiked) {
        currentUserReactions[vId] = 'unlike';
        likesDelta = -1;
        isLiking = false;
      } else {
        currentUserReactions[vId] = 'like';
        likesDelta = 1;
        isLiking = true;
      }

      userMap[uid] = currentUserReactions;

      final videos = List<Map<String, dynamic>>.from(
        state.videos.map((v) => Map<String, dynamic>.from(v)),
      );

      int idx = videos.indexWhere((v) => (v['id']?.toString() ?? v['_id']?.toString()) == vId);
      if (idx == -1 && fallbackVideo != null) {
        videos.add(Map<String, dynamic>.from(fallbackVideo));
        idx = videos.length - 1;
      }

      int newLikes = 0;
      if (idx != -1) {
        final v = videos[idx];
        final currentLikes = TrendingVideoItem.parseCount(v['likesCount'] ?? v['likes']);
        final currentDislikes = TrendingVideoItem.parseCount(v['dislikesCount'] ?? v['dislikes']);

        newLikes = (currentLikes + likesDelta).clamp(0, 9999999);
        final newDislikes = (currentDislikes + dislikesDelta).clamp(0, 9999999);

        v['likesCount'] = newLikes;
        v['likes'] = TrendingVideoItem.formatCount(newLikes);
        v['isLiked'] = isLiking;
        v['liked'] = isLiking;
        v['dislikesCount'] = newDislikes;
        v['dislikes'] = newDislikes;
      }

      emit(state.copyWith(
        userReactions: userMap,
        videos: videos,
      ));

      if (isLiking) {
        debugPrint('=== LIKE API CALLED (EXACTLY 1 TIME) FOR VIDEO: $vId ===');
        final token = _authCubit?.sessionToken;
        final refresh = _authCubit?.refreshToken;
        final res = await _videosRepository.likeVideo(
          videoId: vId,
          sessionToken: token != 'design_preview' ? token : null,
          refreshToken: refresh != 'design_preview' ? refresh : null,
        );
        debugPrint('=== LIKE API RESPONSE RECEIVED FOR VIDEO: $vId (success: ${res['success']}) ===');

        if (res['success'] == true && res['data'] is Map) {
          final data = Map<String, dynamic>.from(res['data'] as Map);
          final rawLikes = data['likes'] ?? data['likeCount'] ?? data['likesCount'];

          if (rawLikes != null) {
            final serverLikes = TrendingVideoItem.parseCount(rawLikes);
            final activeReaction = state.getReaction(vId, uid);
            if (activeReaction == 'like') {
              final updatedVideos = List<Map<String, dynamic>>.from(
                state.videos.map((v) => Map<String, dynamic>.from(v)),
              );
              for (final v in updatedVideos) {
                if (v['id'] == vId) {
                  // Ensure single tap increases count by exactly 1 (e.g. 25 -> 26)
                  final finalLikes = (serverLikes <= newLikes) ? serverLikes : newLikes;
                  v['likesCount'] = finalLikes;
                  v['likes'] = TrendingVideoItem.formatCount(finalLikes);
                  break;
                }
              }
              emit(state.copyWith(videos: updatedVideos));
            }
          }
        }
      }
    } catch (_) {
      // Keep optimistic UI state
    } finally {
      _pendingLikeCalls.remove(vId);
    }
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
      'likes': item['likes'] is int ? item['likes'] as int : (int.tryParse(item['likes']?.toString() ?? '') ?? 0),
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

  Future<void> fetchComments(String videoId) async {
    final vId = videoId.trim();
    if (vId.isEmpty) return;

    try {
      final token = _authCubit?.sessionToken;
      final refresh = _authCubit?.refreshToken;
      final res = await _videosRepository.getComments(
        videoId: vId,
        sessionToken: token != 'design_preview' ? token : null,
        refreshToken: refresh != 'design_preview' ? refresh : null,
      );

      if (res['success'] == true && res['data'] is List) {
        final list = (res['data'] as List)
            .whereType<Map>()
            .map((item) => _commentItemFromApiJson(Map<String, dynamic>.from(item)))
            .toList();

        final commentsMap = Map<String, List<Map<String, dynamic>>>.from(state.commentsMap);
        commentsMap[vId] = list;

        int totalCount = list.length;
        if (res['pagination'] is Map && res['pagination']['total'] is int) {
          totalCount = res['pagination']['total'] as int;
        }

        final updatedVideos = List<Map<String, dynamic>>.from(
          state.videos.map((v) => Map<String, dynamic>.from(v)),
        );
        for (final v in updatedVideos) {
          if (v['id'] == vId) {
            v['commentsCount'] = totalCount;
            v['comments'] = TrendingVideoItem.formatCount(totalCount);
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
    }
  }

  Future<bool> addComment(String videoId, String commentText) async {
    final text = commentText.trim();
    if (text.isEmpty) return false;

    final name = (_authCubit?.userName.isNotEmpty == true)
        ? _authCubit!.userName
        : 'User';
    final avatar = _authCubit?.avatarUrl ?? '';

    final tempCommentId = 'cm_${DateTime.now().millisecondsSinceEpoch}';
    final tempComment = {
      'id': tempCommentId,
      'userName': name,
      'username': name,
      'userAvatar': avatar,
      'avatarUrl': avatar,
      'text': text,
      'timeAgo': 'Just now',
      'time': 'Just now',
      'likes': 0,
    };

    final comments = Map<String, List<Map<String, dynamic>>>.from(state.commentsMap);
    final list = comments.putIfAbsent(
      videoId,
      () => <Map<String, dynamic>>[],
    );
    list.insert(0, tempComment);

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
      currentList.removeWhere((c) => c['id'] == tempCommentId);

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

  Future<bool> deleteComment({
    required String videoId,
    required String commentId,
  }) async {
    final cleanVideoId = videoId.trim();
    final cleanCommentId = commentId.trim();
    if (cleanCommentId.isEmpty) return false;

    final comments = Map<String, List<Map<String, dynamic>>>.from(state.commentsMap);
    final list = comments[cleanVideoId];
    if (list != null) {
      list.removeWhere((item) =>
          (item['id']?.toString() ?? item['_id']?.toString() ?? '') == cleanCommentId);
      comments[cleanVideoId] = list;
    }

    final videos = List<Map<String, dynamic>>.from(
      state.videos.map((v) => Map<String, dynamic>.from(v)),
    );
    for (final v in videos) {
      final vId = v['id']?.toString() ?? v['_id']?.toString() ?? '';
      if (vId == cleanVideoId) {
        final current = v['commentsCount'] as int? ?? 0;
        final newCount = (current - 1).clamp(0, 999999);
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
      final res = await _videosRepository.deleteComment(
        commentId: cleanCommentId,
        sessionToken: token != 'design_preview' ? token : null,
        refreshToken: refresh != 'design_preview' ? refresh : null,
      );

      if (res['success'] == true) {
        return true;
      }
    } catch (_) {
      if (cleanVideoId.isNotEmpty) {
        fetchComments(cleanVideoId);
      }
    }
    return false;
  }
}
