import 'package:flutter/material.dart';

import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';
import 'package:artable_app/core/utils/app_icons.dart';

enum LogoHeaderVariant { full, compact, iconOnly }

/// Logo header matching .logo-header variants from style.css
class LogoHeader extends StatelessWidget {
  const LogoHeader({
    super.key,
    this.variant = LogoHeaderVariant.full,
    this.tagline = 'Every Talent Deserves a Stage',
    this.showTaglineDivider = false,
  });

  final LogoHeaderVariant variant;
  final String tagline;
  final bool showTaglineDivider;

  double get _logoSize => switch (variant) {
        LogoHeaderVariant.full => 190,
        LogoHeaderVariant.compact => 138,
        LogoHeaderVariant.iconOnly => 104,
      };

  double get _bottomMargin => switch (variant) {
        LogoHeaderVariant.full => 14,
        LogoHeaderVariant.compact => 10,
        LogoHeaderVariant.iconOnly => 6,
      };

  double get _gap => switch (variant) {
        LogoHeaderVariant.full => 8,
        LogoHeaderVariant.compact => 6,
        LogoHeaderVariant.iconOnly => 0,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: _bottomMargin),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: _logoSize * 1.3,
            height: _logoSize * 1.3,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: _logoSize * 0.85,
                    height: _logoSize * 0.85,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x35C77CFF),
                          blurRadius: 36,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  Image.asset(
                    'assets/screen_logo.png',
                    width: _logoSize,
                    height: _logoSize,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
          ),
          if (variant != LogoHeaderVariant.iconOnly) ...[
            SizedBox(height: _gap),
            Text(
              'ARTABLE',
              style: variant == LogoHeaderVariant.full
                  ? AppTextStyles.displayExtraBold38
                  : AppTextStyles.displayExtraBold30,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: _gap),
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) =>
                  AppGradients.text.createShader(bounds),
              child: Text(
                tagline,
                style: variant == LogoHeaderVariant.full
                    ? AppTextStyles.displaySemiBold15
                    : AppTextStyles.displaySemiBold135,
                textAlign: TextAlign.center,
              ),
            ),
            if (showTaglineDivider) ...[
              const SizedBox(height: 8),
              _TaglineDivider(),
            ],
          ],
        ],
      ),
    );
  }
}

class _TaglineDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _GradientLine(gradient: AppGradients.taglineLineStart),
        const SizedBox(width: 8),
        AppIcons.sparkle(),
        const SizedBox(width: 8),
        _GradientLine(gradient: AppGradients.taglineLineEnd),
      ],
    );
  }
}

class _GradientLine extends StatelessWidget {
  const _GradientLine({required this.gradient});

  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 1,
      decoration: BoxDecoration(gradient: gradient),
    );
  }
}
