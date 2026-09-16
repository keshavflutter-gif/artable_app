import 'package:flutter/material.dart';
import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/app/theme/app_typography.dart';

class NoInternetDialog extends StatelessWidget {
  const NoInternetDialog({
    super.key,
    required this.onRetry,
  });

  final VoidCallback onRetry;

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onRetry,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => NoInternetDialog(onRetry: onRetry),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(
          color: Color(0xFF33225A),
          width: 1.2,
        ),
      ),
      backgroundColor: const Color(0xFF160E2A),
      elevation: 16,
      shadowColor: Colors.black.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0x28FF3D77),
                    Color(0x289B3DFF),
                  ],
                ),
                border: Border.all(
                  color: const Color(0x459B3DFF),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: ShaderMask(
                  shaderCallback: (bounds) => AppGradients.text.createShader(bounds),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    size: 34,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Internet Connection',
              style: AppTypography.display(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Please check your internet connection and try again to access live data.',
              style: AppTypography.body(
                fontSize: 13,
                color: AppColors.textFaint,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 26),
            Container(
              width: double.infinity,
              height: 46,
              decoration: BoxDecoration(
                gradient: AppGradients.button,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9652FF).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    onRetry();
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Center(
                    child: Text(
                      'Try Again',
                      style: AppTypography.body(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
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
