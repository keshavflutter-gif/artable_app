import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography tokens from doc/css/style.css + shared app helpers.
abstract final class AppTextStyles {
  // --- Shared app styles (home, studio, etc.) ---
  static const TextStyle displayBold = TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      );

  static const TextStyle body = TextStyle(
        fontFamily: 'Inter',
        color: AppColors.text,
      );

  static const TextStyle bodySoft = TextStyle(
        fontFamily: 'Inter',
        color: AppColors.textSoft,
      );

  static TextStyle get sectionTitle => displayBold.copyWith(fontSize: 17);

  static TextStyle get headerTitle => displayBold.copyWith(fontSize: 17.5);

  static TextStyle get greetingHi => bodySoft.copyWith(
        fontSize: 12,
        letterSpacing: 0.2,
      );

  static TextStyle get greetingName => displayBold.copyWith(fontSize: 18.5);

  static TextStyle display({
    double size = 15,
    FontWeight weight = FontWeight.w700,
    Color? color,
    double? height,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: 'Poppins',
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.text,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle bodyStyle({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: 'Inter',
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.text,
        height: height,
        letterSpacing: letterSpacing,
      );

  // --- Auth CSS-exact styles ---
  static const TextStyle displayExtraBold38 = TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w800,
        fontSize: 38,
        letterSpacing: 1.5,
        color: AppColors.text,
        height: 1.2,
      );

  static const TextStyle displayExtraBold30 = TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w800,
        fontSize: 30,
        letterSpacing: 1.5,
        color: AppColors.text,
        height: 1.2,
      );

  static const TextStyle displaySemiBold15 = TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
        fontSize: 15,
        letterSpacing: 0.3,
        height: 1.3,
      );

  static const TextStyle displaySemiBold135 = TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
        fontSize: 13.5,
        letterSpacing: 0.3,
        height: 1.3,
      );

  static const TextStyle displayBold26 = TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w800,
        fontSize: 26,
        color: AppColors.text,
        height: 1.2,
      );

  static const TextStyle displayBold21 = TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w700,
        fontSize: 21,
        height: 1.3,
      );

  static const TextStyle displayBold20 = TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w700,
        fontSize: 20,
        color: AppColors.text,
        height: 1.3,
      );

  static const TextStyle displayBold15 = TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w700,
        fontSize: 15,
        letterSpacing: 0.8,
        color: AppColors.white,
        height: 1.2,
      );

  static const TextStyle displaySemiBold14 = TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
        fontSize: 14,
        height: 1.3,
      );

  static const TextStyle bodyRegular145 = TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        fontSize: 14.5,
        color: AppColors.text,
        height: 1.4,
      );

  static const TextStyle bodyRegular14 = TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        fontSize: 14,
        color: AppColors.textSoft,
        height: 1.55,
      );

  static const TextStyle bodySemiBold135 = TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        fontSize: 13.5,
        color: AppColors.textSoft,
        height: 1.4,
      );

  static const TextStyle bodySemiBold13 = TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: AppColors.purple,
        height: 1.4,
      );

  static const TextStyle bodyBold135 = TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w700,
        fontSize: 13.5,
        color: AppColors.purple,
        height: 1.4,
      );

  static const TextStyle bodySemiBoldSocial = TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        fontSize: 13.5,
        color: AppColors.text,
        height: 1.3,
      );

  static const TextStyle bodyRegular135Footer = TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        fontSize: 13.5,
        color: AppColors.textSoft,
        height: 1.4,
      );

  static const TextStyle bodyBold135Footer = TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w700,
        fontSize: 13.5,
        color: AppColors.purple,
        height: 1.4,
      );

  static const TextStyle hint12 = TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        fontSize: 12,
        color: AppColors.textSoft,
        height: 1.4,
      );

  static const TextStyle divider115 = TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        fontSize: 11.5,
        letterSpacing: 0.4,
        color: AppColors.textFaint,
        height: 1.3,
      );

  static const TextStyle splashVersion = TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        fontSize: 11.5,
        color: AppColors.textFaint,
        height: 1.3,
      );

  static const TextStyle otpDigit = TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w700,
        fontSize: 22,
        color: AppColors.text,
        height: 1.2,
      );

  static const TextStyle skipBtn = TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        fontSize: 13.5,
        color: AppColors.textSoft,
        height: 1.3,
      );
}

