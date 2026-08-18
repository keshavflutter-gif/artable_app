import 'package:flutter/material.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/app/theme/app_radii.dart';
import 'package:artable_app/app/theme/app_shadows.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';
import 'package:artable_app/core/utils/app_icons.dart';

class AuthInput extends StatefulWidget {
  const AuthInput({
    super.key,
    required this.controller,
    required this.placeholder,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String placeholder;
  final Widget icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AuthInput> createState() => _AuthInputState();
}

class _AuthInputState extends State<AuthInput> {
  late bool _obscured;
  bool _focused = false;
  late final FocusNode _focusNode;

  static const _inputHeight = 58.0;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
    _focusNode = FocusNode()..addListener(_handleFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocus);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocus() {
    setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final field = _AuthInputField(
      controller: widget.controller,
      placeholder: widget.placeholder,
      icon: widget.icon,
      obscured: _obscured,
      focusNode: _focusNode,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      onSubmitted: widget.onSubmitted,
      onToggleObscure: widget.obscureText
          ? () => setState(() => _obscured = !_obscured)
          : null,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      height: _inputHeight,
      transform: Matrix4.translationValues(0, _focused ? -1 : 0, 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (_focused)
            Positioned(
              left: -3.5,
              right: -3.5,
              top: -3.5,
              bottom: -3.5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.input + 3.5),
                  border: Border.all(
                    color: const Color(0x8C8B3DFF),
                    width: 3.5,
                  ),
                  boxShadow: AppShadows.authInputFocus,
                ),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadii.input),
              border: Border.all(
                color: _focused ? Colors.transparent : AppColors.inputBorder,
                width: 1.5,
              ),
              boxShadow: _focused ? null : AppShadows.authInput,
            ),
            child: field,
          ),
        ],
      ),
    );
  }
}

class _AuthInputField extends StatelessWidget {
  const _AuthInputField({
    required this.controller,
    required this.placeholder,
    required this.icon,
    required this.obscured,
    required this.focusNode,
    required this.keyboardType,
    required this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
    this.onToggleObscure,
  });

  final TextEditingController controller;
  final String placeholder;
  final Widget icon;
  final bool obscured;
  final FocusNode focusNode;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onToggleObscure;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _AuthInputState._inputHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 12),
          Container(
            width: 34,
            height: 34,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              gradient: AppGradients.fieldIcon,
              borderRadius: BorderRadius.circular(AppRadii.fieldIcon),
            ),
            alignment: Alignment.center,
            child: icon,
          ),
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(
                inputDecorationTheme: const InputDecorationTheme(
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                obscureText: obscured,
                keyboardType: keyboardType,
                textInputAction: textInputAction,
                autofillHints: autofillHints,
                onSubmitted: onSubmitted,
                onTapOutside: (_) => focusNode.unfocus(),
                autocorrect: false,
                enableSuggestions: !obscured,
                cursorColor: AppColors.purple,
                cursorWidth: 1.5,
                style: AppTextStyles.bodyRegular145.copyWith(
                  color: AppColors.text,
                  height: 1.2,
                ),
                decoration: InputDecoration(
                  filled: false,
                  isCollapsed: true,
                  hintText: placeholder,
                  hintStyle: AppTextStyles.bodyRegular145.copyWith(
                    color: AppColors.textFaint,
                    height: 1.2,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
          if (onToggleObscure != null)
            GestureDetector(
              onTap: onToggleObscure,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 8, 12, 8),
                child: obscured ? AppIcons.eye() : AppIcons.eyeOff(),
              ),
            )
          else
            const SizedBox(width: 12),
        ],
      ),
    );
  }
}

/// Field group with optional hint below input.
class FieldGroup extends StatelessWidget {
  const FieldGroup({
    super.key,
    required this.child,
    this.hint,
    this.hintType = FieldHintType.normal,
  });

  final Widget child;
  final String? hint;
  final FieldHintType hintType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          child,
          if (hint != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
              child: Text(
                hint!,
                style: AppTextStyles.hint12.copyWith(
                  color: switch (hintType) {
                    FieldHintType.error => AppColors.pink,
                    FieldHintType.success => AppColors.success,
                    FieldHintType.normal => AppColors.textSoft,
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum FieldHintType { normal, error, success }
