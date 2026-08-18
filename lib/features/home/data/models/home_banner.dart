class HomeBanner {
  const HomeBanner({
    required this.id,
    required this.title,
    this.imageUrl,
    this.linkUrl,
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
  final String? placement;
  final String? startsAt;
  final String? endsAt;
  final bool? isActive;
  final String? createdAt;
  final String? updatedAt;

  factory HomeBanner.fromJson(Map<String, dynamic> json) {
    return HomeBanner(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      linkUrl: json['linkUrl']?.toString(),
      placement: json['placement']?.toString(),
      startsAt: json['startsAt']?.toString(),
      endsAt: json['endsAt']?.toString(),
      isActive: json['isActive'] as bool?,
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }
}
