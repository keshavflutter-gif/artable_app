class FollowResponse {
  const FollowResponse({
    required this.success,
    required this.message,
    required this.following,
  });

  final bool success;
  final String message;
  final bool following;

  factory FollowResponse.fromJson(Map<String, dynamic> json) {
    final successVal = json['success'] == true ||
        json['status'] == 'success' ||
        json['status'] == true;
    final messageVal = json['message']?.toString() ?? '';

    bool followingVal = false;
    if (json.containsKey('following')) {
      followingVal = json['following'] == true || json['following']?.toString() == 'true';
    } else if (json.containsKey('isFollowing')) {
      followingVal = json['isFollowing'] == true || json['isFollowing']?.toString() == 'true';
    } else if (json.containsKey('is_following')) {
      followingVal = json['is_following'] == true || json['is_following']?.toString() == 'true';
    } else if (json['data'] is Map) {
      final dataMap = json['data'] as Map;
      followingVal = dataMap['following'] == true ||
          dataMap['isFollowing'] == true ||
          dataMap['is_following'] == true ||
          dataMap['following']?.toString() == 'true' ||
          dataMap['isFollowing']?.toString() == 'true' ||
          dataMap['is_following']?.toString() == 'true';
    }

    return FollowResponse(
      success: successVal,
      message: messageVal,
      following: followingVal,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'following': following,
      };
}
