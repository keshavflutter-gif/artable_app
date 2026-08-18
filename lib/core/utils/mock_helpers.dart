import 'package:artable_app/data/datasources/mock_data.dart';

class MockHelpers {
  MockHelpers._();

  static Map<String, dynamic> get currentUser {
    return MockData.CREATORS.firstWhere(
      (u) => u['id'] == MockData.CURRENT_USER_ID,
    );
  }

  static Map<String, dynamic>? creatorById(String? id) {
    if (id == null) return null;
    try {
      return MockData.CREATORS.firstWhere((u) => u['id'] == id);
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic>? challengeById(String? id) {
    if (id == null) return null;
    try {
      return MockData.CHALLENGES.firstWhere((c) => c['id'] == id);
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic>? rewardById(String? id) {
    if (id == null) return null;
    try {
      return MockData.REWARDS.firstWhere((r) => r['id'] == id);
    } catch (_) {
      return MockData.REWARDS.first;
    }
  }

  static Map<String, dynamic>? winnerById(String? id) {
    if (id == null) return null;
    try {
      return MockData.WINNERS.firstWhere((w) => w['id'] == id);
    } catch (_) {
      return MockData.WINNERS.first;
    }
  }

  static Map<String, dynamic>? reelById(String? id) {
    if (id == null) return null;
    try {
      return MockData.REELS.firstWhere((r) => r['id'] == id);
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic>? musicTrackById(String? id) {
    if (id == null) return null;
    try {
      return MockData.MUSIC_LIBRARY_TRACKS.firstWhere((t) => t['id'] == id);
    } catch (_) {
      return MockData.MUSIC_LIBRARY_TRACKS.first;
    }
  }

  static double sortValue(Map<String, dynamic> u, String tab) {
    switch (tab) {
      case 'weekly':
        return (u['votes'] as num).toDouble();
      case 'monthly':
        return ((u['challengesWon'] as num) * 100 + (u['talentScore'] as num)).toDouble();
      case 'challenge':
        return (u['challengesWon'] as num) * 100 + (u['votes'] as num) / 1000;
      default:
        return (u['talentScore'] as num).toDouble();
    }
  }
}
