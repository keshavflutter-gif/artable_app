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
      item['username'],
      item['handle'],
    ]);
    final handle = username.isNotEmpty
        ? (username.startsWith('@') ? username : '@$username')
        : '@creator';

    final creator = _firstNonEmptyString([
      user?['fullName'],
      user?['name'],
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
      item['imageUrl'],
      item['coverUrl'],
      item['videoThumbnail'],
      item['thumbnail'],
    ]);

    final rawViews = item['views'];
    String viewsStr = '0';
    if (rawViews is num) {
      viewsStr = _formatCompactNumber(rawViews);
    } else if (rawViews != null && rawViews.toString().isNotEmpty) {
      viewsStr = rawViews.toString();
    }

    String categoryStr = 'Talent';
    if (item['category'] is String &&
        (item['category'] as String).isNotEmpty) {
      categoryStr = item['category'] as String;
    } else if (item['category'] is Map && item['category']['name'] != null) {
      categoryStr = item['category']['name'].toString();
    } else if (item['categoryName'] != null &&
        item['categoryName'].toString().isNotEmpty) {
      categoryStr = item['categoryName'].toString();
    }

    return {
      'id': _stringValue(item['id']),
      'title': _stringValue(item['title']),
      'category': categoryStr,
      'imageUrl': thumb.isNotEmpty
          ? thumb
          : 'https://images.unsplash.com/photo-1518834107812-67b0b7c58434?w=600&q=80',
      'views': viewsStr,
      'avatarUrl': avatarUrl.isNotEmpty
          ? avatarUrl
          : 'https://i.pravatar.cc/100?u=${item['id'] ?? 'user'}',
      'handle': handle,
      'creator': creator.isNotEmpty ? creator : handle,
      'verified': user?['verified'] == true || item['verified'] == true,
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
