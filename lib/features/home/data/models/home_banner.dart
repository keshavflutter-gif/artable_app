class HomeBanner {
  const HomeBanner({
    required this.id,
    required this.title,
    this.imageUrl,
    this.linkUrl,
    this.challengeId,
    this.placement,
    this.startsAt,
    this.endsAt,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String? imageUrl;
  final String? linkUrl;
  /// Linked challenge when this banner promotes a specific challenge.
  final String? challengeId;
  final String? placement;
  final String? startsAt;
  final String? endsAt;
  final bool? isActive;
  final String? createdAt;
  final String? updatedAt;

  factory HomeBanner.fromJson(Map<String, dynamic> json) {
    final linkUrl = json['linkUrl']?.toString();
    final explicitChallengeId = json['challengeId']?.toString() ??
        json['challenge_id']?.toString() ??
        json['targetChallengeId']?.toString();
    return HomeBanner(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      linkUrl: linkUrl,
      challengeId: (explicitChallengeId != null &&
              explicitChallengeId.trim().isNotEmpty)
          ? explicitChallengeId.trim()
          : _challengeIdFromLink(linkUrl),
      placement: json['placement']?.toString(),
      startsAt: json['startsAt']?.toString(),
      endsAt: json['endsAt']?.toString(),
      isActive: json['isActive'] as bool?,
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  static String? _challengeIdFromLink(String? link) {
    final raw = link?.trim() ?? '';
    if (raw.isEmpty) return null;
    try {
      final uri = Uri.parse(raw.startsWith('http') || raw.startsWith('/')
          ? raw
          : 'https://local$raw');
      final qp = uri.queryParameters['id'] ??
          uri.queryParameters['challengeId'] ??
          uri.queryParameters['challenge_id'];
      if (qp != null && qp.trim().isNotEmpty) return qp.trim();
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      final idx = segments.indexWhere(
        (s) => s == 'challenge-detail' || s == 'challenges' || s == 'challenge',
      );
      if (idx >= 0 && idx + 1 < segments.length) {
        final next = segments[idx + 1].trim();
        if (next.isNotEmpty && next != 'active' && next != 'completed') {
          return next;
        }
      }
    } catch (_) {}
    return null;
  }
}
