import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/routes/app_routes.dart';
import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';
import 'package:artable_app/core/widgets/app_back_header.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';
import 'package:artable_app/core/widgets/filter_pills.dart';

class MusicPreviewScreen extends StatelessWidget {
  const MusicPreviewScreen({super.key, this.trackId});

  final String? trackId;

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppBackHeader(title: 'Music Preview'),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const EmptyNote(
                      message:
                          'Music preview from the library will be available soon. You can still add music inside Studio.',
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.push(AppRoutes.studioMusic),
                      child: Text(
                        'Open Studio Music',
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
