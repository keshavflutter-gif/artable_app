import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'package:artable_app/features/studio/presentation/bloc/studio_cubit.dart';
import 'package:artable_app/data/datasources/music_api_service.dart';

/// Plays the selected studio track during video recording with preloading.
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
          avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
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
    final track = studio.selectedTrack;
    if (track == null) {
      _loadedTrackId = null;
      return;
    }

    if (_loadedTrackId == track.id) return;

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
      await player.setUrl(track.audioUrl).timeout(const Duration(seconds: 4));
      _loadedTrackId = track.id;
    } catch (e) {
      debugPrint('StudioMusicPlaybackService preload error: $e');
      _loadedTrackId = null;
    }
  }

  static Future<void> playForRecording(StudioCubit studio) async {
    final track = studio.selectedTrack;
    if (track == null) return;

    try {
      await _configureSession();
      if (_loadedTrackId != track.id) {
        await preloadForStudio(studio);
      }
      final startMs = (studio.musicStartSeconds * 1000).round();
      await _audioPlayer.seek(Duration(milliseconds: startMs));
      await _audioPlayer.setSpeed(studio.speedMultiplier);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('StudioMusicPlaybackService play error: $e');
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
