import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_typography.dart';
import 'package:artable_app/app/routes/app_routes.dart';
import 'package:artable_app/features/shell/presentation/widgets/bottom_nav.dart';

class MainTabShellScope extends InheritedWidget {
  const MainTabShellScope({
    super.key,
    required this.isInsideMainTabShell,
    required super.child,
  });

  final bool isInsideMainTabShell;

  static bool of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MainTabShellScope>()?.isInsideMainTabShell ?? false;
  }

  @override
  bool updateShouldNotify(MainTabShellScope oldWidget) =>
      isInsideMainTabShell != oldWidget.isInsideMainTabShell;
}

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.currentPath,
    required this.body,
    this.bottomNavVariant = BottomNavVariant.standard,
    this.showBottomNav = true,
  });

  final String currentPath;
  final Widget body;
  final BottomNavVariant bottomNavVariant;
  final bool showBottomNav;

  @override
  Widget build(BuildContext context) {
    final inTabShell = MainTabShellScope.of(context);
    final shouldShow = showBottomNav && !inTabShell;

    return Scaffold(
      backgroundColor: Colors.white,
      body: body,
      bottomNavigationBar: shouldShow
          ? ArtableBottomNav(
              currentPath: currentPath,
              variant: bottomNavVariant,
            )
          : null,
    );
  }
}

class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.onBack,
  });

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
        child: Row(
          children: [
            _BackButton(
              onTap: onBack ??
                  () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(AppRoutes.home);
                    }
                  },
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.display(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E1B2E),
                ),
              ),
            ),
            const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFECE8F5), width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D5E2EAA),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.chevron_left,
          size: 20,
          color: Color(0xFF1E1B2E),
        ),
      ),
    );
  }
}
