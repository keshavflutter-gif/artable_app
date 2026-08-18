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
    return presets.firstWhere(
      (p) => p.id == id,
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
