import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import 'package:http/http.dart' as http;

import 'package:artable_app/core/utils/mp4_merger.dart';
import 'package:artable_app/features/studio/data/services/studio_music_playback_service.dart';

/// Initializes a local recorded video after releasing music/camera audio resources.
class StudioVideoPlayerUtils {
  StudioVideoPlayerUtils._();

  static Future<File?> combineVideoFiles(List<String> inputPaths) async {
    if (inputPaths.isEmpty) return null;

    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final mergedFile = File('${tempDir.path}/merged_video_$timestamp.mp4');

      final files = <File>[];
      for (int i = 0; i < inputPaths.length; i++) {
        var clean = inputPaths[i].trim();
        if (clean.startsWith('file://')) clean = clean.replaceFirst('file://', '');

        if (clean.startsWith('http://') || clean.startsWith('https://')) {
          try {
            debugPrint('Downloading remote draft clip for merging ($i/${inputPaths.length}): $clean');
            final response = await http.get(Uri.parse(clean));
            if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
              final tempClipFile = File('${tempDir.path}/remote_clip_${timestamp}_$i.mp4');
              await tempClipFile.writeAsBytes(response.bodyBytes);
              files.add(tempClipFile);
              debugPrint('Downloaded remote clip $i to ${tempClipFile.path} (${response.bodyBytes.length} bytes)');
            } else {
              debugPrint('Failed downloading remote clip $i: status ${response.statusCode}');
            }
          } catch (e) {
            debugPrint('Error downloading remote clip $clean: $e');
          }
        } else {
          final f = File(clean);
          if (await f.exists()) {
            files.add(f);
          }
        }
      }

      if (files.length == 1) {
        await files.first.copy(mergedFile.path);
        return mergedFile;
      }

      if (files.isNotEmpty) {
        final result = await Mp4Merger.mergeMp4Files(files, mergedFile);
        if (result != null && await result.exists() && (await result.length()) > 0) {
          debugPrint('Combined ${files.length} video files using Mp4Merger into ${mergedFile.path}');
          return result;
        }
      }
    } catch (e) {
      debugPrint('Error combining video files with Mp4Merger: $e');
    }
    return null;
  }

  static Future<VideoPlayerController?> initializeClipController(
    String path, {
    bool autoPlay = true,
    bool loop = false,
  }) async {
    var cleanPath = path.trim();
    if (cleanPath.startsWith('file://')) {
      cleanPath = cleanPath.replaceFirst('file://', '');
    }

    try {
      final controller = cleanPath.startsWith('http://') || cleanPath.startsWith('https://')
          ? VideoPlayerController.networkUrl(Uri.parse(cleanPath))
          : VideoPlayerController.file(File(cleanPath));

      await controller.initialize();
      await controller.setLooping(loop);
      if (autoPlay) {
        await controller.play();
      }
      return controller;
    } catch (e) {
      debugPrint('initializeClipController error for $path: $e');
      return null;
    }
  }

  static Future<VideoPlayerController?> initializeRecordedVideo(
    String path, {
    bool autoPlay = true,
    bool loop = true,
  }) async {
    await StudioMusicPlaybackService.releaseForVideoPlayback();

    var cleanPath = path.trim();
    if (cleanPath.startsWith('file://')) {
      cleanPath = cleanPath.replaceFirst('file://', '');
    }

    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      try {
        final controller = VideoPlayerController.networkUrl(Uri.parse(cleanPath));
        await controller.initialize();
        await controller.setLooping(loop);
        if (autoPlay) await controller.play();
        return controller;
      } catch (e) {
        debugPrint('Network video init failed for $cleanPath: $e');
        return null;
      }
    }

    cleanPath = File(cleanPath).absolute.path;

    final file = File(cleanPath);
    final exists = file.existsSync();
    final fileSize = exists ? file.lengthSync() : 0;
    debugPrint('=== VIDEO RECORDING ===');
    debugPrint('Recorded video path: $cleanPath');
    debugPrint('Recorded file exists: $exists');
    debugPrint('Recorded file size: $fileSize');

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
