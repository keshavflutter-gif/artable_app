import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:artable_app/core/utils/media_url_utils.dart';

class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alt = '',
    this.borderRadius,
    this.placeholderIcon,
    this.isVideo = false,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String alt;
  final BorderRadius? borderRadius;
  final IconData? placeholderIcon;
  final bool isVideo;

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

    if (cleanUrl.isEmpty || cleanUrl.contains('storage.example')) {
      img = _buildFallbackContainer();
    } else if (cleanUrl.startsWith('/') ||
        cleanUrl.startsWith('file://') ||
        (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://'))) {
      var filePath = cleanUrl;
      if (filePath.startsWith('file://')) {
        filePath = filePath.replaceFirst('file://', '');
      }
      final file = File(filePath);
      if (file.existsSync()) {
        img = Image.file(
          file,
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
          errorBuilder: (context, error, stackTrace) => _buildFallbackContainer(),
        );
      } else {
        img = _buildFallbackContainer();
      }
    } else {
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
        errorWidget: (context, url, error) => _buildFallbackContainer(),
      );
    }

    if (borderRadius != null) {
      img = ClipRRect(borderRadius: borderRadius!, child: img);
    }
    return img;
  }
}
