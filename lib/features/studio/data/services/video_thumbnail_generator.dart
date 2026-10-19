import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// Generates a real frame thumbnail from a local recorded video.
class VideoThumbnailGenerator {
  VideoThumbnailGenerator._();

  /// Generates a JPEG thumbnail [File] from a local video path.
  static Future<File?> generateThumbnailFromVideo(String videoPath) async {
    try {
      var cleanPath = videoPath.trim();
      if (cleanPath.startsWith('file://')) {
        cleanPath = cleanPath.replaceFirst('file://', '');
      }
      final videoFile = File(cleanPath);
      if (!await videoFile.exists()) {
        debugPrint('VideoThumbnailGenerator: File not found at $cleanPath');
        return null;
      }

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outPath = '${tempDir.path}/thumb_$timestamp.jpg';

      final generatedPath = await VideoThumbnail.thumbnailFile(
        video: cleanPath,
        thumbnailPath: outPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 720,
        quality: 75,
        timeMs: 1000,
      );

      if (generatedPath == null || generatedPath.isEmpty) {
        debugPrint('VideoThumbnailGenerator: thumbnailFile returned null');
        return null;
      }

      final file = File(generatedPath);
      if (!await file.exists() || await file.length() <= 0) {
        debugPrint('VideoThumbnailGenerator: empty thumbnail file');
        return null;
      }

      debugPrint('VideoThumbnailGenerator: created ${file.path}');
      return file;
    } catch (e) {
      debugPrint('VideoThumbnailGenerator error: $e');
      return null;
    }
  }
}
