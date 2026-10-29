import 'package:flutter/material.dart';

import 'package:artable_app/data/datasources/mock_data.dart';

import 'dart:convert';
import 'package:artable_app/core/storage/local_storage.dart';

class ReelMusicMeta {
  const ReelMusicMeta({
    required this.url,
    required this.name,
    this.startSeconds = 0,
    this.durationSeconds = 0,
  });

  final String url;
  final String name;
  final double startSeconds;
  final double durationSeconds;

  Map<String, dynamic> toJson() => {
        'url': url,
        'name': name,
        'start': startSeconds,
        'duration': durationSeconds,
      };

  factory ReelMusicMeta.fromJson(Map<dynamic, dynamic> json) {
    return ReelMusicMeta(
      url: json['url']?.toString().trim() ?? '',
      name: json['name']?.toString().trim() ?? '',
      startSeconds: (json['start'] as num?)?.toDouble() ?? 0,
      durationSeconds: (json['duration'] as num?)?.toDouble() ?? 0,
    );
  }
}

abstract final class ReelHelpers {
  static final RegExp _clipsRegex = RegExp(r'<!--artable_clips:(.*?)-->', dotAll: true);
  static final RegExp _legacyClipsRegex = RegExp(r'\[CLIPS:(.*?)\]');
  static final RegExp _musicRegex = RegExp(r'<!--artable_music:(.*?)-->', dotAll: true);
  static final RegExp _filterRegex = RegExp(r'<!--artable_filter:(.*?)-->', dotAll: true);

  /// Extracts clips list from description if embedded.
  static ({String cleanDescription, List<String>? clips}) parseDescriptionClips(String? description) {
    if (description == null || description.isEmpty) {
      return (cleanDescription: '', clips: null);
    }

    final match = _clipsRegex.firstMatch(description);
    if (match != null) {
      final jsonStr = match.group(1)?.trim();
      final clean = description.replaceAll(_clipsRegex, '').trim();
      if (jsonStr != null && jsonStr.isNotEmpty) {
        try {
          final decoded = jsonDecode(jsonStr);
          if (decoded is List) {
            final list = decoded
                .map((e) => e.toString().trim())
                .where((e) => e.isNotEmpty && e != 'null')
                .toList();
            if (list.length > 1) {
              return (cleanDescription: clean, clips: list);
            }
          }
        } catch (_) {}
      }
      return (cleanDescription: clean, clips: null);
    }

    final legacyMatch = _legacyClipsRegex.firstMatch(description);
    if (legacyMatch != null) {
      final raw = legacyMatch.group(1)?.trim();
      final clean = description.replaceAll(_legacyClipsRegex, '').trim();
      if (raw != null && raw.isNotEmpty) {
        final list = raw
            .split('|')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty && e != 'null')
            .toList();
        if (list.length > 1) {
          return (cleanDescription: clean, clips: list);
        }
      }
      return (cleanDescription: clean, clips: null);
    }

    return (
      cleanDescription: description
          .replaceAll(_clipsRegex, '')
          .replaceAll(_legacyClipsRegex, '')
          .trim(),
      clips: null,
    );
  }

  static String cleanDescription(String? description) {
    if (description == null || description.isEmpty) return '';
    return description
        .replaceAll(_clipsRegex, '')
        .replaceAll(_legacyClipsRegex, '')
        .replaceAll(_musicRegex, '')
        .replaceAll(_filterRegex, '')
        .trim();
  }

  static ({String filterId, bool beautyOn, double beautyIntensity})?
      parseDescriptionFilter(String? description) {
    if (description == null || description.isEmpty) return null;
    final match = _filterRegex.firstMatch(description);
    final jsonStr = match?.group(1)?.trim();
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map) {
        final id = decoded['id']?.toString().trim() ?? '';
        if (id.isEmpty || id == 'natural') return null;
        return (
          filterId: id,
          beautyOn: decoded['beautyOn'] == true,
          beautyIntensity: (decoded['beautyIntensity'] as num?)?.toDouble() ?? 0,
        );
      }
    } catch (_) {}
    return null;
  }

  static String embedFilterInDescription(
    String? description, {
    String? filterId,
    bool beautyOn = false,
    double beautyIntensity = 0,
  }) {
    final stripped = (description ?? '').replaceAll(_filterRegex, '').trim();
    final id = filterId?.trim() ?? '';
    if (id.isEmpty || id == 'natural') {
      if (!beautyOn) return stripped;
    }
    final tag = '<!--artable_filter:${jsonEncode({
      'id': id.isEmpty ? 'natural' : id,
      'beautyOn': beautyOn,
      'beautyIntensity': beautyIntensity,
    })}-->';
    return stripped.isEmpty ? tag : '$stripped\n$tag';
  }

  static ReelMusicMeta? parseDescriptionMusic(String? description) {
    if (description == null || description.isEmpty) return null;
    final match = _musicRegex.firstMatch(description);
    final jsonStr = match?.group(1)?.trim();
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map) {
        final meta = ReelMusicMeta.fromJson(decoded);
        if (meta.url.isNotEmpty) return meta;
      }
    } catch (_) {}
    return null;
  }

  static String embedMusicInDescription(String? description, ReelMusicMeta? music) {
    final stripped = (description ?? '').replaceAll(_musicRegex, '').trim();
    if (music == null || music.url.trim().isEmpty) return stripped;
    final tag = '<!--artable_music:${jsonEncode(music.toJson())}-->';
    return stripped.isEmpty ? tag : '$stripped\n$tag';
  }

  /// Appends clips JSON tag to description for reliable server persistence.
  static String embedClipsInDescription(String? description, List<String>? clips) {
    final baseDesc = (description != null && description.trim().isNotEmpty)
        ? description.replaceAll(_clipsRegex, '').replaceAll(_legacyClipsRegex, '').trim()
        : '';
    if (clips == null || clips.length <= 1) return baseDesc;
    final tag = '<!--artable_clips:${jsonEncode(clips)}-->';
    return baseDesc.isNotEmpty ? '$baseDesc\n$tag' : tag;
  }

  static Map<String, dynamic>? reelById(String id, {List<Map<String, dynamic>>? availableReels}) {
    final cleanId = id.trim();
    if (cleanId.isEmpty) {
      return null;
    }
    if (availableReels != null && availableReels.isNotEmpty) {
      for (final r in availableReels) {
        final rId = r['id']?.toString() ?? r['_id']?.toString() ?? '';
        if (rId == cleanId) return r;
      }
    }
    return null;
  }

  static Map<String, dynamic>? challengeForReel(Map<String, dynamic> reel) {
    final cid = reel['challengeId'] as String?;
    if (cid == null) return null;
    for (final c in MockData.CHALLENGES) {
      if (c['id'] == cid) return c;
    }
    return null;
  }

  static Map<String, dynamic>? challengeById(String id) {
    for (final c in MockData.CHALLENGES) {
      if (c['id'] == id) return c;
    }
    return MockData.CHALLENGES.isNotEmpty ? MockData.CHALLENGES.first : null;
  }

  static Color categoryTint(String category) {
    return switch (category) {
      'Dance' => const Color(0xFFE01D5C),
      'Comedy' => const Color(0xFF3450D6),
      'Fitness' => const Color(0xFF1FAE6A),
      'Singing' => const Color(0xFFFF3D77),
      'Magic' => const Color(0xFF7420E8),
      'Art' => const Color(0xFFE8631F),
      _ => const Color(0xFF8B3DFF),
    };
  }

  static int ratingImpact(double talentScore) => (talentScore * 6).round();

  static String? _nonNaturalFilterId(String? id) {
    final v = id?.trim() ?? '';
    if (v.isEmpty || v.toLowerCase() == 'natural' || v.toLowerCase() == 'null') {
      return null;
    }
    return v;
  }

  static ({String filterId, bool beautyOn, double beautyIntensity})? resolveFilter({
    String? filterId,
    bool? beautyOn,
    double? beautyIntensity,
    String? description,
    String? videoId,
    String? videoUrl,
  }) {
    final parsed = parseDescriptionFilter(description);
    final cached = getCachedFilter(videoId) ?? getCachedFilter(videoUrl);
    final id = _nonNaturalFilterId(filterId) ?? parsed?.filterId ?? cached?.filterId;
    final beauty = beautyOn == true || (parsed?.beautyOn ?? false) || (cached?.beautyOn ?? false);
    final intensity = (beautyIntensity != null && beautyIntensity > 0)
        ? beautyIntensity
        : ((parsed?.beautyIntensity ?? 0) > 0
            ? parsed!.beautyIntensity
            : (cached?.beautyIntensity ?? 0));
    if (id == null && !beauty) return null;
    final meta = (
      filterId: id ?? 'natural',
      beautyOn: beauty,
      beautyIntensity: intensity,
    );
    cacheFilter(videoId, meta);
    cacheFilter(videoUrl, meta);
    return meta;
  }

  static final Map<String, ({String filterId, bool beautyOn, double beautyIntensity})> _filterCache = {};

  static void cacheFilter(
    String? key,
    ({String filterId, bool beautyOn, double beautyIntensity})? meta,
  ) {
    if (key == null || key.trim().isEmpty || meta == null) return;
    final cleanKey = key.trim();
    final existing = _filterCache[cleanKey];
    final unchanged = existing != null &&
        existing.filterId == meta.filterId &&
        existing.beautyOn == meta.beautyOn &&
        existing.beautyIntensity == meta.beautyIntensity;
    _filterCache[cleanKey] = meta;
    final withoutHost = cleanKey.replaceFirst(RegExp(r'^https?://[^/]+'), '');
    if (withoutHost.isNotEmpty && withoutHost != cleanKey) {
      _filterCache[withoutHost] = meta;
    }
    if (unchanged) return;
    try {
      final jsonStr = jsonEncode({
        'id': meta.filterId,
        'beautyOn': meta.beautyOn,
        'beautyIntensity': meta.beautyIntensity,
      });
      LocalStorage.setString('cached_filter_$cleanKey', jsonStr);
      if (withoutHost.isNotEmpty && withoutHost != cleanKey) {
        LocalStorage.setString('cached_filter_$withoutHost', jsonStr);
      }
    } catch (_) {}
  }

  static ({String filterId, bool beautyOn, double beautyIntensity})? getCachedFilter(String? key) {
    if (key == null || key.trim().isEmpty) return null;
    final cleanKey = key.trim();
    if (_filterCache.containsKey(cleanKey)) return _filterCache[cleanKey];
    final withoutHost = cleanKey.replaceFirst(RegExp(r'^https?://[^/]+'), '');
    if (withoutHost.isNotEmpty && _filterCache.containsKey(withoutHost)) {
      return _filterCache[withoutHost];
    }
    try {
      final rawPrefs = LocalStorage.rawPrefs;
      final saved = rawPrefs?.getString('cached_filter_$cleanKey') ??
          (withoutHost.isNotEmpty ? rawPrefs?.getString('cached_filter_$withoutHost') : null);
      if (saved != null && saved.isNotEmpty) {
        final decoded = jsonDecode(saved);
        if (decoded is Map) {
          final id = decoded['id']?.toString().trim() ?? '';
          if (id.isEmpty || id == 'natural') return null;
          final meta = (
            filterId: id,
            beautyOn: decoded['beautyOn'] == true,
            beautyIntensity: (decoded['beautyIntensity'] as num?)?.toDouble() ?? 0,
          );
          _filterCache[cleanKey] = meta;
          return meta;
        }
      }
    } catch (_) {}
    return null;
  }

  static final Map<String, List<String>> _mergedClipsCache = {};

  static void cacheMergedClips(String? key, List<String>? clips) {
    if (key == null || key.trim().isEmpty || clips == null || clips.length <= 1) return;
    final cleanKey = key.trim();
    _mergedClipsCache[cleanKey] = List<String>.from(clips);
    final withoutHost = cleanKey.replaceFirst(RegExp(r'^https?://[^/]+'), '');
    if (withoutHost.isNotEmpty && withoutHost != cleanKey) {
      _mergedClipsCache[withoutHost] = List<String>.from(clips);
    }
    try {
      final jsonStr = jsonEncode(clips);
      LocalStorage.setString('cached_clips_$cleanKey', jsonStr);
      if (withoutHost.isNotEmpty && withoutHost != cleanKey) {
        LocalStorage.setString('cached_clips_$withoutHost', jsonStr);
      }
    } catch (_) {}
  }

  static List<String>? getCachedMergedClips(String? key) {
    if (key == null || key.trim().isEmpty) return null;
    final cleanKey = key.trim();
    if (_mergedClipsCache.containsKey(cleanKey)) {
      return _mergedClipsCache[cleanKey];
    }
    final withoutHost = cleanKey.replaceFirst(RegExp(r'^https?://[^/]+'), '');
    if (withoutHost.isNotEmpty && _mergedClipsCache.containsKey(withoutHost)) {
      return _mergedClipsCache[withoutHost];
    }
    try {
      final rawPrefs = LocalStorage.rawPrefs;
      final saved = rawPrefs?.getString('cached_clips_$cleanKey') ??
          (withoutHost.isNotEmpty ? rawPrefs?.getString('cached_clips_$withoutHost') : null);
      if (saved != null && saved.isNotEmpty) {
        final decoded = jsonDecode(saved);
        if (decoded is List) {
          final list = decoded.map((e) => e.toString()).toList();
          _mergedClipsCache[cleanKey] = list;
          return list;
        }
      }
    } catch (_) {}
    return null;
  }
}
