import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/routes/app_routes.dart';
import 'package:artable_app/features/shell/presentation/widgets/app_shell.dart';
import 'package:artable_app/features/shell/presentation/widgets/bottom_nav.dart';
import 'package:artable_app/features/challenges/presentation/screens/challenges_screen.dart';
import 'package:artable_app/features/home/presentation/screens/home_screen.dart';
import 'package:artable_app/features/notifications/presentation/screens/activity_center_screen.dart';
import 'package:artable_app/features/profile/presentation/screens/my_profile_screen.dart';

class MainTabShell extends StatefulWidget {
  const MainTabShell({
    super.key,
    this.initialIndex = 0,
    this.challengeId,
    this.categoryFilter,
    this.initialChallengesTab = 'active',
  });

  final int initialIndex;
  final String? challengeId;
  final String? categoryFilter;
  final String initialChallengesTab;

  @override
  State<MainTabShell> createState() => _MainTabShellState();
}

class _MainTabShellState extends State<MainTabShell> {
  late int _currentIndex;
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    // Upload tab (index 2) is no longer a screen — open Studio instead.
    _currentIndex = widget.initialIndex == 2 ? 0 : widget.initialIndex;
  }

  @override
  void didUpdateWidget(covariant MainTabShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      setState(() {
        _currentIndex =
            widget.initialIndex == 2 ? _currentIndex : widget.initialIndex;
      });
    }
  }

  void _onTabSelected(int index) {
    if (index == 2) {
      final id = widget.challengeId;
      final path = (id != null && id.isNotEmpty)
          ? '${AppRoutes.studioStart}?id=$id'
          : AppRoutes.studioStart;
      context.push(path);
      return;
    }
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
    });
  }

  void _handleBackPress() {
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
      });
      return;
    }

    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Tap again to exit',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF2C2C2E),
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      );
      return;
    }

    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress();
      },
      child: MainTabShellScope(
        isInsideMainTabShell: true,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: IndexedStack(
            index: _currentIndex > 2 ? _currentIndex - 1 : _currentIndex,
            children: [
              const HomeScreen(),
              ChallengesScreen(
                categoryFilter: widget.categoryFilter,
                initialTab: widget.initialChallengesTab,
              ),
              const ActivityCenterScreen(showBackButton: false),
              MyProfileScreen(isActive: _currentIndex == 4),
            ],
          ),
          bottomNavigationBar: ArtableBottomNav(
            currentIndex: _currentIndex,
            onTabSelected: _onTabSelected,
            variant: BottomNavVariant.standard,
          ),
        ),
      ),
    );
  }
}
