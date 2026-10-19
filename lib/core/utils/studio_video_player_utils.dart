import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import 'package:http/http.dart' as http;

import 'package:artable_app/core/utils/mp4_merger.dart';

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
      final tempRemoteFiles = <File>[];
      for (int i = 0; i < inputPaths.length; i++) {
        var clean = inputPaths[i].trim();
        if (clean.startsWith('file://')) clean = clean.replaceFirst('file://', '');

        // Resolve relative backend URLs to absolute URLs
        if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
          if (clean.startsWith('/') && !File(clean).existsSync()) {
            clean = 'http://server.keshavinfotechdemo2.com:3055$clean';
          } else if (clean.contains('uploads/') && !File(clean).existsSync()) {
            clean = 'http://server.keshavinfotechdemo2.com:3055/${clean.replaceFirst(RegExp(r'^/+'), '')}';
          }
        }

        if (clean.startsWith('http://') || clean.startsWith('https://')) {
          try {
            debugPrint('Downloading remote draft clip for merging ($i/${inputPaths.length}): $clean');
            final response = await http.get(Uri.parse(clean));
            if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
              final tempClipFile = File('${tempDir.path}/remote_clip_${timestamp}_$i.mp4');
              await tempClipFile.writeAsBytes(response.bodyBytes);
              files.add(tempClipFile);
              tempRemoteFiles.add(tempClipFile);
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

      File? mergedResult;
      if (files.length == 1 && inputPaths.length == 1) {
        await files.first.copy(mergedFile.path);
        mergedResult = mergedFile;
      } else if (files.length > 1) {
        final result = await Mp4Merger.mergeMp4Files(files, mergedFile);
        if (result != null && await result.exists() && (await result.length()) > 0) {
          // Mp4Merger can produce a non-empty but unplayable file — validate.
          final playable = await canPlayVideoFile(result.path);
          if (playable) {
            debugPrint(
              'Combined ${files.length} video files using Mp4Merger into ${mergedFile.path}',
            );
            mergedResult = result;
          } else {
            final len = await result.length();
            debugPrint(
              'Mp4Merger output validation returned false (length: $len bytes): ${result.path}',
            );
            // If canPlayVideoFile returned false, the container cannot be decoded reliably by VideoPlayer.
            // Do not return an unplayable file; callers will use the clip playlist and files.first.
            try {
              await result.delete();
            } catch (_) {}
          }
        }
      }

      for (final tempF in tempRemoteFiles) {
        try {
          if (await tempF.exists()) await tempF.delete();
        } catch (_) {}
      }

      return mergedResult;
    } catch (e) {
      debugPrint('Error combining video files with Mp4Merger: $e');
    }
    return null;
  }

  /// Returns true if [path] can be opened by VideoPlayer.
  static Future<bool> canPlayVideoFile(String path) async {
    var cleanPath = path.trim();
    if (cleanPath.startsWith('file://')) {
      cleanPath = cleanPath.replaceFirst('file://', '');
    }
    if (cleanPath.isEmpty) return false;
    if (!cleanPath.startsWith('http')) {
      final file = File(cleanPath);
      if (!file.existsSync() || file.lengthSync() <= 0) return false;
    }

    VideoPlayerController? controller;
    try {
      controller = cleanPath.startsWith('http://') || cleanPath.startsWith('https://')
          ? VideoPlayerController.networkUrl(Uri.parse(cleanPath))
          : VideoPlayerController.file(File(cleanPath));
      await controller.initialize().timeout(const Duration(seconds: 8));
      return controller.value.isInitialized &&
          controller.value.duration.inMilliseconds > 0;
    } catch (e) {
      debugPrint('canPlayVideoFile failed for $cleanPath: $e');
      return false;
    } finally {
      try {
        await controller?.dispose();
      } catch (_) {}
    }
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
    bool copyToStableTemp = false,
  }) async {
    var cleanPath = path.trim();
    if (cleanPath.startsWith('file://')) {
      cleanPath = cleanPath.replaceFirst('file://', '');
    }

    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      try {
        final controller = VideoPlayerController.networkUrl(Uri.parse(cleanPath));
        await controller.initialize();
        await controller.setLooping(loop);
        if (autoPlay) {
          try {
            await controller.play();
          } catch (_) {}
        }
        return controller;
      } catch (e) {
        debugPrint('Network video init failed for $cleanPath: $e');
        return null;
      }
    }

    cleanPath = File(cleanPath).absolute.path;

    var file = File(cleanPath);
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

    // Camera cache files can stay locked briefly — copy to a stable temp path.
    if (copyToStableTemp) {
      final stable = await _copyToStableTemp(file);
      if (stable != null) {
        file = stable;
        cleanPath = stable.path;
        debugPrint('Recorded video copied to stable path: $cleanPath');
      }
    }

    VideoPlayerController? controller;

    for (int attempt = 1; attempt <= 5; attempt++) {
      try {
        final fileController = VideoPlayerController.file(file);
        await fileController.initialize().timeout(
          const Duration(seconds: 12),
          onTimeout: () => throw TimeoutException('Video initialization timed out'),
        );
        if (!fileController.value.isInitialized ||
            fileController.value.duration == Duration.zero) {
          throw Exception('Controller initialized with empty duration');
        }
        controller = fileController;

        await controller.setLooping(loop);
        if (autoPlay) {
          try {
            await controller.play();
          } catch (playErr) {
            // Init succeeded — preview can still show even if autoplay fails.
            debugPrint('initializeRecordedVideo play warning: $playErr');
          }
        }
        debugPrint('Recorded video initialized at $cleanPath');
        return controller;
      } catch (e) {
        debugPrint('initializeRecordedVideo attempt $attempt error: $e');
        try {
          await controller?.dispose();
        } catch (_) {}
        controller = null;
        if (attempt < 5) {
          await Future.delayed(Duration(milliseconds: 250 * attempt));
        }
      }
    }

    return null;
  }

  static Future<File?> _copyToStableTemp(File source) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final dest = File(
        '${tempDir.path}/preview_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );
      await source.copy(dest.path);
      if (await dest.exists() && await dest.length() > 0) {
        return dest;
      }
    } catch (e) {
      debugPrint('Stable temp copy failed: $e');
    }
    return null;
  }

  static Future<bool> _waitForRecordedFile(File file) async {
    var lastSize = -1;
    var stableCount = 0;

    // Up to ~5s for MediaRecorder flush after stopVideoRecording.
    for (var attempt = 0; attempt < 40; attempt++) {
      if (!file.existsSync()) {
        await Future.delayed(const Duration(milliseconds: 125));
        continue;
      }

      final size = file.lengthSync();
      // Ignore tiny incomplete files.
      if (size > 1024 && size == lastSize) {
        stableCount++;
        if (stableCount >= 2) return true;
      } else {
        stableCount = 0;
      }

      lastSize = size;
      await Future.delayed(const Duration(milliseconds: 125));
    }

    return file.existsSync() && file.lengthSync() > 1024;
  }
}
