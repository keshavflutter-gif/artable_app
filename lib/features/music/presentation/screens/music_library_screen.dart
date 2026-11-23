import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/routes/app_routes.dart';
import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';
import 'package:artable_app/core/widgets/app_back_header.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';
import 'package:artable_app/core/widgets/filter_pills.dart';

class MusicLibraryScreen extends StatefulWidget {
  const MusicLibraryScreen({super.key});

  @override
  State<MusicLibraryScreen> createState() => _MusicLibraryScreenState();
}

class _MusicLibraryScreenState extends State<MusicLibraryScreen> {
  static const _tabs = ['All', 'Trending', 'Popular', 'New'];
  var _tab = 'All';

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      child: Column(
        children: [
          const AppBackHeader(title: 'Music Library'),
          FilterPills(
            items: _tabs,
            selected: _tab,
            onSelected: (t) => setState(() => _tab = t),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const EmptyNote(
                      message:
                          'Browse music from Studio when creating a video. Full library listing will be available soon.',
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.push(AppRoutes.studioStart),
                      child: Text(
                        'Open Studio',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.purple,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
