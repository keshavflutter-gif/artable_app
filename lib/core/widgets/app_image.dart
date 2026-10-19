import 'dart:io';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import 'package:artable_app/core/utils/media_url_utils.dart';

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
    final cleanKey = MediaUrlUtils.resolve(key).trim();
    if (cleanKey.isEmpty || bytes.isEmpty) return;
    _VideoThumbnailView._cache[cleanKey] = bytes;
    _VideoThumbnailView._cache[key.trim()] = bytes;
    try {
      getTemporaryDirectory().then((tempDir) async {
        try {
          final cacheFile = File('${tempDir.path}/vthumb_${cleanKey.hashCode.abs()}.jpg');
          await cacheFile.writeAsBytes(bytes);
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

    // 1. If we already have a real valid image thumbnail URL (remote or local), load it directly for instant display
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
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(covariant _VideoThumbnailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoSource != widget.videoSource) {
      _loadThumbnail();
    }
  }

  Future<void> _loadThumbnail() async {
    final src = widget.videoSource.trim();
    if (src.isEmpty) {
      if (mounted) setState(() => _failed = true);
      return;
    }

    // 1. Check in-memory RAM cache
    if (_VideoThumbnailView._cache.containsKey(src)) {
      if (mounted) {
        setState(() {
          _bytes = _VideoThumbnailView._cache[src];
          _failed = false;
        });
      }
      return;
    }

    _failed = false;
    _bytes = null;

    final future = _VideoThumbnailView._inFlight.putIfAbsent(src, () async {
      try {
        // 2. Check disk cache
        try {
          final tempDir = await getTemporaryDirectory();
          final cacheFile = File('${tempDir.path}/vthumb_${src.hashCode.abs()}.jpg');
          if (await cacheFile.exists() && await cacheFile.length() > 0) {
            final diskBytes = await cacheFile.readAsBytes();
            if (diskBytes.isNotEmpty) {
              _VideoThumbnailView._cache[src] = diskBytes;
              return diskBytes;
            }
          }
        } catch (_) {}

        Uint8List? data;

        // 3. Direct extraction using VideoThumbnail.thumbnailData
        try {
          data = await VideoThumbnail.thumbnailData(
            video: src,
            imageFormat: ImageFormat.JPEG,
            maxWidth: 512,
            quality: 75,
            timeMs: 500,
          );
          if (data == null || data.isEmpty) {
            data = await VideoThumbnail.thumbnailData(
              video: src,
              imageFormat: ImageFormat.JPEG,
              maxWidth: 512,
              quality: 75,
              timeMs: 0,
            );
          }
        } catch (e) {
          debugPrint('VideoThumbnail.thumbnailData direct attempt error for $src: $e');
        }

        // 4. Try thumbnailFile if thumbnailData didn't yield bytes
        if (data == null || data.isEmpty) {
          try {
            final tempDir = await getTemporaryDirectory();
            final outPath = '${tempDir.path}/vthumb_${src.hashCode.abs()}.jpg';
            var generatedPath = await VideoThumbnail.thumbnailFile(
              video: src,
              thumbnailPath: outPath,
              imageFormat: ImageFormat.JPEG,
              maxWidth: 512,
              quality: 75,
              timeMs: 500,
            );
            if (generatedPath == null || generatedPath.isEmpty) {
              generatedPath = await VideoThumbnail.thumbnailFile(
                video: src,
                thumbnailPath: outPath,
                imageFormat: ImageFormat.JPEG,
                maxWidth: 512,
                quality: 75,
                timeMs: 0,
              );
            }
            if (generatedPath != null && generatedPath.isNotEmpty) {
              final f = File(generatedPath);
              if (await f.exists() && await f.length() > 0) {
                data = await f.readAsBytes();
              }
            }
          } catch (e) {
            debugPrint('VideoThumbnail.thumbnailFile direct attempt error for $src: $e');
          }
        }

        // 5. If remote HTTP/HTTPS video URL extraction failed directly on device,
        // download the first segment locally to guarantee 100% reliable local extraction
        if ((data == null || data.isEmpty) &&
            (src.startsWith('http://') || src.startsWith('https://'))) {
          try {
            final tempDir = await getTemporaryDirectory();
            final tempVideoFile = File('${tempDir.path}/vdl_${src.hashCode.abs()}.mp4');

            if (!await tempVideoFile.exists() || await tempVideoFile.length() == 0) {
              final client = http.Client();
              try {
                final response = await client.send(http.Request('GET', Uri.parse(src)));
                if (response.statusCode >= 200 && response.statusCode < 300) {
                  final sink = tempVideoFile.openWrite();
                  int totalBytes = 0;
                  const maxBytesToRead = 3 * 1024 * 1024; // 3MB is plenty for video headers & initial frames
                  await for (final chunk in response.stream) {
                    sink.add(chunk);
                    totalBytes += chunk.length;
                    if (totalBytes >= maxBytesToRead) break;
                  }
                  await sink.flush();
                  await sink.close();
                }
              } finally {
                client.close();
              }
            }

            if (await tempVideoFile.exists() && await tempVideoFile.length() > 0) {
              data = await VideoThumbnail.thumbnailData(
                video: tempVideoFile.path,
                imageFormat: ImageFormat.JPEG,
                maxWidth: 512,
                quality: 75,
                timeMs: 500,
              );
              if (data == null || data.isEmpty) {
                data = await VideoThumbnail.thumbnailData(
                  video: tempVideoFile.path,
                  imageFormat: ImageFormat.JPEG,
                  maxWidth: 512,
                  quality: 75,
                  timeMs: 0,
                );
              }
            }
          } catch (e) {
            debugPrint('Local segment download & thumbnail extraction error for $src: $e');
          }
        }

        // 6. Save extracted bytes to memory and disk cache
        if (data != null && data.isNotEmpty) {
          try {
            final tempDir = await getTemporaryDirectory();
            final cacheFile = File('${tempDir.path}/vthumb_${src.hashCode.abs()}.jpg');
            await cacheFile.writeAsBytes(data, flush: true);
          } catch (_) {}

          _VideoThumbnailView._cache[src] = data;
          return data;
        }
      } catch (e) {
        debugPrint('_VideoThumbnailView error generating thumb for $src: $e');
      } finally {
        _VideoThumbnailView._inFlight.remove(src);
      }
      return null;
    });

    final resBytes = await future;
    if (!mounted) return;
    setState(() {
      if (resBytes != null && resBytes.isNotEmpty) {
        _bytes = resBytes;
        _failed = false;
      } else {
        _failed = true;
      }
    });
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
    if (_failed) {
      return _buildFallback();
    }

    // While loading, if a valid (non-dummy) fallback image is available, show it as placeholder
    final fb = widget.fallbackImageUrl;
    if (fb != null && fb.isNotEmpty && !MediaUrlUtils.isDummyThumbnail(fb)) {
      return CachedNetworkImage(
        imageUrl: fb,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorWidget: (context, url, error) => widget.fallback,
        placeholder: (context, url) => widget.fallback,
      );
    }

    return widget.fallback;
  }

  Widget _buildFallback() {
    final fb = widget.fallbackImageUrl;
    if (fb != null && fb.isNotEmpty && !MediaUrlUtils.isDummyThumbnail(fb)) {
      return CachedNetworkImage(
        imageUrl: fb,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorWidget: (context, url, error) => widget.fallback,
      );
    }
    return widget.fallback;
  }
}
