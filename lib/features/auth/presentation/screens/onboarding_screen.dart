import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/app/routes/app_routes.dart';
import 'package:artable_app/core/storage/onboarding_storage_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _index = 0;

  static const _slides = [
    _SlideData(
      asset: 'assets/illustration-onboarding-1.svg',
      title: 'Showcase Your Talent',
      body:
          'Record and share your singing, dancing, comedy, art, fitness, magic, acting, sports and more.',
    ),
    _SlideData(
      asset: 'assets/illustration-onboarding-2.svg',
      title: 'Join Challenges',
      body:
          'Participate in active challenges, get rated by users, and climb the leaderboard.',
    ),
    _SlideData(
      asset: 'assets/illustration-onboarding-3.svg',
      title: 'Win Rewards',
      body:
          'Earn prizes, badges, daily bonuses, referral rewards, and wallet rewards.',
    ),
  ];

  final _onboardingStorage = OnboardingStorageService();

  @override
  void initState() {
    super.initState();
    unawaited(_redirectIfAlreadyCompleted());
  }

  Future<void> _redirectIfAlreadyCompleted() async {
    final completed = await _onboardingStorage.isCompleted();
    if (!mounted || !completed) return;
    context.go(AppRoutes.login);
  }

  void _goToLogin() {
    unawaited(_completeOnboarding());
  }

  Future<void> _completeOnboarding() async {
    await _onboardingStorage.markCompleted();
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  void _next() {
    if (_index < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _goToLogin();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
            'assets/bg-frame-1.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.topCenter,
          ),

          // 2. Main onboarding content matching Figma design 100%
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 8),

                // Top Bar - Skip button in top right
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 24),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: _goToLogin,
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: Color(0xFF7A6F93),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Centered 3 dots page indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (i) {
                    final active = i == _index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: active ? 22 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        gradient: active ? AppGradients.button : null,
                        color: active ? null : const Color(0xFFE5E0F2),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 12),

                // Swipable Slide Content ONLY (Illustration + Title + Subtitle)
                SizedBox(
                  height: 340,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          // Hero Illustration
                          SizedBox(
                            height: 195,
                            child: SvgPicture.asset(
                              slide.asset,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Title with Gradient Text
                          ShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (bounds) =>
                                AppGradients.text.createShader(bounds),
                            child: Text(
                              slide.title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Subtitle Body Text with 36px side padding
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 36),
                            child: Text(
                              slide.body,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF7A6F93),
                                height: 1.45,
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 28),

                // FIXED Action Button (Next / Get Started) - Outside PageView so it never moves when swiping!
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GestureDetector(
                    onTap: _next,
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
                      child: Text(
                        _index == _slides.length - 1 ? 'Get Started' : 'Next',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideData {
  const _SlideData({
    required this.asset,
    required this.title,
    required this.body,
  });

  final String asset;
  final String title;
  final String body;
}
