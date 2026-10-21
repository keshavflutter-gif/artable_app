import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/core/widgets/gradient_button.dart';
import 'package:artable_app/features/studio/presentation/bloc/studio_cubit.dart';

class VideoSpeedOption {
  const VideoSpeedOption({
    required this.speed,
    required this.label,
    required this.subtitle,
    required this.icon,
  });

  final double speed;
  final String label;
  final String subtitle;
  final IconData icon;
}

class VideoSpeedSheet extends StatefulWidget {
  const VideoSpeedSheet({
    super.key,
    this.onSpeedChanged,
  });

  final void Function(String speedStr, double multiplier)? onSpeedChanged;

  static void show(
    BuildContext context, {
    void Function(String speedStr, double multiplier)? onSpeedChanged,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VideoSpeedSheet(onSpeedChanged: onSpeedChanged),
    );
  }

  @override
  State<VideoSpeedSheet> createState() => _VideoSpeedSheetState();
}

class _VideoSpeedSheetState extends State<VideoSpeedSheet> {
  static const List<VideoSpeedOption> _presets = [
    VideoSpeedOption(
      speed: 0.4,
      label: '0.4x',
      subtitle: 'Super Slow',
      icon: Icons.slow_motion_video_rounded,
    ),
    VideoSpeedOption(
      speed: 0.5,
      label: '0.5x',
      subtitle: 'Slow Motion',
      icon: Icons.slow_motion_video_rounded,
    ),
    VideoSpeedOption(
      speed: 0.75,
      label: '0.75x',
      subtitle: 'Relaxed',
      icon: Icons.speed_rounded,
    ),
    VideoSpeedOption(
      speed: 1.0,
      label: '1.0x',
      subtitle: 'Normal Speed',
      icon: Icons.play_arrow_rounded,
    ),
    VideoSpeedOption(
      speed: 1.25,
      label: '1.25x',
      subtitle: 'Brisk Pace',
      icon: Icons.fast_forward_rounded,
    ),
    VideoSpeedOption(
      speed: 1.5,
      label: '1.5x',
      subtitle: 'Fast Motion',
      icon: Icons.fast_forward_rounded,
    ),
    VideoSpeedOption(
      speed: 2.0,
      label: '2.0x',
      subtitle: 'Double Speed',
      icon: Icons.bolt_rounded,
    ),
    VideoSpeedOption(
      speed: 3.0,
      label: '3.0x',
      subtitle: 'Triple Speed',
      icon: Icons.bolt_rounded,
    ),
    VideoSpeedOption(
      speed: 4.0,
      label: '4.0x',
      subtitle: 'Maximum Speed',
      icon: Icons.electric_bolt_rounded,
    ),
  ];

  late double _selectedSpeed;

  @override
  void initState() {
    super.initState();
    final studio = context.read<StudioCubit>();
    _selectedSpeed = studio.speedMultiplier;
  }

  String _formatSpeed(double speed) {
    if (speed == speed.roundToDouble()) {
      return '${speed.toInt()}x';
    }
    return '${speed.toStringAsFixed(speed * 10 == (speed * 10).roundToDouble() ? 1 : 2)}x';
  }

  void _applySpeed(double speed) {
    setState(() {
      _selectedSpeed = speed;
    });
  }

  void _confirmAndClose() {
    final speedStr = _formatSpeed(_selectedSpeed);
    context.read<StudioCubit>().setSpeed(speedStr);
    widget.onSpeedChanged?.call(speedStr, _selectedSpeed);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final formattedSpeed = _formatSpeed(_selectedSpeed);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF161421),
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        border: Border(
          top: BorderSide(color: Color(0xFF332A50), width: 1.2),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.paddingOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: AppGradients.button,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.speed_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Playback Speed',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  gradient: AppGradients.button,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  formattedSpeed,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Adjust how fast or slow your video clip plays.',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 20),

          // Presets Grid
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _presets.map((preset) {
              final isSelected = (_selectedSpeed - preset.speed).abs() < 0.04;
              return GestureDetector(
                onTap: () => _applySpeed(preset.speed),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.purple.withValues(alpha: 0.25)
                        : const Color(0xFF221C35),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.purple : const Color(0xFF382F54),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        preset.icon,
                        size: 16,
                        color: isSelected ? const Color(0xFFFF528E) : Colors.white70,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        preset.label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Fine tuning slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('0.4x Slow', style: TextStyle(color: Colors.white38, fontSize: 11)),
              Text('Fine Tune Slider (0.4x - 4.0x)', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
              Text('4.0x Fast', style: TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.purple,
              inactiveTrackColor: Colors.white12,
              thumbColor: const Color(0xFFFF528E),
              overlayColor: AppColors.purple.withValues(alpha: 0.2),
              valueIndicatorColor: AppColors.purple,
              trackHeight: 3,
            ),
            child: Slider(
              value: _selectedSpeed.clamp(0.4, 4.0),
              min: 0.4,
              max: 4.0,
              divisions: 36,
              label: formattedSpeed,
              onChanged: (val) {
                final rounded = double.parse(val.toStringAsFixed(1));
                _applySpeed(rounded);
              },
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: () => _applySpeed(1.0),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Reset (1x)'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: GradientButton(
                  label: 'Apply Speed',
                  height: 48,
                  onPressed: _confirmAndClose,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
