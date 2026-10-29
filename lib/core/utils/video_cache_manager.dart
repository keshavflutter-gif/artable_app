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
  static final Map<String, HttpClient> _inFlightClients = {};
  static final Set<String> _completedUrls = {};
  static final Map<String, String> _urlToLocalPath = {};
  static Directory? _tempDir;

  static Future<Directory> _sharedTempDir() async {
    return _tempDir ??= await getTemporaryDirectory();
  }

  /// Stops a background full-file download so ExoPlayer can stream this URL
  /// immediately (Range requests) instead of competing for bandwidth.
  static void cancelPrecache(String? rawUrl) {
    if (rawUrl == null) return;
    final resolved = MediaUrlUtils.resolve(rawUrl).trim();
    if (resolved.isEmpty) return;
    final hash = computeHash(resolved);
    final client = _inFlightClients.remove(hash);
    if (client != null) {
      debugPrint('[VideoCacheManager] Cancelled precache so playback can start: $resolved');
      try {
        client.close(force: true);
      } catch (_) {}
    }
  }

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

    final aliased = _urlToLocalPath[resolved] ?? _urlToLocalPath[clean];
    if (aliased != null) {
      final aliasedFile = File(aliased);
      if (aliasedFile.existsSync() && aliasedFile.lengthSync() > 1024) {
        return aliasedFile;
      }
    }

    if (!resolved.startsWith('http://') && !resolved.startsWith('https://')) {
      final f = File(resolved);
      if (f.existsSync() && f.lengthSync() > 1024) {
        return f;
      }
    }

    try {
      final tempDir = await _sharedTempDir();
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

  /// Points a remote playback URL at the local recorded file so the first
  /// Challenge Arena play after upload does not stream a cold CDN copy.
  static Future<File?> associateLocalFile(String? localPath, String? remoteUrl) async {
    if (localPath == null || remoteUrl == null) return null;
    var local = localPath.trim();
    if (local.startsWith('file://')) local = local.replaceFirst('file://', '');
    final remote = MediaUrlUtils.resolve(remoteUrl).trim();
    if (local.isEmpty || remote.isEmpty) return null;
    if (!remote.startsWith('http://') && !remote.startsWith('https://')) return null;

    final source = File(local);
    if (!source.existsSync() || source.lengthSync() <= 1024) return null;

    _urlToLocalPath[remote] = source.path;
    _urlToLocalPath[remoteUrl.trim()] = source.path;

    try {
      final tempDir = await _sharedTempDir();
      final cacheDir = Directory('${tempDir.path}/shared_videos');
      if (!cacheDir.existsSync()) {
        cacheDir.createSync(recursive: true);
      }
      final hash = computeHash(remote);
      final target = File('${cacheDir.path}/cached_video_$hash.mp4');
      if (target.existsSync() && target.lengthSync() > 30000) {
        _completedUrls.add(remote);
        return target;
      }
      if (source.path == target.path) {
        _completedUrls.add(remote);
        return source;
      }
      await source.copy(target.path);
      _completedUrls.add(remote);
      _urlToLocalPath[remote] = target.path;
      debugPrint('[VideoCacheManager] Bound local recording to remote URL cache: $remote');
      return target;
    } catch (e) {
      debugPrint('[VideoCacheManager] associateLocalFile copy failed, using source path: $e');
      return source;
    }
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
      final tempDir = await _sharedTempDir();
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
      _inFlightClients[urlHash] = client;

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
      _inFlightClients.remove(urlHash);
      client?.close(force: true);
    }

    return null;
  }

  static VideoFormat? _formatHintFor(String url) {
    final lower = url.toLowerCase().split('?').first;
    if (lower.endsWith('.m3u8') || lower.contains('/hls/')) {
      return VideoFormat.hls;
    }
    if (lower.endsWith('.mpd')) return VideoFormat.dash;
    return null;
  }

  /// Creates an initialized [VideoPlayerController] using local cache when possible.
  /// Visible playback should pass [waitForInFlightDownload] = Duration.zero so
  /// ExoPlayer can Range-stream the first frame immediately.
  static Future<VideoPlayerController?> createAndInitController(
    String rawUrl, {
    Duration timeout = const Duration(seconds: 8),
    Duration waitForInFlightDownload = Duration.zero,
  }) async {
    final clean = rawUrl.trim();
    if (clean.isEmpty || clean == 'null') return null;

    final resolved = MediaUrlUtils.resolve(clean);
    if (resolved.isEmpty) return null;

    var cached = await findCachedVideoFile(resolved);

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
        // Visible playback: drop competing full-file download so ExoPlayer
        // can use HTTP Range and start on the first frames.
        cancelPrecache(resolved);
        debugPrint('[VideoCacheManager] Streaming from NETWORK: $resolved');
        controller = VideoPlayerController.networkUrl(
          Uri.parse(resolved),
          formatHint: _formatHintFor(resolved),
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
      }
    }

    await controller.initialize().timeout(timeout);
    if (cached == null &&
        (resolved.startsWith('http://') || resolved.startsWith('https://'))) {
      await _primeNetworkBuffer(controller);
    }
    return controller;
  }

  static Duration _bufferedAhead(VideoPlayerController controller) {
    final pos = controller.value.position;
    var end = Duration.zero;
    for (final range in controller.value.buffered) {
      if (range.end > end) end = range.end;
    }
    final extra = end - pos;
    return extra.isNegative ? Duration.zero : extra;
  }

  /// Fills ~1s of ExoPlayer buffer while the thumbnail is still showing, so
  /// the first play after upload does not stall every second.
  static Future<void> _primeNetworkBuffer(VideoPlayerController controller) async {
    if (!controller.value.isInitialized) return;
    final durationMs = controller.value.duration.inMilliseconds;
    final targetMs = durationMs > 0
        ? (durationMs * 0.22).round().clamp(800, 1800)
        : 1100;
    final target = Duration(milliseconds: targetMs);
    if (_bufferedAhead(controller) >= target) return;

    try {
      await controller.setVolume(0);
      await controller.play();
      final deadline = DateTime.now().add(const Duration(milliseconds: 2000));
      while (DateTime.now().isBefore(deadline)) {
        if (_bufferedAhead(controller) >= target) break;
        if (controller.value.hasError) break;
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      await controller.pause();
      await controller.seekTo(Duration.zero);
    } catch (_) {
      try {
        await controller.pause();
        await controller.seekTo(Duration.zero);
      } catch (_) {}
    }
  }

  /// Pre-caches a list of video URLs in background (e.g. for trending feed).
  static void precacheBatch(
    List<String?> urls, {
    int maxCount = 5,
    int parallelism = 2,
  }) {
    final seen = <String>{};
    final cleanUrls = <String>[];
    for (final raw in urls) {
      if (raw == null) continue;
      final u = MediaUrlUtils.resolve(raw).trim();
      if (u.isEmpty || seen.contains(u)) continue;
      if (!u.startsWith('http://') && !u.startsWith('https://')) continue;
      seen.add(u);
      cleanUrls.add(u);
      if (cleanUrls.length >= maxCount) break;
    }

    () async {
      for (var i = 0; i < cleanUrls.length; i += parallelism) {
        final slice = cleanUrls.skip(i).take(parallelism);
        await Future.wait(
          slice.map((u) async {
            try {
              await precacheVideo(u);
            } catch (_) {}
          }),
        );
      }
    }();
  }
}
