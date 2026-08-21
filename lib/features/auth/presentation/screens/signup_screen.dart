import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:artable_app/app/routes/app_routes.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _nameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  String? _confirmError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final pass = _passwordController.text;
    final confirm = _confirmController.text;

    String? nameErr;
    String? emailErr;
    String? phoneErr;
    String? passErr;
    String? confirmErr;

    if (name.isEmpty) {
      nameErr = 'Full name is required';
    }

    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9.+_-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (email.isEmpty) {
      emailErr = 'Email address is required';
    } else if (!emailRegExp.hasMatch(email)) {
      emailErr = 'Please enter a valid email address';
    }

    if (phone.isEmpty) {
      phoneErr = 'Phone number is required';
    } else if (phone.length != 10) {
      phoneErr = 'Please enter a valid phone number';
    }

    if (pass.isEmpty) {
      passErr = 'Password is required';
    } else if (pass.length < 6) {
      passErr = 'Password must be at least 6 characters long';
    }

    if (confirm.isEmpty) {
      confirmErr = 'Confirm password is required';
    } else if (pass.isNotEmpty && pass != confirm) {
      confirmErr = 'Passwords do not match';
    }

    setState(() {
      _nameError = nameErr;
      _emailError = emailErr;
      _phoneError = phoneErr;
      _passwordError = passErr;
      _confirmError = confirmErr;
    });

    if (nameErr != null ||
        emailErr != null ||
        phoneErr != null ||
        passErr != null ||
        confirmErr != null) {
      return;
    }

    final auth = context.read<AuthCubit>();
    if (auth.isLoading) return;

    final response = await auth.register(
      fullName: name,
      email: email,
      password: pass,
      confirmPassword: confirm,
      phoneNumber: phone.isNotEmpty ? phone : null,
    );
    if (!mounted) return;

    if (response != null && response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.message.isNotEmpty
                ? response.message
                : 'Account created! Please verify OTP.',
          ),
          backgroundColor: const Color(0xFF27AE60),
        ),
      );

      final verifyId = response.verifyId.isNotEmpty
          ? response.verifyId
          : (auth.pendingVerifyId ?? '');
      final userId = response.userId.isNotEmpty
          ? response.userId
          : (auth.pendingUserId ?? '');
      final destination = Uri.encodeComponent(email);
      final encodedVerifyId = Uri.encodeComponent(verifyId);
      final encodedUserId = Uri.encodeComponent(userId);

      context.push(
        '${AppRoutes.otpVerification}?from=signup&destination=$destination&verifyId=$encodedVerifyId&userId=$encodedUserId&channel=EMAIL',
        extra: {
          'email': email,
          'password': pass,
          'verifyId': verifyId,
          'userId': userId,
          'channel': 'EMAIL',
        },
      );
      return;
    }

    final apiMsg = auth.errorMessage ?? response?.message ?? 'Unable to create account. Please try again.';
    setState(() {
      _emailError = apiMsg;
    });
  }

  @override
  Widget build(BuildContext context) {
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

          // 2. Main Signup content inside SingleChildScrollView
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

                  const SizedBox(height: 4),

                  // Logo Centerpiece
                  SizedBox(
                    height: 115,
                    child: Center(
                      child: Image.asset(
                        'assets/screen_logo.png',
                        width: 115,
                        height: 115,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ARTABLE Title
                  const Text(
                    'ARTABLE',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      color: Color(0xFF1E1633),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),

                  // Tagline: Create • Showcase • Inspire matching Figma
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) =>
                        AppGradients.text.createShader(bounds),
                    child: const Text(
                      'Create • Showcase • Inspire',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Full Name Input
                  _CustomAuthInput(
                    controller: _nameController,
                    hintText: 'Full Name',
                    icon: Icons.person_outline_rounded,
                    keyboardType: TextInputType.name,
                    errorText: _nameError,
                    onChanged: (_) {
                      if (_nameError != null) setState(() => _nameError = null);
                    },
                  ),

                  const SizedBox(height: 10),

                  // Email Address Input
                  _CustomAuthInput(
                    controller: _emailController,
                    hintText: 'Email Address',
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    errorText: _emailError,
                    onChanged: (_) {
                      if (_emailError != null) setState(() => _emailError = null);
                    },
                  ),

                  const SizedBox(height: 10),

                  // Phone Number Input (10 Digits)
                  _CustomAuthInput(
                    controller: _phoneController,
                    hintText: 'Phone Number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    errorText: _phoneError,
                    onChanged: (_) {
                      if (_phoneError != null) setState(() => _phoneError = null);
                    },
                  ),

                  const SizedBox(height: 10),

                  // Password Input
                  _CustomAuthInput(
                    controller: _passwordController,
                    hintText: 'Password',
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscurePassword,
                    errorText: _passwordError,
                    onChanged: (_) {
                      if (_passwordError != null) setState(() => _passwordError = null);
                    },
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18,
                        color: const Color(0xFF9E95B4),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Confirm Password Input
                  _CustomAuthInput(
                    controller: _confirmController,
                    hintText: 'Confirm Password',
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscureConfirmPassword,
                    errorText: _confirmError,
                    onChanged: (_) {
                      if (_confirmError != null) setState(() => _confirmError = null);
                    },
                    suffixIcon: IconButton(
                      onPressed: () => setState(
                          () => _obscureConfirmPassword = !_obscureConfirmPassword),
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18,
                        color: const Color(0xFF9E95B4),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // CREATE ACCOUNT Button
                  GestureDetector(
                    onTap: context.select<AuthCubit, bool>((auth) => auth.isLoading)
                        ? null
                        : _submit,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppGradients.button,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x55FF3D77),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: context.select<AuthCubit, bool>((auth) => auth.isLoading)
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
                                  'CREATE ACCOUNT ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
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

                  const SizedBox(height: 16),

                  // OR CONTINUE WITH Divider
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: const Color(0xFFEFEBF7),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OR CONTINUE WITH',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFB3A9C9),
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: const Color(0xFFEFEBF7),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Social Buttons (Google & Apple)
                  Row(
                    children: [
                      Expanded(
                        child: _SocialButton(
                          asset: 'assets/google.svg',
                          label: 'Google',
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SocialButton(
                          asset: 'assets/apple.svg',
                          label: 'Apple',
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Already a member? Log In Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already a member? ',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1E1633),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.login),
                        child: const Text(
                          'Log In',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1E1633),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
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
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.inputFormatters,
    this.errorText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
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
          height: 48,
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
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F3FC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 17,
                  color: const Color(0xFF9B51E0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
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
              ?suffixIcon,
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
                color: Colors.redAccent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.asset,
    required this.label,
    required this.onTap,
  });

  final String asset;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFEFEBF7),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              asset,
              width: 18,
              height: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E1633),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
