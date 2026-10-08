class UserInfo {
  const UserInfo({
    required this.id,
    this.email,
    this.username,
    this.firstName,
    this.middleName,
    this.lastName,
    this.rawFullName,
    this.phoneNumber,
    this.gender,
    this.dob,
    this.bio,
    this.category,
    this.socialLinks,
    this.profilePhotoUrl,
    this.coverImageUrl,
    this.talentScore,
    this.challengesWon,
    this.rewardEarnings,
    this.isBlueTick,
    this.isVerified,
    this.isFollowing = false,
    this.rawJson,
    this.totalLikes = 0,
    this.totalViews = 0,
    this.totalVideos = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.topVideo,
    this.videos = const [],
    this.badges = const [],
    this.instagramUrl,
    this.youtubeUrl,
    this.websiteUrl,
  });

  final String id;
  final String? email;
  final String? username;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? rawFullName;
  final String? phoneNumber;
  final String? gender;
  final String? dob;
  final String? bio;
  final String? category;
  final List<Map<String, dynamic>>? socialLinks;
  final String? profilePhotoUrl;
  final String? coverImageUrl;
  final String? talentScore;
  final int? challengesWon;
  final String? rewardEarnings;
  final bool? isBlueTick;
  final bool? isVerified;
  final bool isFollowing;
  final Map<String, dynamic>? rawJson;
  final int totalLikes;
  final int totalViews;
  final int totalVideos;
  final int followersCount;
  final int followingCount;
  final Map<String, dynamic>? topVideo;
  final List<Map<String, dynamic>> videos;
  final List<dynamic> badges;
  final String? instagramUrl;
  final String? youtubeUrl;
  final String? websiteUrl;

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    String? first = json['firstName']?.toString() ?? json['first_name']?.toString();
    String? middle = json['middleName']?.toString() ?? json['middle_name']?.toString();
    String? last = json['lastName']?.toString() ?? json['last_name']?.toString();
    final uname = json['username']?.toString() ?? json['user_name']?.toString();

    final rawFullName = json['fullName']?.toString() ??
        json['full_name']?.toString() ??
        json['displayName']?.toString() ??
        json['display_name']?.toString() ??
        ((json['name'] != null && json['name'].toString() != uname) ? json['name'].toString() : null);

    if ((first == null || first.trim().isEmpty) && rawFullName != null && rawFullName.trim().isNotEmpty) {
      final parts = rawFullName.trim().split(RegExp(r'\s+'));
      if (parts.length == 1) {
        first = parts.first;
      } else if (parts.length == 2) {
        first = parts.first;
        last ??= parts.last;
      } else if (parts.length > 2) {
        first = parts.first;
        middle ??= parts.sublist(1, parts.length - 1).join(' ');
        last ??= parts.last;
      }
    }

    Map<String, dynamic>? parsedTopVideo;
    final topVidRaw = json['topVideo'] ?? json['top_video'];
    if (topVidRaw is Map) {
      parsedTopVideo = Map<String, dynamic>.from(topVidRaw);
    }

    final parsedVideos = <Map<String, dynamic>>[];
    final videosRaw = json['videos'];
    if (videosRaw is List) {
      for (final item in videosRaw) {
        if (item is Map) {
          parsedVideos.add(Map<String, dynamic>.from(item));
        }
      }
    }

    final parsedBadges = <dynamic>[];
    final badgesRaw = json['badges'];
    if (badgesRaw is List) {
      parsedBadges.addAll(badgesRaw);
    }

    return UserInfo(
      id: json['id']?.toString() ??
          json['_id']?.toString() ??
          json['userId']?.toString() ??
          json['user_id']?.toString() ??
          json['uid']?.toString() ??
          '',
      email: json['email']?.toString(),
      username: uname,
      firstName: first,
      middleName: middle,
      lastName: last,
      rawFullName: rawFullName,
      phoneNumber: json['phoneNumber']?.toString() ??
          json['phone']?.toString() ??
          json['mobile']?.toString(),
      gender: json['gender']?.toString(),
      dob: json['dob']?.toString(),
      bio: _parseBio(json),
      category: json['talentCategory']?.toString() ??
          json['talent_category']?.toString() ??
          json['category']?.toString() ??
          json['categoryName']?.toString() ??
          json['category_name']?.toString(),
      socialLinks: _parseSocialLinks(json),
      profilePhotoUrl: json['profilePhotoUrl']?.toString() ??
          json['profile_photo_url']?.toString() ??
          json['avatarUrl']?.toString() ??
          json['avatar_url']?.toString() ??
          json['photoUrl']?.toString(),
      coverImageUrl: json['coverImageUrl']?.toString() ??
          json['cover_image_url']?.toString() ??
          json['coverUrl']?.toString() ??
          json['cover_url']?.toString(),
      talentScore: json['talentScore']?.toString() ?? json['talent_score']?.toString(),
      challengesWon: _parseInt(json['challengesWon'] ?? json['challenges_won']),
      rewardEarnings: json['rewardEarnings']?.toString() ?? json['reward_earnings']?.toString(),
      isBlueTick: _parseBool(json['isBlueTick'] ?? json['is_blue_tick']),
      isVerified: _parseBool(json['isVerified'] ?? json['is_verified']),
      isFollowing: _parseBool(json['isFollowing'] ?? json['is_following'] ?? json['following']),
      totalLikes: _parseInt(json['totalLikes'] ?? json['total_likes']) ?? 0,
      totalViews: _parseInt(json['totalViews'] ?? json['total_views']) ?? 0,
      totalVideos: _parseInt(json['totalVideos'] ?? json['total_videos']) ?? 0,
      followersCount: _parseInt(json['followersCount'] ?? json['followers_count'] ?? json['followers']) ?? 0,
      followingCount: _parseInt(json['followingCount'] ?? json['following_count'] ?? json['following']) ?? 0,
      topVideo: parsedTopVideo,
      videos: parsedVideos,
      badges: parsedBadges,
      instagramUrl: json['instagramUrl']?.toString() ?? json['instagram_url']?.toString(),
      youtubeUrl: json['youtubeUrl']?.toString() ?? json['youtube_url']?.toString(),
      websiteUrl: json['websiteUrl']?.toString() ?? json['website_url']?.toString(),
      rawJson: json,
    );
  }

  static bool _parseBool(dynamic val) {
    if (val == null) return false;
    if (val == true || val == 1) return true;
    final str = val.toString().trim().toLowerCase();
    return str == 'true' || str == '1';
  }

  factory UserInfo.fromApiResponse(Map<String, dynamic> json) {
    final combined = Map<String, dynamic>.from(json);

    // Merge direct wrapper objects if present
    for (final key in [
      'data',
      'result',
      'response',
      'payload',
      'user',
      'userInfo',
      'userData',
      'profile',
      'userProfile',
      'userDetails',
      'user_details',
    ]) {
      final val = json[key];
      if (val is Map) {
        val.forEach((k, v) {
          if (v != null) combined[k.toString()] = v;
        });
      } else if (val is List && val.isNotEmpty && val.first is Map) {
        (val.first as Map).forEach((k, v) {
          if (v != null) combined[k.toString()] = v;
        });
      }
    }

    // Merge nested user/profile objects inside data
    if (json['data'] is Map) {
      final dataMap = json['data'] as Map;
      for (final key in [
        'user',
        'userInfo',
        'userData',
        'profile',
        'userProfile',
        'userDetails',
        'user_details',
      ]) {
        final val = dataMap[key];
        if (val is Map) {
          val.forEach((k, v) {
            if (v != null) combined[k.toString()] = v;
          });
        }
      }
    }

    return UserInfo.fromJson(combined);
  }

  static int? _parseInt(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString());
  }

  static String? _parseBio(Map<String, dynamic> json) {
    final candidateKeys = [
      'bio',
      'biography',
      'description',
      'user_description',
      'userDescription',
      'about',
      'aboutMe',
      'about_me',
      'userBio',
      'user_bio',
      'bioData',
      'bio_data',
      'biodata',
      'summary',
      'userSummary',
      'statusMessage',
      'status_message',
    ];

    for (final key in candidateKeys) {
      final val = json[key];
      if (val != null) {
        final str = val.toString().trim();
        if (str.isNotEmpty && str != 'null' && str != 'undefined') {
          return str;
        }
      }
    }

    for (final key in ['profile', 'user', 'userInfo', 'userData', 'data', 'userDetails', 'user_details']) {
      final nested = json[key];
      if (nested is Map) {
        for (final bioKey in candidateKeys) {
          final val = nested[bioKey];
          if (val != null) {
            final str = val.toString().trim();
            if (str.isNotEmpty && str != 'null' && str != 'undefined') {
              return str;
            }
          }
        }
      }
    }

    return null;
  }

  static List<Map<String, dynamic>>? _parseSocialLinks(dynamic source) {
    if (source == null) return null;

    final results = <Map<String, dynamic>>[];

    dynamic rawLinks;
    if (source is Map<String, dynamic> || source is Map) {
      rawLinks = source['socialLinks'] ?? source['social_links'];

      for (final key in ['websiteUrl', 'website_url', 'website', 'instagramUrl', 'instagram_url', 'instagram', 'youtubeUrl', 'youtube_url', 'youtube']) {
        final val = source[key]?.toString().trim();
        if (val != null && val.isNotEmpty && val != 'null' && val != 'undefined') {
          results.add({'platform': key, 'url': val});
        }
      }
    } else {
      rawLinks = source;
    }

    if (rawLinks is List) {
      for (final item in rawLinks) {
        if (item is Map) {
          results.add(Map<String, dynamic>.from(item));
        }
      }
    } else if (rawLinks is Map) {
      rawLinks.forEach((k, v) {
        if (v != null && v.toString().trim().isNotEmpty && v.toString().trim() != 'null') {
          results.add({'platform': k.toString(), 'url': v.toString().trim()});
        }
      });
    }

    return results.isNotEmpty ? results : null;
  }

  String get fullName {
    if (rawFullName != null && rawFullName!.trim().isNotEmpty && !_isPlaceholderName(rawFullName!)) {
      return rawFullName!.trim();
    }
    final parts = [firstName, middleName, lastName]
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty && !_isPlaceholderName(part))
        .toList();
    if (parts.isNotEmpty) return parts.join(' ');
    return '';
  }

  String get displayName {
    final full = fullName;
    if (full.isNotEmpty) return full;

    final usernameValue = username?.trim();
    if (usernameValue != null && usernameValue.isNotEmpty) {
      return usernameValue;
    }

    final emailValue = email?.trim();
    if (emailValue != null && emailValue.isNotEmpty) {
      return emailValue.split('@').first;
    }

    return '';
  }

  static bool isPlaceholderName(String value) {
    const placeholders = {'user', 'na', 'n/a'};
    return placeholders.contains(value.toLowerCase());
  }

  static bool _isPlaceholderName(String value) => isPlaceholderName(value);
}
