import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

import 'package:artable_app/features/studio/data/services/studio_music_playback_service.dart';

/// Initializes a local recorded video after releasing music/camera audio resources.
class StudioVideoPlayerUtils {
  StudioVideoPlayerUtils._();

  static Future<VideoPlayerController?> initializeRecordedVideo(
    String path, {
    bool autoPlay = true,
    bool loop = true,
  }) async {
    await StudioMusicPlaybackService.releaseForVideoPlayback();

    var cleanPath = path;
    if (cleanPath.startsWith('file://')) {
      cleanPath = cleanPath.replaceFirst('file://', '');
    }
    cleanPath = File(cleanPath).absolute.path;

    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      try {
        final controller = VideoPlayerController.networkUrl(Uri.parse(cleanPath));
        await controller.initialize();
        await controller.setLooping(loop);
        if (autoPlay) await controller.play();
        return controller;
      } catch (e) {
        debugPrint('Network video init failed: $e');
        return null;
      }
    }

    final file = File(cleanPath);
    if (!await _waitForRecordedFile(file)) {
      debugPrint('Recorded video file not ready: $cleanPath');
      return null;
    }

    VideoPlayerController? controller;

    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        final fileController = VideoPlayerController.file(file);
        await fileController.initialize().timeout(
          const Duration(seconds: 8),
          onTimeout: () => throw TimeoutException('Video initialization timed out'),
        );
        controller = fileController;

        await controller.setLooping(loop);
        if (autoPlay) {
          await controller.play();
        }
        debugPrint('Recorded video initialized at $cleanPath');
        return controller;
      } catch (e) {
        debugPrint('initializeRecordedVideo attempt $attempt error: $e');
        try {
          await controller?.dispose();
        } catch (_) {}
        controller = null;
        if (attempt < 3) {
          await Future.delayed(Duration(milliseconds: 150 * attempt));
        }
      }
    }

    return null;
  }

  static Future<bool> _waitForRecordedFile(File file) async {
    var lastSize = -1;

    for (var attempt = 0; attempt < 20; attempt++) {
      if (!file.existsSync()) {
        await Future.delayed(const Duration(milliseconds: 100));
        continue;
      }

      final size = file.lengthSync();
      if (size > 0 && size == lastSize) {
        return true;
      }

      lastSize = size;
      await Future.delayed(const Duration(milliseconds: 100));
    }

    return file.existsSync() && file.lengthSync() > 0;
  }
}
