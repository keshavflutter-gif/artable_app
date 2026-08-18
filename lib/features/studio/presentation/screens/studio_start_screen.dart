import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/routes/app_routes.dart';
import 'package:artable_app/data/datasources/music_api_service.dart';
import 'package:artable_app/core/utils/reel_helpers.dart';
import 'package:artable_app/core/widgets/app_screen_header.dart';
import 'package:artable_app/core/widgets/gradient_button.dart';
import 'package:artable_app/core/widgets/secondary_outline_button.dart';
import 'package:artable_app/features/studio/presentation/widgets/studio_shared_widgets.dart';

class StudioStartScreen extends StatefulWidget {
  const StudioStartScreen({super.key, this.challengeId});

  final String? challengeId;

  @override
  State<StudioStartScreen> createState() => _StudioStartScreenState();
}

class _StudioStartScreenState extends State<StudioStartScreen> {
  Map<String, dynamic> get _challenge =>
      ReelHelpers.challengeById(widget.challengeId ?? 'c1')!;

  @override
  void initState() {
    super.initState();
    MusicApiService.prefetchTracks();
  }

  @override
  Widget build(BuildContext context) {
    final challenge = _challenge;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            const AppScreenHeader(title: 'Studio'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const StudioStepIndicator(activeIndex: 0),
                    StudioHeroCard(challenge: challenge),
                    const SizedBox(height: 16),
                    const _InfoNote(),
                    const SizedBox(height: 26),
                    const Text(
                      'Recording Tips',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _TipGrid(),
                    const SizedBox(height: 22),
                    GradientButton(
                      label: 'Start Recording',
                      icon: const Icon(Icons.videocam_outlined, color: Colors.white, size: 18),
                      onPressed: () => context.push(
                        '${AppRoutes.studioCamera}?id=${challenge['id']}',
                      ),
                    ),
                    const SizedBox(height: 10),
                    SecondaryOutlineButton(
                      label: 'View Drafts',
                      icon: const Icon(Icons.description_outlined, size: 17),
                      onPressed: () => context.push(
                        '${AppRoutes.studioDrafts}?id=${challenge['id']}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.purple.withValues(alpha: 0.08),
            const Color(0xFFFF8A3D).withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.16)),
      ),
      child: const Row(
        children: [
          _InfoIcon(),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Gallery upload is not allowed. Record your video using the in-app studio.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.text,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoIcon extends StatelessWidget {
  const _InfoIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(Icons.info_outline, size: 14, color: AppColors.purple),
    );
  }
}

class _TipGrid extends StatelessWidget {
  const _TipGrid();

  @override
  Widget build(BuildContext context) {
    const tips = [
      (Color(0x24FF8A3D), Color(0x0AFF8A3D), AppColors.orange, Icons.wb_sunny_outlined, 'Good lighting'),
      (Color(0x248B3DFF), Color(0x0A8B3DFF), AppColors.purple, Icons.mic_none, 'Clear sound'),
      (Color(0x24FF3D77), Color(0x0AFF3D77), AppColors.pink, Icons.gps_fixed, 'Keep talent centered'),
      (Color(0x2421B573), Color(0x0A21B573), AppColors.success, Icons.check, 'Follow challenge rules'),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.4,
      children: tips
          .map(
            (t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [t.$1, t.$2],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.purple.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(t.$4, size: 15, color: t.$3),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      t.$5,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
