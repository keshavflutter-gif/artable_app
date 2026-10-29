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
                _buildFieldLabel('Password'),
                const SizedBox(height: 6),
                _buildDialogField(
                  controller: _passwordController,
                  hintText: 'Enter your password',
                  icon: Icons.lock_outline_rounded,
                  obscureText: _obscurePassword,
                  hasError: _errorMessage != null &&
                      _passwordController.text.isEmpty,
                  suffix: GestureDetector(
                    onTap: _isProcessing
                        ? null
                        : () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 8,
                      ),
                      child: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: const Color(0xFF7A7090),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _buildFieldLabel('Reason (Optional)'),
                const SizedBox(height: 6),
                _buildDialogField(
                  controller: _reasonController,
                  hintText: 'Why are you leaving?',
                  icon: Icons.chat_bubble_outline_rounded,
                  maxLines: 3,
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

  Widget _buildFieldLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF241E38),
        ),
      ),
    );
  }

  Widget _buildDialogField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    bool hasError = false,
    int maxLines = 1,
    Widget? suffix,
  }) {
    final isMultiline = maxLines > 1;
    return Container(
      height: isMultiline ? null : 48,
      constraints: isMultiline ? const BoxConstraints(minHeight: 88) : null,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasError ? const Color(0xFFE53935) : const Color(0xFFECE8F5),
          width: hasError ? 1.5 : 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: isMultiline ? 8 : 0),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF3EAFD),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 17, color: const Color(0xFF8B3DFF)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: isMultiline ? 10 : 0),
              child: TextField(
                controller: controller,
                obscureText: obscureText,
                enabled: !_isProcessing,
                maxLines: obscureText ? 1 : maxLines,
                textAlignVertical: isMultiline
                    ? TextAlignVertical.top
                    : TextAlignVertical.center,
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                },
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF241E38),
                  height: 1.3,
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintMaxLines: isMultiline ? 2 : 1,
                  hintStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFB3A9C9),
                    height: 1.3,
                  ),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  isDense: true,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
          if (suffix != null) suffix,
        ],
      ),
    );
  }
}

