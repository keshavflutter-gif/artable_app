import 'package:flutter/material.dart';

import 'package:artable_app/data/datasources/mock_data.dart';

import 'dart:convert';
import 'package:artable_app/core/storage/local_storage.dart';

abstract final class ReelHelpers {
  static final RegExp _clipsRegex = RegExp(r'<!--artable_clips:(.*?)-->', dotAll: true);
  static final RegExp _legacyClipsRegex = RegExp(r'\[CLIPS:(.*?)\]');

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

    return (cleanDescription: description.trim(), clips: null);
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
      return MockData.REELS.isNotEmpty ? MockData.REELS.first : null;
    }
    if (availableReels != null && availableReels.isNotEmpty) {
      for (final r in availableReels) {
        final rId = r['id']?.toString() ?? r['_id']?.toString() ?? '';
        if (rId == cleanId) return r;
      }
    }
    for (final r in MockData.REELS) {
      final rId = r['id']?.toString() ?? r['_id']?.toString() ?? '';
      if (rId == cleanId) return r;
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
