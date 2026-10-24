import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import 'package:artable_app/core/utils/media_url_utils.dart';
import 'package:artable_app/features/studio/data/services/video_thumbnail_generator.dart';

class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.url,
    this.videoUrl,
    this.fallbackUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderIcon,
    this.isVideo = false,
  });

  final String url;
  final String? videoUrl;
  final String? fallbackUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData? placeholderIcon;
  final bool isVideo;

  static void cacheThumbnail(String key, Uint8List bytes) {
    if (key.trim().isEmpty || bytes.isEmpty) return;
    var rawKey = key.trim();
    if (rawKey.startsWith('file://')) rawKey = rawKey.replaceFirst('file://', '');
    final cleanKey = MediaUrlUtils.resolve(rawKey).trim();

    _VideoThumbnailView._cache[key.trim()] = bytes;
    _VideoThumbnailView._cache[rawKey] = bytes;
    if (cleanKey.isNotEmpty) _VideoThumbnailView._cache[cleanKey] = bytes;

    final basename = rawKey.split(RegExp(r'[/\\]')).last;
    final bool isGenericBasename = [
      'rec.mp4', 'cap.mp4', 'video.mp4', 'temp.mp4', 'output.mp4', 'input.mp4',
      'merged.mp4', 'scaled_video.mp4', 'draft.mp4'
    ].contains(basename.toLowerCase());
    if (basename.isNotEmpty && !isGenericBasename && !rawKey.startsWith('/') && !rawKey.contains(':\\')) {
      _VideoThumbnailView._cache[basename] = bytes;
    }

    try {
      getTemporaryDirectory().then((tempDir) async {
        try {
          final cacheFile = File('${tempDir.path}/vthumb_${rawKey.hashCode.abs()}.jpg');
          await cacheFile.writeAsBytes(bytes, flush: true);
          if (cleanKey.isNotEmpty && cleanKey != rawKey) {
            final cleanFile = File('${tempDir.path}/vthumb_${cleanKey.hashCode.abs()}.jpg');
            await cleanFile.writeAsBytes(bytes, flush: true);
          }
          if (basename.isNotEmpty && !isGenericBasename) {
            final baseFile = File('${tempDir.path}/vthumb_${basename.hashCode.abs()}.jpg');
            await baseFile.writeAsBytes(bytes, flush: true);
          }
        } catch (_) {}
      }).catchError((_) {});
    } catch (_) {}
  }

  static Uint8List? getCachedThumbnail(String key) {
    if (key.trim().isEmpty) return null;
    var rawKey = key.trim();
    if (rawKey.startsWith('file://')) rawKey = rawKey.replaceFirst('file://', '');
    final cleanKey = MediaUrlUtils.resolve(rawKey).trim();
    final basename = rawKey.split(RegExp(r'[/\\]')).last;
    final bool isGenericBasename = [
      'rec.mp4', 'cap.mp4', 'video.mp4', 'temp.mp4', 'output.mp4', 'input.mp4',
      'merged.mp4', 'scaled_video.mp4', 'draft.mp4'
    ].contains(basename.toLowerCase());

    return _VideoThumbnailView._cache[key.trim()] ??
        _VideoThumbnailView._cache[rawKey] ??
        (cleanKey.isNotEmpty ? _VideoThumbnailView._cache[cleanKey] : null) ??
        (!isGenericBasename && !rawKey.startsWith('/') && !rawKey.contains(':\\') && basename.isNotEmpty
            ? _VideoThumbnailView._cache[basename]
            : null);
  }

  Widget _buildFallbackContainer() {
    IconData icon;
    if (placeholderIcon != null) {
      icon = placeholderIcon!;
    } else if (isVideo) {
      icon = Icons.play_circle_fill_rounded;
    } else if (borderRadius != null && (width == height || (width != null && width! <= 100))) {
      icon = Icons.person_rounded;
    } else {
      icon = Icons.image_outlined;
    }

    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A1560), Color(0xFF4C248B)],
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          color: Colors.white70,
          size: (width != null && width! < 50) ? 18 : 26,
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF3EBFF),
        borderRadius: borderRadius,
      ),
      child: Center(
        child: SizedBox(
          width: (width != null && width! < 50) ? 14 : 20,
          height: (width != null && width! < 50) ? 14 : 20,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B3DFF)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget img;
    final cleanUrl = MediaUrlUtils.resolve(url);
    final cleanVideoUrl = MediaUrlUtils.resolve(videoUrl);

    final hasVideoSource = cleanVideoUrl.isNotEmpty;
    final isUrlVideo = MediaUrlUtils.looksLikeVideoUrl(cleanUrl);
    final isUrlDummy = MediaUrlUtils.isDummyThumbnail(cleanUrl);
    final isUrlEmpty = cleanUrl.isEmpty;
    final hasValidThumbnail = !isUrlDummy && !isUrlVideo && !isUrlEmpty;

    final effectiveFallbackImage = (fallbackUrl != null &&
            fallbackUrl!.trim().isNotEmpty &&
            !MediaUrlUtils.isDummyThumbnail(fallbackUrl))
        ? fallbackUrl!.trim()
        : (hasValidThumbnail ? cleanUrl : null);

    // 1. If we already have a real valid image thumbnail URL (remote or local), load it directly
    if (hasValidThumbnail && (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://'))) {
      img = CachedNetworkImage(
        imageUrl: cleanUrl,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: width != null ? (width! * 2).toInt() : 150,
        memCacheHeight: height != null ? (height! * 2).toInt() : 200,
        maxWidthDiskCache: 600,
        maxHeightDiskCache: 800,
        fadeInDuration: const Duration(milliseconds: 150),
        fadeOutDuration: const Duration(milliseconds: 100),
        placeholder: (context, url) => _buildLoadingPlaceholder(),
        errorWidget: (context, url, error) {
          if (hasVideoSource) {
            return _VideoThumbnailView(
              videoSource: cleanVideoUrl,
              fallbackImageUrl: effectiveFallbackImage,
              width: width,
              height: height,
              fit: fit,
              fallback: _buildFallbackContainer(),
            );
          }
          return _buildFallbackContainer();
        },
      );
    } else if (hasValidThumbnail && File(cleanUrl).existsSync()) {
      img = Image.file(
        File(cleanUrl),
        width: width,
        height: height,
        fit: fit,
        cacheWidth: width != null ? (width! * 2).toInt() : 150,
        cacheHeight: height != null ? (height! * 2).toInt() : 200,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return child;
          }
          return _buildLoadingPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) {
          if (hasVideoSource) {
            return _VideoThumbnailView(
              videoSource: cleanVideoUrl,
              fallbackImageUrl: effectiveFallbackImage,
              width: width,
              height: height,
              fit: fit,
              fallback: _buildFallbackContainer(),
            );
          }
          return _buildFallbackContainer();
        },
      );
    } else if (hasVideoSource) {
      // 2. Only if thumbnail image is missing, dummy, or a video file, extract frame from video
      img = _VideoThumbnailView(
        videoSource: cleanVideoUrl,
        fallbackImageUrl: effectiveFallbackImage,
        width: width,
        height: height,
        fit: fit,
        fallback: _buildFallbackContainer(),
      );
    } else if (isUrlVideo) {
      img = _VideoThumbnailView(
        videoSource: cleanUrl,
        fallbackImageUrl: effectiveFallbackImage,
        width: width,
        height: height,
        fit: fit,
        fallback: _buildFallbackContainer(),
      );
    } else if (effectiveFallbackImage != null && effectiveFallbackImage.isNotEmpty) {
      img = _VideoThumbnailView(
        videoSource: '',
        fallbackImageUrl: effectiveFallbackImage,
        width: width,
        height: height,
        fit: fit,
        fallback: _buildFallbackContainer(),
      );
    } else {
      img = _buildFallbackContainer();
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: img);
    }
    return img;
  }
}

class _VideoThumbnailView extends StatefulWidget {
  const _VideoThumbnailView({
    required this.videoSource,
    this.fallbackImageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    required this.fallback,
  });

  final String videoSource;
  final String? fallbackImageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget fallback;

  static final Map<String, Uint8List> _cache = {};
  static final Map<String, Future<Uint8List?>> _inFlight = {};

  @override
  State<_VideoThumbnailView> createState() => _VideoThumbnailViewState();
}

class _VideoThumbnailViewState extends State<_VideoThumbnailView> {
  Uint8List? _bytes;
  bool _isDisposed = false;
  bool _hasFailed = false;
  Timer? _safetyTimer;

  @override
  void initState() {
    super.initState();
    _startSafetyTimer();
    _loadThumbnail();
  }

  void _startSafetyTimer() {
    _safetyTimer?.cancel();
    // Maximum 2.0 seconds loading spinner before gracefully falling back
    _safetyTimer = Timer(const Duration(milliseconds: 2000), () {
      if (!_isDisposed && mounted && _bytes == null) {
        setState(() {
          _hasFailed = true;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant _VideoThumbnailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoSource != widget.videoSource) {
      _hasFailed = false;
      _startSafetyTimer();
      _loadThumbnail();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _safetyTimer?.cancel();
    _safetyTimer = null;
    super.dispose();
  }

  Future<void> _loadThumbnail() async {
    var src = widget.videoSource.trim();
    if (src.startsWith('file://')) {
      src = src.replaceFirst('file://', '');
    }
    src = MediaUrlUtils.resolve(src).trim();

    if (src.isEmpty) {
      _safetyTimer?.cancel();
      if (mounted) {
        setState(() {
          _hasFailed = true;
        });
      }
      return;
    }

    final isRemote = src.startsWith('http://') || src.startsWith('https://');

    // If local file does not exist, fail immediately to prevent infinite loading spinner
    if (!isRemote && !File(src).existsSync()) {
      _safetyTimer?.cancel();
      if (mounted) {
        setState(() {
          _hasFailed = true;
        });
      }
      return;
    }

    // 1. Check in-memory RAM cache
    if (_VideoThumbnailView._cache.containsKey(src)) {
      _safetyTimer?.cancel();
      if (mounted) {
        setState(() {
          _bytes = _VideoThumbnailView._cache[src];
          _hasFailed = false;
        });
      }
      return;
    }

    final basename = src.split(RegExp(r'[/\\]')).last;
    if (basename.isNotEmpty && _VideoThumbnailView._cache.containsKey(basename)) {
      _safetyTimer?.cancel();
      if (mounted) {
        setState(() {
          _bytes = _VideoThumbnailView._cache[basename];
          _hasFailed = false;
        });
      }
      return;
    }

    final keyHash = src.hashCode.abs().toString();

    // 2. Check disk cache
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheFile = File('${tempDir.path}/vthumb_$keyHash.jpg');
      if (await cacheFile.exists() && await cacheFile.length() > 0) {
        final diskBytes = await cacheFile.readAsBytes();
        if (diskBytes.isNotEmpty) {
          _VideoThumbnailView._cache[src] = diskBytes;
          if (basename.isNotEmpty) {
            _VideoThumbnailView._cache[basename] = diskBytes;
          }
          _safetyTimer?.cancel();
          if (mounted) {
            setState(() {
              _bytes = diskBytes;
              _hasFailed = false;
            });
          }
          return;
        }
      }
    } catch (_) {}

    // 3. Extract JPEG frame in background for local video files
    final future = _VideoThumbnailView._inFlight.putIfAbsent(src, () async {
      Uint8List? data;
      try {
        final genFile = await VideoThumbnailGenerator.generateThumbnailFromVideo(src);
        if (genFile != null && await genFile.exists()) {
          final bytes = await genFile.readAsBytes();
          if (bytes.isNotEmpty) {
            data = bytes;
          }
        }
      } catch (_) {}

      try {
        if (data == null || data.isEmpty) {
          if (!isRemote) {
            final f = File(src);
            if (await f.exists()) {
              for (final t in [0, 200, 500]) {
                try {
                  data = await VideoThumbnail.thumbnailData(
                    video: f.path,
                    imageFormat: ImageFormat.JPEG,
                    maxWidth: 240,
                    quality: 65,
                    timeMs: t,
                  ).timeout(const Duration(milliseconds: 2000));
                  if (data != null && data.isNotEmpty) break;
                } catch (_) {}
              }
            }
          } else {
            // Remote extraction direct attempt
            for (final t in [0, 200]) {
              try {
                data = await VideoThumbnail.thumbnailData(
                  video: src,
                  imageFormat: ImageFormat.JPEG,
                  maxWidth: 512,
                  quality: 80,
                  timeMs: t,
                ).timeout(const Duration(milliseconds: 2000));
                if (data != null && data.isNotEmpty) break;
              } catch (_) {}
            }

            // Remote download first segment to extract locally
            if (data == null || data.isEmpty) {
              File? tempVideoFile;
              try {
                final tempDir = await getTemporaryDirectory();
                tempVideoFile = File('${tempDir.path}/vdl_$keyHash.mp4');

                if (!await tempVideoFile.exists() || await tempVideoFile.length() == 0) {
                  final client = http.Client();
                  try {
                    final req = http.Request('GET', Uri.parse(src));
                    final response = await client.send(req).timeout(const Duration(seconds: 4));
                    if (response.statusCode >= 200 && response.statusCode < 300) {
                      final sink = tempVideoFile.openWrite();
                      int totalBytes = 0;
                      const maxBytes = 2 * 1024 * 1024;
                      await for (final chunk in response.stream.timeout(const Duration(seconds: 3))) {
                        sink.add(chunk);
                        totalBytes += chunk.length;
                        if (totalBytes >= maxBytes) break;
                      }
                      await sink.flush();
                      await sink.close();
                    }
                  } finally {
                    client.close();
                  }
                }

                if (await tempVideoFile.exists() && await tempVideoFile.length() > 0) {
                  for (final t in [0, 200, 500]) {
                    try {
                      data = await VideoThumbnail.thumbnailData(
                        video: tempVideoFile.path,
                        imageFormat: ImageFormat.JPEG,
                        maxWidth: 512,
                        quality: 80,
                        timeMs: t,
                      ).timeout(const Duration(milliseconds: 2000));
                      if (data != null && data.isNotEmpty) break;
                    } catch (_) {}
                  }
                }
              } catch (e) {
                debugPrint('Segment download thumbnail error: $e');
              }
            }
          }
        }

        if (data != null && data.isNotEmpty) {
          _VideoThumbnailView._cache[src] = data;
          if (basename.isNotEmpty) {
            _VideoThumbnailView._cache[basename] = data;
          }
          try {
            final tempDir = await getTemporaryDirectory();
            final cacheFile = File('${tempDir.path}/vthumb_$keyHash.jpg');
            await cacheFile.writeAsBytes(data, flush: true);
          } catch (_) {}
          return data;
        }
      } catch (e) {
        debugPrint('Thumbnail generation error for $src: $e');
      } finally {
        _VideoThumbnailView._inFlight.remove(src);
      }
      return null;
    });

    final resBytes = await future;
    _safetyTimer?.cancel();
    if (_isDisposed || !mounted) return;
    if (resBytes != null && resBytes.isNotEmpty) {
      setState(() {
        _bytes = resBytes;
        _hasFailed = false;
      });
    } else {
      setState(() {
        _hasFailed = true;
      });
    }
  }

  Widget _buildFallback() {
    final fallbackUrl = widget.fallbackImageUrl?.trim();
    if (fallbackUrl != null &&
        fallbackUrl.isNotEmpty &&
        !MediaUrlUtils.isDummyThumbnail(fallbackUrl) &&
        !MediaUrlUtils.looksLikeVideoUrl(fallbackUrl)) {
      if (fallbackUrl.startsWith('http://') || fallbackUrl.startsWith('https://')) {
        return CachedNetworkImage(
          imageUrl: fallbackUrl,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          fadeInDuration: const Duration(milliseconds: 150),
          fadeOutDuration: const Duration(milliseconds: 100),
          errorWidget: (context, url, error) => widget.fallback,
        );
      } else if (File(fallbackUrl).existsSync()) {
        return Image.file(
          File(fallbackUrl),
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          errorBuilder: (context, error, stackTrace) => widget.fallback,
        );
      }
    }
    return widget.fallback;
  }

  @override
  Widget build(BuildContext context) {
    if (_bytes != null) {
      return Image.memory(
        _bytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }

    if (_hasFailed) {
      return _buildFallback();
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: const BoxDecoration(
        color: Color(0xFFF3EBFF),
      ),
      child: Center(
        child: SizedBox(
          width: (widget.width != null && widget.width! < 50) ? 14 : 20,
          height: (widget.width != null && widget.width! < 50) ? 14 : 20,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B3DFF)),
          ),
        ),
      ),
    );
  }
}

