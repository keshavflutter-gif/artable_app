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

  static bool _isHttpUrlKey(String key) {
    return key.startsWith('http://') || key.startsWith('https://');
  }

  static void cacheMergedClips(String? key, List<String>? clips) {
    if (key == null || key.trim().isEmpty || clips == null || clips.length <= 1) {
      return;
    }
    final cleanKey = key.trim();
    // Never index playlists by media URL — shared path suffixes leak clips
    // across videos. Prefer video ids only.
    if (_isHttpUrlKey(cleanKey) || cleanKey.contains('/uploads/')) return;
    _mergedClipsCache[cleanKey] = List<String>.from(clips);
    try {
      LocalStorage.setString('cached_clips_$cleanKey', jsonEncode(clips));
    } catch (_) {}
  }

  static List<String>? getCachedMergedClips(String? key) {
    if (key == null || key.trim().isEmpty) return null;
    final cleanKey = key.trim();
    if (_isHttpUrlKey(cleanKey) || cleanKey.contains('/uploads/')) return null;
    if (_mergedClipsCache.containsKey(cleanKey)) {
      return _mergedClipsCache[cleanKey];
    }
    try {
      final saved = LocalStorage.rawPrefs?.getString('cached_clips_$cleanKey');
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

  static final Map<String, ReelMusicMeta> _musicCache = {};

  static void cacheMusic(String? key, ReelMusicMeta? music) {
    if (key == null || key.trim().isEmpty || music == null) return;
    final url = music.url.trim();
    if (url.isEmpty || url == 'null') return;
    final cleanKey = key.trim();
    // Video-id keys only — URL keys caused one reel's BGM on another.
    if (_isHttpUrlKey(cleanKey) || cleanKey.contains('/uploads/')) return;
    final meta = ReelMusicMeta(
      url: url,
      name: music.name.trim(),
      startSeconds: music.startSeconds,
      durationSeconds: music.durationSeconds,
    );
    _musicCache[cleanKey] = meta;
    try {
      LocalStorage.setString('cached_music_$cleanKey', jsonEncode(meta.toJson()));
    } catch (_) {}
  }

  static ReelMusicMeta? getCachedMusic(String? key) {
    if (key == null || key.trim().isEmpty) return null;
    final cleanKey = key.trim();
    if (_isHttpUrlKey(cleanKey) || cleanKey.contains('/uploads/')) return null;
    if (_musicCache.containsKey(cleanKey)) return _musicCache[cleanKey];
    try {
      final saved = LocalStorage.rawPrefs?.getString('cached_music_$cleanKey');
      if (saved != null && saved.isNotEmpty) {
        final decoded = jsonDecode(saved);
        if (decoded is Map) {
          final meta = ReelMusicMeta.fromJson(decoded);
          if (meta.url.isNotEmpty) {
            _musicCache[cleanKey] = meta;
            return meta;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Prefer description embed, then direct fields, then cache by video id only.
  /// Never uses videoUrl as a cache key for lookup — that leaked one reel's
  /// track onto others when URLs shared path prefixes / hosts.
  ///
  /// [resolveAudioUrl] lets callers fill a missing URL from the music catalog
  /// (e.g. MusicApiService.resolveByName) when the API kept the name but
  /// stripped the stream URL / HTML comment.
  static ReelMusicMeta? resolveMusic({
    String? description,
    String? musicUrl,
    String? musicName,
    double? startSeconds,
    double? durationSeconds,
    String? videoId,
    String? videoUrl,
    String? Function(String musicName)? resolveAudioUrl,
  }) {
    final fromDesc = parseDescriptionMusic(description);
    final direct = (musicUrl ?? '').trim();
    final named = (musicName ?? '').trim();
    ReelMusicMeta? meta;
    // Prefer explicit musicUrl/musicName (latest submit) over HTML comment in
    // description, which can still hold the first song saved on a draft.
    if (direct.isNotEmpty && direct != 'null') {
      meta = ReelMusicMeta(
        url: direct,
        name: named.isNotEmpty ? named : (fromDesc?.name ?? ''),
        startSeconds: startSeconds ?? fromDesc?.startSeconds ?? 0,
        durationSeconds: durationSeconds ?? fromDesc?.durationSeconds ?? 0,
      );
    } else if (fromDesc != null && fromDesc.url.isNotEmpty) {
      meta = fromDesc;
    } else if (videoId != null && videoId.trim().isNotEmpty) {
      meta = getCachedMusic(videoId);
    }

    if ((meta == null || meta.url.isEmpty) &&
        named.isNotEmpty &&
        !named.startsWith('Original Sound') &&
        resolveAudioUrl != null) {
      final resolved = resolveAudioUrl(named)?.trim() ?? '';
      if (resolved.isNotEmpty && resolved != 'null') {
        meta = ReelMusicMeta(
          url: resolved,
          name: named,
          startSeconds: startSeconds ?? meta?.startSeconds ?? 0,
          durationSeconds: durationSeconds ?? meta?.durationSeconds ?? 0,
        );
      }
    }

    if (meta != null && meta.url.isNotEmpty) {
      if (meta.name.isEmpty && named.isNotEmpty && !named.startsWith('Original Sound')) {
        meta = ReelMusicMeta(
          url: meta.url,
          name: named,
          startSeconds: meta.startSeconds,
          durationSeconds: meta.durationSeconds,
        );
      }
      cacheMusic(videoId, meta);
    }
    return meta;
  }

  /// Merge API video detail onto an existing reel map without dropping music /
  /// clip metadata the API may have stripped.
  static Map<String, dynamic> mergeReelMaps(
    Map<String, dynamic> primary,
    Map<String, dynamic>? fallback,
  ) {
    if (fallback == null || fallback.isEmpty) {
      return Map<String, dynamic>.from(primary);
    }
    final out = Map<String, dynamic>.from(primary);

    bool isImagePath(String s) {
      final lower = s.toLowerCase().split('?').first;
      return lower.endsWith('.jpg') ||
          lower.endsWith('.jpeg') ||
          lower.endsWith('.png') ||
          lower.endsWith('.webp') ||
          lower.endsWith('.gif') ||
          lower.endsWith('.bmp');
    }

    String pick(String key, {bool rejectImage = false}) {
      final a = out[key]?.toString().trim() ?? '';
      if (a.isNotEmpty && a != 'null' && !(rejectImage && isImagePath(a))) {
        return a;
      }
      final b = fallback[key]?.toString().trim() ?? '';
      if (b.isNotEmpty && b != 'null' && !(rejectImage && isImagePath(b))) {
        return b;
      }
      return '';
    }

    for (final key in [
      'musicUrl',
      'music_url',
      'audioUrl',
      'musicName',
      'music',
      'description',
      'caption',
      'thumbnailUrl',
      'imageUrl',
    ]) {
      final v = pick(key);
      if (v.isNotEmpty) out[key] = v;
    }
    for (final key in ['videoUrl', 'videoPath']) {
      final v = pick(key, rejectImage: true);
      if (v.isNotEmpty) {
        out[key] = v;
      } else if (isImagePath(out[key]?.toString().trim() ?? '')) {
        out.remove(key);
      }
    }
    if (out['musicStartSeconds'] == null && fallback['musicStartSeconds'] != null) {
      out['musicStartSeconds'] = fallback['musicStartSeconds'];
    }
    if (out['musicCropDuration'] == null && fallback['musicCropDuration'] != null) {
      out['musicCropDuration'] = fallback['musicCropDuration'];
    }
    final primaryClips = out['mergedClipPaths'];
    final fallbackClips = fallback['mergedClipPaths'];
    final primaryEmpty = primaryClips is! List || primaryClips.isEmpty;
    if (primaryEmpty && fallbackClips is List && fallbackClips.isNotEmpty) {
      out['mergedClipPaths'] = List<String>.from(fallbackClips.map((e) => e.toString()));
    }

    // Keep the stronger engagement totals when merging list → detail maps.
    void mergeCount(String labelKey, String countKey) {
      final a = _parseEngagementCount(out[countKey] ?? out[labelKey]);
      final b = _parseEngagementCount(fallback[countKey] ?? fallback[labelKey]);
      final best = a > b ? a : b;
      out[countKey] = best;
      out[labelKey] = _formatEngagementCount(best);
    }

    mergeCount('views', 'viewsCount');
    mergeCount('likes', 'likesCount');
    mergeCount('comments', 'commentsCount');
    mergeCount('shares', 'sharesCount');
    mergeCount('saves', 'savesCount');
    return out;
  }

  static int _parseEngagementCount(dynamic raw) {
    if (raw == null) return 0;
    if (raw is num) return raw.toInt();
    final str = raw.toString().trim().toUpperCase();
    if (str.isEmpty || str == 'NULL' || str == 'UNDEFINED' || str == 'NAN') {
      return 0;
    }
    final asInt = int.tryParse(str);
    if (asInt != null) return asInt;
    final asDouble = double.tryParse(str);
    if (asDouble != null) return asDouble.toInt();
    if (str.endsWith('K')) {
      final n = double.tryParse(str.replaceAll('K', '').trim());
      if (n != null) return (n * 1000).round();
    }
    if (str.endsWith('M')) {
      final n = double.tryParse(str.replaceAll('M', '').trim());
      if (n != null) return (n * 1000000).round();
    }
    return 0;
  }

  static String _formatEngagementCount(int count) {
    if (count >= 1000000) {
      final val = count / 1000000;
      return '${val.toStringAsFixed(1).replaceAll('.0', '')}M';
    }
    if (count >= 1000) {
      final val = count / 1000;
      return '${val.toStringAsFixed(1).replaceAll('.0', '')}K';
    }
    return count.toString();
  }
}
