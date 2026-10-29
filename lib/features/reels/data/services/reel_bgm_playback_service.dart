import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Plays uploaded BGM on the active Challenge Arena / reels item.
class ReelBgmPlaybackService {
  ReelBgmPlaybackService._();

  static AudioPlayer? _player;
  static String? _loadedUrl;
  static String? _activeReelId;
  static int _epoch = 0;

  static Future<void> sync({
    required String reelId,
    required String url,
    required int startMs,
    required int videoPositionMs,
    required bool shouldPlay,
    double speed = 1.0,
  }) async {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty || !shouldPlay) {
      if (_activeReelId == reelId || _activeReelId == null) {
        await pause();
      }
      return;
    }

    final epoch = ++_epoch;
    _activeReelId = reelId;
    try {
      final player = _player ??= AudioPlayer();
      if (_loadedUrl != cleanUrl) {
        try {
          await player.stop();
        } catch (_) {}
        await player.setUrl(cleanUrl).timeout(const Duration(seconds: 8));
        await player.setLoopMode(LoopMode.one);
        _loadedUrl = cleanUrl;
      }
      if (epoch != _epoch || _activeReelId != reelId) return;

      final targetMs = (startMs + videoPositionMs).clamp(0, 3600000);
      try {
        await player.setSpeed(speed.clamp(0.4, 4.0));
      } catch (_) {}
      try {
        await player.seek(Duration(milliseconds: targetMs));
      } catch (_) {}
      await player.setVolume(1.0);
      if (epoch != _epoch || _activeReelId != reelId) return;
      if (!player.playing) {
        unawaited(player.play());
      }
    } catch (e) {
      debugPrint('ReelBgmPlaybackService sync error: $e');
    }
  }

  static Future<void> pause() async {
    try {
      await _player?.pause();
    } catch (_) {}
  }

  static Future<void> stop() async {
    _epoch++;
    _activeReelId = null;
    _loadedUrl = null;
    final player = _player;
    _player = null;
    if (player == null) return;
    try {
      await player.stop();
    } catch (_) {}
    try {
      await player.dispose();
    } catch (_) {}
  }
}
