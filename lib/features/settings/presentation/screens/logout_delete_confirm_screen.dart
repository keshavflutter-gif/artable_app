import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/core/widgets/app_back_header.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:artable_app/app/routes/app_routes.dart';

class LogoutDeleteConfirmScreen extends StatelessWidget {
  const LogoutDeleteConfirmScreen({super.key, this.mode = 'logout'});

  final String mode;

  @override
  Widget build(BuildContext context) {
    final isDelete = mode == 'delete';

    final title = isDelete ? 'Delete account?' : 'Log out?';
    final subtitle = isDelete
        ? 'This permanently removes your profile, videos, and wallet history.'
        : 'You can log in again anytime.';
    
    final primaryButtonLabel = isDelete ? 'Delete Account' : 'Log Out';
    
    final iconData = isDelete ? Icons.delete_outline_rounded : Icons.exit_to_app_rounded;
    final iconColor = isDelete ? const Color(0xFFFF3D77) : const Color(0xFF8B3DFF);
    final iconBgColor = isDelete ? const Color(0xFFFFE8EE) : const Color(0xFFF3EAFD);

    return AppScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppBackHeader(title: 'Confirm'),
          Expanded(
            child: AppContent(
              noBottomPad: true,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  // Large circular icon container
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      iconData,
                      color: iconColor,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title Text
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF241E38),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Color(0xFF7A7090),
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Action Button (Gradient/Solid)
                  Container(
                    height: 54,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: isDelete ? null : AppGradients.button,
                      color: isDelete ? const Color(0xFFFF3D77) : null,
                      borderRadius: BorderRadius.circular(27),
                      boxShadow: [
                        BoxShadow(
                          color: (isDelete ? const Color(0xFFFF3D77) : const Color(0xFFFF5487))
                              .withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          if (!isDelete) {
                            await context.read<AuthCubit>().logout();
                          }
                          if (context.mounted) {
                            context.go(AppRoutes.login);
                          }
                        },
                        borderRadius: BorderRadius.circular(27),
                        child: Center(
                          child: Text(
                            primaryButtonLabel,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Cancel Button (Outlined)
                  SizedBox(
                    height: 54,
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFECE8F5), width: 1.5),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(27),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Color(0xFF241E38),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(flex: 3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
