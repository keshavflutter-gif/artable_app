import 'package:flutter/material.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_shadows.dart';
import 'package:artable_app/core/utils/app_icons.dart';

class BackButtonWidget extends StatelessWidget {
  const BackButtonWidget({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: const CircleBorder(
        side: BorderSide(color: AppColors.inputBorder, width: 1.5),
      ),
      elevation: 0,
      child: InkWell(
        onTap: onPressed ?? () => Navigator.of(context).maybePop(),
        customBorder: const CircleBorder(),
        child: Ink(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: AppShadows.backBtn,
          ),
          child: Center(child: AppIcons.chevronLeft()),
        ),
      ),
    );
  }
}

class TopRow extends StatelessWidget {
  const TopRow({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [BackButtonWidget(onPressed: onBack)],
      ),
    );
  }
}
