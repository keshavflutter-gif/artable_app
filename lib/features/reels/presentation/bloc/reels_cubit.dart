import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:artable_app/data/datasources/mock_data.dart';
import 'reels_state.dart';

class ReelsCubit extends Cubit<ReelsState> {
  ReelsCubit() : super(ReelsState());

  List<Map<String, dynamic>> get videos => state.videos;
  bool isLiked(String videoId) => state.isLiked(videoId);
  bool isBookmarked(String videoId) => state.isBookmarked(videoId);
  double? getUserRating(String videoId) => state.getUserRating(videoId);
  List<Map<String, dynamic>> getComments(String videoId) =>
      state.getComments(videoId);

  void toggleLike(String videoId) {
    final liked = Set<String>.from(state.likedVideoIds);
    final videos = List<Map<String, dynamic>>.from(
      state.videos.map((v) => Map<String, dynamic>.from(v)),
    );

    int delta = 0;
    if (liked.contains(videoId)) {
      liked.remove(videoId);
      delta = -1;
    } else {
      liked.add(videoId);
      delta = 1;
    }

    for (final v in videos) {
      if (v['id'] == videoId) {
        final current = v['likesCount'] as int? ?? 0;
        v['likesCount'] = (current + delta).clamp(0, 999999);
        break;
      }
    }

    emit(state.copyWith(
      likedVideoIds: liked,
      videos: videos,
    ));
  }

  void toggleBookmark(String videoId) {
    final bookmarked = Set<String>.from(state.bookmarkedVideoIds);
    if (bookmarked.contains(videoId)) {
      bookmarked.remove(videoId);
    } else {
      bookmarked.add(videoId);
    }
    emit(state.copyWith(bookmarkedVideoIds: bookmarked));
  }

  void rateVideo(String videoId, double rating) {
    final ratings = Map<String, double>.from(state.userRatings);
    ratings[videoId] = rating;

    final videos = List<Map<String, dynamic>>.from(
      state.videos.map((v) => Map<String, dynamic>.from(v)),
    );
    for (final v in videos) {
      if (v['id'] == videoId) {
        v['rating'] = rating;
        break;
      }
    }

    emit(state.copyWith(
      userRatings: ratings,
      videos: videos,
    ));
  }

  void addComment(String videoId, String commentText) {
    final comments = Map<String, List<Map<String, dynamic>>>.from(state.commentsMap);
    final list = comments.putIfAbsent(
      videoId,
      () {
        final raw = MockData.COMMENTS[videoId] ?? [];
        return List<Map<String, dynamic>>.from(raw);
      },
    );

    final newComment = {
      'id': 'cm_${DateTime.now().millisecondsSinceEpoch}',
      'userName': 'Ritesh Walia',
      'userAvatar': 'https://loremflickr.com/100/100/man,portrait?lock=501',
      'text': commentText,
      'timeAgo': 'Just now',
      'likes': 0,
    };
    list.insert(0, newComment);

    final videos = List<Map<String, dynamic>>.from(
      state.videos.map((v) => Map<String, dynamic>.from(v)),
    );
    for (final v in videos) {
      if (v['id'] == videoId) {
        final current = v['commentsCount'] as int? ?? 0;
        v['commentsCount'] = (current + 1).clamp(0, 999999);
        break;
      }
    }

    emit(state.copyWith(
      commentsMap: comments,
      videos: videos,
    ));
  }
}
