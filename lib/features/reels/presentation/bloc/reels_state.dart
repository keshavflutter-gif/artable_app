import 'package:artable_app/data/datasources/mock_data.dart';

class ReelsState {
  ReelsState({
    List<Map<String, dynamic>>? videos,
    Map<String, List<Map<String, dynamic>>>? commentsMap,
    Map<String, Map<String, String>>? userReactions,
    Set<String>? bookmarkedVideoIds,
    Map<String, double>? userRatings,
  })  : videos = videos ?? List<Map<String, dynamic>>.from(MockData.REELS),
        commentsMap = commentsMap ?? const {},
        userReactions = userReactions ?? const {},
        bookmarkedVideoIds = bookmarkedVideoIds ?? const {},
        userRatings = userRatings ?? const {};

  final List<Map<String, dynamic>> videos;
  final Map<String, List<Map<String, dynamic>>> commentsMap;
  /// userReactions maps userId -> (videoId -> 'like' | 'dislike')
  final Map<String, Map<String, String>> userReactions;
  final Set<String> bookmarkedVideoIds;
  final Map<String, double> userRatings;

  String? getReaction(String videoId, [String userId = 'default_user']) {
    return userReactions[userId]?[videoId];
  }

  bool isLiked(String videoId, [String userId = 'default_user', Map<String, dynamic>? fallbackVideo]) {
    final r = getReaction(videoId, userId);
    if (r != null) {
      return r == 'like';
    }
    final cleanId = videoId.trim();
    for (final v in videos) {
      final vId = v['id']?.toString() ?? v['_id']?.toString() ?? '';
      if (vId == cleanId) {
        return v['isLiked'] == true || v['liked'] == true || v['hasLiked'] == true || v['userLiked'] == true;
      }
    }
    if (fallbackVideo != null) {
      return fallbackVideo['isLiked'] == true ||
          fallbackVideo['liked'] == true ||
          fallbackVideo['hasLiked'] == true ||
          fallbackVideo['userLiked'] == true ||
          fallbackVideo['isUserLiked'] == true;
    }
    return false;
  }

  bool isDisliked(String videoId, [String userId = 'default_user']) {
    final r = getReaction(videoId, userId);
    if (r != null) {
      return r == 'dislike';
    }
    for (final v in videos) {
      if (v['id'] == videoId) {
        return v['isDisliked'] == true || v['disliked'] == true;
      }
    }
    return false;
  }

  Set<String> getLikedVideoIds([String userId = 'default_user']) {
    final res = <String>{};
    final userMap = userReactions[userId];
    if (userMap != null) {
      userMap.forEach((vId, r) {
        if (r == 'like') res.add(vId);
      });
    }
    return res;
  }

  Set<String> get likedVideoIds => getLikedVideoIds('default_user');

  bool isBookmarked(String videoId) => bookmarkedVideoIds.contains(videoId);
  double? getUserRating(String videoId) {
    final cleanId = videoId.trim();
    if (userRatings.containsKey(cleanId)) {
      return userRatings[cleanId];
    }
    for (final v in videos) {
      final vId = v['id']?.toString() ?? v['_id']?.toString() ?? '';
      if (vId == cleanId) {
        if (v['userRating'] != null) {
          final parsed = double.tryParse(v['userRating'].toString());
          if (parsed != null && parsed > 0) return parsed;
        }
        if (v['score'] != null) {
          final parsed = double.tryParse(v['score'].toString());
          if (parsed != null && parsed > 0) return parsed;
        }
        if (v['rating'] != null) {
          final parsed = double.tryParse(v['rating'].toString());
          if (parsed != null && parsed > 0) return parsed;
        }
        if (v['ratings'] is List && (v['ratings'] as List).isNotEmpty) {
          final list = v['ratings'] as List;
          for (final item in list) {
            if (item is Map) {
              final score = item['score'] ?? item['rating'];
              if (score != null) {
                final parsed = double.tryParse(score.toString());
                if (parsed != null && parsed > 0) return parsed;
              }
            }
          }
        }
      }
    }
    return null;
  }

  List<Map<String, dynamic>> getComments(String videoId) {
    return commentsMap[videoId] ?? const [];
  }

  int getCommentsCount(String videoId, [int fallback = 0]) {
    final cleanId = videoId.trim();
    for (final v in videos) {
      final vId = v['id']?.toString() ?? v['_id']?.toString() ?? '';
      if (vId == cleanId) {
        if (v['commentsCount'] is int) {
          final count = v['commentsCount'] as int;
          if (commentsMap.containsKey(cleanId) && commentsMap[cleanId]!.length > count) {
            return commentsMap[cleanId]!.length;
          }
          return count;
        }
        if (v['comments'] != null) {
          final parsed = int.tryParse(v['comments'].toString());
          if (parsed != null && parsed >= 0) return parsed;
        }
      }
    }
    if (commentsMap.containsKey(cleanId)) {
      return commentsMap[cleanId]!.length;
    }
    return fallback;
  }

  ReelsState copyWith({
    List<Map<String, dynamic>>? videos,
    Map<String, List<Map<String, dynamic>>>? commentsMap,
    Map<String, Map<String, String>>? userReactions,
    Set<String>? bookmarkedVideoIds,
    Map<String, double>? userRatings,
  }) {
    return ReelsState(
      videos: videos ?? this.videos,
      commentsMap: commentsMap ?? this.commentsMap,
      userReactions: userReactions ?? this.userReactions,
      bookmarkedVideoIds: bookmarkedVideoIds ?? this.bookmarkedVideoIds,
      userRatings: userRatings ?? this.userRatings,
    );
  }
}
