Map<String, dynamic> notificationToUiMap(Map<String, dynamic> json) {
  final category = (json['category'] ??
          json['type'] ??
          json['channel'] ??
          'general')
      .toString()
      .toLowerCase();

  final data = json['data'] is Map
      ? Map<String, dynamic>.from(json['data'] as Map)
      : json['payload'] is Map
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : const <String, dynamic>{};

  return {
    'id': json['id']?.toString() ?? '',
    'title': json['title']?.toString() ??
        json['heading']?.toString() ??
        'Notification',
    'description': json['description']?.toString() ??
        json['body']?.toString() ??
        json['message']?.toString() ??
        '',
    'time': json['time']?.toString() ??
        json['timeAgo']?.toString() ??
        json['createdAt']?.toString() ??
        '',
    'read': json['read'] == true || json['isRead'] == true,
    'category': category,
    'avatarUrl': json['avatarUrl']?.toString() ?? json['imageUrl']?.toString(),
    'icon': json['icon']?.toString(),
    'route': (json['route'] ?? data['route'])?.toString() ?? '',
    'screen': (json['screen'] ?? data['screen'])?.toString() ?? '',
    'targetId': (json['targetId'] ??
            json['entityId'] ??
            json['challengeId'] ??
            json['videoId'] ??
            json['rewardId'] ??
            json['userId'] ??
            data['id'] ??
            data['challengeId'] ??
            data['videoId'] ??
            data['rewardId'] ??
            data['userId'] ??
            '')
        .toString(),
    'type': (json['type'] ?? data['type'] ?? category).toString().toLowerCase(),
  };
}

Map<String, dynamic> activityToUiMap(Map<String, dynamic> json) {
  return {
    'id': json['id']?.toString() ?? '',
    'type': (json['type'] ?? json['category'] ?? 'general')
        .toString()
        .toLowerCase(),
    'text': json['text']?.toString() ??
        json['title']?.toString() ??
        json['message']?.toString() ??
        '',
    'related': json['related']?.toString() ??
        json['subtitle']?.toString() ??
        json['context']?.toString() ??
        '',
    'time': json['time']?.toString() ??
        json['timeAgo']?.toString() ??
        json['createdAt']?.toString() ??
        '',
  };
}

String searchFilterToApiCategory(String filter) {
  switch (filter) {
    case 'Challenges':
      return 'challenges';
    case 'Rewards':
      return 'rewards';
    case 'Winners':
      return 'winners';
    case 'Social':
      return 'social';
    case 'Referrals':
      return 'referrals';
    default:
      return 'all';
  }
}

String activityFilterToApiType(String filter) {
  switch (filter) {
    case 'Likes':
      return 'likes';
    case 'Comments':
      return 'comments';
    case 'Ratings':
      return 'ratings';
    case 'Challenges':
      return 'challenges';
    case 'Rewards':
      return 'rewards';
    default:
      return 'all';
  }
}

Map<String, dynamic> searchVideoToUi(Map<String, dynamic> v) {
  return {
    'id': v['id']?.toString() ?? '',
    'title': v['title']?.toString() ?? '',
    'thumbnailUrl':
        v['thumbnailUrl']?.toString() ?? v['imageUrl']?.toString() ?? '',
    'videoUrl': v['videoUrl']?.toString() ?? v['url']?.toString(),
    'creatorName': v['creatorName']?.toString() ??
        v['authorName']?.toString() ??
        v['userName']?.toString() ??
        '',
  };
}

Map<String, dynamic> searchCreatorToUi(Map<String, dynamic> c) {
  return {
    'id': c['id']?.toString() ?? '',
    'name': c['name']?.toString() ?? c['fullName']?.toString() ?? '',
    'handle': c['handle']?.toString() ?? c['username']?.toString() ?? '',
    'avatarUrl':
        c['avatarUrl']?.toString() ?? c['profileImage']?.toString() ?? '',
  };
}

Map<String, dynamic> searchChallengeToUi(Map<String, dynamic> c) {
  return {
    'id': c['id']?.toString() ?? '',
    'title': c['title']?.toString() ?? '',
    'imageUrl': c['imageUrl']?.toString() ?? c['bannerUrl']?.toString() ?? '',
    'category': c['category']?.toString() ?? '',
    'entryFee': c['entryFee']?.toString() ?? c['fee']?.toString() ?? 'Free',
  };
}