import 'package:artable_app/features/trending/data/models/trending_videos_response.dart';
import 'home_banner.dart';

class HomeUiMapper {
  HomeUiMapper._();

  static Map<String, dynamic> bannerToMegaPromo(HomeBanner banner) {
    return {
      'tag': banner.placement?.trim().isNotEmpty == true
          ? banner.placement!
          : 'Featured',
      'icon': 'trophy',
      'countdown': _countdownDaysFromEndsAt(banner.endsAt),
      'title': banner.title,
      'subtitle': banner.linkUrl?.trim().isNotEmpty == true
          ? banner.linkUrl!
          : '',
      'ctaLabel': 'Join Now',
      'imageUrl': banner.imageUrl ?? '',
      'linkUrl': banner.linkUrl,
      'id': banner.id,
    };
  }

  static Map<String, dynamic> bannerToHeroSlide(HomeBanner banner) {
    return {
      'imageUrl': banner.imageUrl ?? '',
      'title': banner.title,
      'subtitle': banner.placement?.trim().isNotEmpty == true
          ? banner.placement!
          : '',
      'cta': 'View',
      'linkUrl': banner.linkUrl,
      'id': banner.id,
    };
  }

  static Map<String, dynamic> featuredChallengeToUiMap(
      Map<String, dynamic> item) {
    final image = _firstNonEmptyString([
      item['bannerUrl'],
      item['imageUrl'],
      item['coverUrl'],
      item['banner'],
      item['image'],
    ]);

    final timeLeft = _firstNonEmptyString([
      item['daysLeftLabel'],
      item['timeLeft'],
      item['endDateLabel'],
      item['daysLeft'] != null ? '${item['daysLeft']} days left' : null,
    ]);

    final prize = _firstNonEmptyString([
      item['prizePoolLabel'],
      item['prize'],
      item['prizePool'],
      item['totalPrize'],
    ]);

    return {
      'id': _stringValue(item['id']),
      'title': _stringValue(item['title']),
      'timeLeft': timeLeft.isNotEmpty ? timeLeft : 'Active',
      'prize': prize.isNotEmpty ? prize : '₹5,000',
      'imageUrl': image.isNotEmpty
          ? image
          : 'https://images.unsplash.com/photo-1547153760-18fc86324498?w=800&q=80',
      'category': _stringValue(item['categoryName'] ?? item['category']),
      'joinedLabel': _stringValue(item['joinedLabel']),
    };
  }

  static Map<String, dynamic> trendingVideoToUiMap(Map<String, dynamic> item) {
    final user = item['user'] is Map
        ? Map<String, dynamic>.from(item['user'] as Map)
        : null;

    final username = _firstNonEmptyString([
      user?['username'],
      user?['handle'],
      user?['name'],
      item['username'],
      item['handle'],
    ]);
    final handle = username.isNotEmpty
        ? (username.startsWith('@') ? username : '@$username')
        : '@user';

    final creator = _firstNonEmptyString([
      user?['fullName'],
      user?['name'],
      user?['username'],
      item['creator'],
      item['authorName'],
    ]);

    final avatarUrl = _firstNonEmptyString([
      user?['profilePhotoUrl'],
      user?['avatarUrl'],
      item['avatarUrl'],
    ]);

    final thumb = _firstNonEmptyString([
      item['thumbnailUrl'],
      item['thumbnail_url'],
      item['imageUrl'],
      item['image_url'],
      item['coverUrl'],
      item['cover_url'],
      item['videoThumbnail'],
      item['video_thumbnail'],
      item['thumbnail'],
      item['posterUrl'],
      item['poster_url'],
    ]);

    final videoUrl = _firstNonEmptyString([
      item['videoUrl'],
      item['video_url'],
      item['mediaUrl'],
      item['media_url'],
      item['videoPath'],
      item['video_path'],
      item['fileUrl'],
      item['file_url'],
      item['url'],
      item['streamUrl'],
      item['stream_url'],
      item['video'],
      item['path'],
    ]);

    final rawViews = item['viewsLabel'] ?? item['views'] ?? item['viewCount'];
    String viewsStr = '0';
    if (rawViews is num) {
      viewsStr = _formatCompactNumber(rawViews);
    } else if (rawViews != null && rawViews.toString().trim().isNotEmpty) {
      viewsStr = rawViews.toString().trim();
    }

    String categoryStr = 'TALENT';
    if (item['categoryBadge'] != null &&
        item['categoryBadge'].toString().trim().isNotEmpty) {
      categoryStr = item['categoryBadge'].toString().trim();
    } else if (item['badgeLabel'] != null &&
        item['badgeLabel'].toString().trim().isNotEmpty) {
      categoryStr = item['badgeLabel'].toString().trim();
    } else if (item['category'] is String &&
        (item['category'] as String).trim().isNotEmpty) {
      categoryStr = (item['category'] as String).trim();
    } else if (item['category'] is Map &&
        item['category']['name'] != null &&
        item['category']['name'].toString().trim().isNotEmpty) {
      categoryStr = item['category']['name'].toString().trim();
    } else if (item['categoryName'] != null &&
        item['categoryName'].toString().trim().isNotEmpty) {
      categoryStr = item['categoryName'].toString().trim();
    } else if (item['statusBadge'] is Map &&
        item['statusBadge']['label'] != null &&
        item['statusBadge']['label'].toString().trim().isNotEmpty) {
      categoryStr = item['statusBadge']['label'].toString().trim();
    }

    final rawDescription = _firstNonEmptyString([
      item['description'],
      item['caption'],
      item['title'],
    ]);

    String formattedHashtags = '';
    final rawHashtags = item['hashtags'] ?? item['tags'] ?? item['hashTags'];
    if (rawHashtags is List) {
      formattedHashtags = rawHashtags
          .map((e) => e.toString().trim().replaceAll(RegExp(r'^#+'), ''))
          .where((e) => e.isNotEmpty)
          .map((e) => '#$e')
          .join(' ');
    } else if (rawHashtags is String && rawHashtags.trim().isNotEmpty) {
      formattedHashtags = rawHashtags
          .split(RegExp(r'[\s,\n]+'))
          .map((e) => e.trim().replaceAll(RegExp(r'^#+'), ''))
          .where((e) => e.isNotEmpty)
          .map((e) => '#$e')
          .join(' ');
    }

    final cleanRawDesc = rawDescription.replaceAll(RegExp(r'#+'), '#');

    String finalCaption = '';
    if (cleanRawDesc.isNotEmpty && formattedHashtags.isNotEmpty) {
      if (cleanRawDesc.contains('#')) {
        finalCaption = cleanRawDesc;
      } else {
        finalCaption = '$cleanRawDesc $formattedHashtags';
      }
    } else if (cleanRawDesc.isNotEmpty) {
      finalCaption = cleanRawDesc;
    } else if (formattedHashtags.isNotEmpty) {
      finalCaption = formattedHashtags;
    }

    final challengeTitleStr = _firstNonEmptyString([
      item['challengeTitle'],
      item['challenge'] is Map ? item['challenge']['title'] : null,
    ]);

    final rawLikes = TrendingVideoItem.parseCount(
      item['likesCount'] ?? item['likes_count'] ?? item['likeCount'] ?? item['likes'] ?? item['_count']?['likes'],
    );
    final rawComments = TrendingVideoItem.parseCount(
      item['commentsCount'] ?? item['comments_count'] ?? item['commentCount'] ?? item['comments'] ?? item['_count']?['comments'],
    );
    final rawShares = TrendingVideoItem.parseCount(
      item['sharesCount'] ?? item['shares_count'] ?? item['shareCount'] ?? item['shares'] ?? item['_count']?['shares'],
    );
    final parsedViews = TrendingVideoItem.parseCount(
      item['viewsCount'] ?? item['views_count'] ?? item['viewCount'] ?? item['views'] ?? item['_count']?['views'],
    );

    final isLikedBool = item['isLiked'] == true ||
        item['liked'] == true ||
        item['hasLiked'] == true ||
        item['userLiked'] == true ||
        item['userReaction']?.toString().toLowerCase() == 'like';

    return {
      'id': _stringValue(item['id']),
      'title': _stringValue(item['title']),
      'caption': finalCaption,
      'category': categoryStr,
      'imageUrl': thumb,
      'thumbnailUrl': thumb,
      'videoUrl': videoUrl,
      'views': viewsStr.isNotEmpty ? viewsStr : _formatCompactNumber(parsedViews),
      'viewsCount': parsedViews,
      'likes': item['likesLabel'] != null
          ? item['likesLabel'].toString()
          : _formatCompactNumber(rawLikes),
      'likesCount': rawLikes,
      'isLiked': isLikedBool,
      'liked': isLikedBool,
      'comments': item['commentsLabel'] != null
          ? item['commentsLabel'].toString()
          : _formatCompactNumber(rawComments),
      'commentsCount': rawComments,
      'shares': item['sharesLabel'] != null
          ? item['sharesLabel'].toString()
          : _formatCompactNumber(rawShares),
      'sharesCount': rawShares,
      'musicName': _firstNonEmptyString([item['musicName'], item['music']]).isNotEmpty
          ? _firstNonEmptyString([item['musicName'], item['music']])
          : (creator.isNotEmpty ? 'Original Sound — $creator' : (handle.isNotEmpty ? 'Original Sound — $handle' : 'Original Sound')),
      'avatarUrl': avatarUrl,
      'handle': handle,
      'creator': creator.isNotEmpty ? creator : handle,
      'verified': user?['isVerified'] == true ||
          user?['verified'] == true ||
          item['verified'] == true,
      'challengeId': item['challengeId'] ?? (item['challenge'] is Map ? item['challenge']['id'] : ''),
      'challengeTitle': challengeTitleStr,
    };
  }

  static String _formatCompactNumber(num value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1).replaceAll('.0', '')}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1).replaceAll('.0', '')}K';
    }
    return value.toInt().toString();
  }

  static String _countdownDaysFromEndsAt(String? endsAt) {
    if (endsAt == null || endsAt.trim().isEmpty) return '0';
    final parsed = DateTime.tryParse(endsAt);
    if (parsed == null) return '0';
    final days = parsed.difference(DateTime.now().toUtc()).inDays;
    return days < 0 ? '0' : days.toString();
  }

  static String _stringValue(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return '';
    return text;
  }

  static String _firstNonEmptyString(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null &&
          text.isNotEmpty &&
          text != 'null' &&
          text != 'undefined') {
        return text;
      }
    }
    return '';
  }
}
