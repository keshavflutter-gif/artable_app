class UpdateProfileRequest {
  const UpdateProfileRequest({
    this.fullName = '',
    required this.firstName,
    this.middleName = '',
    this.lastName = '',
    required this.username,
    this.bio = '',
    this.category = '',
    this.socialLinks = const <String, dynamic>{},
    this.profileImage = '',
    this.coverImage = '',
  });

  final String fullName;
  final String firstName;
  final String middleName;
  final String lastName;
  final String username;
  final String bio;
  final String category;
  final dynamic socialLinks;
  final String profileImage;
  final String coverImage;

  Map<String, dynamic> toJson() {
    final computedFullName = fullName.trim().isNotEmpty
        ? fullName.trim()
        : [firstName, middleName, lastName]
            .where((s) => s.trim().isNotEmpty)
            .join(' ')
            .trim();

    return {
      if (computedFullName.isNotEmpty) 'fullName': computedFullName,
      if (computedFullName.isNotEmpty) 'name': computedFullName,
      'firstName': firstName.isNotEmpty ? firstName : computedFullName,
      'middleName': middleName,
      'lastName': lastName,
      'username': username,
      'bio': bio,
      'category': category,
      if (category.isNotEmpty) 'talentCategory': category,
      if (profileImage.isNotEmpty) 'profileImage': profileImage,
      if (profileImage.isNotEmpty) 'profilePhotoUrl': profileImage,
      if (profileImage.isNotEmpty) 'avatarUrl': profileImage,
      if (coverImage.isNotEmpty) 'coverImage': coverImage,
      if (coverImage.isNotEmpty) 'coverImageUrl': coverImage,
      if (coverImage.isNotEmpty) 'coverUrl': coverImage,
      'socialLinks': socialLinks is Map
          ? socialLinks
          : (socialLinks is List
              ? _listToMap(socialLinks as List)
              : <String, dynamic>{}),
    };
  }

  static Map<String, dynamic> _listToMap(List list) {
    final map = <String, dynamic>{};
    for (final item in list) {
      if (item is Map) {
        final url = item['url']?.toString() ??
            item['websiteUrl']?.toString() ??
            item['website']?.toString();
        if (url != null && url.isNotEmpty && url != 'https://') {
          if (url.contains('instagram.com')) {
            map['instagramUrl'] = url;
          } else if (url.contains('youtube.com') || url.contains('youtu.be')) {
            map['youtubeUrl'] = url;
          } else {
            map['websiteUrl'] = url;
          }
        }
      }
    }
    return map;
  }
}

