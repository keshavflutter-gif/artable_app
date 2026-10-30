import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:artable_app/core/services/video_interstitial_ad.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';
import 'package:artable_app/app/routes/app_routes.dart';
import 'package:artable_app/core/utils/validators.dart';
import 'package:artable_app/core/widgets/secondary_outline_button.dart';
import 'package:artable_app/features/challenges/presentation/bloc/challenges_cubit.dart';
import 'package:artable_app/features/home/presentation/bloc/home_cubit.dart';
import 'package:artable_app/features/trending/presentation/bloc/trending_videos_cubit.dart';
import 'package:artable_app/features/studio/presentation/bloc/studio_cubit.dart';
import 'package:artable_app/features/studio/presentation/widgets/studio_shared_widgets.dart';

class StudioSuccessScreen extends StatefulWidget {
  const StudioSuccessScreen({super.key, this.challengeId});

  final String? challengeId;

  @override
  State<StudioSuccessScreen> createState() => _StudioSuccessScreenState();
}

class _StudioSuccessScreenState extends State<StudioSuccessScreen> {
  Map<String, dynamic> _challenge = const {};
  bool _loadingChallenge = true;

  String get _resolvedChallengeId {
    final studio = context.read<StudioCubit>();
    final candidates = <String?>[
      widget.challengeId,
      studio.videoChallengeId,
      studio.state.studioSetup?.challenge.id,
    ];
    for (final id in candidates) {
      if (Validators.isRealDatabaseId(id)) return id!.trim();
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadSubmittedChallenge();
      await VideoInterstitialAd.instance.load();
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      await VideoInterstitialAd.instance.show();
    });
  }

  Future<void> _loadSubmittedChallenge() async {
    final studio = context.read<StudioCubit>();
    final setupMap = studio.state.studioSetup?.challenge.toUiMap();
    if (setupMap != null && (setupMap['title'] as String? ?? '').isNotEmpty) {
      if (mounted) {
        setState(() {
          _challenge = setupMap;
          _loadingChallenge = false;
        });
      }
    }

    final id = _resolvedChallengeId;
    if (id.isEmpty) {
      if (mounted) setState(() => _loadingChallenge = false);
      return;
    }

    final cubit = context.read<ChallengesCubit>();
    var detail = cubit.getChallengeDetail(id);
    detail ??= await cubit.loadChallengeDetail(id);
    if (!mounted) return;
    if (detail != null) {
      final mapped = detail.toUiMap();
      setState(() {
        _challenge = mapped;
        _loadingChallenge = false;
      });
      return;
    }
    if (mounted) setState(() => _loadingChallenge = false);
  }

  @override
  Widget build(BuildContext context) {
    final hasCard = (_challenge['title'] as String? ?? '').trim().isNotEmpty;

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
              if (_loadingChallenge && !hasCard)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                )
              else if (hasCard)
                ChallengeSummaryCard(challenge: _challenge),
              const SizedBox(height: 20),
              SecondaryOutlineButton(
                label: 'Join More Challenges',
                height: 50,
                onPressed: () => context.push(AppRoutes.categories),
              ),
              const SizedBox(height: 12),
              SecondaryOutlineButton(
                label: 'Back to Home',
                height: 50,
                onPressed: () {
                  try {
                    context.read<HomeCubit>().loadHomeDashboard(forceRefresh: true);
                  } catch (_) {}
                  try {
                    context.read<TrendingVideosCubit>().loadTrendingVideos(forceRefresh: true);
                  } catch (_) {}
                  context.go(AppRoutes.home);
                },
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
