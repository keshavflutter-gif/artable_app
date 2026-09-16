class SaveStudioDraftResponse {
  const SaveStudioDraftResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool success;
  final String message;
  final StudioDraftItem? data;

  factory SaveStudioDraftResponse.fromJson(Map<String, dynamic> json) {
    return SaveStudioDraftResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] is Map<String, dynamic>
          ? StudioDraftItem.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

class StudioDraftItem {
  const StudioDraftItem({
    required this.id,
    required this.userId,
    this.challengeId,
    this.categoryId,
    required this.title,
    this.description,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.hashtags,
    required this.status,
    this.rejectionReason,
    required this.durationSeconds,
    required this.views,
    required this.likes,
    required this.dislikes,
    required this.shares,
    required this.saves,
    required this.averageRating,
    required this.ratingCount,
    required this.isTrending,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String? challengeId;
  final String? categoryId;
  final String title;
  final String? description;
  final String videoUrl;
  final String thumbnailUrl;
  final List<String> hashtags;
  final String status;
  final String? rejectionReason;
  final int durationSeconds;
  final int views;
  final int likes;
  final int dislikes;
  final int shares;
  final int saves;
  final String averageRating;
  final int ratingCount;
  final bool isTrending;
  final String? createdAt;
  final String? updatedAt;

  factory StudioDraftItem.fromJson(Map<String, dynamic> json) {
    List<String> parsedHashtags = [];
    if (json['hashtags'] is List) {
      parsedHashtags = (json['hashtags'] as List)
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return StudioDraftItem(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      challengeId: json['challengeId']?.toString(),
      categoryId: json['categoryId']?.toString(),
      title: json['title']?.toString() ?? 'Draft Entry',
      description: json['description']?.toString(),
      videoUrl: json['videoUrl']?.toString() ?? '',
      thumbnailUrl: json['thumbnailUrl']?.toString() ?? '',
      hashtags: parsedHashtags,
      status: json['status']?.toString() ?? 'DRAFT',
      rejectionReason: json['rejectionReason']?.toString(),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      views: (json['views'] as num?)?.toInt() ?? 0,
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      dislikes: (json['dislikes'] as num?)?.toInt() ?? 0,
      shares: (json['shares'] as num?)?.toInt() ?? 0,
      saves: (json['saves'] as num?)?.toInt() ?? 0,
      averageRating: json['averageRating']?.toString() ?? '0',
      ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
      isTrending: json['isTrending'] as bool? ?? false,
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toUiMap() {
    final mins = durationSeconds ~/ 60;
    final secs = (durationSeconds % 60).toString().padLeft(2, '0');
    final durationStr = '$mins:$secs';

    return {
      'id': id,
      'userId': userId,
      'challengeId': challengeId,
      'categoryId': categoryId,
      'title': title,
      'challengeTitle': title,
      'description': description,
      'videoUrl': videoUrl,
      'videoPath': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'imageUrl': thumbnailUrl,
      'hashtags': hashtags,
      'status': status,
      'durationSeconds': durationSeconds,
      'duration': durationStr,
      'views': views,
      'likes': likes,
      'dislikes': dislikes,
      'shares': shares,
      'saves': saves,
      'averageRating': averageRating,
      'ratingCount': ratingCount,
      'isTrending': isTrending,
      'createdAt': createdAt,
      'recordedAt': createdAt ?? DateTime.now().toIso8601String(),
      'updatedAt': updatedAt,
    };
  }
}
