import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import 'package:artable_app/core/utils/media_url_utils.dart';

/// Centralized manager for high-performance video caching and smooth playback.
/// Eliminates network lag, stuttering, and decoder contention.
abstract final class VideoCacheManager {
  VideoCacheManager._();

  static final Map<String, Future<File?>> _inFlightDownloads = {};
  static final Set<String> _completedUrls = {};

  /// Computes a stable hash for any URL to identify its cache file.
  static String computeHash(String url) {
    return md5.convert(utf8.encode(url.trim())).toString();
  }

  /// Checks if a fully downloaded local copy of the video exists on disk.
  static Future<File?> findCachedVideoFile(String? rawUrl) async {
    if (rawUrl == null) return null;
    var clean = rawUrl.trim();
    if (clean.isEmpty || clean == 'null') return null;

    if (clean.startsWith('file://')) {
      clean = clean.replaceFirst('file://', '');
    }

    // Direct local file check
    if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
      final f = File(clean);
      if (f.existsSync() && f.lengthSync() > 1024) {
        return f;
      }
    }

    final resolved = MediaUrlUtils.resolve(clean).trim();
    if (resolved.isEmpty) return null;

    if (!resolved.startsWith('http://') && !resolved.startsWith('https://')) {
      final f = File(resolved);
      if (f.existsSync() && f.lengthSync() > 1024) {
        return f;
      }
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final urlHash = computeHash(resolved);
      final rawHash = computeHash(clean);

      String fileName = '';
      try {
        final uri = Uri.parse(resolved);
        if (uri.pathSegments.isNotEmpty) {
          fileName = uri.pathSegments.last;
        }
      } catch (_) {}

      final candidates = <File>[
        File('${tempDir.path}/shared_videos/cached_video_$urlHash.mp4'),
        File('${tempDir.path}/shared_videos/cached_video_$rawHash.mp4'),
        File('${tempDir.path}/cached_video_$urlHash.mp4'),
        File('${tempDir.path}/cached_video_$rawHash.mp4'),
        if (fileName.isNotEmpty) ...[
          File('${tempDir.path}/shared_videos/$fileName'),
          File('${tempDir.path}/$fileName'),
        ],
        File('${tempDir.path}/vclip_$urlHash.mp4'),
        File('${tempDir.path}/v_${resolved.hashCode.abs()}.mp4'),
        File('${tempDir.path}/vdl_${resolved.hashCode.abs()}.mp4'),
      ];

      for (final candidate in candidates) {
        if (candidate.existsSync()) {
          try {
            if (candidate.lengthSync() > 30000) {
              return candidate;
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('[VideoCacheManager] Error finding cached file: $e');
    }

    return null;
  }

  /// Silently pre-caches a remote video to local storage in background.
  /// Uses streamed atomic write to avoid blocking and never throws unhandled StreamSink errors.
  static Future<File?> precacheVideo(String? rawUrl) async {
    if (rawUrl == null) return null;
    final clean = MediaUrlUtils.resolve(rawUrl).trim();
    if (clean.isEmpty || (!clean.startsWith('http://') && !clean.startsWith('https://'))) {
      return null;
    }

    if (_completedUrls.contains(clean)) {
      return findCachedVideoFile(clean);
    }

    // Check if already on disk
    final existing = await findCachedVideoFile(clean);
    if (existing != null) {
      _completedUrls.add(clean);
      return existing;
    }

    final urlHash = computeHash(clean);

    // If already in flight, reuse existing future
    if (_inFlightDownloads.containsKey(urlHash)) {
      return _inFlightDownloads[urlHash];
    }

    final future = _executeDownload(clean, urlHash);
    _inFlightDownloads[urlHash] = future;

    try {
      final result = await future;
      if (result != null) {
        _completedUrls.add(clean);
      }
      return result;
    } finally {
      _inFlightDownloads.remove(urlHash);
    }
  }

  static Future<File?> _executeDownload(String url, String urlHash) async {
    HttpClient? client;
    File? tmpFile;

    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${tempDir.path}/shared_videos');
      if (!cacheDir.existsSync()) {
        try {
          cacheDir.createSync(recursive: true);
        } catch (_) {}
      }

      final targetFile = File('${cacheDir.path}/cached_video_$urlHash.mp4');

      final uri = Uri.tryParse(url);
      if (uri == null) return null;

      client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 15)
        ..idleTimeout = const Duration(seconds: 15)
        ..badCertificateCallback = ((cert, host, port) => true);

      final req = await client.getUrl(uri);
      req.headers.set(HttpHeaders.userAgentHeader,
          'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Artable/1.0');
      req.headers.set(HttpHeaders.acceptHeader, '*/*');

      final resp = await req.close().timeout(const Duration(seconds: 25));
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        return null;
      }
      final expectedLength = resp.contentLength;

      tmpFile = File('${cacheDir.path}/tmp_${urlHash}_${DateTime.now().millisecondsSinceEpoch}.tmp');
      final sink = tmpFile.openWrite(mode: FileMode.writeOnly);

      try {
        await for (final chunk in resp.timeout(const Duration(minutes: 2))) {
          sink.add(chunk);
        }
      } finally {
        await sink.flush();
        await sink.close();
      }

      final actualLength = tmpFile.existsSync() ? tmpFile.lengthSync() : 0;
      final isComplete = actualLength > 30000 &&
          (expectedLength <= 0 || actualLength >= (expectedLength * 0.95).round());

      if (isComplete) {
        if (targetFile.existsSync()) {
          try {
            targetFile.deleteSync();
          } catch (_) {}
        }
        await tmpFile.rename(targetFile.path);
        debugPrint('[VideoCacheManager] Successfully cached video ($actualLength bytes): ${targetFile.path}');
        return targetFile;
      } else {
        if (tmpFile.existsSync()) {
          try {
            tmpFile.deleteSync();
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('[VideoCacheManager] Background precache error for $url: $e');
      if (tmpFile != null && tmpFile.existsSync()) {
        try {
          tmpFile.deleteSync();
        } catch (_) {}
      }
    } finally {
      client?.close(force: true);
    }

    return null;
  }

  /// Creates an initialized [VideoPlayerController] using local cache when possible
  /// for instant, buttery-smooth playback without network buffering.
  static Future<VideoPlayerController?> createAndInitController(
    String rawUrl, {
    Duration timeout = const Duration(seconds: 12),
    Duration waitForInFlightDownload = Duration.zero,
  }) async {
    final clean = rawUrl.trim();
    if (clean.isEmpty || clean == 'null') return null;

    final resolved = MediaUrlUtils.resolve(clean);
    if (resolved.isEmpty) return null;

    // 1. Try local cache first for instant 0ms playback
    var cached = await findCachedVideoFile(resolved);

    // 1b. If a background precache of this exact video is already running,
    // optionally wait for it instead of opening a second network stream that
    // would compete with it for bandwidth.
    if (cached == null && waitForInFlightDownload > Duration.zero) {
      final inFlight = _inFlightDownloads[computeHash(resolved.trim())];
      if (inFlight != null) {
        debugPrint('[VideoCacheManager] Waiting for in-flight precache: $resolved');
        cached = await inFlight.timeout(
          waitForInFlightDownload,
          onTimeout: () => null,
        ).catchError((_) => null);
      }
    }

    VideoPlayerController controller;

    if (cached != null) {
      debugPrint('[VideoCacheManager] Playing from LOCAL CACHE: ${cached.path}');
      controller = VideoPlayerController.file(
        cached,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
    } else {
      var cleanFilePath = resolved.startsWith('file://')
          ? resolved.replaceFirst('file://', '')
          : resolved;
      final localFile = File(cleanFilePath);

      if (resolved.startsWith('file://') ||
          localFile.existsSync() ||
          resolved.startsWith('/data/') ||
          resolved.startsWith('/storage/')) {
        debugPrint('[VideoCacheManager] Playing from LOCAL FILE: ${localFile.path}');
        controller = VideoPlayerController.file(
          localFile,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
      } else {
        debugPrint('[VideoCacheManager] Streaming from NETWORK: $resolved');
        controller = VideoPlayerController.networkUrl(
          Uri.parse(resolved),
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
      }
    }

    await controller.initialize().timeout(timeout);
    return controller;
  }

  /// Pre-caches a list of video URLs sequentially in background (e.g. for trending feed)
  static void precacheBatch(List<String?> urls, {int maxCount = 3}) {
    final cleanUrls = urls
        .where((u) => u != null && u.trim().isNotEmpty && u.trim() != 'null')
        .map((u) => MediaUrlUtils.resolve(u!).trim())
        .where((u) => u.startsWith('http://') || u.startsWith('https://'))
        .take(maxCount)
        .toList();

    () async {
      for (final u in cleanUrls) {
        try {
          await precacheVideo(u);
          await Future.delayed(const Duration(milliseconds: 600));
        } catch (_) {}
      }
    }();
  }
}
