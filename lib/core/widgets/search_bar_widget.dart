import 'package:flutter/material.dart';

import 'package:artable_app/app/theme/app_gradients.dart';

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({
    super.key,
    this.placeholder = 'Search...',
    this.onChanged,
    this.showFilter = false,
    this.controller,
  });

  final String placeholder;
  final ValueChanged<String>? onChanged;
  final bool showFilter;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(22, 12, 22, 12),
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3FC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search,
            size: 18,
            color: Color(0xFF9E95B4),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1E1633),
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                filled: false,
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: placeholder,
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFB3A9C9),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          if (showFilter) ...[
            const SizedBox(width: 8),
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                gradient: AppGradients.button,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.tune, size: 14, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}
