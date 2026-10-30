import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import 'package:artable_app/core/utils/media_url_utils.dart';

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
      cleanPath = MediaUrlUtils.resolve(cleanPath).trim();
      if (cleanPath.isEmpty) return null;
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
      clean = MediaUrlUtils.resolve(clean).trim().replaceAll('\\', '/');
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
  static final Map<String, Future<List<Uint8List>>> _inflightFilmstrip = {};
  static final Map<String, List<void Function(List<Uint8List>)>> _partialListeners = {};

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
    return '${extra ?? ""}_${clean}_${sMs}_$eMs';
  }

  /// Returns cached filmstrip frames if already extracted.
  static List<Uint8List>? getCachedFilmstripFrames(String cacheKeyOrPath) {
    var clean = cacheKeyOrPath.trim();
    if (clean.startsWith('file://')) clean = clean.substring(7);
    clean = clean.replaceAll('\\', '/');
    return _filmstripCache[clean] ?? _filmstripCache[cacheKeyOrPath];
  }

  static bool _isSameFrame(Uint8List a, Uint8List b) {
    if (identical(a, b) || a.length != b.length) return a.length == b.length;
    final step = (a.length / 12).floor().clamp(1, a.length);
    for (int i = 0; i < a.length; i += step) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static void _emitPartial(String cacheKey, List<Uint8List> frames) {
    if (frames.isEmpty) return;
    _filmstripCache[cacheKey] = frames;
    final listeners = _partialListeners[cacheKey];
    if (listeners == null) return;
    for (final listener in List<void Function(List<Uint8List>)>.from(listeners)) {
      try {
        listener(frames);
      } catch (_) {}
    }
  }

  static Future<Uint8List?> _frameAt(String videoPath, int timeMs) async {
    try {
      final data = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 80,
        maxHeight: 80,
        quality: 50,
        timeMs: timeMs.clamp(0, 3600000),
      ).timeout(const Duration(milliseconds: 900), onTimeout: () => null);
      if (data != null && data.isNotEmpty && data.length > 200) return data;
    } catch (_) {}
    return null;
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
    void Function(List<Uint8List> frames)? onPartial,
  }) async {
    try {
      var cleanPath = videoPath.trim();
      if (cleanPath.startsWith('file://')) {
        cleanPath = cleanPath.substring(7);
      }
      cleanPath = MediaUrlUtils.resolve(cleanPath).trim().replaceAll('\\', '/');
      if (cleanPath.isEmpty) return const [];

      final int count = targetCount.clamp(1, 8);
      final cacheKey = buildCacheKey(
        cleanPath,
        trimStart: trimStart,
        trimEnd: trimEnd,
        extra: cacheKeyExtra,
      );

      final cached = _filmstripCache[cacheKey];
      if (cached != null && cached.length > 1) {
        onPartial?.call(cached);
        return cached;
      }

      if (onPartial != null) {
        _partialListeners.putIfAbsent(cacheKey, () => []).add(onPartial);
      }

      final inflight = _inflightFilmstrip[cacheKey];
      if (inflight != null) {
        try {
          return await inflight;
        } finally {
          _partialListeners[cacheKey]?.remove(onPartial);
        }
      }

      final extractFuture = _extractFilmstripUncached(
        cleanPath: cleanPath,
        cacheKey: cacheKey,
        count: count,
        trimStart: trimStart,
        trimEnd: trimEnd,
        duration: duration,
      );
      _inflightFilmstrip[cacheKey] = extractFuture;
      try {
        return await extractFuture;
      } finally {
        _inflightFilmstrip.remove(cacheKey);
        _partialListeners.remove(cacheKey);
      }
    } catch (e) {
      debugPrint('VideoThumbnailGenerator extractFilmstripFrames error: $e');
      return const [];
    }
  }

  static Future<List<Uint8List>> _extractFilmstripUncached({
    required String cleanPath,
    required String cacheKey,
    required int count,
    required Duration trimStart,
    Duration? trimEnd,
    Duration? duration,
  }) async {
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

    final int segmentMs = (endMs - startMs).clamp(1, 3600000);
    final List<Uint8List?> slotFrames = List.filled(count, null);
    Uint8List? previous;

    for (int i = 0; i < count; i++) {
      final double ratio = (count <= 1) ? 0.5 : ((i + 0.5) / count);
      int tMs = startMs + (segmentMs * ratio).round();
      Uint8List? data = await _frameAt(effectivePath, tMs);

      if (data != null && previous != null && _isSameFrame(previous, data)) {
        for (final bump in [400, 800, 1200]) {
          final retryAt = (tMs + bump).clamp(startMs, endMs);
          if (retryAt == tMs) continue;
          final retry = await _frameAt(effectivePath, retryAt);
          if (retry != null && !_isSameFrame(previous, retry)) {
            data = retry;
            break;
          }
        }
      }

      if (data != null) {
        slotFrames[i] = data;
        previous = data;
        final prefix = <Uint8List>[];
        for (final slot in slotFrames) {
          if (slot == null) break;
          prefix.add(slot);
        }
        _emitPartial(cacheKey, prefix);
      }

      await Future<void>.delayed(Duration.zero);
    }

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

    final List<Uint8List> finalFrames = slotFrames.whereType<Uint8List>().toList();
    if (finalFrames.isNotEmpty) {
      _filmstripCache[cacheKey] = finalFrames;
      _emitPartial(cacheKey, finalFrames);
    }
    return finalFrames;
  }
}
