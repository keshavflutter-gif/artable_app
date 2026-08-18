import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/app/theme/app_typography.dart';
import 'package:artable_app/app/routes/app_routes.dart';
import 'package:artable_app/core/utils/app_icons.dart';

enum BottomNavVariant { home, standard }

class ArtableBottomNav extends StatelessWidget {
  const ArtableBottomNav({
    super.key,
    this.currentPath = AppRoutes.home,
    this.currentIndex,
    this.onTabSelected,
    this.variant = BottomNavVariant.standard,
  });

  final String currentPath;
  final int? currentIndex;
  final ValueChanged<int>? onTabSelected;
  final BottomNavVariant variant;

  bool _isActive(int index, String path) {
    if (currentIndex != null) {
      return currentIndex == index;
    }
    if (path == AppRoutes.home) {
      return currentPath == AppRoutes.splash || currentPath == AppRoutes.home;
    }
    if (path == AppRoutes.profile) {
      return currentPath == AppRoutes.profile ||
          currentPath.startsWith(AppRoutes.publicProfile);
    }
    return currentPath.startsWith(path);
  }

  @override
  Widget build(BuildContext context) {
    final items = variant == BottomNavVariant.home ? _homeItems : _standardItems;

    return Container(
      height: 74 + MediaQuery.paddingOf(context).bottom,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.inputBorder)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x145E2EAA),
            blurRadius: 24,
            offset: Offset(0, -8),
          ),
        ],
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final active = _isActive(index, item.path);
          void handleTap() {
            if (onTabSelected != null) {
              onTabSelected!(index);
            } else {
              context.go(item.path);
            }
          }

          if (item.isUpload) {
            return _UploadNavItem(
              label: item.label,
              active: active,
              onTap: handleTap,
            );
          }
          return _NavItem(
            label: item.label,
            icon: item.icon,
            active: active,
            onTap: handleTap,
          );
        }),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({
    required this.label,
    required this.path,
    required this.icon,
    this.isUpload = false,
  });

  final String label;
  final String path;
  final Widget Function({required Color color}) icon;
  final bool isUpload;
}

const _homeItems = [
  _NavItemData(
    label: 'Home',
    path: AppRoutes.home,
    icon: _homeIcon,
  ),
  _NavItemData(
    label: 'Challenges',
    path: AppRoutes.challenges,
    icon: _trophyIcon,
  ),
  _NavItemData(
    label: 'Upload',
    path: AppRoutes.submitEntry,
    icon: _plusIcon,
    isUpload: true,
  ),
  _NavItemData(
    label: 'Activity',
    path: AppRoutes.activityCenter,
    icon: _activityIcon,
  ),
  _NavItemData(
    label: 'Profile',
    path: AppRoutes.profile,
    icon: _profileIcon,
  ),
];

const _standardItems = [
  _NavItemData(
    label: 'Home',
    path: AppRoutes.home,
    icon: _homeIcon,
  ),
  _NavItemData(
    label: 'Challenges',
    path: AppRoutes.challenges,
    icon: _trophyIcon,
  ),
  _NavItemData(
    label: 'Upload',
    path: AppRoutes.submitEntry,
    icon: _plusIcon,
    isUpload: true,
  ),
  _NavItemData(
    label: 'Activity',
    path: AppRoutes.activityCenter,
    icon: _activityIcon,
  ),
  _NavItemData(
    label: 'Profile',
    path: AppRoutes.profile,
    icon: _profileIcon,
  ),
];

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final Widget Function({required Color color}) icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.purple : AppColors.textFaint;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon(color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.body(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadNavItem extends StatelessWidget {
  const _UploadNavItem({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.translate(
              offset: const Offset(0, -22),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: AppGradients.button,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x73FF3D77),
                      blurRadius: 26,
                      offset: Offset(0, 12),
                    ),
                  ],
                  border: Border.all(color: Colors.white, width: 5),
                ),
                child: Center(
                  child: _plusIcon(color: Colors.white),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -22),
              child: Text(
                label,
                style: AppTypography.body(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.purple,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _homeIcon({required Color color}) => AppIcons.home(color: color);

Widget _trophyIcon({required Color color}) => AppIcons.trophy(color: color);

Widget _plusIcon({required Color color}) => AppIcons.plus(color: color);

Widget _activityIcon({required Color color}) => AppIcons.activity(color: color);

Widget _profileIcon({required Color color}) => AppIcons.profile(color: color);
