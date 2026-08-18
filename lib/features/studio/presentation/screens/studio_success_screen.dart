import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';
import 'package:artable_app/app/routes/app_routes.dart';
import 'package:artable_app/core/utils/reel_helpers.dart';
import 'package:artable_app/core/widgets/gradient_button.dart';
import 'package:artable_app/core/widgets/secondary_outline_button.dart';
import 'package:artable_app/features/studio/presentation/widgets/studio_shared_widgets.dart';

class StudioSuccessScreen extends StatelessWidget {
  const StudioSuccessScreen({super.key, this.challengeId});

  final String? challengeId;

  @override
  Widget build(BuildContext context) {
    final challenge = ReelHelpers.challengeById(challengeId ?? 'c1')!;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 40, 22, 24),
          child: Column(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.button,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF3D77).withValues(alpha: 0.32),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: const Icon(Icons.check, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 18),
              Text(
                'Entry Submitted!',
                style: AppTextStyles.displayBold21.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your video has been submitted for review.',
                style: AppTextStyles.bodyRegular14.copyWith(fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              ChallengeSummaryCard(challenge: challenge),
              const SizedBox(height: 20),
              GradientButton(
                label: 'View Entry',
                onPressed: () => context.push(
                  '${AppRoutes.challengeDetail}?id=${challenge['id']}',
                ),
              ),
              const SizedBox(height: 12),
              SecondaryOutlineButton(
                label: 'Join More Challenges',
                height: 50,
                onPressed: () => context.push(AppRoutes.categories),
              ),
              const SizedBox(height: 12),
              SecondaryOutlineButton(
                label: 'Back to Home',
                height: 50,
                onPressed: () => context.push(AppRoutes.home),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 14, color: AppColors.purple),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      'Your entry will be reviewed before it goes live.',
                      style: AppTextStyles.hint12.copyWith(fontSize: 11.5),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
