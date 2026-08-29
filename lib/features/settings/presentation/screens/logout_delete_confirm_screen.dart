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
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => LogoutConfirmDialogContent(isDelete: isDelete),
    );

    if (confirm == true && context.mounted) {
      if (!isDelete) {
        await context.read<AuthCubit>().logout();
      }
      if (context.mounted) {
        context.go(AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDelete = mode == 'delete';
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.45),
      body: Center(
        child: LogoutConfirmDialogContent(
          isDelete: isDelete,
          onClose: () => context.pop(),
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
            const SizedBox(height: 26),

            // Primary Action Button (Gradient matching Logout dialog)
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
                  onTap: _isProcessing
                      ? null
                      : () async {
                          setState(() {
                            _isProcessing = true;
                          });
                          if (!isDelete) {
                            await context.read<AuthCubit>().logout();
                          }
                          if (context.mounted) {
                            if (widget.onClose != null) {
                              widget.onClose!();
                            } else {
                              Navigator.of(context).pop(true);
                            }
                            context.go(AppRoutes.login);
                          }
                        },
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

            // Cancel Button (Outlined)
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
    );
  }
}
