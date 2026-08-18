import 'package:flutter/material.dart';

class GradientSwitch extends StatelessWidget {
  const GradientSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final canTap = enabled && onChanged != null;

    return GestureDetector(
      onTap: canTap ? () => onChanged!(!value) : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.6,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 26,
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            gradient: value
                ? const LinearGradient(
                    colors: [
                      Color(0xFFFF8F55), // Orange
                      Color(0xFFFF5487), // Pink
                      Color(0xFF9652FF), // Purple
                    ],
                  )
                : null,
            color: value ? null : const Color(0xFFECE8F5),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 3,
                    offset: const Offset(0, 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
