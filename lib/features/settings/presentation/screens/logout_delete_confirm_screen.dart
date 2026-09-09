import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:artable_app/app/routes/app_routes.dart';

class LogoutDeleteConfirmScreen extends StatelessWidget {
  const LogoutDeleteConfirmScreen({super.key, this.mode = 'logout'});

  final String mode;

  static Future<void> show(BuildContext context, {String mode = 'logout'}) async {
    final isDelete = mode == 'delete';
    await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => LogoutConfirmDialogContent(isDelete: isDelete),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDelete = mode == 'delete';
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.45),
      body: Center(
        child: SingleChildScrollView(
          child: LogoutConfirmDialogContent(
            isDelete: isDelete,
            onClose: () => context.pop(),
          ),
        ),
      ),
    );
  }
}

class LogoutConfirmDialogContent extends StatefulWidget {
  const LogoutConfirmDialogContent({
    super.key,
    required this.isDelete,
    this.onClose,
  });

  final bool isDelete;
  final VoidCallback? onClose;

  @override
  State<LogoutConfirmDialogContent> createState() => _LogoutConfirmDialogContentState();
}

class _LogoutConfirmDialogContentState extends State<LogoutConfirmDialogContent> {
  bool _isProcessing = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  late final TextEditingController _passwordController;
  late final TextEditingController _reasonController;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    final isDelete = widget.isDelete;

    if (isDelete && _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your password to delete account.';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      if (isDelete) {
        final success = await context.read<AuthCubit>().deleteAccount(
          password: _passwordController.text,
          reason: _reasonController.text.trim().isNotEmpty
              ? _reasonController.text.trim()
              : null,
        );

        if (!mounted) return;

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account deleted successfully.'),
              backgroundColor: Color(0xFF8B3DFF),
            ),
          );
          if (widget.onClose != null) {
            widget.onClose!();
          } else {
            Navigator.of(context).pop(true);
          }
          context.go(AppRoutes.login);
        } else {
          final err = context.read<AuthCubit>().state.errorMessage;
          setState(() {
            _isProcessing = false;
            _errorMessage = err ?? 'Failed to delete account. Please check your password.';
          });
        }
      } else {
        await context.read<AuthCubit>().logout();
        if (!mounted) return;
        if (widget.onClose != null) {
          widget.onClose!();
        } else {
          Navigator.of(context).pop(true);
        }
        context.go(AppRoutes.login);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'An error occurred. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDelete = widget.isDelete;
    final title = isDelete ? 'Delete account?' : 'Log out?';
    final subtitle = isDelete
        ? 'This permanently removes your profile, videos, and wallet history.'
        : 'You can log in again anytime.';
    final primaryButtonLabel = isDelete ? 'Delete Account' : 'Log Out';
    final iconData = isDelete ? Icons.delete_outline_rounded : Icons.exit_to_app_rounded;
    const iconColor = Color(0xFF8B3DFF);
    const iconBgColor = Color(0xFFF3EAFD);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: const BorderSide(color: Color(0xFFECE8F5), width: 1.5),
      ),
      backgroundColor: Colors.white,
      elevation: 20,
      shadowColor: const Color(0xFF5E2EAA).withValues(alpha: 0.15),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Circular Icon Badge
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: 34,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF241E38),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12.5,
                    color: Color(0xFF7A7090),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Error banner if any
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFCACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 18, color: Color(0xFFE53935)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Color(0xFFE53935),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Extra Input Fields for Delete Account Mode
              if (isDelete) ...[
                // Password Field
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Password',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF241E38),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F7FB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _errorMessage != null && _passwordController.text.isEmpty
                          ? const Color(0xFFE53935)
                          : const Color(0xFFECE8F5),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF8B3DFF)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          enabled: !_isProcessing,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: Color(0xFF241E38),
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Enter your password',
                            hintStyle: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: Color(0xFFB3A9C9),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                          color: const Color(0xFF7A7090),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Reason Field (Optional)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Reason (Optional)',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF241E38),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F7FB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFECE8F5)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Color(0xFF8B3DFF)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _reasonController,
                          enabled: !_isProcessing,
                          maxLines: 2,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: Color(0xFF241E38),
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Why are you leaving?',
                            hintStyle: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: Color(0xFFB3A9C9),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ] else
                const SizedBox(height: 10),

              // Primary Action Button
              Container(
                height: 50,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: AppGradients.button,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5487).withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isProcessing ? null : _handleConfirm,
                    borderRadius: BorderRadius.circular(25),
                    child: Center(
                      child: _isProcessing
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              primaryButtonLabel,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Cancel Button
              SizedBox(
                height: 50,
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isProcessing
                      ? null
                      : () {
                          if (widget.onClose != null) {
                            widget.onClose!();
                          } else {
                            Navigator.of(context).pop(false);
                          }
                        },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFECE8F5), width: 1.5),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Color(0xFF7A7090),
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

