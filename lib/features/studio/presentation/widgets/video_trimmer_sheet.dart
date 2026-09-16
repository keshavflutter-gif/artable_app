import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/core/widgets/gradient_button.dart';
import 'package:artable_app/features/studio/presentation/bloc/studio_cubit.dart';

class VideoTrimmerSheet extends StatefulWidget {
  const VideoTrimmerSheet({
    super.key,
    this.videoController,
  });

  final VideoPlayerController? videoController;

  static Future<void> show(
    BuildContext context, {
    VideoPlayerController? videoController,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VideoTrimmerSheet(
        videoController: videoController,
      ),
    );
  }

  @override
  State<VideoTrimmerSheet> createState() => _VideoTrimmerSheetState();
}

class _VideoTrimmerSheetState extends State<VideoTrimmerSheet> {
  late double _totalDuration;
  late double _startSeconds;
  late double _endSeconds;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    final studioState = context.read<StudioCubit>().state;
    final recordedSecs = _parseDurationToSeconds(studioState.recordedDuration);
    final controllerSecs = (widget.videoController?.value.duration.inMilliseconds ?? 0) / 1000.0;

    if (recordedSecs > 0) {
      _totalDuration = recordedSecs;
    } else if (controllerSecs > 0) {
      _totalDuration = controllerSecs;
    } else {
      _totalDuration = 30.0;
    }

    _startSeconds = studioState.videoTrimStartSeconds.clamp(0.0, _totalDuration - 1.0);
    _endSeconds = (studioState.videoTrimEndSeconds ?? _totalDuration).clamp(_startSeconds + 1.0, _totalDuration);
  }

  double _parseDurationToSeconds(String duration) {
    try {
      final parts = duration.split(':');
      if (parts.length == 2) {
        final m = int.parse(parts[0]);
        final s = int.parse(parts[1]);
        return (m * 60 + s).toDouble();
      }
    } catch (_) {}
    return 30.0;
  }

  String _formatSeconds(double sec) {
    final totalSec = sec.round();
    final m = (totalSec ~/ 60).toString().padLeft(2, '0');
    final s = (totalSec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _togglePlayPause() {
    final controller = widget.videoController;
    if (controller != null && controller.value.isInitialized) {
      if (controller.value.isPlaying) {
        controller.pause();
        setState(() => _isPlaying = false);
      } else {
        controller.seekTo(Duration(milliseconds: (_startSeconds * 1000).round()));
        controller.play();
        setState(() => _isPlaying = true);
      }
    } else {
      setState(() => _isPlaying = !_isPlaying);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clipDuration = (_endSeconds - _startSeconds).clamp(1.0, _totalDuration);
    final formattedClip = _formatSeconds(clipDuration);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2DCEF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.content_cut_rounded,
                  color: AppColors.purple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trim Video Length',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF241E38),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Drag handles to select start and end points',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF7A7090),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _togglePlayPause,
                icon: Icon(
                  _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  color: AppColors.purple,
                  size: 34,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Duration Info Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F3FC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFECE6F8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'START TIME',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF8B80A5),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatSeconds(_startSeconds),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF241E38),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.purple,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Selected: $formattedClip',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'END TIME',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF8B80A5),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatSeconds(_endSeconds),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF241E38),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Range Slider
          SliderTheme(
            data: SliderThemeData(
              rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 10),
              activeTrackColor: AppColors.purple,
              inactiveTrackColor: const Color(0xFFE8E2F5),
              thumbColor: AppColors.purple,
              overlayColor: AppColors.purple.withValues(alpha: 0.2),
            ),
            child: RangeSlider(
              values: RangeValues(_startSeconds, _endSeconds),
              min: 0.0,
              max: _totalDuration,
              divisions: (_totalDuration.toInt() > 0) ? _totalDuration.toInt() : 30,
              labels: RangeLabels(
                _formatSeconds(_startSeconds),
                _formatSeconds(_endSeconds),
              ),
              onChanged: (values) {
                if (values.end - values.start >= 1.0) {
                  setState(() {
                    _startSeconds = values.start;
                    _endSeconds = values.end;
                  });
                }
              },
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0:00',
                style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
              ),
              Text(
                'Full length: ${_formatSeconds(_totalDuration)}',
                style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 20),

          GradientButton(
            label: 'Apply Trim',
            onPressed: () {
              context.read<StudioCubit>().setVideoTrimRange(
                    start: _startSeconds,
                    end: _endSeconds,
                    formattedDuration: formattedClip,
                  );
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
