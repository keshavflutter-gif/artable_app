import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'package:artable_app/features/studio/presentation/bloc/studio_cubit.dart';
import 'package:artable_app/data/datasources/music_api_service.dart';

/// Plays the selected studio track during video recording and video editing with preloading.
class StudioMusicPlaybackService {
  StudioMusicPlaybackService._();

  static AudioPlayer? _player;
  static String? _loadedTrackId;
  static Future<void>? _preloadFuture;
  static bool _sessionConfigured = false;

  static AudioPlayer get _audioPlayer => _player ??= AudioPlayer();

  static Future<void> _configureSession() async {
    if (_sessionConfigured) return;
    try {
      final session = await AudioSession.instance;
      await session.configure(
        const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
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
    final musicStr = studio.selectedMusic;
    if (musicStr == null || musicStr.trim().isEmpty) return null;

    final cached = MusicApiService.cachedTracks;
    final fallbacks = MusicApiService.fallbackTracks;
    final allTracks = cached != null && cached.isNotEmpty ? cached : fallbacks;

    final targetLower = musicStr.trim().toLowerCase();
    for (final t in allTracks) {
      final titleArtist = '${t.title} — ${t.artist}'.toLowerCase();
      if (titleArtist == targetLower ||
          t.title.toLowerCase() == targetLower ||
          targetLower.contains(t.title.toLowerCase())) {
        return t;
      }
    }
    return allTracks.first;
  }

  /// Prepares audio session and player before camera recording starts.
  static Future<void> prepareForRecordingStart() async {
    try {
      await _configureSession();
      final player = _player;
      if (player != null && player.playing) {
        await player.pause();
      }
    } catch (e) {
      debugPrint('StudioMusicPlaybackService prepareForRecordingStart error: $e');
    }
  }

  static Future<void> preloadForStudio(StudioCubit studio) async {
    final track = _resolveTrack(studio);
    if (track == null) {
      _loadedTrackId = null;
      return;
    }

    if (_loadedTrackId == track.id && _player != null) return;

    if (_preloadFuture != null) return;

    _preloadFuture = _loadTrack(track);
    try {
      await _preloadFuture;
    } catch (e) {
      debugPrint('StudioMusicPlaybackService preload error: $e');
    } finally {
      _preloadFuture = null;
    }
  }

  static Future<void> _loadTrack(FreeToUseTrack track) async {
    try {
      await _configureSession();
      final player = _audioPlayer;
      try {
        await player.stop();
      } catch (_) {}
      await player.setUrl(track.audioUrl).timeout(const Duration(seconds: 5));
      await player.setVolume(1.0);
      await player.setLoopMode(LoopMode.one);
      _loadedTrackId = track.id;
    } catch (e) {
      debugPrint('StudioMusicPlaybackService _loadTrack error: $e');
      _loadedTrackId = null;
    }
  }

  static Future<void> playForRecording(StudioCubit studio) async {
    await playForEditor(studio, 0);
  }

  /// Plays global background music for the multi-video editor starting at [globalPositionMs].
  static Future<void> playForEditor(StudioCubit studio, int globalPositionMs) async {
    final track = _resolveTrack(studio);
    if (track == null) {
      await pause();
      return;
    }

    try {
      await _configureSession();
      if (_loadedTrackId != track.id || _player == null) {
        await preloadForStudio(studio);
      }
      final player = _audioPlayer;
      await player.setVolume(1.0);
      await player.setLoopMode(LoopMode.one);

      final musicStartMs = (studio.musicStartSeconds * 1000).round();
      final targetMs = musicStartMs + globalPositionMs;
      final trackDurMs = player.duration?.inMilliseconds ?? 0;
      final effectiveMs = (trackDurMs > 0 && targetMs >= trackDurMs)
          ? targetMs % trackDurMs
          : targetMs;

      if (!player.playing) {
        await player.seek(Duration(milliseconds: effectiveMs.clamp(0, 3600000)));
        await player.setSpeed(1.0);
        await player.play();
      } else {
        final currentAudioMs = player.position.inMilliseconds;
        if ((currentAudioMs - effectiveMs).abs() > 250) {
          await player.seek(Duration(milliseconds: effectiveMs.clamp(0, 3600000)));
        }
      }
    } catch (e) {
      debugPrint('StudioMusicPlaybackService playForEditor error: $e');
    }
  }

  static Future<void> pause() async {
    try {
      final player = _player;
      if (player != null && player.playing) {
        await player.pause();
      }
    } catch (e) {
      debugPrint('StudioMusicPlaybackService pause error: $e');
    }
  }

  static Future<void> seekToMs(int ms) async {
    try {
      final player = _player;
      if (player != null) {
        final trackDurMs = player.duration?.inMilliseconds ?? 0;
        final effectiveMs = (trackDurMs > 0 && ms >= trackDurMs) ? ms % trackDurMs : ms;
        await player.seek(Duration(milliseconds: effectiveMs.clamp(0, 3600000)));
      }
    } catch (e) {
      debugPrint('StudioMusicPlaybackService seek error: $e');
    }
  }

  static Future<void> checkAndSyncPosition(int expectedMs) async {
    try {
      final player = _player;
      if (player != null && player.playing) {
        final currentAudioMs = player.position.inMilliseconds;
        final trackDurMs = player.duration?.inMilliseconds ?? 0;
        final effectiveMs = (trackDurMs > 0 && expectedMs >= trackDurMs)
            ? expectedMs % trackDurMs
            : expectedMs;
        if ((currentAudioMs - effectiveMs).abs() > 250) {
          await player.seek(Duration(milliseconds: effectiveMs.clamp(0, 3600000)));
        }
      }
    } catch (e) {
      debugPrint('StudioMusicPlaybackService sync check error: $e');
    }
  }

  static Future<void> stop() async {
    try {
      final player = _player;
      _player = null;
      if (player != null) {
        await player.stop();
        await player.dispose();
      }
      _loadedTrackId = null;
    } catch (e) {
      debugPrint('StudioMusicPlaybackService stop error: $e');
    }
  }

  /// Releases music audio focus so [VideoPlayerController] can initialize immediately.
  static Future<void> releaseForVideoPlayback() async {
    try {
      final player = _player;
      _player = null;
      if (player != null) {
        await player.stop();
        await player.dispose();
      }
      final session = await AudioSession.instance;
      await session.setActive(false);
      _sessionConfigured = false;
      _loadedTrackId = null;
    } catch (e) {
      debugPrint('StudioMusicPlaybackService release error: $e');
    }
  }
}


