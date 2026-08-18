import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';

/// OTP row matching .otp-row from style.css with JS logic from common.js
class OtpInputRow extends StatefulWidget {
  const OtpInputRow({
    super.key,
    required this.controllers,
    required this.focusNodes,
    this.hasError = false,
    this.onChanged,
  });

  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final bool hasError;
  final VoidCallback? onChanged;

  @override
  State<OtpInputRow> createState() => OtpInputRowState();
}

class OtpInputRowState extends State<OtpInputRow> {
  bool get isComplete =>
      widget.controllers.every((c) => c.text.length == 1);

  String get otpValue => widget.controllers.map((c) => c.text).join();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = ((constraints.maxWidth - 5 * 6) / 6).clamp(36.0, 42.0);
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            return Padding(
              padding: EdgeInsets.only(left: index == 0 ? 0 : 6),
              child: SizedBox(
                width: boxWidth,
                height: 48,
                child: _OtpBox(
                  controller: widget.controllers[index],
                  focusNode: widget.focusNodes[index],
                  hasError: widget.hasError,
                  onChanged: (value) {
                    final digit = value.replaceAll(RegExp(r'[^0-9]'), '');
                    if (digit.length > 1) {
                      _handlePaste(digit);
                      return;
                    }
                    widget.controllers[index].text = digit;
                    widget.controllers[index].selection =
                        TextSelection.collapsed(offset: digit.length);
                    if (digit.isNotEmpty && index < 5) {
                      widget.focusNodes[index + 1].requestFocus();
                    }
                    widget.onChanged?.call();
                  },
                  onBackspace: () {
                    if (widget.controllers[index].text.isEmpty && index > 0) {
                      widget.focusNodes[index - 1].requestFocus();
                    }
                  },
                ),
              ),
            );
          }),
        );
      },
    );
  }

  void _handlePaste(String digits) {
    for (var i = 0; i < widget.controllers.length; i++) {
      widget.controllers[i].text = i < digits.length ? digits[i] : '';
    }
    final focusIndex =
        digits.length >= 6 ? 5 : digits.length.clamp(0, 5);
    widget.focusNodes[focusIndex].requestFocus();
    widget.onChanged?.call();
  }
}

class _OtpBox extends StatefulWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onChanged,
    required this.onBackspace,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  @override
  State<_OtpBox> createState() => _OtpBoxState();
}

class _OtpBoxState extends State<_OtpBox> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _focused = widget.focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.hasError
        ? const Color(0xFFFF3D77)
        : _focused
            ? const Color(0xFF9B51E0)
            : const Color(0xFFEFEBF7);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
          width: _focused || widget.hasError ? 1.8 : 1.2,
        ),
        boxShadow: widget.hasError
            ? [
                const BoxShadow(
                  color: Color(0x33FF3D77),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                )
              ]
            : _focused
                ? [
                    const BoxShadow(
                      color: Color(0x339B51E0),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    )
                  ]
                : [
                    const BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    )
                  ],
      ),
      alignment: Alignment.center,
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              widget.controller.text.isEmpty) {
            widget.onBackspace();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          style: AppTextStyles.otpDigit.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: widget.hasError ? AppColors.pink : AppColors.text,
          ),
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            filled: false,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (value) {
            if (value.isEmpty) widget.onBackspace();
            widget.onChanged(value);
          },
          onTapOutside: (_) => widget.focusNode.unfocus(),
        ),
      ),
    );
  }
}

/// Resend timer matching startResendTimer from common.js
class ResendTimer extends StatefulWidget {
  const ResendTimer({
    super.key,
    this.seconds = 30,
    this.onResend,
  });

  final int seconds;
  final VoidCallback? onResend;

  @override
  State<ResendTimer> createState() => ResendTimerState();
}

class ResendTimerState extends State<ResendTimer> {
  int _remaining = 0;
  bool _showResend = false;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    setState(() {
      _remaining = widget.seconds;
      _showResend = false;
    });
    _tick();
  }

  void _tick() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_remaining <= 0) {
        setState(() => _showResend = true);
        return;
      }
      setState(() => _remaining -= 1);
      _tick();
    });
  }

  String get _formatted {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return 'Resend code in $m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 26),
      child: Center(
        child: _showResend
            ? InkWell(
                onTap: () {
                  widget.onResend?.call();
                  startTimer();
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    'Resend Code',
                    style: AppTextStyles.bodyBold135.copyWith(
                      color: AppColors.purple,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_outlined, size: 16, color: AppColors.textSoft),
                  const SizedBox(width: 6),
                  Text(_formatted, style: AppTextStyles.bodySemiBold135),
                ],
              ),
      ),
    );
  }
}
