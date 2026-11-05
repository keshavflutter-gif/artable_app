import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/core/widgets/gradient_button.dart';
import 'package:artable_app/features/studio/presentation/bloc/studio_cubit.dart';

/// Mix original clip audio + background music with independent sliders.
class VideoVolumeSheet extends StatefulWidget {
  const VideoVolumeSheet({
    super.key,
    this.hasMusic = false,
    this.onVolumesChanged,
  });

  final bool hasMusic;
  final void Function(double original, double music)? onVolumesChanged;

  static Future<void> show(
    BuildContext context, {
    bool hasMusic = false,
    void Function(double original, double music)? onVolumesChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VideoVolumeSheet(
        hasMusic: hasMusic,
        onVolumesChanged: onVolumesChanged,
      ),
    );
  }

  @override
  State<VideoVolumeSheet> createState() => _VideoVolumeSheetState();
}

class _VideoVolumeSheetState extends State<VideoVolumeSheet> {
  late double _original;
  late double _music;

  @override
  void initState() {
    super.initState();
    final studio = context.read<StudioCubit>();
    _original = studio.originalAudioVolume;
    _music = studio.musicVolume;
  }

  void _emitLive() {
    widget.onVolumesChanged?.call(_original, _music);
  }

  @override
  Widget build(BuildContext context) {
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
                color: Colors.black12,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Volume mix',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.hasMusic
                ? 'Balance original video sound and music'
                : 'Adjust original video sound',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 22),
          _VolumeRow(
            icon: Icons.videocam_rounded,
            label: 'Original',
            value: _original,
            accent: const Color(0xFF8B3DFF),
            onChanged: (v) {
              setState(() => _original = v);
              context.read<StudioCubit>().setOriginalAudioVolume(v);
              _emitLive();
            },
            onMuteToggle: () {
              final next = _original > 0.001 ? 0.0 : 1.0;
              setState(() => _original = next);
              context.read<StudioCubit>().setOriginalAudioVolume(next);
              _emitLive();
            },
          ),
          const SizedBox(height: 18),
          Opacity(
            opacity: widget.hasMusic ? 1 : 0.45,
            child: IgnorePointer(
              ignoring: !widget.hasMusic,
              child: _VolumeRow(
                icon: Icons.music_note_rounded,
                label: widget.hasMusic ? 'Music' : 'Music (add a track first)',
                value: _music,
                accent: const Color(0xFFFF3D77),
                onChanged: (v) {
                  setState(() => _music = v);
                  context.read<StudioCubit>().setMusicVolume(v);
                  _emitLive();
                },
                onMuteToggle: () {
                  final next = _music > 0.001 ? 0.0 : 1.0;
                  setState(() => _music = next);
                  context.read<StudioCubit>().setMusicVolume(next);
                  _emitLive();
                },
              ),
            ),
          ),
          const SizedBox(height: 22),
          GradientButton(
            label: 'Done',
            onPressed: () {
              context.read<StudioCubit>().setAudioVolumes(
                    originalAudioVolume: _original,
                    musicVolume: _music,
                  );
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _VolumeRow extends StatelessWidget {
  const _VolumeRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.onChanged,
    required this.onMuteToggle,
  });

  final IconData icon;
  final String label;
  final double value;
  final Color accent;
  final ValueChanged<double> onChanged;
  final VoidCallback onMuteToggle;

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).round();
    final muted = value <= 0.001;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ),
            Text(
              muted ? 'Off' : '$pct%',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: muted ? Colors.grey : accent,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: onMuteToggle,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  size: 18,
                  color: muted ? Colors.grey : accent,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: accent,
            inactiveTrackColor: accent.withValues(alpha: 0.15),
            thumbColor: accent,
            overlayColor: accent.withValues(alpha: 0.12),
            trackHeight: 3.5,
          ),
          child: Slider(
            value: value.clamp(0.0, 1.0),
            min: 0,
            max: 1,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
