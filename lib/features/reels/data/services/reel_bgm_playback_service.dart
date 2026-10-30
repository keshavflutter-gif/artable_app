import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Shared BGM player for Challenge Arena / trending reels.
///
/// Rules:
/// - Only one reel owns playback (`_activeReelId`).
/// - `_wantPlaying` gates ALL resume paths — pause / ads / swipe must set it false
///   so [ensurePlaying] cannot revive the previous track.
/// - Landing on a reel with no music must [silenceForReel], not leave old audio.
class ReelBgmPlaybackService {
  ReelBgmPlaybackService._();

  static AudioPlayer? _player;
  static String? _loadedUrl;
  static String? _activeReelId;
  static bool _wantPlaying = false;
  static int _epoch = 0;
  static bool _sessionConfigured = false;
  static Future<void> _chain = Future.value();

  static String? get activeReelId => _activeReelId;
  static bool get isWantPlaying => _wantPlaying;

  static Future<T?> _enqueue<T>(Future<T> Function() action) {
    final result = _chain.then<T?>((_) => action()).catchError((Object e, StackTrace st) {
      debugPrint('ReelBgmPlaybackService op error: $e');
      return null;
    });
    _chain = result.then((_) {}, onError: (_, _) {});
    return result;
  }

  static AudioPlayer _ensurePlayer() => _player ??= AudioPlayer(
        handleInterruptions: false,
      );

  static Future<void> _configureSession() async {
    if (_sessionConfigured) return;
    try {
      final session = await AudioSession.instance;
      await session.configure(
        const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.mixWithOthers,
          avAudioSessionMode: AVAudioSessionMode.defaultMode,
          androidAudioAttributes: AndroidAudioAttributes(
            contentType: AndroidAudioContentType.music,
            usage: AndroidAudioUsage.media,
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
          androidWillPauseWhenDucked: false,
        ),
      );
      _sessionConfigured = true;
    } catch (e) {
      debugPrint('ReelBgmPlaybackService session config error: $e');
    }
  }

  static Future<void> sync({
    required String reelId,
    required String url,
    required int startMs,
    required int videoPositionMs,
    required bool shouldPlay,
    double speed = 1.0,
    bool forceSeek = false,
  }) async {
    await _enqueue(() => _syncLocked(
          reelId: reelId,
          url: url,
          startMs: startMs,
          videoPositionMs: videoPositionMs,
          shouldPlay: shouldPlay,
          speed: speed,
          forceSeek: forceSeek,
        ));
  }

  /// Active reel has no BGM — claim ownership and kill any previous track.
  static Future<void> silenceForReel(String reelId) async {
    await _enqueue(() => _silenceLocked(reelId));
  }

  /// Soft leave: pause only if [reelId] still owns the player.
  static Future<void> deactivate(String reelId) async {
    await _enqueue(() => _deactivateLocked(reelId));
  }

  /// Hard stop for ads / page changes — nothing should keep humming.
  static Future<void> halt() async {
    await _enqueue(_haltLocked);
  }

  static Future<void> _silenceLocked(String reelId) async {
    _epoch++;
    _wantPlaying = false;
    _activeReelId = reelId;
    _loadedUrl = null;
    await _stopPlayerLocked();
  }

  static Future<void> _deactivateLocked(String reelId) async {
    if (_activeReelId != null && _activeReelId != reelId) return;
    _epoch++;
    _wantPlaying = false;
    if (_activeReelId == reelId) {
      _activeReelId = null;
    }
    await _pauseLocked();
  }

  static Future<void> _haltLocked() async {
    _epoch++;
    _wantPlaying = false;
    _activeReelId = null;
    // Keep _loadedUrl so a quick return to the same reel can reuse the source,
    // but player must be paused/stopped so ads stay silent.
    await _stopPlayerLocked();
  }

  static Future<void> _stopPlayerLocked() async {
    try {
      await _player?.pause();
    } catch (_) {}
    try {
      await _player?.stop();
    } catch (_) {}
  }

  static Future<void> _syncLocked({
    required String reelId,
    required String url,
    required int startMs,
    required int videoPositionMs,
    required bool shouldPlay,
    double speed = 1.0,
    bool forceSeek = false,
  }) async {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty || !shouldPlay) {
      await _silenceLocked(reelId);
      return;
    }

    final epoch = ++_epoch;
    final reelChanged = _activeReelId != reelId;
    _activeReelId = reelId;
    _wantPlaying = true;
    try {
      await _configureSession();
      final player = _ensurePlayer();
      final urlChanged = _loadedUrl != cleanUrl;
      if (urlChanged) {
        try {
          await player.stop();
        } catch (_) {}
        await player.setUrl(cleanUrl).timeout(const Duration(seconds: 8));
        await player.setLoopMode(LoopMode.one);
        _loadedUrl = cleanUrl;
      }
      if (epoch != _epoch || !_wantPlaying || _activeReelId != reelId) return;

      final targetMs = (startMs + videoPositionMs).clamp(0, 3600000);
      try {
        await player.setSpeed(speed.clamp(0.4, 4.0));
      } catch (_) {}
      final currentMs = player.position.inMilliseconds;
      final drift = (currentMs - targetMs).abs();
      if (forceSeek || urlChanged || reelChanged || !player.playing || drift > 1800) {
        try {
          await player.seek(Duration(milliseconds: targetMs));
        } catch (_) {}
      }
      await player.setVolume(1.0);
      if (epoch != _epoch || !_wantPlaying || _activeReelId != reelId) return;
      if (!player.playing) {
        await player.play();
      }
    } catch (e) {
      debugPrint('ReelBgmPlaybackService sync error: $e');
    }
  }

  /// Resume only while the owning reel still wants audio.
  static void ensurePlaying({String? reelId}) {
    try {
      if (!_wantPlaying || _loadedUrl == null || _activeReelId == null) return;
      if (reelId != null && _activeReelId != reelId) return;
      final player = _player;
      if (player != null && !player.playing) {
        unawaited(player.play());
      }
    } catch (_) {}
  }

  static Future<void> pause() async {
    await _enqueue(() async {
      _wantPlaying = false;
      await _pauseLocked();
    });
  }

  static Future<void> _pauseLocked() async {
    try {
      await _player?.pause();
    } catch (_) {}
  }

  static Future<void> stop() async {
    await _enqueue(() async {
      _epoch++;
      _wantPlaying = false;
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
    });
  }
}
