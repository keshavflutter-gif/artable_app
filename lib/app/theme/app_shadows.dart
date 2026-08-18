import 'package:flutter/material.dart';

/// Shadow tokens from doc/css/style.css
abstract final class AppShadows {
  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x1A8B3DFF),
      blurRadius: 30,
      offset: Offset(0, 10),
    ),
  ];

  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x1F5E2EAA),
      blurRadius: 40,
      offset: Offset(0, 18),
    ),
  ];

  static const List<BoxShadow> btn = [
    BoxShadow(
      color: Color(0x47FF3D77),
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
  ];

  static const List<BoxShadow> btnGradient = [
    BoxShadow(
      color: Color(0x24FF3D77),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> input = [
    BoxShadow(
      color: Color(0x0D5E2EAA),
      blurRadius: 14,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> authInput = [
    BoxShadow(
      color: Color(0x145E2EAA),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> authInputFocus = [
    BoxShadow(
      color: Color(0x2E8B3DFF),
      blurRadius: 22,
      offset: Offset(0, 10),
    ),
  ];

  static const List<BoxShadow> socialBtn = [
    BoxShadow(
      color: Color(0x145E2EAA),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> logoMark = [
    BoxShadow(
      color: Color(0x5C8B3DFF),
      blurRadius: 30,
      offset: Offset(0, 18),
    ),
  ];

  static const List<BoxShadow> backBtn = [
    BoxShadow(
      color: Color(0x0D5E2EAA),
      blurRadius: 14,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> otpFocus = [
    BoxShadow(
      color: Color(0x248B3DFF),
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> otpError = [
    BoxShadow(
      color: Color(0x2EFF3D77),
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];
}
