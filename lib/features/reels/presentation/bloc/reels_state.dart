import 'package:artable_app/data/datasources/mock_data.dart';

class ReelsState {
  ReelsState({
    List<Map<String, dynamic>>? videos,
    Map<String, List<Map<String, dynamic>>>? commentsMap,
    Set<String>? likedVideoIds,
    Set<String>? bookmarkedVideoIds,
    Map<String, double>? userRatings,
  })  : videos = videos ?? List<Map<String, dynamic>>.from(MockData.REELS),
        commentsMap = commentsMap ?? const {},
        likedVideoIds = likedVideoIds ?? const {},
        bookmarkedVideoIds = bookmarkedVideoIds ?? const {},
        userRatings = userRatings ?? const {};

  final List<Map<String, dynamic>> videos;
  final Map<String, List<Map<String, dynamic>>> commentsMap;
  final Set<String> likedVideoIds;
  final Set<String> bookmarkedVideoIds;
  final Map<String, double> userRatings;

  bool isLiked(String videoId) => likedVideoIds.contains(videoId);
  bool isBookmarked(String videoId) => bookmarkedVideoIds.contains(videoId);
  double? getUserRating(String videoId) => userRatings[videoId];

  List<Map<String, dynamic>> getComments(String videoId) {
    if (commentsMap.containsKey(videoId)) {
      return commentsMap[videoId]!;
    }
    final raw = MockData.COMMENTS[videoId] ?? [];
    return List<Map<String, dynamic>>.from(raw);
  }

  ReelsState copyWith({
    List<Map<String, dynamic>>? videos,
    Map<String, List<Map<String, dynamic>>>? commentsMap,
    Set<String>? likedVideoIds,
    Set<String>? bookmarkedVideoIds,
    Map<String, double>? userRatings,
  }) {
    return ReelsState(
      videos: videos ?? this.videos,
      commentsMap: commentsMap ?? this.commentsMap,
      likedVideoIds: likedVideoIds ?? this.likedVideoIds,
      bookmarkedVideoIds: bookmarkedVideoIds ?? this.bookmarkedVideoIds,
      userRatings: userRatings ?? this.userRatings,
    );
  }
}
