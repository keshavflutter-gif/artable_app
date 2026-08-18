import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_radii.dart';
import 'package:artable_app/app/theme/app_shadows.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';

class BtnSocial extends StatelessWidget {
  const BtnSocial({
    super.key,
    required this.label,
    required this.assetPath,
    this.onPressed,
  });

  final String label;
  final String assetPath;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.btn),
        elevation: 0,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadii.btn),
          child: Ink(
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.btn),
              border: Border.all(color: AppColors.inputBorder, width: 1.5),
              boxShadow: AppShadows.socialBtn,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(assetPath, width: 19, height: 19),
                const SizedBox(width: 8),
                Text(label, style: AppTextStyles.bodySemiBoldSocial),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SocialRow extends StatelessWidget {
  const SocialRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: const [
          BtnSocial(label: 'Google', assetPath: 'assets/google.svg'),
          SizedBox(width: 12),
          BtnSocial(label: 'Apple', assetPath: 'assets/apple.svg'),
        ],
      ),
    );
  }
}
