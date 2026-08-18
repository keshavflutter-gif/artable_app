import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';
import 'package:artable_app/features/studio/presentation/bloc/studio_cubit.dart';
import 'package:artable_app/data/datasources/music_api_service.dart';
import 'package:artable_app/core/widgets/app_network_image.dart';
import 'package:artable_app/core/widgets/gradient_button.dart';

class SongTrimmerSheet extends StatefulWidget {
  const SongTrimmerSheet({
    super.key,
    required this.track,
    this.initialStartSeconds = 0.0,
    this.initialCropDuration = 30.0,
    required this.onApply,
  });

  final FreeToUseTrack track;
  final double initialStartSeconds;
  final double initialCropDuration;
  final Function(double start, double duration) onApply;

  static void show(
    BuildContext context, {
    required FreeToUseTrack track,
    double initialStart = 0.0,
    double initialDuration = 30.0,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SongTrimmerSheet(
        track: track,
        initialStartSeconds: initialStart,
        initialCropDuration: initialDuration,
        onApply: (start, duration) {
          ctx.read<StudioCubit>().setSelectedTrack(
                track,
                start: start,
                duration: duration,
              );
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  State<SongTrimmerSheet> createState() => _SongTrimmerSheetState();
}

class _SongTrimmerSheetState extends State<SongTrimmerSheet> {
  late double _startSeconds;
  late double _cropDuration;
  bool _isPlaying = false;
  Timer? _previewTimer;
  double _previewProgress = 0.0;

  final List<double> _presetDurations = [15.0, 30.0, 60.0];

  @override
  void initState() {
    super.initState();
    _startSeconds = widget.initialStartSeconds.clamp(0.0, widget.track.duration - 5.0);
    _cropDuration = widget.initialCropDuration.clamp(5.0, widget.track.duration - _startSeconds);
    if (_cropDuration > widget.track.duration) {
      _cropDuration = widget.track.duration;
    }
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    super.dispose();
  }

  String _formatTime(double sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec.toInt() % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _togglePreview() {
    if (_isPlaying) {
      _stopPreview();
    } else {
      _startPreview();
    }
  }

  void _startPreview() {
    _previewTimer?.cancel();
    setState(() {
      _isPlaying = true;
      _previewProgress = 0.0;
    });

    const stepMs = 100;
    final totalSteps = (_cropDuration * 1000) / stepMs;
    int currentStep = 0;

    _previewTimer = Timer.periodic(const Duration(milliseconds: stepMs), (t) {
      currentStep++;
      if (currentStep >= totalSteps) {
        _stopPreview();
      } else {
        setState(() {
          _previewProgress = currentStep / totalSteps;
        });
      }
    });
  }

  void _stopPreview() {
    _previewTimer?.cancel();
    if (mounted) {
      setState(() {
        _isPlaying = false;
        _previewProgress = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxStart = (widget.track.duration - _cropDuration).clamp(0.0, widget.track.duration);
    final endSeconds = (_startSeconds + _cropDuration).clamp(0.0, widget.track.duration);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header: Song Details & Close
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AppNetworkImage(
                  url: widget.track.coverUrl,
                  width: 50,
                  height: 50,
                  alt: widget.track.title,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.track.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.track.artist} · Full length: ${widget.track.formattedDuration}',
                      style: AppTextStyles.hint12.copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: AppColors.textSoft),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Duration Preset Selection Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Clip Duration: ',
                style: AppTextStyles.hint12.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              ..._presetDurations.map((dur) {
                if (dur > widget.track.duration) return const SizedBox.shrink();
                final isSelected = (_cropDuration - dur).abs() < 1.0;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('${dur.toInt()}s'),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _cropDuration = dur;
                          if (_startSeconds + _cropDuration > widget.track.duration) {
                            _startSeconds = (widget.track.duration - _cropDuration).clamp(0.0, widget.track.duration);
                          }
                          _stopPreview();
                        });
                      }
                    },
                    selectedColor: AppColors.purple,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSoft,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                    backgroundColor: const Color(0xFFF5F2FC),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 18),

          // Timestamp Readout
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F2FC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.content_cut, size: 14, color: AppColors.purple),
                    const SizedBox(width: 6),
                    Text(
                      'Crop Range: ${_formatTime(_startSeconds)} - ${_formatTime(endSeconds)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.purple,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _togglePreview,
                  child: Row(
                    children: [
                      Icon(
                        _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                        size: 22,
                        color: AppColors.purple,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isPlaying ? 'Pause' : 'Preview',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.purple,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Waveform & Range Slider
          _WaveformTrimmerWidget(
            waveform: widget.track.waveform,
            totalDuration: widget.track.duration,
            startSeconds: _startSeconds,
            cropDuration: _cropDuration,
            previewProgress: _previewProgress,
            isPlaying: _isPlaying,
            onStartChanged: (newStart) {
              setState(() {
                _startSeconds = newStart.clamp(0.0, maxStart);
                _stopPreview();
              });
            },
          ),
          const SizedBox(height: 22),

          // Action Button
          GradientButton(
            label: 'Done — Apply Song (${_cropDuration.toInt()}s)',
            onPressed: () => widget.onApply(_startSeconds, _cropDuration),
          ),
        ],
      ),
    );
  }
}

class _WaveformTrimmerWidget extends StatelessWidget {
  const _WaveformTrimmerWidget({
    required this.waveform,
    required this.totalDuration,
    required this.startSeconds,
    required this.cropDuration,
    required this.previewProgress,
    required this.isPlaying,
    required this.onStartChanged,
  });

  final List<int> waveform;
  final double totalDuration;
  final double startSeconds;
  final double cropDuration;
  final double previewProgress;
  final bool isPlaying;
  final ValueChanged<double> onStartChanged;

  @override
  Widget build(BuildContext context) {
    final bars = waveform.isNotEmpty
        ? waveform
        : List.generate(45, (i) => ((i * 13 + 7) % 80) + 15);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final cropRatio = (cropDuration / totalDuration).clamp(0.1, 1.0);
        final cropWidth = totalWidth * cropRatio;
        final maxStartOffset = totalWidth - cropWidth;

        final currentStartOffset = (startSeconds / totalDuration) * totalWidth;
        final clampedStartOffset = currentStartOffset.clamp(0.0, maxStartOffset);

        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            final newOffset = (clampedStartOffset + details.delta.dx).clamp(0.0, maxStartOffset);
            final newStartSec = (newOffset / totalWidth) * totalDuration;
            onStartChanged(newStartSec);
          },
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F6FC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE9E4F7)),
            ),
            child: Stack(
              children: [
                // Base Waveform (Inactive background)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: bars.map((val) {
                      final h = (val.clamp(10, 100) / 100) * 44;
                      return Container(
                        width: 3,
                        height: h,
                        decoration: BoxDecoration(
                          color: AppColors.purple.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Active Crop Highlight Window
                Positioned(
                  left: clampedStartOffset,
                  width: cropWidth.clamp(40.0, totalWidth),
                  top: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.purple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.purple, width: 2.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left handle bar
                        Container(
                          width: 8,
                          height: double.infinity,
                          decoration: const BoxDecoration(
                            color: AppColors.purple,
                            borderRadius: BorderRadius.horizontal(left: Radius.circular(8)),
                          ),
                          child: const Icon(Icons.drag_indicator, size: 10, color: Colors.white),
                        ),
                        // Right handle bar
                        Container(
                          width: 8,
                          height: double.infinity,
                          decoration: const BoxDecoration(
                            color: AppColors.purple,
                            borderRadius: BorderRadius.horizontal(right: Radius.circular(8)),
                          ),
                          child: const Icon(Icons.drag_indicator, size: 10, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),

                // Playhead indicator when playing preview
                if (isPlaying)
                  Positioned(
                    left: clampedStartOffset + (cropWidth * previewProgress),
                    top: 4,
                    bottom: 4,
                    child: Container(
                      width: 3,
                      decoration: BoxDecoration(
                        color: AppColors.pink,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: const [
                          BoxShadow(color: AppColors.pink, blurRadius: 4),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
