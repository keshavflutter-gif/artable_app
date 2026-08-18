import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/app/theme/app_shadows.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:artable_app/app/routes/app_routes.dart';
import 'package:artable_app/core/utils/app_icons.dart';
import 'package:artable_app/core/widgets/app_screen.dart';
import 'package:artable_app/features/auth/presentation/widgets/auth_input.dart';
import 'package:artable_app/core/widgets/back_button.dart';
import 'package:artable_app/core/widgets/btn_gradient.dart';
import 'package:artable_app/core/widgets/logo_header.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    super.key,
    this.email,
    this.token,
  });

  final String? email;
  final String? token;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _newHint;
  String? _confirmHint;
  FieldHintType _newHintType = FieldHintType.normal;
  FieldHintType _confirmHintType = FieldHintType.normal;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verifyTokenInBackground();
    });
  }

  Future<void> _verifyTokenInBackground() async {
    final token = widget.token;
    if (token != null && token.isNotEmpty) {
      final auth = context.read<AuthCubit>();
      final response = await auth.verifyResetToken(token: token);
      if (!mounted) return;
      if (response == null || !response.success) {
        final message = auth.resetTokenMessage ??
            auth.errorMessage ??
            response?.message ??
            'Invalid link';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pass = _newPasswordController.text;
    final confirm = _confirmController.text;

    if (pass.length < 8) {
      setState(() {
        _newHint = 'Password must be at least 8 characters';
        _newHintType = FieldHintType.error;
        _confirmHint = null;
      });
      return;
    }
    if (pass != confirm) {
      setState(() {
        _confirmHint = 'Passwords do not match';
        _confirmHintType = FieldHintType.error;
        _newHint = null;
      });
      return;
    }

    setState(() {
      _newHint = null;
      _confirmHint = null;
    });

    final auth = context.read<AuthCubit>();
    if (auth.isResettingPassword) return;

    final token = widget.token ?? auth.activeResetToken ?? '';
    debugPrint('=== SUBMITTING RESET PASSWORD WITH TOKEN: $token ===');

    final response = await auth.resetPassword(
      token: token,
      password: pass,
    );

    if (!mounted) return;

    if (response != null && response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.message.isNotEmpty
                ? response.message
                : 'Password reset successfully',
          ),
          backgroundColor: const Color(0xFF27AE60),
        ),
      );
      setState(() => _showSuccess = true);
    } else {
      final errorMsg = auth.errorMessage ??
          response?.message ??
          'Failed to reset password. Please try again.';
      setState(() {
        _confirmHint = errorMsg;
        _confirmHintType = FieldHintType.error;
      });
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
    return AppScreen(
      bgAsset: 'assets/bg-frame-3.png',
      child: _showSuccess ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildForm() {
    final isResetting = context.select<AuthCubit, bool>(
      (auth) => auth.isResettingPassword,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TopRow(
          onBack: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.login),
        ),
        const LogoHeader(variant: LogoHeaderVariant.iconOnly),
        Text(
          'Reset Password',
          style: AppTextStyles.displayBold26,
          textAlign: TextAlign.center,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 22),
          child: Text(
            "Create a new password that's at least 8 characters long",
            style: AppTextStyles.bodyRegular14,
            textAlign: TextAlign.center,
          ),
        ),
        FieldGroup(
          hint: _newHint,
          hintType: _newHintType,
          child: AuthInput(
            controller: _newPasswordController,
            placeholder: 'New Password',
            icon: AppIcons.lock(),
            obscureText: true,
            autofillHints: const [AutofillHints.newPassword],
          ),
        ),
        FieldGroup(
          hint: _confirmHint,
          hintType: _confirmHintType,
          child: AuthInput(
            controller: _confirmController,
            placeholder: 'Confirm New Password',
            icon: AppIcons.lock(),
            obscureText: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: BtnGradient(
            label: isResetting ? 'PLEASE WAIT...' : 'RESET PASSWORD',
            onPressed: isResetting ? () {} : _submit,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.button,
            boxShadow: AppShadows.btn,
          ),
          alignment: Alignment.center,
          child: AppIcons.check(),
        ),
        const SizedBox(height: 20),
        Text('Password Reset!', style: AppTextStyles.displayBold20),
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 26),
          child: Text(
            'Your password has been changed successfully. You can now log in with your new password.',
            style: AppTextStyles.bodyRegular14.copyWith(height: 1.6),
            textAlign: TextAlign.center,
          ),
        ),
        BtnGradient(
          label: 'BACK TO LOGIN',
          onPressed: () => context.go(AppRoutes.login),
        ),
      ],
    );
  }
}
