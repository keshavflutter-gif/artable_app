import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Gradient tokens from doc/css/style.css
abstract final class AppGradients {
  static const LinearGradient logo = LinearGradient(
    begin: Alignment(-0.9, -1.0),
    end: Alignment(0.9, 1.0),
    colors: [
      Color(0xFFFFDE59),
      Color(0xFFFFA53C),
      Color(0xFFFF5C8A),
      Color(0xFFC246E8),
      Color(0xFF4C6CF7),
    ],
    stops: [0.0, 0.22, 0.45, 0.68, 1.0],
  );

  static const LinearGradient button = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFFF8F55),
      Color(0xFFFF5487),
      Color(0xFF9652FF),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient buttonActive = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFF07531),
      Color(0xFFF02D66),
      Color(0xFF7A2CF2),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient text = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFFF7A45),
      Color(0xFFFF3D77),
      Color(0xFF9B3DFF),
    ],
    stops: [0.0, 0.6, 1.0],
  );

  static const LinearGradient fieldIcon = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x24FF8A3D),
      Color(0x248B3DFF),
    ],
  );

  static const LinearGradient taglineLineStart = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Colors.transparent, AppColors.inputBorder],
  );

  static const LinearGradient taglineLineEnd = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.inputBorder, Colors.transparent],
  );

  static const LinearGradient studioHeader = LinearGradient(
    begin: Alignment(-0.85, -1.0),
    end: Alignment(0.75, 1.0),
    colors: [Color(0xFF180B36), Color(0xFF1F1049), Color(0xFF170A30)],
    stops: [0, 0.55, 1],
  );
}
