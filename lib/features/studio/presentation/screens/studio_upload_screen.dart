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
    'Preparing video',
    'Getting upload URL',
    'Uploading video to storage',
    'Submitting entry',
  ];

  int _percent = 0;
  int _stepIndex = 0;
  bool _isUploading = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startUploadPipeline();
    });
  }

  Future<void> _startUploadPipeline() async {
    if (_isUploading) return;
    setState(() {
      _isUploading = true;
      _hasError = false;
      _errorMessage = '';
      _percent = 5;
      _stepIndex = 0;
    });

    final studioCubit = context.read<StudioCubit>();
    final authCubit = context.read<AuthCubit>();
    final videosRepo = VideosRepository();

    try {
      // Step 0: Preparing Video
      final videoPath = studioCubit.recordedVideoPath;
      if (videoPath == null || videoPath.trim().isEmpty) {
        throw Exception('No recorded video path found. Please re-record video.');
      }

      setState(() {
        _percent = 20;
        _stepIndex = 0;
      });
      await Future.delayed(const Duration(milliseconds: 200));

      // Step 1 & 2: Get Presigned URL & Upload to Storage
      setState(() {
        _percent = 40;
        _stepIndex = 1;
      });

      final manualThumbnail = studioCubit.selectedThumbnailPath;
      final title = (studioCubit.videoTitle != null && studioCubit.videoTitle!.trim().isNotEmpty)
          ? studioCubit.videoTitle!.trim()
          : 'Talent Performance Entry';
      final description = studioCubit.videoDescription;
      final categoryId = studioCubit.videoCategoryId;
      final hashtags = (studioCubit.videoHashtags != null && studioCubit.videoHashtags!.trim().isNotEmpty)
          ? studioCubit.videoHashtags!
          : '#dance #talent #artable';
      final challengeId = studioCubit.videoChallengeId ?? widget.challengeId ?? 'c1';

      setState(() {
        _percent = 60;
        _stepIndex = 2;
      });

      // Call Repository createVideo (which executes Presigned URL + Storage PUT upload + Create Video API)
      final res = await videosRepo.createVideo(
        title: title,
        videoPathOrUrl: videoPath,
        manualSelectedThumbnailPath: manualThumbnail,
        description: description,
        categoryId: categoryId,
        hashtags: hashtags,
        challengeId: challengeId,
        sessionToken: authCubit.sessionToken,
        refreshToken: authCubit.refreshToken,
      );

      // Step 3: Submitting Entry & Feed Refresh
      setState(() {
        _percent = 85;
        _stepIndex = 3;
      });

      debugPrint('Create Video API success: $res');

      if (mounted) {
        final homeCubit = context.read<HomeCubit>();
        final trendingCubit = context.read<TrendingVideosCubit>();
        try {
          await homeCubit.loadHomeDashboard(forceRefresh: true);
        } catch (_) {}
        try {
          await trendingCubit.loadTrendingVideos(forceRefresh: true);
        } catch (_) {}
      }

      setState(() {
        _percent = 100;
        _stepIndex = 3;
      });

      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        context.go('${AppRoutes.studioSuccess}?id=${widget.challengeId ?? 'c1'}');
      }
    } catch (e) {
      debugPrint('StudioUploadScreen error during upload pipeline: $e');
      if (mounted) {
        setState(() {
          _isUploading = false;
          _hasError = true;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
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
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _hasError ? Colors.red : const Color(0xFFFF3D77),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '$_percent%',
                            style: AppTextStyles.displayBold21.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                              color: _hasError ? Colors.red : AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 26),
                          if (_hasError) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _errorMessage.isNotEmpty
                                          ? _errorMessage
                                          : 'Upload failed. Please check your internet connection and try again.',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _startUploadPipeline,
                              icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                              label: const Text(
                                'Retry Upload',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.purple,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                            ),
                          ] else ...[
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
