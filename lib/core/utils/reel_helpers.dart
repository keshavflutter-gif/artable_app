import 'package:flutter/material.dart';

import 'package:artable_app/data/datasources/mock_data.dart';

abstract final class ReelHelpers {
  static Map<String, dynamic>? reelById(String id) {
    for (final r in MockData.REELS) {
      if (r['id'] == id) return r;
    }
    return MockData.REELS.isNotEmpty ? MockData.REELS.first : null;
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
}
