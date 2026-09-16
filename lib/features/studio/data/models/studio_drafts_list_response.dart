import 'save_studio_draft_response.dart';

class StudioDraftsListResponse {
  const StudioDraftsListResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool success;
  final String message;
  final List<StudioDraftItem> data;

  factory StudioDraftsListResponse.fromJson(Map<String, dynamic> json) {
    List<StudioDraftItem> items = [];
    final listRaw = json['data'];
    if (listRaw is List) {
      for (final raw in listRaw) {
        if (raw is Map) {
          final itemMap = Map<String, dynamic>.from(raw);
          if (itemMap['challenge'] is Map) {
            final ch = Map<String, dynamic>.from(itemMap['challenge'] as Map);
            if ((itemMap['title'] == null || itemMap['title'].toString().trim().isEmpty) &&
                ch['title'] != null) {
              itemMap['title'] = ch['title'];
            }
            if ((itemMap['thumbnailUrl'] == null || itemMap['thumbnailUrl'].toString().trim().isEmpty) &&
                ch['bannerUrl'] != null) {
              itemMap['thumbnailUrl'] = ch['bannerUrl'];
            }
          }
          items.add(StudioDraftItem.fromJson(itemMap));
        }
      }
    }

    return StudioDraftsListResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: items,
    );
  }
}
