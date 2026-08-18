import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';
import 'package:artable_app/app/routes/app_routes.dart';
import 'package:artable_app/core/utils/app_icons.dart';

enum BottomNavVariant { home, categories, defaultNav }

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.current,
    this.variant = BottomNavVariant.home,
  });

  final String current;
  final BottomNavVariant variant;

  @override
  Widget build(BuildContext context) {
    final items = switch (variant) {
      BottomNavVariant.home => _homeItems,
      BottomNavVariant.categories => _categoriesItems,
      _ => _categoriesItems,
    };

    return Container(
      height: 74 + MediaQuery.paddingOf(context).bottom,
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.inputBorder)),
        boxShadow: [BoxShadow(color: Color(0x145E2EAA), blurRadius: 24, offset: Offset(0, -8))],
      ),
      child: Row(
        children: items.map((item) => _NavItem(item: item, active: current == item.route)).toList(),
      ),
    );
  }

  static final _homeItems = [
    _NavItemData('Home', AppRoutes.home, (c) => AppIcons.home(color: c)),
    _NavItemData('Challenges', AppRoutes.challenges, (c) => AppIcons.trophy(color: c)),
    _NavItemData('Upload', AppRoutes.submitEntry, (_) => AppIcons.plus(), upload: true),
    _NavItemData('Activity', AppRoutes.activityCenter, (c) => AppIcons.activity(color: c)),
    _NavItemData('Profile', AppRoutes.myProfile, (c) => AppIcons.profile(color: c)),
  ];

  static final _categoriesItems = [
    _NavItemData('Home', AppRoutes.home, (c) => AppIcons.home(color: c)),
    _NavItemData('Categories', AppRoutes.categories, (c) => AppIcons.grid(color: c)),
    _NavItemData('Upload', AppRoutes.submitEntry, (_) => AppIcons.plus(), upload: true),
    _NavItemData('Challenges', AppRoutes.challenges, (c) => AppIcons.trophy(color: c)),
    _NavItemData('Profile', AppRoutes.myProfile, (c) => AppIcons.profile(color: c)),
  ];
}

class _NavItemData {
  _NavItemData(this.label, this.route, this.icon, {this.upload = false});
  final String label;
  final String route;
  final Widget Function(Color?) icon;
  final bool upload;
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.item, required this.active});

  final _NavItemData item;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.purple : AppColors.textFaint;
    if (item.upload) {
      return Expanded(
        child: GestureDetector(
          onTap: () => context.go(item.route),
          child: Column(
            children: [
              Transform.translate(
                offset: const Offset(0, -22),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppGradients.button,
                    boxShadow: const [
                      BoxShadow(color: Color(0x73FF3D77), blurRadius: 26, offset: Offset(0, 12)),
                    ],
                    border: Border.all(color: Colors.white, width: 5),
                  ),
                  child: item.icon(Colors.white),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -14),
                child: const Text(
                  'Upload',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.purple),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Expanded(
      child: GestureDetector(
        onTap: () => context.go(item.route),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            item.icon(color),
            const SizedBox(height: 4),
            Text(item.label, style: TextStyle(fontSize: 10.5, color: color)),
          ],
        ),
      ),
    );
  }
}

class StudioHeader extends StatelessWidget {
  const StudioHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
      decoration: const BoxDecoration(gradient: AppGradients.studioHeader),
      child: Row(
        children: [
          AppIcons.menu(),
          const SizedBox(width: 11),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              gradient: AppGradients.button,
              boxShadow: const [BoxShadow(color: Color(0x66FF3D77), blurRadius: 14, offset: Offset(0, 6))],
            ),
            child: Center(child: SvgPicture.asset('assets/logo.svg', width: 21, height: 21)),
          ),
          const SizedBox(width: 9),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: AppTextStyles.display(size: 15).copyWith(color: Colors.white, letterSpacing: 0.1),
                  children: const [
                    TextSpan(text: 'ARTABLE '),
                    TextSpan(text: 'STUDIO', style: TextStyle(color: Color(0xFFFFC24D))),
                  ],
                ),
              ),
              Text(
                'By Artable Studio Pvt. Ltd.',
                style: AppTextStyles.bodyStyle(size: 9, color: const Color(0x99FFFFFF)),
              ),
            ],
          ),
          const Spacer(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              AppIcons.bell(),
              Positioned(
                top: -5,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  decoration: BoxDecoration(
                    gradient: AppGradients.button,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF170A30), width: 1.5),
                  ),
                  child: const Center(
                    child: Text('3', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0x47FFFFFF), width: 2),
                    gradient: AppGradients.button,
                  ),
                  child: const Center(
                    child: Text('RW', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    'Ritesh Walia',
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyStyle(size: 12.5, color: Colors.white, weight: FontWeight.w700),
                  ),
                ),
                AppIcons.chevronDown(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
