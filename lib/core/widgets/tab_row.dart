import 'package:flutter/material.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/app/theme/app_typography.dart';

class TabRow extends StatelessWidget {
  const TabRow({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 2),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final active = index == selectedIndex;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: index == 0 ? 0 : 3.5, right: index == tabs.length - 1 ? 0 : 3.5),
              child: GestureDetector(
                onTap: () => onTabSelected(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: EdgeInsets.symmetric(
                    vertical: active ? 10.5 : 9,
                    horizontal: active ? 5.5 : 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: active ? AppGradients.button : null,
                    color: active ? null : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: active
                        ? null
                        : Border.all(color: AppColors.inputBorder, width: 1.5),
                    boxShadow: active
                        ? const [
                            BoxShadow(
                              color: Color(0x598B3DFF),
                              blurRadius: 14,
                              offset: Offset(0, 6),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    tabs[index],
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.display(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : AppColors.textSoft,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
