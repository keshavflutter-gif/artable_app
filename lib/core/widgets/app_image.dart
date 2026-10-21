import 'dart:io';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import 'package:artable_app/core/utils/media_url_utils.dart';
import 'package:artable_app/features/studio/data/services/video_thumbnail_generator.dart';

class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.url,
    this.videoUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderIcon,
    this.isVideo = false,
  });

  final String url;
  final String? videoUrl;
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
    if (basename.isNotEmpty) _VideoThumbnailView._cache[basename] = bytes;

    try {
      getTemporaryDirectory().then((tempDir) async {
        try {
          final cacheFile = File('${tempDir.path}/vthumb_${rawKey.hashCode.abs()}.jpg');
          await cacheFile.writeAsBytes(bytes, flush: true);
          if (cleanKey.isNotEmpty && cleanKey != rawKey) {
            final cleanFile = File('${tempDir.path}/vthumb_${cleanKey.hashCode.abs()}.jpg');
            await cleanFile.writeAsBytes(bytes, flush: true);
          }
          if (basename.isNotEmpty) {
            final baseFile = File('${tempDir.path}/vthumb_${basename.hashCode.abs()}.jpg');
            await baseFile.writeAsBytes(bytes, flush: true);
          }
        } catch (_) {}
      }).catchError((_) {});
    } catch (_) {}
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

    // 1. If we already have a real valid image thumbnail URL (remote or local), load it directly
    if (hasValidThumbnail && (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://'))) {
      img = CachedNetworkImage(
        imageUrl: cleanUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => Container(
          width: width,
          height: height,
          color: const Color(0xFF2A1560),
        ),
        errorWidget: (context, url, error) {
          if (hasVideoSource) {
            return _VideoThumbnailView(
              videoSource: cleanVideoUrl,
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
        errorBuilder: (context, error, stackTrace) {
          if (hasVideoSource) {
            return _VideoThumbnailView(
              videoSource: cleanVideoUrl,
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
        fallbackImageUrl: hasValidThumbnail ? cleanUrl : null,
        width: width,
        height: height,
        fit: fit,
        fallback: _buildFallbackContainer(),
      );
    } else if (isUrlVideo) {
      img = _VideoThumbnailView(
        videoSource: cleanUrl,
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
  VideoPlayerController? _controller;
  bool _isPlayerInitialized = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(covariant _VideoThumbnailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoSource != widget.videoSource) {
      _controller?.dispose();
      _controller = null;
      _isPlayerInitialized = false;
      _loadThumbnail();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  Future<void> _loadThumbnail() async {
    var src = widget.videoSource.trim();
    if (src.startsWith('file://')) {
      src = src.replaceFirst('file://', '');
    }
    src = MediaUrlUtils.resolve(src).trim();
    if (src.isEmpty) return;

    // 1. Check in-memory RAM cache
    if (_VideoThumbnailView._cache.containsKey(src)) {
      if (mounted) {
        setState(() {
          _bytes = _VideoThumbnailView._cache[src];
        });
      }
      return;
    }

    final basename = src.split(RegExp(r'[/\\]')).last;
    if (basename.isNotEmpty && _VideoThumbnailView._cache.containsKey(basename)) {
      if (mounted) {
        setState(() {
          _bytes = _VideoThumbnailView._cache[basename];
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
          if (mounted) {
            setState(() {
              _bytes = diskBytes;
            });
          }
          return;
        }
      }
    } catch (_) {}

    final isRemote = src.startsWith('http://') || src.startsWith('https://');

    // 3. Launch VideoPlayerController as instant visual fallback
    if (_controller == null && !_isPlayerInitialized) {
      _initVideoPlayer(src, isRemote);
    }

    // 4. Extract JPEG frame in background for fast caching
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
                  maxWidth: 512,
                  quality: 80,
                  timeMs: t,
                );
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
              );
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
                  final response = await client.send(req).timeout(const Duration(seconds: 5));
                  if (response.statusCode >= 200 && response.statusCode < 300) {
                    final sink = tempVideoFile.openWrite();
                    int totalBytes = 0;
                    const maxBytes = 4 * 1024 * 1024;
                    await for (final chunk in response.stream.timeout(const Duration(seconds: 5))) {
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
                    );
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
    if (_isDisposed || !mounted) return;
    if (resBytes != null && resBytes.isNotEmpty) {
      setState(() {
        _bytes = resBytes;
        _controller?.dispose();
        _controller = null;
        _isPlayerInitialized = false;
      });
    }
  }

  void _initVideoPlayer(String src, bool isRemote) {
    try {
      final controller = isRemote
          ? VideoPlayerController.networkUrl(Uri.parse(src))
          : VideoPlayerController.file(File(src));
      _controller = controller;
      controller.initialize().then((_) {
        if (_isDisposed || !mounted || _controller != controller) {
          controller.dispose();
          return;
        }
        controller.setVolume(0.0);
        controller.seekTo(const Duration(milliseconds: 200)).then((_) {
          if (_isDisposed || !mounted || _controller != controller) return;
          controller.pause();
          setState(() {
            _isPlayerInitialized = true;
          });
        }).catchError((_) {
          if (_isDisposed || !mounted || _controller != controller) return;
          controller.pause();
          setState(() {
            _isPlayerInitialized = true;
          });
        });
      }).catchError((e) {
        debugPrint('VideoPlayer fallback init error for $src: $e');
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_bytes != null) {
      return Image.memory(
        _bytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) => widget.fallback,
      );
    }

    if (_isPlayerInitialized && _controller != null && _controller!.value.isInitialized) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: ClipRect(
          child: FittedBox(
            fit: widget.fit,
            child: SizedBox(
              width: _controller!.value.size.width > 0 ? _controller!.value.size.width : 200,
              height: _controller!.value.size.height > 0 ? _controller!.value.size.height : 200,
              child: VideoPlayer(_controller!),
            ),
          ),
        ),
      );
    }

    return widget.fallback;
  }
}
