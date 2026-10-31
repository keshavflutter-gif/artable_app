import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'package:artable_app/features/studio/presentation/bloc/studio_cubit.dart';
import 'package:artable_app/data/datasources/music_api_service.dart';

/// Plays the selected studio track during video recording and video editing.
///
/// All player ops are serialized to avoid native crashes when music is updated
/// while video sync / play / dispose run at the same time.
class StudioMusicPlaybackService {
  StudioMusicPlaybackService._();

  static AudioPlayer? _player;
  static String? _loadedTrackId;
  static String? _loadedAudioUrl;
  static bool _sessionConfigured = false;
  static bool _isLoading = false;
  static int _playEpoch = 0;

  /// Serial queue so stop/load/play/seek never overlap.
  static Future<void> _chain = Future.value();

  static Future<T?> _enqueue<T>(Future<T> Function() action) {
    final result = _chain.then<T?>((_) => action()).catchError((Object e, StackTrace st) {
      debugPrint('StudioMusicPlaybackService op error: $e');
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
      debugPrint('StudioMusicPlaybackService session config error: $e');
    }
  }

  static FreeToUseTrack? _resolveTrack(StudioCubit studio) {
    if (studio.selectedTrack != null) return studio.selectedTrack;
    return MusicApiService.resolveByName(studio.selectedMusic);
  }

  /// Call when the user picks a different track so the next play reloads audio.
  static void invalidateLoadedTrack() {
    _loadedTrackId = null;
    _loadedAudioUrl = null;
  }

  static Future<void> prepareForRecordingStart() async {
    await _enqueue(() async {
      await _configureSession();
      final player = _player;
      if (player != null && player.playing) {
        await player.pause();
      }
    });
  }

  static Future<void> preloadForStudio(StudioCubit studio) async {
    await _enqueue(() => _preloadLocked(studio));
  }

  static Future<void> _preloadLocked(StudioCubit studio) async {
    final track = _resolveTrack(studio);
    if (track == null) {
      _loadedTrackId = null;
      _loadedAudioUrl = null;
      return;
    }

    if (_loadedTrackId == track.id &&
        _loadedAudioUrl == track.audioUrl &&
        _player != null &&
        !_isLoading) {
      return;
    }

    await _loadTrackLocked(track);
  }

  static Future<void> _loadTrackLocked(FreeToUseTrack track) async {
    _isLoading = true;
    try {
      await _configureSession();
      final player = _ensurePlayer();
      try {
        await player.pause();
      } catch (_) {}
      try {
        await player.stop();
      } catch (_) {}

      final url = track.audioUrl.trim();
      if (url.isEmpty) {
        _loadedTrackId = null;
        _loadedAudioUrl = null;
        return;
      }

      await player.setUrl(url).timeout(const Duration(seconds: 8));
      await player.setVolume(1.0);
      await player.setLoopMode(LoopMode.one);
      _loadedTrackId = track.id;
      _loadedAudioUrl = url;
    } catch (e) {
      debugPrint('StudioMusicPlaybackService _loadTrack error: $e');
      _loadedTrackId = null;
      _loadedAudioUrl = null;
    } finally {
      _isLoading = false;
    }
  }

  static Future<void> playForRecording(StudioCubit studio) async {
    await playForEditor(studio, 0);
  }

  static bool get isPlaying => _player?.playing ?? false;

  /// Plays background music for the editor starting at [globalPositionMs].
  /// Set [forceSeek] on video loop / restart so BGM rewinds with the video.
  static Future<void> playForEditor(
    StudioCubit studio,
    int globalPositionMs, {
    bool forceSeek = false,
  }) async {
    final epoch = _playEpoch;
    await _enqueue(() async {
      if (epoch != _playEpoch) return;
      final track = _resolveTrack(studio);
      if (track == null) {
        final player = _player;
        if (player != null && player.playing) {
          await player.pause();
        }
        return;
      }

      await _configureSession();
      if (_loadedTrackId != track.id ||
          _loadedAudioUrl != track.audioUrl ||
          _player == null) {
        await _loadTrackLocked(track);
      }

      final player = _player;
      if (player == null || _loadedTrackId != track.id) return;

      await player.setVolume(1.0);
      await player.setLoopMode(LoopMode.one);

      final musicStartMs = (studio.musicStartSeconds * 1000).round();
      final totalVideoSec = studio.effectiveVideoDuration;
      final totalVideoMs = (totalVideoSec * 1000).round();
      final cropLimitMs = (totalVideoMs > 0 && totalVideoMs > (studio.musicCropDuration * 1000).round())
          ? totalVideoMs
          : (studio.musicCropDuration * 1000).round();

      // Loop within the crop range if playback position is beyond crop duration
      final effectiveOffsetMs =
          cropLimitMs > 0 ? (globalPositionMs % cropLimitMs) : globalPositionMs;
      final targetMs = musicStartMs + effectiveOffsetMs;
      final trackDurMs = player.duration?.inMilliseconds ?? 0;
      final effectiveMs = (trackDurMs > 0 && targetMs >= trackDurMs)
          ? targetMs % trackDurMs
          : targetMs;
      final seekMs = effectiveMs.clamp(0, 3600000);

      final speedMultiplier = studio.speedMultiplier.clamp(0.4, 4.0);
      final drift = (player.position.inMilliseconds - seekMs).abs();

      if (epoch != _playEpoch) return;
      if (!player.playing || forceSeek || drift > 1800) {
        try {
          await player.seek(Duration(milliseconds: seekMs));
          await player.setSpeed(speedMultiplier);
        } catch (_) {}
        if (epoch != _playEpoch) return;
        // Do NOT await player.play()! In just_audio, play() returns a Future that
        // only completes when playback finishes or is paused/stopped.
        // Awaiting it inside the serial queue causes a permanent deadlock.
        if (!player.playing) {
          unawaited(player.play());
        }
      } else {
        try {
          if ((player.speed - speedMultiplier).abs() > 0.05) {
            await player.setSpeed(speedMultiplier);
          }
        } catch (_) {}
      }
    });
  }

  /// Update playback speed for background audio.
  static Future<void> setPlaybackSpeed(double speed) async {
    await _enqueue(() async {
      final player = _player;
      if (player != null) {
        try {
          await player.setSpeed(speed.clamp(0.4, 4.0));
        } catch (e) {
          debugPrint('StudioMusicPlaybackService setPlaybackSpeed error: $e');
        }
      }
    });
  }

  /// Instantly pause audio playback synchronously without waiting for the async queue.
  static void directPause() {
    try {
      final p = _player;
      if (p != null) {
        p.pause();
      }
    } catch (e) {
      debugPrint('StudioMusicPlaybackService directPause error: $e');
    }
  }

  static Future<void> pause() async {
    _playEpoch++;
    directPause();
    await _enqueue(() async {
      final player = _player;
      if (player != null && player.playing) {
        try {
          await player.pause();
        } catch (_) {}
      }
    }).timeout(const Duration(milliseconds: 300), onTimeout: () => null);
  }

  static Future<void> seekToMs(int ms) async {
    await _enqueue(() async {
      final player = _player;
      if (player == null || _isLoading) return;
      try {
        final trackDurMs = player.duration?.inMilliseconds ?? 0;
        final effectiveMs =
            (trackDurMs > 0 && ms >= trackDurMs) ? ms % trackDurMs : ms;
        await player.seek(Duration(milliseconds: effectiveMs.clamp(0, 3600000)));
      } catch (e) {
        debugPrint('StudioMusicPlaybackService seekToMs error: $e');
      }
    });
  }

  static int _lastSyncCheckMs = 0;

  /// Resume BGM if it dropped out, without seeking (seeking breaks the track).
  static void ensurePlaying() {
    try {
      final p = _player;
      if (p != null && !p.playing && !_isLoading) {
        unawaited(p.play());
      }
    } catch (e) {
      debugPrint('StudioMusicPlaybackService ensurePlaying error: $e');
    }
  }

  /// Keeps background music loosely in sync with video position.
  /// Does not restart or seek during normal playback.
  static Future<void> checkAndSyncVideoPosition(
    StudioCubit studio,
    int videoPositionMs,
  ) async {
    final epoch = _playEpoch;
    final track = _resolveTrack(studio);
    if (track == null || epoch != _playEpoch) return;

    final player = _player;
    if (player == null) {
      // First load never stuck (epoch abort / releaseForVideoPlayback) —
      // reload instead of ensurePlaying() which is a no-op when _player is null.
      unawaited(playForEditor(studio, videoPositionMs, forceSeek: true));
      return;
    }
    if (!player.playing) {
      ensurePlaying();
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    // Soft sync only — aggressive seeking is what makes draft-continue music break.
    if (now - _lastSyncCheckMs < 1200) return;
    _lastSyncCheckMs = now;

    final speedMultiplier = studio.speedMultiplier.clamp(0.4, 4.0);
    try {
      if ((player.speed - speedMultiplier).abs() > 0.05) {
        await player.setSpeed(speedMultiplier);
      }
    } catch (_) {}

    try {
      final musicStartMs = (studio.musicStartSeconds * 1000).round();
      final totalVideoSec = studio.effectiveVideoDuration;
      final totalVideoMs = (totalVideoSec * 1000).round();
      final cropLimitMs = (totalVideoMs > 0 && totalVideoMs > (studio.musicCropDuration * 1000).round())
          ? totalVideoMs
          : (studio.musicCropDuration * 1000).round();
      final effectiveOffsetMs =
          cropLimitMs > 0 ? (videoPositionMs % cropLimitMs) : videoPositionMs;
      final targetMs = musicStartMs + effectiveOffsetMs;
      final trackDurMs = player.duration?.inMilliseconds ?? 0;
      final effectiveMs = (trackDurMs > 0 && targetMs >= trackDurMs)
          ? targetMs % trackDurMs
          : targetMs;
      final currentAudioMs = player.position.inMilliseconds;
      // Only seek on huge drift (e.g. clip loop). Small drift seeking breaks BGM.
      if ((currentAudioMs - effectiveMs).abs() > 2500) {
        await seekToMs(effectiveMs);
      }
    } catch (e) {
      debugPrint('StudioMusicPlaybackService sync check error: $e');
    }
  }

  static Future<void> checkAndSyncPosition(int expectedMs) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    // Throttle to at most once every 350ms to prevent seek floods
    if (now - _lastSyncCheckMs < 350) return;
    _lastSyncCheckMs = now;

    final player = _player;
    if (player == null || _isLoading || !player.playing) return;
    try {
      final currentAudioMs = player.position.inMilliseconds;
      final trackDurMs = player.duration?.inMilliseconds ?? 0;
      final effectiveMs = (trackDurMs > 0 && expectedMs >= trackDurMs)
          ? expectedMs % trackDurMs
          : expectedMs;
      if ((currentAudioMs - effectiveMs).abs() > 500) {
        await seekToMs(effectiveMs);
      }
    } catch (e) {
      debugPrint('StudioMusicPlaybackService sync check error: $e');
    }
  }

  static Future<void> stop() async {
    _playEpoch++;
    directPause();
    final playerToDispose = _player;
    _player = null;
    _loadedTrackId = null;
    _loadedAudioUrl = null;
    _isLoading = false;
    if (playerToDispose != null) {
      await _enqueue(() async {
        try {
          await playerToDispose.stop();
        } catch (_) {}
        try {
          await playerToDispose.dispose();
        } catch (_) {}
      }).timeout(const Duration(milliseconds: 500), onTimeout: () => null);
    }
  }

  /// Releases music audio focus so [VideoPlayerController] can initialize.
  static Future<void> releaseForVideoPlayback() async {
    _playEpoch++;
    directPause();
    final playerToDispose = _player;
    _player = null;
    _loadedTrackId = null;
    _loadedAudioUrl = null;
    _isLoading = false;
    if (playerToDispose != null) {
      await _enqueue(() async {
        try {
          await playerToDispose.stop();
        } catch (_) {}
        try {
          await playerToDispose.dispose();
        } catch (_) {}
        try {
          final session = await AudioSession.instance;
          await session.setActive(false);
        } catch (_) {}
        _sessionConfigured = false;
      }).timeout(const Duration(milliseconds: 500), onTimeout: () => null);
    }
  }
}
