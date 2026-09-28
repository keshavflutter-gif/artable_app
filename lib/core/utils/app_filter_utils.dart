import 'dart:ui';
import 'package:flutter/material.dart';

class FilterPreset {
  final String id;
  final String label;
  final IconData icon;
  final List<Color> gradient;
  final List<double>? matrix;

  const FilterPreset({
    required this.id,
    required this.label,
    required this.icon,
    required this.gradient,
    this.matrix,
  });
}

abstract final class AppFilterUtils {
  static const List<FilterPreset> presets = [
    FilterPreset(
      id: 'natural',
      label: 'Natural',
      icon: Icons.wb_sunny_outlined,
      gradient: [Color(0xFFDCE3EE), Color(0xFFF4F6FA)],
      matrix: null,
    ),
    FilterPreset(
      id: 'clarendon',
      label: 'Clarendon',
      icon: Icons.wb_sunny,
      gradient: [Color(0xFF81D4FA), Color(0xFF1E88E5)],
      matrix: [
        1.20, 0.05, 0.00, 0.0, 5.0,
        0.00, 1.15, 0.05, 0.0, 5.0,
        0.00, 0.05, 1.30, 0.0, 15.0,
        0.00, 0.00, 0.00, 1.0, 0.0,
      ],
    ),
    FilterPreset(
      id: 'gingham',
      label: 'Gingham',
      icon: Icons.grid_on,
      gradient: [Color(0xFFE0E0E0), Color(0xFFB0BEC5)],
      matrix: [
        0.92, 0.05, 0.03, 0.0, 18.0,
        0.04, 0.88, 0.05, 0.0, 18.0,
        0.04, 0.04, 0.82, 0.0, 22.0,
        0.00, 0.00, 0.00, 1.0, 0.0,
      ],
    ),
    FilterPreset(
      id: 'moon',
      label: 'Moon',
      icon: Icons.brightness_2,
      gradient: [Color(0xFF78909C), Color(0xFF263238)],
      matrix: [
        0.35, 0.55, 0.10, 0.0, 8.0,
        0.35, 0.55, 0.10, 0.0, 8.0,
        0.35, 0.55, 0.10, 0.0, 8.0,
        0.00, 0.00, 0.00, 1.0, 0.0,
      ],
    ),
    FilterPreset(
      id: 'lark',
      label: 'Lark',
      icon: Icons.nature,
      gradient: [Color(0xFFA5D6A7), Color(0xFF0288D1)],
      matrix: [
        1.02, 0.05, 0.00, 0.0, 8.0,
        0.00, 1.15, 0.05, 0.0, 10.0,
        0.00, 0.05, 1.25, 0.0, 15.0,
        0.00, 0.00, 0.00, 1.0, 0.0,
      ],
    ),
    FilterPreset(
      id: 'reyes',
      label: 'Reyes',
      icon: Icons.wb_twilight,
      gradient: [Color(0xFFFFF59D), Color(0xFFBCAAA4)],
      matrix: [
        0.88, 0.12, 0.05, 0.0, 28.0,
        0.05, 0.85, 0.05, 0.0, 22.0,
        0.05, 0.05, 0.72, 0.0, 18.0,
        0.00, 0.00, 0.00, 1.0, 0.0,
      ],
    ),
    FilterPreset(
      id: 'juno',
      label: 'Juno',
      icon: Icons.flare,
      gradient: [Color(0xFFFF8A65), Color(0xFFAB47BC)],
      matrix: [
        1.25, 0.05, 0.00, 0.0, 12.0,
        0.00, 1.10, 0.05, 0.0, 5.0,
        0.05, 0.00, 1.20, 0.0, 18.0,
        0.00, 0.00, 0.00, 1.0, 0.0,
      ],
    ),
    FilterPreset(
      id: 'slumber',
      label: 'Slumber',
      icon: Icons.bedtime,
      gradient: [Color(0xFFD1C4E9), Color(0xFF8D6E63)],
      matrix: [
        0.85, 0.10, 0.05, 0.0, 18.0,
        0.05, 0.85, 0.10, 0.0, 14.0,
        0.05, 0.05, 0.75, 0.0, 10.0,
        0.00, 0.00, 0.00, 1.0, 0.0,
      ],
    ),
    FilterPreset(
      id: 'crema',
      label: 'Crema',
      icon: Icons.coffee,
      gradient: [Color(0xFFFFF8E1), Color(0xFFD7CCC8)],
      matrix: [
        1.05, 0.10, 0.00, 0.0, 14.0,
        0.05, 1.00, 0.05, 0.0, 10.0,
        0.00, 0.05, 0.88, 0.0, 10.0,
        0.00, 0.00, 0.00, 1.0, 0.0,
      ],
    ),
    FilterPreset(
      id: 'ludwig',
      label: 'Ludwig',
      icon: Icons.wb_sunny_rounded,
      gradient: [Color(0xFFFFAB91), Color(0xFFD84315)],
      matrix: [
        1.20, 0.02, 0.00, 0.0, 10.0,
        0.00, 1.12, 0.02, 0.0, 5.0,
        0.00, 0.02, 1.05, 0.0, 0.0,
        0.00, 0.00, 0.00, 1.0, 0.0,
      ],
    ),
    FilterPreset(
      id: 'aden',
      label: 'Aden',
      icon: Icons.filter_hdr,
      gradient: [Color(0xFFF8BBD0), Color(0xFFCE93D8)],
      matrix: [
        0.98, 0.06, 0.05, 0.0, 22.0,
        0.05, 0.88, 0.05, 0.0, 14.0,
        0.05, 0.05, 0.92, 0.0, 24.0,
        0.00, 0.00, 0.00, 1.0, 0.0,
      ],
    ),
    FilterPreset(
      id: 'perpetua',
      label: 'Perpetua',
      icon: Icons.park,
      gradient: [Color(0xFF80CBC4), Color(0xFF00897B)],
      matrix: [
        0.90, 0.10, 0.05, 0.0, 0.0,
        0.05, 1.15, 0.10, 0.0, 10.0,
        0.00, 0.10, 1.20, 0.0, 15.0,
        0.00, 0.00, 0.00, 1.0, 0.0,
      ],
    ),
    FilterPreset(
      id: 'valencia',
      label: 'Valencia',
      icon: Icons.wb_sunny_outlined,
      gradient: [Color(0xFFFFE082), Color(0xFFFF8F00)],
      matrix: [
        1.15, 0.10, 0.00, 0.0, 18.0,
        0.05, 1.05, 0.00, 0.0, 12.0,
        0.00, 0.05, 0.82, 0.0, 10.0,
        0.00, 0.00, 0.00, 1.0, 0.0,
      ],
    ),
    FilterPreset(
      id: 'sierra',
      label: 'Sierra',
      icon: Icons.landscape,
      gradient: [Color(0xFFA1887F), Color(0xFF4E342E)],
      matrix: [
        0.98, 0.10, 0.00, 0.0, 18.0,
        0.05, 0.92, 0.05, 0.0, 14.0,
        0.00, 0.05, 0.82, 0.0, 10.0,
        0.00, 0.00, 0.00, 1.0, 0.0,
      ],
    ),
    FilterPreset(
      id: 'willow',
      label: 'Willow',
      icon: Icons.filter_vintage,
      gradient: [Color(0xFFE1BEE7), Color(0xFF616161)],
      matrix: [
        0.32, 0.48, 0.15, 0.0, 18.0,
        0.32, 0.48, 0.15, 0.0, 16.0,
        0.35, 0.43, 0.20, 0.0, 20.0,
        0.00, 0.00, 0.00, 1.0, 0.0,
      ],
    ),
    FilterPreset(
      id: 'lofi',
      label: 'Lo-Fi',
      icon: Icons.center_focus_strong,
      gradient: [Color(0xFFFF5252), Color(0xFF7C4DFF)],
      matrix: [
        1.35, -0.05, -0.05, 0.0, -10.0,
        -0.05, 1.30, -0.05, 0.0, -10.0,
        -0.05, -0.05, 1.25, 0.0, -10.0,
        0.00, 0.00, 0.00, 1.0, 0.0,
      ],
    ),
    FilterPreset(
      id: 'nashville',
      label: 'Nashville',
      icon: Icons.music_note,
      gradient: [Color(0xFFFF80AB), Color(0xFFFF4081)],
      matrix: [
        1.15, 0.10, 0.05, 0.0, 22.0,
        0.05, 0.90, 0.10, 0.0, 12.0,
        0.10, 0.05, 1.10, 0.0, 28.0,
        0.00, 0.00, 0.00, 1.0, 0.0,
      ],
    ),
    FilterPreset(
      id: 'xpro2',
      label: 'X-Pro II',
      icon: Icons.camera,
      gradient: [Color(0xFFFFD54F), Color(0xFF303F9F)],
      matrix: [
        1.30, 0.05, 0.00, 0.0, -15.0,
        0.05, 1.20, 0.00, 0.0, -10.0,
        0.00, 0.05, 1.10, 0.0, 10.0,
        0.00, 0.00, 0.00, 1.0, 0.0,
      ],
    ),
    FilterPreset(
      id: 'inkwell',
      label: 'Inkwell',
      icon: Icons.palette,
      gradient: [Color(0xFFE0E0E0), Color(0xFF212121)],
      matrix: [
        0.30, 0.59, 0.11, 0.0, 0.0,
        0.30, 0.59, 0.11, 0.0, 0.0,
        0.30, 0.59, 0.11, 0.0, 0.0,
        0.00, 0.00, 0.00, 1.0, 0.0,
      ],
    ),
    FilterPreset(
      id: 'glow',
      label: 'Glow',
      icon: Icons.auto_awesome,
      gradient: [Color(0xFFFFE9C7), Color(0xFFFFC369)],
      matrix: [
        1.15, 0.10, 0.05, 0.0, 10.0,
        0.05, 1.10, 0.05, 0.0, 8.0,
        0.00, 0.05, 0.90, 0.0, 0.0,
        0.00, 0.00, 0.00, 1.0, 0.0,
      ],
    ),
    FilterPreset(
      id: 'warm',
      label: 'Warm',
      icon: Icons.local_fire_department_outlined,
      gradient: [Color(0xFFFFD3A8), Color(0xFFFF8A5B)],
      matrix: [
        1.25, 0.10, 0.00, 0.0, 15.0,
        0.05, 1.10, 0.00, 0.0, 5.0,
        0.00, 0.00, 0.80, 0.0, 0.0,
        0.00, 0.00, 0.00, 1.0, 0.0,
      ],
    ),
    FilterPreset(
      id: 'studio',
      label: 'Studio',
      icon: Icons.videocam_outlined,
      gradient: [Color(0xFFC9C2FF), Color(0xFF8B3DFF)],
      matrix: [
        1.05, 0.05, 0.05, 0.0, 5.0,
        0.00, 1.15, 0.05, 0.0, 5.0,
        0.05, 0.10, 1.25, 0.0, 10.0,
        0.00, 0.00, 0.00, 1.0, 0.0,
      ],
    ),
    FilterPreset(
      id: 'beauty',
      label: 'Beauty',
      icon: Icons.star,
      gradient: [Color(0xFFFFD1E3), Color(0xFFFF3D77)],
      matrix: [
        1.12, 0.08, 0.05, 0.0, 14.0,
        0.05, 1.10, 0.05, 0.0, 10.0,
        0.05, 0.05, 1.05, 0.0, 8.0,
        0.00, 0.00, 0.00, 1.0, 0.0,
      ],
    ),
    FilterPreset(
      id: 'mono',
      label: 'Mono',
      icon: Icons.contrast,
      gradient: [Color(0xFFCFCFCF), Color(0xFF5B5B5B)],
      matrix: [
        0.2126, 0.7152, 0.0722, 0.0, 0.0,
        0.2126, 0.7152, 0.0722, 0.0, 0.0,
        0.2126, 0.7152, 0.0722, 0.0, 0.0,
        0.0000, 0.0000, 0.0000, 1.0, 0.0,
      ],
    ),
    FilterPreset(
      id: 'vintage',
      label: 'Vintage',
      icon: Icons.camera_roll_outlined,
      gradient: [Color(0xFFE2C4A2), Color(0xFF9E774E)],
      matrix: [
        0.393, 0.769, 0.189, 0.0, 0.0,
        0.349, 0.686, 0.168, 0.0, 0.0,
        0.272, 0.534, 0.131, 0.0, 0.0,
        0.000, 0.000, 0.000, 1.0, 0.0,
      ],
    ),
    FilterPreset(
      id: 'cool',
      label: 'Cool',
      icon: Icons.ac_unit,
      gradient: [Color(0xFFA1E7FF), Color(0xFF3399FF)],
      matrix: [
        0.90, 0.00, 0.10, 0.0, 0.0,
        0.00, 1.10, 0.10, 0.0, 5.0,
        0.00, 0.15, 1.30, 0.0, 12.0,
        0.00, 0.00, 0.00, 1.0, 0.0,
      ],
    ),
  ];

  static FilterPreset getPreset(String id) {
    final cleanId = id.trim().toLowerCase();
    return presets.firstWhere(
      (p) => p.id.toLowerCase() == cleanId,
      orElse: () => presets.first,
    );
  }

  /// Builds a real-time filtered view wrapping [child] with color matrix and beauty smoothing overlay.
  static Widget buildFilteredView({
    required Widget child,
    required String filterId,
    required bool beautyOn,
    required double beautyIntensity,
    bool performanceMode = false,
  }) {
    final preset = getPreset(filterId);
    Widget filteredChild = child;

    // Apply color matrix filter
    if (preset.matrix != null) {
      filteredChild = ColorFiltered(
        colorFilter: ColorFilter.matrix(preset.matrix!),
        child: filteredChild,
      );
    }

    // Full beauty overlay when idle; lightweight tint while recording.
    if (beautyOn && beautyIntensity > 0 && !performanceMode) {
      final factor = (beautyIntensity / 100).clamp(0.0, 1.0);
      filteredChild = Stack(
        fit: StackFit.passthrough,
        children: [
          filteredChild,
          Positioned.fill(
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: 1.5 * factor,
                  sigmaY: 1.5 * factor,
                ),
                child: Container(
                  color: Colors.pinkAccent.withValues(alpha: 0.06 * factor),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.0,
                    colors: [
                      const Color(0xFFFFF0F5).withValues(alpha: 0.12 * factor),
                      const Color(0xFFFFD1DC).withValues(alpha: 0.04 * factor),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } else if (beautyOn && beautyIntensity > 0 && performanceMode) {
      final factor = (beautyIntensity / 100).clamp(0.0, 1.0);
      filteredChild = ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.pinkAccent.withValues(alpha: 0.06 * factor),
          BlendMode.softLight,
        ),
        child: filteredChild,
      );
    }

    return filteredChild;
  }
}
