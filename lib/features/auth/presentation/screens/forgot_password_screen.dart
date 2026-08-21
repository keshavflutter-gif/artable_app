import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:artable_app/app/routes/app_routes.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  String? _errorHint;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorHint = 'Please enter your email address');
      return;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      setState(() => _errorHint = 'Please enter a valid email address');
      return;
    }

    setState(() => _errorHint = null);

    final auth = context.read<AuthCubit>();
    if (auth.isSendingForgotPassword) return;

    final response = await auth.forgotPassword(email: email);
    if (!mounted) return;

    if (response != null && response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.message.isNotEmpty
                ? response.message
                : 'Reset Password link sent on your E-mail address. Please check your inbox!',
          ),
          backgroundColor: const Color(0xFF27AE60),
          duration: const Duration(seconds: 4),
        ),
      );

      final encodedEmail = Uri.encodeComponent(email);
      context.push('${AppRoutes.resetPassword}?email=$encodedEmail');
      return;
    } else {
      final errorMsg = auth.errorMessage ??
          response?.message ??
          'Failed to send reset link. Please try again.';
      setState(() => _errorHint = errorMsg);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Full-bleed background watercolor frame asset
          Image.asset(
            'assets/bg-frame-3.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.topCenter,
          ),

          // 2. Main Forgot Password content inside SingleChildScrollView
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
                          : context.go(AppRoutes.login),
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

                  const SizedBox(height: 12),

                  // Logo Centerpiece
                  SizedBox(
                    height: 140,
                    child: Center(
                      child: Image.asset(
                        'assets/screen_logo.png',
                        width: 140,
                        height: 140,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Forgot Password Title & Subtitle (Left-aligned matching Figma)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Forgot Password?',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                            color: Color(0xFF1E1633),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Enter your email address to receive reset instructions',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF8E82A6),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Email Address Input
                  _CustomAuthInput(
                    controller: _emailController,
                    hintText: 'Email Address',
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    errorText: _errorHint,
                    onChanged: (_) {
                      if (_errorHint != null) {
                        setState(() => _errorHint = null);
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  // SEND RESET LINK Button
                  GestureDetector(
                    onTap: context.select<AuthCubit, bool>(
                            (auth) => auth.isSendingForgotPassword)
                        ? null
                        : _submit,
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
                              (auth) => auth.isSendingForgotPassword)
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'SEND RESET LINK ',
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

                  const SizedBox(height: 18),

                  // Remembered it? Back to Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Remembered it? ',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF7A6F93),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.login),
                        child: const Text(
                          'Back to Login',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF9B51E0),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
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

class _CustomAuthInput extends StatelessWidget {
  const _CustomAuthInput({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.keyboardType,
    this.errorText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasError ? const Color(0xFFFF3D77) : const Color(0xFFEFEBF7),
              width: hasError ? 1.5 : 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F3FC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: const Color(0xFF9B51E0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  onChanged: onChanged,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF1E1633),
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFFB3A9C9),
                      fontWeight: FontWeight.w400,
                    ),
                    filled: false,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              errorText!,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFFF3D77),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}
