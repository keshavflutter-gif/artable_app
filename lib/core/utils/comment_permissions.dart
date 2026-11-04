/// Comment delete rules:
/// - Comment author can delete their own comment
/// - Video owner can delete any comment on their video
/// - Everyone else cannot delete
abstract final class CommentPermissions {
  CommentPermissions._();

  static String? _cleanId(dynamic raw) {
    final v = raw?.toString().trim() ?? '';
    if (v.isEmpty || v == 'null' || v == 'default_user') return null;
    return v;
  }

  static String? commentAuthorId(Map<String, dynamic> comment) {
    final direct = _cleanId(
      comment['userId'] ??
          comment['user_id'] ??
          comment['authorId'] ??
          comment['author_id'] ??
          comment['createdBy'] ??
          comment['created_by'],
    );
    if (direct != null) return direct;

    final user = comment['user'];
    if (user is Map) {
      return _cleanId(user['id'] ?? user['_id'] ?? user['userId'] ?? user['user_id']);
    }
    return null;
  }

  static String? videoOwnerId(Map<String, dynamic>? video) {
    if (video == null) return null;
    final direct = _cleanId(
      video['userId'] ??
          video['user_id'] ??
          video['creatorId'] ??
          video['creator_id'] ??
          video['ownerId'] ??
          video['owner_id'],
    );
    if (direct != null) return direct;

    for (final key in ['user', 'creator', 'author', 'owner']) {
      final nested = video[key];
      if (nested is Map) {
        final id = _cleanId(nested['id'] ?? nested['_id'] ?? nested['userId']);
        if (id != null) return id;
      }
    }
    return null;
  }

  static bool canDeleteComment({
    required String? currentUserId,
    required Map<String, dynamic> comment,
    Map<String, dynamic>? video,
  }) {
    final me = _cleanId(currentUserId);
    if (me == null) return false;

    final authorId = commentAuthorId(comment);
    if (authorId != null && authorId == me) return true;

    final ownerId = videoOwnerId(video);
    if (ownerId != null && ownerId == me) return true;

    // Explicit flags from API if provided
    if (comment['canDelete'] == true || comment['can_delete'] == true) {
      return true;
    }
    // Own video: owner may delete any comment on it
    if (video?['isMyVideo'] == true) {
      return true;
    }

    return false;
  }
}
