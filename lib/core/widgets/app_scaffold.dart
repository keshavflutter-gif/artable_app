import 'package:flutter/material.dart';

import 'package:artable_app/features/shell/presentation/widgets/app_shell.dart';
import 'package:artable_app/app/theme/app_colors.dart';

class AppSearchBar extends StatefulWidget {
  const AppSearchBar({
    super.key,
    required this.controller,
    this.hint = 'Search users, videos, challenges...',
    this.onSubmitted,
    this.onChanged,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.isNotEmpty;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F6FD),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFEDE8F8),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0615083C),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: widget.controller,
        autofocus: widget.autofocus,
        cursorColor: const Color(0xFF8B3DFF),
        cursorWidth: 1.8,
        cursorRadius: const Radius.circular(2),
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: Color(0xFF1B132C),
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          filled: false,
          hintText: widget.hint,
          hintStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: Color(0xFFB5ADC8),
            fontWeight: FontWeight.w400,
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 48),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 16, right: 8),
            child: Icon(
              Icons.search_rounded,
              size: 20,
              color: Color(0xFF958CAE),
            ),
          ),
          suffixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 48),
          suffixIcon: hasText
              ? Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: GestureDetector(
                    onTap: () {
                      widget.controller.clear();
                      widget.onChanged?.call('');
                      widget.onSubmitted?.call('');
                    },
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE5DFEE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 13,
                        color: Color(0xFF6E6680),
                      ),
                    ),
                  ),
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onSubmitted: widget.onSubmitted,
        onChanged: widget.onChanged,
      ),
    );
  }
}

class AppContent extends StatelessWidget {
  const AppContent({
    super.key,
    required this.child,
    this.noBottomPad = false,
    this.padding,
  });

  final Widget child;
  final bool noBottomPad;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ??
          EdgeInsets.fromLTRB(22, 0, 22, noBottomPad ? 22 : 100),
      child: child,
    );
  }
}

class AppScreen extends StatelessWidget {
  const AppScreen({
    super.key,
    required this.child,
    this.bottomNav,
  });

  final Widget child;
  final Widget? bottomNav;

  @override
  Widget build(BuildContext context) {
    final inTabShell = MainTabShellScope.of(context);
    final effectiveBottomNav = inTabShell ? null : bottomNav;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: effectiveBottomNav == null,
        child: Column(
          children: [
            Expanded(child: child),
            if (effectiveBottomNav != null) effectiveBottomNav,
          ],
        ),
      ),
    );
  }
}
