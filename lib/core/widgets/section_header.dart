import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_typography.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.viewAllLabel,
    this.viewAllRoute,
    this.marginTop = 26,
  });

  final String title;
  final String? viewAllLabel;
  final String? viewAllRoute;
  final double marginTop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: marginTop, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTypography.display(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ),
          if (viewAllLabel != null)
            GestureDetector(
              onTap: viewAllRoute != null ? () => context.go(viewAllRoute!) : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    viewAllLabel!,
                    style: AppTypography.body(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: viewAllRoute != null
                          ? const Color(0xFFE31668)
                          : AppColors.purple,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 13,
                    color: viewAllRoute != null
                        ? const Color(0xFFE31668)
                        : AppColors.purple,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
