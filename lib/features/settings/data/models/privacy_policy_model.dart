class PrivacySectionItem {
  const PrivacySectionItem({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  factory PrivacySectionItem.fromJson(Map<String, dynamic> json) {
    return PrivacySectionItem(
      title: json['title']?.toString().trim() ?? '',
      body: json['body']?.toString().trim() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'body': body,
      };
}

class PrivacyPolicyData {
  const PrivacyPolicyData({
    required this.id,
    required this.slug,
    required this.title,
    required this.lastUpdated,
    required this.tabs,
    required this.sections,
    this.isActive = true,
  });

  final String id;
  final String slug;
  final String title;
  final String lastUpdated;
  final List<String> tabs;
  final List<PrivacySectionItem> sections;
  final bool isActive;

  factory PrivacyPolicyData.fromJson(Map<String, dynamic> json) {
    final rawTabs = json['tabs'];
    final tabsList = <String>[];
    if (rawTabs is List) {
      for (final t in rawTabs) {
        final s = t?.toString().trim();
        if (s != null && s.isNotEmpty) tabsList.add(s);
      }
    }

    final rawSections = json['sections'];
    final sectionsList = <PrivacySectionItem>[];
    if (rawSections is List) {
      for (final s in rawSections) {
        if (s is Map) {
          sectionsList.add(
            PrivacySectionItem.fromJson(Map<String, dynamic>.from(s)),
          );
        }
      }
    }

    return PrivacyPolicyData(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? 'privacy-policy',
      title: json['title']?.toString() ?? 'Privacy Policy',
      lastUpdated: json['lastUpdated']?.toString() ?? json['last_updated']?.toString() ?? '',
      tabs: tabsList,
      sections: sectionsList,
      isActive: json['isActive'] == true || json['is_active'] == true,
    );
  }
}

typedef StaticPageData = PrivacyPolicyData;
typedef StaticSectionItem = PrivacySectionItem;
