import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:artable_app/app/routes/app_routes.dart';
import 'package:artable_app/features/auth/presentation/widgets/otp_input_row.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    super.key,
    this.from = 'signup',
    this.destination = '+1 •••• •• 123',
    this.verifyId = '',
    this.userId = '',
    this.channel = 'EMAIL',
    this.email,
    this.password,
  });

  final String from;
  final String destination;
  final String verifyId;
  final String userId;
  final String channel;
  final String? email;
  final String? password;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  // late String _currentVerifyId;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // _currentVerifyId = widget.verifyId;
    _controllers = List.generate(6, (_) => TextEditingController());
    _focusNodes = List.generate(6, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  bool _isOtpComplete() => _controllers.every((c) => c.text.length == 1);

  Future<void> _verify() async {
    final enteredOtp = _controllers.map((c) => c.text.trim()).join();
    if (!_isOtpComplete() || enteredOtp != '123456') {
      setState(() => _hasError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid OTP. Please enter 123456'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    setState(() => _hasError = false);

    // final otp = _controllers.map((c) => c.text.trim()).join();
    // final auth = context.read<AuthCubit>();
    // if (auth.isVerifyingOtp) return;

    // final effectiveVerifyId = _currentVerifyId.isNotEmpty
    //     ? _currentVerifyId
    //     : widget.verifyId;

    // final response = await auth.verifyOtp(
    //   verifyId: effectiveVerifyId,
    //   otp: otp,
    //   channel: widget.channel,
    //   email: widget.email,
    //   password: widget.password,
    // );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('OTP Verified successfully'),
        backgroundColor: Color(0xFF27AE60),
      ),
    );

    if (widget.from == 'forgot') {
      context.push(AppRoutes.resetPassword);
    } else {
      final emailParam = widget.email != null ? Uri.encodeComponent(widget.email!) : '';
      final passParam = widget.password != null ? Uri.encodeComponent(widget.password!) : '';
      final loginUrl = (emailParam.isNotEmpty || passParam.isNotEmpty)
          ? '${AppRoutes.login}?email=$emailParam&password=$passParam'
          : AppRoutes.login;
      context.go(loginUrl);
    }
  }

  Future<void> _resendOtp() async {
    final auth = context.read<AuthCubit>();
    if (auth.isResendingOtp) return;

    final targetEmail = widget.email ??
        (widget.destination.contains('@') ? widget.destination : null);

    final response = await auth.resendOtp(
      userId: widget.userId,
      email: targetEmail,
      channel: widget.channel,
    );

    if (!mounted) return;

    if (response != null && response.success) {
      if (response.verifyId.isNotEmpty) {
        setState(() {
          // _currentVerifyId = response.verifyId;
          _hasError = false;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.message.isNotEmpty
                ? response.message
                : 'OTP resent successfully',
          ),
          backgroundColor: const Color(0xFF27AE60),
        ),
      );
    } else {
      final errorMsg =
          auth.errorMessage ?? response?.message ?? 'Failed to resend OTP';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  String get _formattedDestination {
    final raw = widget.destination.trim();
    if (raw.isEmpty || raw == '+1 •••• •• 123') {
      return '+1 **** ** 123';
    }
    if (RegExp(r'^\d{10}$').hasMatch(raw)) {
      return '+91 **** ** ${raw.substring(7)}';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final backRoute = widget.from == 'forgot'
        ? AppRoutes.forgotPassword
        : AppRoutes.signup;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Full-bleed background watercolor frame asset matching Figma
          Image.asset(
            'assets/bg-frame-1.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.topCenter,
          ),

          // 2. Main OTP Content inside SingleChildScrollView
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  // Top Back Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => context.canPop()
                          ? context.pop()
                          : context.go(backRoute),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x15000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.chevron_left_rounded,
                          size: 22,
                          color: Color(0xFF1E1633),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Logo Centerpiece
                  SizedBox(
                    height: 135,
                    child: Center(
                      child: Image.asset(
                        'assets/screen_logo.png',
                        width: 135,
                        height: 135,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Verify OTP Title
                  const Text(
                    'Verify OTP',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                      color: Color(0xFF1E1633),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // Subtitle
                  const Text(
                    'Enter the verification code sent to your mobile number/email',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF8E82A6),
                      fontWeight: FontWeight.w400,
                      height: 1.35,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formattedDestination,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6E6485),
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  // 6 OTP Input Boxes
                  OtpInputRow(
                    controllers: _controllers,
                    focusNodes: _focusNodes,
                    hasError: _hasError,
                    onChanged: () {
                      if (_hasError) setState(() => _hasError = false);
                    },
                  ),

                  const SizedBox(height: 12),

                  // Resend Code Link
                  GestureDetector(
                    onTap: context.select<AuthCubit, bool>(
                            (auth) => auth.isResendingOtp)
                        ? null
                        : _resendOtp,
                    child: context.select<AuthCubit, bool>(
                            (auth) => auth.isResendingOtp)
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF9B51E0),
                            ),
                          )
                        : const Text(
                            'Resend Code',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF9B51E0),
                            ),
                            textAlign: TextAlign.center,
                          ),
                  ),

                  const SizedBox(height: 20),

                  // VERIFY Button
                  GestureDetector(
                    onTap: context.select<AuthCubit, bool>(
                            (auth) => auth.isVerifyingOtp)
                        ? null
                        : _verify,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: AppGradients.button,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x55FF3D77),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: context.select<AuthCubit, bool>(
                              (auth) => auth.isVerifyingOtp)
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'VERIFY ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
