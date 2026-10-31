import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Shared BGM player for Challenge Arena / trending reels / video detail.
///
/// Rules:
/// - Only one reel owns playback (`_activeReelId`).
/// - `_wantPlaying` gates ALL resume paths — pause / close / ads / swipe must
///   clear it (via [killNow]) so in-flight [sync] cannot revive audio after exit.
/// - Landing on a reel with no music must [silenceForReel].
/// - Video loop / scrub must call [sync] with `forceSeek: true` so music
///   restarts at `startMs + videoPosition` with the slider.
class ReelBgmPlaybackService {
  ReelBgmPlaybackService._();

  static AudioPlayer? _player;
  static String? _loadedUrl;
  static int _loadedStartMs = -1;
  static int _loadedCropMs = -1;
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

  /// Immediate, synchronous kill — call this on back / close / pause / dispose
  /// BEFORE any async work so a queued [sync] cannot restart audio.
  static void killNow() {
    _epoch++;
    _wantPlaying = false;
    _activeReelId = null;
    try {
      _player?.pause();
    } catch (_) {}
  }

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
    int cropDurationMs = 0,
  }) async {
    await _enqueue(() => _syncLocked(
          reelId: reelId,
          url: url,
          startMs: startMs,
          videoPositionMs: videoPositionMs,
          shouldPlay: shouldPlay,
          speed: speed,
          forceSeek: forceSeek,
          cropDurationMs: cropDurationMs,
        ));
  }

  /// Active reel has no BGM — claim ownership and kill any previous track.
  static Future<void> silenceForReel(String reelId) async {
    killNow();
    _activeReelId = reelId;
    await _enqueue(() => _silenceLocked(reelId));
  }

  /// Soft leave: pause only if [reelId] still owns the player.
  /// Never kill when ownership is unset — that aborts an in-flight first [sync].
  static Future<void> deactivate(String reelId) async {
    if (_activeReelId == reelId) {
      killNow();
    }
    await _enqueue(() => _deactivateLocked(reelId));
  }

  /// Hard stop for ads / page changes / screen exit.
  static Future<void> halt() async {
    killNow();
    await _enqueue(_haltLocked);
  }

  static Future<void> _silenceLocked(String reelId) async {
    _wantPlaying = false;
    _activeReelId = reelId;
    _loadedUrl = null;
    _loadedStartMs = -1;
    _loadedCropMs = -1;
    await _stopPlayerLocked();
  }

  static Future<void> _deactivateLocked(String reelId) async {
    // Another reel already owns audio — leave it alone.
    if (_activeReelId != null && _activeReelId != reelId) return;
    _wantPlaying = false;
    if (_activeReelId == reelId) {
      _activeReelId = null;
    }
    await _pauseLocked();
  }

  static Future<void> _haltLocked() async {
    _wantPlaying = false;
    _activeReelId = null;
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

  static Future<void> _loadSource({
    required AudioPlayer player,
    required String url,
    required int startMs,
    required int cropDurationMs,
  }) async {
    try {
      await player.stop();
    } catch (_) {}
    final safeStart = startMs < 0 ? 0 : startMs;
    // Prefer plain URL load — ClippingAudioSource often fails on remote MP3s
    // (end beyond stream length), which left video muted with no BGM.
    await player.setUrl(url).timeout(const Duration(seconds: 8));
    await player.setLoopMode(LoopMode.one);
    _loadedUrl = url;
    _loadedStartMs = safeStart;
    // Crop is only used for video-window modulo when seeking, not for clipping.
    _loadedCropMs = cropDurationMs > 250 ? cropDurationMs : 0;
  }

  static Future<void> _syncLocked({
    required String reelId,
    required String url,
    required int startMs,
    required int videoPositionMs,
    required bool shouldPlay,
    double speed = 1.0,
    bool forceSeek = false,
    int cropDurationMs = 0,
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
      if (epoch != _epoch || !_wantPlaying) return;

      final player = _ensurePlayer();
      final safeStart = startMs < 0 ? 0 : startMs;
      final safeCrop = cropDurationMs > 250 ? cropDurationMs : 0;
      final urlChanged = _loadedUrl != cleanUrl;
      final windowChanged =
          _loadedStartMs != safeStart || _loadedCropMs != safeCrop;
      if (urlChanged || windowChanged) {
        await _loadSource(
          player: player,
          url: cleanUrl,
          startMs: safeStart,
          cropDurationMs: safeCrop,
        );
        if (epoch != _epoch || !_wantPlaying) return;
      }
      if (epoch != _epoch || !_wantPlaying || _activeReelId != reelId) return;

      // Position inside the music window that should match the video clock.
      final posInWindow = safeCrop > 0
          ? (videoPositionMs % safeCrop)
          : (videoPositionMs < 0 ? 0 : videoPositionMs);
      // Absolute seek into the full track (startMs + offset in crop window).
      final targetMs = (safeStart + posInWindow).clamp(0, 3600000);

      try {
        await player.setSpeed(speed.clamp(0.4, 4.0));
      } catch (_) {}
      final currentMs = player.position.inMilliseconds;
      final drift = (currentMs - targetMs).abs();
      // Tight threshold so slider/video/music stay locked; forceSeek on loops.
      if (forceSeek ||
          urlChanged ||
          windowChanged ||
          reelChanged ||
          !player.playing ||
          drift > 450) {
        try {
          await player.seek(Duration(milliseconds: targetMs));
        } catch (_) {}
      }
      if (epoch != _epoch || !_wantPlaying || _activeReelId != reelId) return;
      await player.setVolume(1.0);
      if (epoch != _epoch || !_wantPlaying || _activeReelId != reelId) return;
      if (!player.playing) {
        // Do not await play() — it completes only when playback ends.
        unawaited(player.play());
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
    killNow();
    await _enqueue(_pauseLocked);
  }

  static Future<void> _pauseLocked() async {
    try {
      await _player?.pause();
    } catch (_) {}
  }

  static Future<void> stop() async {
    killNow();
    _loadedUrl = null;
    _loadedStartMs = -1;
    _loadedCropMs = -1;
    await _enqueue(() async {
      _wantPlaying = false;
      _activeReelId = null;
      _loadedUrl = null;
      _loadedStartMs = -1;
      _loadedCropMs = -1;
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
