import 'package:flutter/material.dart';

import 'package:artable_app/features/shell/presentation/widgets/app_shell.dart';
import 'package:artable_app/features/shell/presentation/widgets/bottom_nav.dart';
import 'package:artable_app/features/challenges/presentation/screens/challenges_screen.dart';
import 'package:artable_app/features/challenges/presentation/screens/submit_entry_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  void didUpdateWidget(covariant MainTabShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      setState(() {
        _currentIndex = widget.initialIndex;
      });
    }
  }

  void _onTabSelected(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainTabShellScope(
      isInsideMainTabShell: true,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: IndexedStack(
          index: _currentIndex,
          children: [
            const HomeScreen(),
            ChallengesScreen(
              categoryFilter: widget.categoryFilter,
              initialTab: widget.initialChallengesTab,
            ),
            SubmitEntryScreen(challengeId: widget.challengeId),
            const ActivityCenterScreen(showBackButton: false),
            const MyProfileScreen(),
          ],
        ),
        bottomNavigationBar: ArtableBottomNav(
          currentIndex: _currentIndex,
          onTabSelected: _onTabSelected,
          variant: BottomNavVariant.standard,
        ),
      ),
    );
  }
}
