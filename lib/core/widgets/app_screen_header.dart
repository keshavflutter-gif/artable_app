import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_text_styles.dart';

class AppScreenHeader extends StatelessWidget {
  const AppScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = true,
    this.onBack,
    this.bottomBorder = false,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final bool showBack;
  final VoidCallback? onBack;
  final bool bottomBorder;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(8, 8, 8, subtitle != null ? 0 : 8),
      decoration: bottomBorder
          ? BoxDecoration(
              border: Border(
                bottom: BorderSide(color: const Color(0xFF5E2EAA).withValues(alpha: 0.08)),
              ),
            )
          : null,
      child: Row(
        children: [
          if (showBack)
            IconButton(
              onPressed: onBack ?? () => context.pop(),
              icon: const Icon(Icons.chevron_left, size: 28),
              style: IconButton.styleFrom(
                foregroundColor: const Color(0xFF241E38),
              ),
            )
          else
            const SizedBox(width: 48),
          Expanded(
            child: Column(
              children: [
                Text(
                  title,
                  style: AppTextStyles.displaySemiBold15.copyWith(fontSize: 17),
                  textAlign: TextAlign.center,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: AppTextStyles.hint12.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8B849C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            width: 48,
            child: trailing != null
                ? Align(alignment: Alignment.centerRight, child: trailing)
                : null,
          ),
        ],
      ),
    );
  }
}
