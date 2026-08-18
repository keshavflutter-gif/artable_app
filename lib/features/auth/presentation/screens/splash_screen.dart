import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:artable_app/app/routes/app_routes.dart';
import 'package:artable_app/core/storage/onboarding_storage_service.dart';

/// Splash screen — matches Figma splash design 100%.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const _splashDelay = Duration(milliseconds: 1800);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  var _navigated = false;
  final _onboardingStorage = OnboardingStorageService();

  @override
  void initState() {
    super.initState();
    _timer = Timer(SplashScreen._splashDelay, _navigateFromSplash);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _navigateFromSplash() async {
    if (!mounted || _navigated) return;
    _navigated = true;

    final auth = context.read<AuthCubit>();
    await auth.ensureInitialized();

    final onboardingCompleted = await _onboardingStorage.isCompleted();
    if (!mounted) return;

    if (auth.isLoggedIn) {
      context.go(AppRoutes.home);
    } else if (!onboardingCompleted) {
      context.go(AppRoutes.onboarding);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () => unawaited(_navigateFromSplash()),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Full-bleed background watercolor frame asset
            Image.asset(
              'assets/bg-frame-1.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              alignment: Alignment.topCenter,
            ),

            // 2. Centered Logo + ARTABLE + Tagline matching Figma layout
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Logo 3D A Icon
                  Image.asset(
                    'assets/screen_logo.png',
                    width: 210,
                    height: 210,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 22),
                  // Title ARTABLE
                  const Text(
                    'ARTABLE',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5,
                      color: Color(0xFF1E1633),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // Tagline with Gradient Text
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) =>
                        AppGradients.text.createShader(bounds),
                    child: const Text(
                      'Every Talent Deserves a Stage',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),

            // 3. Subtle Version Text at bottom
            Positioned(
              bottom: 28,
              left: 0,
              right: 0,
              child: Text(
                'v1.0.0',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black.withValues(alpha: 0.25),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
