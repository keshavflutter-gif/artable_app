import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:artable_app/core/utils/formatters.dart';

class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alt = '',
    this.borderRadius,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String alt;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final w = width?.round() ?? 400;
    final h = height?.round() ?? 400;
    final fallback = AppFormatters.imgFallbackUrl(alt, w: w, h: h);

    Widget img = CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      errorWidget: (context, url, error) => CachedNetworkImage(
        imageUrl: fallback,
        width: width,
        height: height,
        fit: fit,
      ),
    );

    if (borderRadius != null) {
      img = ClipRRect(borderRadius: borderRadius!, child: img);
    }
    return img;
  }
}
