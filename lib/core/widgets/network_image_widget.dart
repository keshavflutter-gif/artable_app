import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:artable_app/app/theme/app_colors.dart';

import 'package:artable_app/core/utils/media_url_utils.dart';

class NetworkImageWidget extends StatelessWidget {
  const NetworkImageWidget({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.alignment = Alignment.center,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final cleanUrl = MediaUrlUtils.resolve(url);
    if (cleanUrl.isEmpty) {
      final fallback = Container(
        width: width,
        height: height,
        color: AppColors.inputBg,
        alignment: Alignment.center,
        child: Icon(Icons.image_outlined, color: AppColors.textFaint, size: 24),
      );
      if (borderRadius != null) {
        return ClipRRect(borderRadius: borderRadius!, child: fallback);
      }
      return fallback;
    }

    // Fill parent when size isn't fixed (e.g. AspectRatio / Stack.expand).
    // Without this, CachedNetworkImage can stay blank until a later rebuild.
    final image = LayoutBuilder(
      builder: (context, constraints) {
        final w = width ??
            (constraints.hasBoundedWidth && constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : null);
        final h = height ??
            (constraints.hasBoundedHeight && constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : null);
        return CachedNetworkImage(
          imageUrl: cleanUrl,
          width: w,
          height: h,
          fit: fit,
          alignment: alignment,
          placeholder: (context, url) => Container(
            width: w,
            height: h,
            color: AppColors.inputBg,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: w,
            height: h,
            color: AppColors.inputBg,
            alignment: Alignment.center,
            child: Icon(Icons.image_outlined, color: AppColors.textFaint, size: 24),
          ),
        );
      },
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}
