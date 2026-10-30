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
    this.cropAspectRatio = '9:16',
    this.isMuted = false,
    this.hasError = false,
    this.onRetry,
    this.clipControllers,
    this.currentClipIndex = 0,
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
  final String cropAspectRatio;
  final bool isMuted;
  final bool hasError;
  final VoidCallback? onRetry;

  /// When multiple clips are provided, both current + next stay mounted so
  /// handoff does not remount the video texture (avoids visible breaks).
  final List<VideoPlayerController>? clipControllers;
  final int currentClipIndex;

  double get _targetContainerRatio {
    switch (cropAspectRatio) {
      case '1:1':
        return 1.0;
      case '4:5':
        return 4 / 5;
      case '16:9':
        return 16 / 9;
      case '9:16':
      default:
        return 3 / 4;
    }
  }

  Widget _buildSurface(VideoPlayerController vc) {
    final ratio = cropAspectRatio == '1:1'
        ? 1.0
        : cropAspectRatio == '4:5'
            ? 4 / 5
            : cropAspectRatio == '16:9'
                ? 16 / 9
                : (vc.value.aspectRatio > 0 ? vc.value.aspectRatio : 9 / 16);
    return AspectRatio(
      aspectRatio: ratio,
      // No ValueKey(controller) — remounting the texture is what makes
      // draft-continue / clip switches visibly stutter.
      child: VideoPlayer(vc),
    );
  }

  Widget _buildPlayerLayers() {
    final clips = clipControllers;
    if (clips != null && clips.length > 1) {
      final nextIndex = (currentClipIndex + 1) % clips.length;
      final layers = <Widget>[];

      void addLayer(int index, {required bool visible}) {
        if (index < 0 || index >= clips.length) return;
        final c = clips[index];
        if (!c.value.isInitialized) return;
        layers.add(
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: visible ? 1 : 0,
                child: Center(child: _buildSurface(c)),
              ),
            ),
          ),
        );
      }

      if (nextIndex != currentClipIndex) {
        addLayer(nextIndex, visible: false);
      }
      addLayer(currentClipIndex, visible: true);

      if (layers.isNotEmpty) {
        return Stack(fit: StackFit.expand, children: layers);
      }
    }

    final vc = videoController;
    if (vc == null || !vc.value.isInitialized) {
      return const SizedBox.shrink();
    }
    return Center(child: _buildSurface(vc));
  }

  @override
  Widget build(BuildContext context) {
    final vc = videoController;
    final clipsReady = clipControllers != null &&
        clipControllers!.isNotEmpty &&
        clipControllers!.any((c) => c.value.isInitialized);
    final isReady = isVideoInitialized &&
        !hasError &&
        ((vc != null && vc.value.isInitialized && !vc.value.hasError) || clipsReady);

    return AspectRatio(
      aspectRatio: _targetContainerRatio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (isReady)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                color: Colors.black,
                child: AppFilterUtils.buildFilteredView(
                  filterId: filterId,
                  beautyOn: beautyOn,
                  beautyIntensity: beautyIntensity,
                  performanceMode: true,
                  child: _buildPlayerLayers(),
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
          if (isMuted)
            Positioned(
              top: 12,
              right: 12,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.volume_off,
                        size: 12,
                        color: Colors.white,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Muted',
                        style: TextStyle(
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
