import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';
import 'package:artable_app/app/routes/app_routes.dart';
import 'package:artable_app/core/utils/reel_helpers.dart';
import 'package:artable_app/core/widgets/app_screen_header.dart';
import 'package:artable_app/features/studio/presentation/bloc/studio_cubit.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:artable_app/features/home/presentation/bloc/home_cubit.dart';
import 'package:artable_app/features/trending/presentation/bloc/trending_videos_cubit.dart';
import 'package:artable_app/features/trending/data/repositories/videos_repository.dart';

class StudioUploadScreen extends StatefulWidget {
  const StudioUploadScreen({super.key, this.challengeId});

  final String? challengeId;

  @override
  State<StudioUploadScreen> createState() => _StudioUploadScreenState();
}

class _StudioUploadScreenState extends State<StudioUploadScreen> {
  static const _steps = [
    'Compressing video',
    'Generating thumbnail',
    'Checking content',
    'Submitting entry',
  ];

  int _percent = 0;
  int _stepIndex = 0;
  Timer? _timer;
  bool _apiCalled = false;

  void _triggerCreateVideoApi() {
    if (_apiCalled) return;
    _apiCalled = true;

    final studioCubit = context.read<StudioCubit>();
    final authCubit = context.read<AuthCubit>();
    final videosRepo = VideosRepository();

    final videoPath = studioCubit.recordedVideoPath ??
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4';
    final manualThumbnail = studioCubit.selectedThumbnailPath;

    final title =
        (studioCubit.videoTitle != null && studioCubit.videoTitle!.trim().isNotEmpty)
            ? studioCubit.videoTitle!.trim()
            : 'Talent Performance Entry';
    final description = studioCubit.videoDescription;
    final categoryId = studioCubit.videoCategoryId;
    final hashtags =
        (studioCubit.videoHashtags != null && studioCubit.videoHashtags!.trim().isNotEmpty)
            ? studioCubit.videoHashtags!
            : '#dance #talent #artable';
    final challengeId = studioCubit.videoChallengeId ?? widget.challengeId ?? 'c1';

    videosRepo
        .createVideo(
      title: title,
      videoPathOrUrl: videoPath,
      manualSelectedThumbnailPath: manualThumbnail,
      description: description,
      categoryId: categoryId,
      hashtags: hashtags,
      challengeId: challengeId,
      sessionToken: authCubit.sessionToken,
      refreshToken: authCubit.refreshToken,
    )
        .then((res) {
      debugPrint('Create Video API success: $res');
      if (mounted) {
        try {
          context.read<HomeCubit>().loadHomeDashboard(forceRefresh: true);
        } catch (_) {}
        try {
          context.read<TrendingVideosCubit>().loadTrendingVideos(forceRefresh: true);
        } catch (_) {}
      }
    }).catchError((err) {
      debugPrint('Create Video API error: $err');
    });
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 160), (_) {
      if (_percent >= 100) return;
      setState(() {
        _percent = (_percent + 4).clamp(0, 100);
        _stepIndex = ((_percent / 100) * _steps.length).floor().clamp(0, _steps.length - 1);
      });
      if (_stepIndex == 1) {
        _triggerCreateVideoApi();
      }
      if (_percent >= 100) {
        _timer?.cancel();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            context.go('${AppRoutes.studioSuccess}?id=${widget.challengeId ?? 'c1'}');
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ReelHelpers.challengeById(widget.challengeId ?? 'c1');

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            const AppScreenHeader(title: 'Submitting Entry', showBack: false),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.inputBorder),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5E2EAA).withValues(alpha: 0.12),
                            blurRadius: 28,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: _percent / 100,
                              minHeight: 10,
                              backgroundColor: const Color(0xFFF0ECFA),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF3D77)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '$_percent%',
                            style: AppTextStyles.displayBold21.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(height: 26),
                          ...List.generate(_steps.length, (i) {
                            final state = i < _stepIndex
                                ? _StepState.done
                                : i == _stepIndex
                                    ? _StepState.active
                                    : _StepState.pending;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _UploadStep(label: _steps[i], state: state),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.info_outline, size: 14, color: AppColors.purple),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            'Please keep the app open while we submit your entry.',
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
          ],
        ),
      ),
    );
  }
}

enum _StepState { pending, active, done }

class _UploadStep extends StatelessWidget {
  const _UploadStep({required this.label, required this.state});

  final String label;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (state) {
      _StepState.done => (const Color(0x2421B573), const Color(0xFF21B573)),
      _StepState.active => (AppColors.purple.withValues(alpha: 0.14), AppColors.purple),
      _StepState.pending => (const Color(0xFFF0ECFA), AppColors.textFaint),
    };

    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(
            state == _StepState.done ? Icons.check_circle : Icons.access_time,
            size: 14,
            color: fg,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: state == _StepState.pending ? AppColors.textFaint : AppColors.text,
            ),
          ),
        ),
      ],
    );
  }
}
