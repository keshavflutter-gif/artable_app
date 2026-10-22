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
      if (clean.contains('loremflickr.com')) {
        if (clean.contains('dance')) {
          return 'https://images.unsplash.com/photo-1547153760-18fc86324498?w=700&h=440&q=80&fit=crop';
        } else if (clean.contains('singer') || clean.contains('concert') || clean.contains('music')) {
          return 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=700&h=440&q=80&fit=crop';
        } else if (clean.contains('comedian') || clean.contains('standup')) {
          return 'https://images.unsplash.com/photo-1585699324551-f6c309eedeca?w=700&h=440&q=80&fit=crop';
        } else if (clean.contains('fitness') || clean.contains('workout') || clean.contains('athlete') || clean.contains('sports')) {
          return 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=700&h=440&q=80&fit=crop';
        } else if (clean.contains('magician') || clean.contains('magic')) {
          return 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=700&h=440&q=80&fit=crop';
        } else if (clean.contains('painter') || clean.contains('artist')) {
          return 'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?w=700&h=440&q=80&fit=crop';
        } else if (clean.contains('actor') || clean.contains('theater')) {
          return 'https://images.unsplash.com/photo-1507676184212-d03ab07a01bf?w=700&h=440&q=80&fit=crop';
        } else if (clean.contains('portrait') || clean.contains('woman')) {
          return 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=120&h=120&q=80&fit=crop';
        } else if (clean.contains('man')) {
          return 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=120&h=120&q=80&fit=crop';
        }
        return 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=700&h=440&q=80&fit=crop';
      }
      return clean;
    }

    // Absolute local filesystem path on mobile or desktop
    if (clean.startsWith('/data/') ||
        clean.startsWith('/storage/') ||
        clean.startsWith('/sdcard/') ||
        clean.startsWith('/var/') ||
        clean.contains(':\\') ||
        clean.contains(':/') ||
        File(clean).existsSync()) {
      return clean;
    }

    // Relative server path e.g. /uploads/xxx.jpg, uploads/xxx.jpg, thumbnails/xxx.jpg
    final base = ApiConfig.baseUrl.replaceAll(RegExp(r'/$'), '');
    final cleanRel = clean.replaceFirst(RegExp(r'^/+'), '');
    return '$base/$cleanRel';
  }

  static String? extractThumbnail(Map<String, dynamic> json) {
    const directKeys = [
      'thumbnailUrl',
      'thumbnail_url',
      'videoThumbnail',
      'video_thumbnail',
      'posterUrl',
      'poster_url',
      'thumbnail',
      'thumb',
    ];
    for (final k in directKeys) {
      final v = json[k];
      if (v is String) {
        final resolved = resolve(v);
        if (resolved.isNotEmpty &&
            !looksLikeVideoUrl(resolved) &&
            !isDummyThumbnail(resolved)) {
          return resolved;
        }
      } else if (v is Map) {
        final nested = extractThumbnail(Map<String, dynamic>.from(v));
        if (nested != null && nested.isNotEmpty) return nested;
      }
    }
    // Also check 'imageUrl' only if it's on the root video object and NOT a dummy/banner image
    final directImg = json['imageUrl'] ?? json['image_url'];
    if (directImg is String) {
      final resolved = resolve(directImg);
      if (resolved.isNotEmpty &&
          !looksLikeVideoUrl(resolved) &&
          !isDummyThumbnail(resolved)) {
        return resolved;
      }
    } else if (directImg is Map) {
      final nested = extractThumbnail(Map<String, dynamic>.from(directImg));
      if (nested != null && nested.isNotEmpty) return nested;
    }
    return null;
  }

  /// Detects whether an image URL is truly a dummy placeholder, mock data, or invalid.
  static bool isDummyThumbnail(String? url) {
    if (url == null) return true;
    final clean = url.trim().toLowerCase();
    if (clean.isEmpty ||
        clean == 'null' ||
        clean == 'undefined' ||
        clean.contains('storage.example') ||
        clean.contains('example.com')) {
      return true;
    }
    // Check for dummy / mock thumbnail patterns
    if (clean.contains('dummy') ||
        clean.contains('placeholder') ||
        clean.contains('16x16') ||
        clean.contains('unsplash') ||
        clean.contains('loremflickr') ||
        clean.contains('picsum') ||
        clean.contains('pravatar') ||
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
