import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// Generates a real frame thumbnail from a local recorded video.
class VideoThumbnailGenerator {
  VideoThumbnailGenerator._();

  /// Generates a JPEG thumbnail [File] from a local video path.
  static Future<File?> generateThumbnailFromVideo(
    String videoPath, {
    int? timeMs,
  }) async {
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

      // Desired sample times to try: prioritize requested timeMs
      final List<int> candidateTimes = (timeMs != null && timeMs >= 0)
          ? [timeMs, timeMs + 100, (timeMs - 100).clamp(0, 3600000), 500]
          : [500, 800, 1000, 200];

      // 1. Fast in-memory thumbnailData first (both maxWidth & maxHeight so Android getScaledFrameAtTime is used)
      for (final t in candidateTimes) {
        try {
          final data = await VideoThumbnail.thumbnailData(
            video: effectivePath,
            imageFormat: ImageFormat.JPEG,
            maxWidth: 360,
            maxHeight: 360,
            quality: 70,
            timeMs: t,
          ).timeout(const Duration(milliseconds: 2500), onTimeout: () => null);
          if (data != null && data.isNotEmpty && data.length > 200) {
            final file = File(outPath);
            await file.writeAsBytes(data, flush: true);
            debugPrint('VideoThumbnailGenerator: created via thumbnailData at ${file.path} (t=$t ms)');
            return file;
          }
        } catch (_) {}
      }

      // 2. Fallback to thumbnailFile using folder directory (tempDir.path)
      for (final t in candidateTimes) {
        try {
          final generatedPath = await VideoThumbnail.thumbnailFile(
            video: effectivePath,
            thumbnailPath: tempDir.path,
            imageFormat: ImageFormat.JPEG,
            maxWidth: 360,
            maxHeight: 360,
            quality: 70,
            timeMs: t,
          ).timeout(const Duration(milliseconds: 2500), onTimeout: () => null);
          if (generatedPath != null && generatedPath.isNotEmpty) {
            final file = File(generatedPath);
            if (await file.exists() && await file.length() > 0) {
              debugPrint('VideoThumbnailGenerator: created ${file.path}');
              return file;
            }
          }
        } catch (_) {}
      }

      // If remote URL and direct extraction failed, download a small segment (max 3MB) locally
      if (isRemote) {
        try {
          final tempVideo = File('${tempDir.path}/vtemp_$timestamp.mp4');
          final client = HttpClient();
          client.connectionTimeout = const Duration(seconds: 3);
          final req = await client.getUrl(Uri.parse(cleanPath)).timeout(const Duration(seconds: 3));
          final resp = await req.close().timeout(const Duration(seconds: 3));
          if (resp.statusCode >= 200 && resp.statusCode < 300) {
            final sink = tempVideo.openWrite();
            int downloaded = 0;
            const maxDownload = 3 * 1024 * 1024;
            await for (final chunk in resp.timeout(const Duration(seconds: 3))) {
              sink.add(chunk);
              downloaded += chunk.length;
              if (downloaded >= maxDownload) break;
            }
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
                ).timeout(const Duration(milliseconds: 2000));
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

  /// Extracts JPEG frame bytes for a video at a specific [timeMs].
  static Future<Uint8List?> extractFrameBytes(
    String videoPath, {
    int timeMs = 0,
    int maxWidth = 360,
    int maxHeight = 360,
    int quality = 70,
  }) async {
    try {
      var clean = videoPath.trim();
      if (clean.startsWith('file://')) clean = clean.substring(7);
      clean = clean.replaceAll('\\', '/');
      if (clean.isEmpty) return null;

      final data = await VideoThumbnail.thumbnailData(
        video: clean,
        imageFormat: ImageFormat.JPEG,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        quality: quality,
        timeMs: timeMs,
      ).timeout(const Duration(milliseconds: 2500), onTimeout: () => null);

      if (data != null && data.isNotEmpty && data.length > 200) {
        return data;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static final Map<String, List<Uint8List>> _filmstripCache = {};

  /// Clears the entire filmstrip cache in memory.
  static void clearCache() {
    _filmstripCache.clear();
  }

  /// Clears cached frames for a specific video path or clip identifier.
  static void clearCacheForVideo(String videoPath) {
    var clean = videoPath.trim();
    if (clean.startsWith('file://')) clean = clean.substring(7);
    clean = clean.replaceAll('\\', '/');
    _filmstripCache.removeWhere((k, _) => k.contains(clean));
  }

  /// Builds a deterministic, collision-free cache key for a filmstrip segment.
  static String buildCacheKey(
    String videoPath, {
    Duration trimStart = Duration.zero,
    Duration? trimEnd,
    int? count,
    String? extra,
  }) {
    var clean = videoPath.trim();
    if (clean.startsWith('file://')) clean = clean.substring(7);
    clean = clean.replaceAll('\\', '/');
    final sMs = trimStart.inMilliseconds;
    final eMs = trimEnd?.inMilliseconds ?? 0;
    return '${extra ?? ""}_${clean}_${sMs}_${eMs}_${count ?? 0}';
  }

  /// Returns cached filmstrip frames if already extracted.
  static List<Uint8List>? getCachedFilmstripFrames(String cacheKeyOrPath) {
    var clean = cacheKeyOrPath.trim();
    if (clean.startsWith('file://')) clean = clean.substring(7);
    clean = clean.replaceAll('\\', '/');
    return _filmstripCache[clean] ?? _filmstripCache[cacheKeyOrPath];
  }

  /// Generates a list of progressive distinct frame bytes strictly across the
  /// [trimStart] to [trimEnd] trimmed segment of a video.
  static Future<List<Uint8List>> extractFilmstripFrames(
    String videoPath, {
    int targetCount = 7,
    Duration trimStart = Duration.zero,
    Duration? trimEnd,
    Duration? duration,
    String? cacheKeyExtra,
  }) async {
    try {
      var cleanPath = videoPath.trim();
      if (cleanPath.startsWith('file://')) {
        cleanPath = cleanPath.substring(7);
      }
      cleanPath = cleanPath.replaceAll('\\', '/');
      if (cleanPath.isEmpty) return const [];

      final int count = targetCount.clamp(1, 15);
      final cacheKey = buildCacheKey(
        cleanPath,
        trimStart: trimStart,
        trimEnd: trimEnd,
        count: count,
        extra: cacheKeyExtra,
      );

      if (_filmstripCache.containsKey(cacheKey) && _filmstripCache[cacheKey]!.isNotEmpty) {
        return _filmstripCache[cacheKey]!;
      }

      final isRemote = cleanPath.startsWith('http://') || cleanPath.startsWith('https://');
      String effectivePath = cleanPath;

      if (isRemote) {
        final tempDir = await getTemporaryDirectory();
        final urlHash = cleanPath.hashCode.abs();
        final cachedVideo = File('${tempDir.path}/vclip_$urlHash.mp4');
        if (await cachedVideo.exists() && await cachedVideo.length() > 5000) {
          effectivePath = cachedVideo.path;
        } else {
          try {
            final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
            final req = await client.getUrl(Uri.parse(cleanPath));
            final resp = await req.close();
            if (resp.statusCode >= 200 && resp.statusCode < 300) {
              final sink = cachedVideo.openWrite();
              await resp.pipe(sink);
              await sink.flush();
              await sink.close();
              effectivePath = cachedVideo.path;
            }
          } catch (e) {
            debugPrint('VideoThumbnailGenerator remote clip fetch error: $e');
          }
        }
      } else {
        final localFile = File(cleanPath);
        if (!await localFile.exists()) {
          return const [];
        }
      }

      // Calculate exact start and end in ms
      final int startMs = trimStart.inMilliseconds.clamp(0, 3600000);
      int endMs = trimEnd != null ? trimEnd.inMilliseconds : 0;
      if (endMs <= startMs) {
        final fallbackDurMs = (duration != null && duration.inMilliseconds > 500)
            ? duration.inMilliseconds
            : 6000;
        endMs = fallbackDurMs;
      }
      if (endMs <= startMs) {
        endMs = startMs + 6000;
      }

      final int segmentMs = endMs - startMs;

      // Compute exact center sample time for each timeline cell slot
      final List<int> sampleTimes = [];
      for (int i = 0; i < count; i++) {
        final double ratio = (count <= 1) ? 0.5 : ((i + 0.5) / count);
        final int t = startMs + (segmentMs * ratio).round();
        sampleTimes.add(t);
      }

      final List<Uint8List?> slotFrames = List.filled(count, null);
      for (int i = 0; i < count; i++) {
        final tMs = sampleTimes[i];
        Uint8List? data;
        try {
          data = await VideoThumbnail.thumbnailData(
            video: effectivePath,
            imageFormat: ImageFormat.JPEG,
            maxWidth: 120,
            maxHeight: 120,
            quality: 45,
            timeMs: tMs,
          ).timeout(const Duration(milliseconds: 2500), onTimeout: () => null);
        } catch (_) {}

        if (data != null && data.isNotEmpty && data.length > 200) {
          slotFrames[i] = data;
        }

        // Brief yield so Android MediaMetadataRetriever recovers
        await Future.delayed(const Duration(milliseconds: 10));
      }

      // Fill any missing slots with the closest available slot's frame
      Uint8List? lastAvailable;
      for (int i = 0; i < count; i++) {
        if (slotFrames[i] != null) {
          lastAvailable = slotFrames[i];
        } else if (lastAvailable != null) {
          slotFrames[i] = lastAvailable;
        }
      }
      Uint8List? nextAvailable;
      for (int i = count - 1; i >= 0; i--) {
        if (slotFrames[i] != null) {
          nextAvailable = slotFrames[i];
        } else if (nextAvailable != null) {
          slotFrames[i] = nextAvailable;
        }
      }

      // Final single-frame fallback if all slots failed
      if (slotFrames.every((f) => f == null)) {
        try {
          final single = await VideoThumbnail.thumbnailData(
            video: effectivePath,
            imageFormat: ImageFormat.JPEG,
            maxWidth: 120,
            maxHeight: 120,
            quality: 45,
            timeMs: (startMs + 250).clamp(0, endMs),
          ).timeout(const Duration(milliseconds: 2000), onTimeout: () => null);
          if (single != null && single.isNotEmpty) {
            slotFrames.fillRange(0, count, single);
          }
        } catch (_) {}
      }

      final List<Uint8List> finalFrames = slotFrames.whereType<Uint8List>().toList();

      if (finalFrames.isNotEmpty) {
        _filmstripCache[cacheKey] = finalFrames;
        return finalFrames;
      }

      return const [];
    } catch (e) {
      debugPrint('VideoThumbnailGenerator extractFilmstripFrames error: $e');
      return const [];
    }
  }
}
