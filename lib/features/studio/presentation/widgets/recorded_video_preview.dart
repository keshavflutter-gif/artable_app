import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/core/utils/app_filter_utils.dart';

class RecordedVideoPreview extends StatelessWidget {
  const RecordedVideoPreview({
    super.key,
    required this.videoController,
    required this.isVideoInitialized,
    required this.playing,
    required this.onTogglePlayPause,
    required this.duration,
    required this.isFrontCamera,
    required this.filterId,
    required this.beautyOn,
    required this.beautyIntensity,
    this.hasError = false,
    this.onRetry,
  });

  final VideoPlayerController? videoController;
  final bool isVideoInitialized;
  final bool playing;
  final VoidCallback onTogglePlayPause;
  final String duration;
  final bool isFrontCamera;
  final String filterId;
  final bool beautyOn;
  final double beautyIntensity;
  final bool hasError;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (isVideoInitialized &&
              videoController != null &&
              videoController!.value.isInitialized)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                color: Colors.black,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: videoController!.value.aspectRatio > 0
                        ? videoController!.value.aspectRatio
                        : 9 / 16,
                    child: AppFilterUtils.buildFilteredView(
                      filterId: filterId,
                      beautyOn: beautyOn,
                      beautyIntensity: beautyIntensity,
                      child: VideoPlayer(videoController!),
                    ),
                  ),
                ),
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                color: const Color(0xFF150C2B),
                child: Center(
                  child: hasError
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.white54, size: 36),
                            const SizedBox(height: 10),
                            Text(
                              'Could not play recorded video',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (onRetry != null) ...[
                              const SizedBox(height: 10),
                              TextButton(
                                onPressed: onRetry,
                                child: const Text('Retry'),
                              ),
                            ],
                          ],
                        )
                      : const CircularProgressIndicator(
                          color: AppColors.purple,
                          strokeWidth: 3,
                        ),
                ),
              ),
            ),
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTogglePlayPause,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      isFrontCamera ? Icons.person : Icons.photo_camera,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isFrontCamera ? 'Front Camera' : 'Back Camera',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: playing ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.4),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.7),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 10,
            bottom: 10,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  duration,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
