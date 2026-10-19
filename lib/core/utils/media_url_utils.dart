import 'dart:io';

import 'package:artable_app/core/network/api_config.dart';

/// Normalizes API media URLs for display (relative paths, nested maps, etc.).
class MediaUrlUtils {
  MediaUrlUtils._();

  static bool looksLikeVideoUrl(String url) {
    final lower = url.toLowerCase().split('?').first;
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.m4v') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.3gp');
  }

  static bool looksLikeImageUrl(String url) {
    final lower = url.toLowerCase().split('?').first;
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.bmp');
  }

  /// Turns relative API paths into absolute URLs. Leaves http(s) and local files alone.
  static String resolve(String? raw) {
    if (raw == null) return '';
    var clean = raw.trim();
    if (clean.isEmpty || clean == 'null' || clean.contains('storage.example')) {
      return '';
    }
    if (clean.startsWith('file://')) {
      return clean.replaceFirst('file://', '');
    }
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return clean;
    }

    // Absolute local filesystem path
    if ((clean.startsWith('/') || clean.contains(':\\') || clean.contains(':/')) &&
        File(clean).existsSync()) {
      return clean;
    }

    // Relative server path e.g. /uploads/xxx.jpg, uploads/xxx.jpg, thumbnails/xxx.jpg
    final base = ApiConfig.baseUrl.replaceAll(RegExp(r'/$'), '');
    final cleanRel = clean.replaceFirst(RegExp(r'^/+'), '');
    return '$base/$cleanRel';
  }

  static String? extractThumbnail(Map<String, dynamic> json) {
    const keys = [
      'thumbnailUrl',
      'thumbnail_url',
      'videoThumbnail',
      'video_thumbnail',
      'imageUrl',
      'image_url',
      'coverUrl',
      'cover_url',
      'posterUrl',
      'poster_url',
      'thumbnail',
      'thumb',
      'previewUrl',
      'preview_url',
    ];
    for (final k in keys) {
      final v = json[k];
      if (v is String) {
        final resolved = resolve(v);
        if (resolved.isNotEmpty && !looksLikeVideoUrl(resolved)) {
          return resolved;
        }
      } else if (v is Map) {
        final nested = extractThumbnail(Map<String, dynamic>.from(v));
        if (nested != null && nested.isNotEmpty) return nested;
      }
    }
    return null;
  }

  /// Detects whether an image URL is a dummy placeholder or invalid.
  static bool isDummyThumbnail(String? url) {
    if (url == null) return true;
    final clean = url.trim().toLowerCase();
    if (clean.isEmpty || clean == 'null' || clean.contains('storage.example')) {
      return true;
    }
    // Check for dummy thumbnail patterns
    if (clean.contains('dummy') ||
        clean.contains('placeholder') ||
        clean.contains('16x16') ||
        looksLikeVideoUrl(clean)) {
      return true;
    }
    return false;
  }

  static String? extractVideoUrl(Map<String, dynamic> json) {
    const keys = [
      'videoUrl',
      'video_url',
      'mediaUrl',
      'media_url',
      'videoPath',
      'video_path',
      'fileUrl',
      'file_url',
      'streamUrl',
      'stream_url',
      'clips',
      'mergedClips',
      'merged_clips',
      'mergedClipPaths',
      'merged_clip_paths',
      'media',
      'video',
      'url',
    ];
    for (final k in keys) {
      final v = json[k];
      if (v is String) {
        final resolved = resolve(v);
        if (resolved.isNotEmpty && !looksLikeImageUrl(resolved)) {
          return resolved;
        }
      } else if (v is List && v.isNotEmpty) {
        for (final item in v) {
          if (item is String) {
            final resolved = resolve(item);
            if (resolved.isNotEmpty && !looksLikeImageUrl(resolved)) {
              return resolved;
            }
          } else if (item is Map) {
            final nested = extractVideoUrl(Map<String, dynamic>.from(item));
            if (nested != null && nested.isNotEmpty) return nested;
          }
        }
      } else if (v is Map) {
        final nested = extractVideoUrl(Map<String, dynamic>.from(v));
        if (nested != null && nested.isNotEmpty) return nested;
      }
    }
    return null;
  }
}
