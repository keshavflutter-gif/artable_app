import 'package:flutter/material.dart';

import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/app/theme/app_radii.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';

class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.enabled = true,
    this.fullWidth = true,
    this.height = 56,
    this.padding,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool enabled;
  final bool fullWidth;
  final double height;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.button,
          borderRadius: BorderRadius.circular(AppRadii.btn),
          boxShadow: const [
            BoxShadow(
              color: Color(0x52FF3D77),
              blurRadius: 26,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(AppRadii.btn),
            child: Padding(
              padding: padding ?? const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  if (icon != null) ...[icon!, const SizedBox(width: 10)],
                  Text(label, style: AppTextStyles.displaySemiBold15),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
