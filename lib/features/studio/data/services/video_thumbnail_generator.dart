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
      final isRemote = cleanPath.startsWith('http://') || cleanPath.startsWith('https://');
      if (!isRemote) {
        final videoFile = File(cleanPath);
        if (!await videoFile.exists()) {
          debugPrint('VideoThumbnailGenerator: File not found at $cleanPath');
          return null;
        }
      }

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outPath = '${tempDir.path}/thumb_$timestamp.jpg';

      String effectivePath = cleanPath;
      File? downloadedTempVideo;

      // If remote URL, and direct attempts might fail on some Android devices,
      // prepare local file download if needed
      var generatedPath = await VideoThumbnail.thumbnailFile(
        video: effectivePath,
        thumbnailPath: outPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 720,
        quality: 75,
        timeMs: 200,
      );

      if (generatedPath == null || generatedPath.isEmpty) {
        generatedPath = await VideoThumbnail.thumbnailFile(
          video: effectivePath,
          thumbnailPath: outPath,
          imageFormat: ImageFormat.JPEG,
          maxWidth: 720,
          quality: 75,
          timeMs: 0,
        );
      }

      if (generatedPath == null || generatedPath.isEmpty) {
        generatedPath = await VideoThumbnail.thumbnailFile(
          video: effectivePath,
          thumbnailPath: outPath,
          imageFormat: ImageFormat.JPEG,
          maxWidth: 720,
          quality: 75,
          timeMs: 500,
        );
      }

      if (generatedPath != null && generatedPath.isNotEmpty) {
        final file = File(generatedPath);
        if (await file.exists() && await file.length() > 0) {
          debugPrint('VideoThumbnailGenerator: created ${file.path}');
          return file;
        }
      }

      // Try thumbnailData in-memory extraction
      for (final t in [200, 0, 500, -1]) {
        try {
          final data = await VideoThumbnail.thumbnailData(
            video: effectivePath,
            imageFormat: ImageFormat.JPEG,
            maxWidth: 720,
            quality: 75,
            timeMs: t,
          );
          if (data != null && data.isNotEmpty) {
            final file = File(outPath);
            await file.writeAsBytes(data, flush: true);
            debugPrint('VideoThumbnailGenerator: created via thumbnailData at ${file.path}');
            return file;
          }
        } catch (_) {}
      }

      // If remote URL and direct extraction failed, download complete video file locally
      if (isRemote) {
        try {
          final tempVideo = File('${tempDir.path}/vtemp_$timestamp.mp4');
          final client = HttpClient();
          final req = await client.getUrl(Uri.parse(cleanPath));
          final resp = await req.close();
          if (resp.statusCode >= 200 && resp.statusCode < 300) {
            final sink = tempVideo.openWrite();
            await resp.pipe(sink);
            await sink.flush();
            await sink.close();
            downloadedTempVideo = tempVideo;
            effectivePath = tempVideo.path;

            for (final t in [200, 0, 500, -1]) {
              try {
                final data = await VideoThumbnail.thumbnailData(
                  video: effectivePath,
                  imageFormat: ImageFormat.JPEG,
                  maxWidth: 720,
                  quality: 75,
                  timeMs: t,
                );
                if (data != null && data.isNotEmpty) {
                  final file = File(outPath);
                  await file.writeAsBytes(data, flush: true);
                  debugPrint('VideoThumbnailGenerator: created via remote-downloaded video at ${file.path}');
                  return file;
                }
              } catch (_) {}
            }
          }
        } catch (e) {
          debugPrint('VideoThumbnailGenerator remote download error: $e');
        } finally {
          if (downloadedTempVideo != null && await downloadedTempVideo.exists()) {
            try {
              await downloadedTempVideo.delete();
            } catch (_) {}
          }
        }
      }

      debugPrint('VideoThumbnailGenerator: failed to extract thumbnail from $videoPath');
      return null;
    } catch (e) {
      debugPrint('VideoThumbnailGenerator error: $e');
      return null;
    }
  }
}
