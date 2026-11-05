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
  /// Bumped to abandon in-flight load/stop work when switching/clearing tracks.
  static int _loadEpoch = 0;

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

  /// Drop a stuck queue so a hung dispose/load cannot block the next track forever.
  static void _resetChain() {
    _chain = Future.value();
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
    _loadEpoch++;
    // Abandoned in-flight loads must not leave seek/ensurePlaying blocked.
    _isLoading = false;
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
    final epoch = _loadEpoch;
    await _enqueue(() async {
      if (epoch != _loadEpoch) return;
      await _preloadLocked(studio, epoch);
    });
  }

  /// Pause + force-reload current cubit track without disposing the player.
  /// Prefer this when switching songs so load cannot get stuck behind dispose.
  static Future<void> reloadForStudio(StudioCubit studio) async {
    _playEpoch++;
    directPause();
    invalidateLoadedTrack();
    final epoch = _loadEpoch;
    _resetChain();
    await _enqueue(() async {
      if (epoch != _loadEpoch) return;
      await _preloadLocked(studio, epoch);
    });
  }

  static Future<void> _preloadLocked(StudioCubit studio, int epoch) async {
    final track = _resolveTrack(studio);
    if (track == null) {
      _loadedTrackId = null;
      _loadedAudioUrl = null;
      return;
    }

    if (epoch != _loadEpoch) return;

    if (_loadedTrackId == track.id &&
        _loadedAudioUrl == track.audioUrl &&
        _player != null &&
        !_isLoading) {
      try {
        await _player!.setVolume(studio.musicVolume.clamp(0.0, 1.0));
      } catch (_) {}
      return;
    }

    await _loadTrackLocked(track, studio.musicVolume, epoch);
  }

  static Future<void> _loadTrackLocked(
    FreeToUseTrack track,
    double musicVolume,
    int epoch,
  ) async {
    if (epoch != _loadEpoch) return;
    _isLoading = true;
    try {
      await _configureSession();
      if (epoch != _loadEpoch) return;
      final player = _ensurePlayer();
      try {
        await player.pause();
      } catch (_) {}
      try {
        await player.stop();
      } catch (_) {}
      if (epoch != _loadEpoch) return;

      final url = track.audioUrl.trim();
      if (url.isEmpty) {
        _loadedTrackId = null;
        _loadedAudioUrl = null;
        return;
      }

      await player.setUrl(url).timeout(const Duration(seconds: 8));
      if (epoch != _loadEpoch) return;
      await player.setVolume(musicVolume.clamp(0.0, 1.0));
      await player.setLoopMode(LoopMode.one);
      await player.setSpeed(1.0);
      _loadedTrackId = track.id;
      _loadedAudioUrl = url;
    } catch (e) {
      debugPrint('StudioMusicPlaybackService _loadTrack error: $e');
      if (epoch == _loadEpoch) {
        _loadedTrackId = null;
        _loadedAudioUrl = null;
      }
    } finally {
      // Always clear — ops are serialized, so a newer load will set true again.
      // Leaving this true after epoch abort was blocking cancel→reselect.
      _isLoading = false;
    }
  }

  static Future<void> playForRecording(StudioCubit studio) async {
    await playForEditor(studio, 0);
  }

  static bool get isPlaying => _player?.playing ?? false;
  static bool get isLoading => _isLoading;

  /// Plays background music for the editor starting at [globalPositionMs].
  /// Set [forceSeek] on video loop / restart so BGM rewinds with the video.
  static Future<void> playForEditor(
    StudioCubit studio,
    int globalPositionMs, {
    bool forceSeek = false,
  }) async {
    final epoch = ++_playEpoch;
    final loadEpoch = _loadEpoch;
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
      if (epoch != _playEpoch) return;
      if (_loadedTrackId != track.id ||
          _loadedAudioUrl != track.audioUrl ||
          _player == null) {
        await _loadTrackLocked(track, studio.musicVolume, loadEpoch);
      }
      if (epoch != _playEpoch || loadEpoch != _loadEpoch) return;

      final player = _player;
      if (player == null || _loadedTrackId != track.id) return;

      await player.setVolume(studio.musicVolume.clamp(0.0, 1.0));
      await player.setLoopMode(LoopMode.one);

      // Video globalPosition is source-time; music always plays at 1x and
      // follows output/wall time (= source / videoSpeed).
      final seekMs = _musicSeekMsForVideoPosition(studio, globalPositionMs);

      final drift = (player.position.inMilliseconds - seekMs).abs();

      if (epoch != _playEpoch) return;
      if (!player.playing || forceSeek || drift > 1800) {
        try {
          await player.seek(Duration(milliseconds: seekMs));
          await player.setSpeed(1.0);
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
          if ((player.speed - 1.0).abs() > 0.05) {
            await player.setSpeed(1.0);
          }
        } catch (_) {}
      }
    });
  }

  /// Music must stay at normal pitch/tempo even when video speed changes.
  static Future<void> setPlaybackSpeed(double speed) async {
    await _enqueue(() async {
      final player = _player;
      if (player != null) {
        try {
          await player.setSpeed(1.0);
        } catch (e) {
          debugPrint('StudioMusicPlaybackService setPlaybackSpeed error: $e');
        }
      }
    });
  }

  static Future<void> setVolume(double volume) async {
    await _enqueue(() async {
      final player = _player;
      if (player != null) {
        try {
          await player.setVolume(volume.clamp(0.0, 1.0));
        } catch (e) {
          debugPrint('StudioMusicPlaybackService setVolume error: $e');
        }
      }
    });
  }

  /// Convert video source position → music timeline position (1x output time).
  static int _musicSeekMsForVideoPosition(
    StudioCubit studio,
    int videoSourcePositionMs,
  ) {
    final musicStartMs = (studio.musicStartSeconds * 1000).round();
    final speed = studio.speedMultiplier.clamp(0.4, 4.0);
    final outputPositionMs =
        (videoSourcePositionMs / speed).round().clamp(0, 3600000);

    final outputVideoMs =
        (studio.playbackDurationSeconds * 1000).round().clamp(0, 3600000);
    final cropMs = (studio.musicCropDuration * 1000).round();
    final cropLimitMs = (outputVideoMs > 0 && outputVideoMs > cropMs)
        ? outputVideoMs
        : (cropMs > 0 ? cropMs : outputVideoMs);

    final effectiveOffsetMs =
        cropLimitMs > 0 ? (outputPositionMs % cropLimitMs) : outputPositionMs;
    final targetMs = musicStartMs + effectiveOffsetMs;

    final trackDurMs = _player?.duration?.inMilliseconds ?? 0;
    final effectiveMs = (trackDurMs > 0 && targetMs >= trackDurMs)
        ? targetMs % trackDurMs
        : targetMs;
    return effectiveMs.clamp(0, 3600000);
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

  /// Seek music for a video source-timeline position (applies speed → 1x mapping).
  static Future<void> seekForVideoPosition(
    StudioCubit studio,
    int videoSourcePositionMs,
  ) async {
    await seekToMs(
      _musicSeekMsForVideoPosition(studio, videoSourcePositionMs),
    );
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

    // Never slow/speed the song with the video — always normal tempo.
    try {
      if ((player.speed - 1.0).abs() > 0.05) {
        await player.setSpeed(1.0);
      }
    } catch (_) {}

    try {
      final effectiveMs =
          _musicSeekMsForVideoPosition(studio, videoPositionMs);
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
    _loadEpoch++;
    directPause();
    final playerToDispose = _player;
    _player = null;
    _loadedTrackId = null;
    _loadedAudioUrl = null;
    _isLoading = false;
    // Unblock future reloads even if dispose hangs.
    _resetChain();
    if (playerToDispose != null) {
      unawaited(() async {
        try {
          await playerToDispose.stop();
        } catch (_) {}
        try {
          await playerToDispose.dispose();
        } catch (_) {}
      }());
    }
  }

  /// Releases music audio focus so [VideoPlayerController] can initialize.
  static Future<void> releaseForVideoPlayback() async {
    _playEpoch++;
    _loadEpoch++;
    directPause();
    final playerToDispose = _player;
    _player = null;
    _loadedTrackId = null;
    _loadedAudioUrl = null;
    _isLoading = false;
    _resetChain();
    if (playerToDispose != null) {
      unawaited(() async {
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
      }());
    }
  }
}
