import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    Widget img;
    final cleanUrl = url.trim();

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
        placeholder: (context, url) => Container(
          width: width,
          height: height,
          color: const Color(0xFF2A1560),
        ),
        errorWidget: (context, url, error) => _buildFallbackContainer(),
      );
    }

    if (borderRadius != null) {
      img = ClipRRect(borderRadius: borderRadius!, child: img);
    }
    return img;
  }
}
