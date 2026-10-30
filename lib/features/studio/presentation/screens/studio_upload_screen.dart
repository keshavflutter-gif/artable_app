import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';
import 'package:artable_app/app/routes/app_routes.dart';
import 'package:artable_app/core/widgets/app_screen_header.dart';
import 'package:artable_app/features/studio/presentation/bloc/studio_cubit.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:artable_app/features/home/presentation/bloc/home_cubit.dart';
import 'package:artable_app/features/trending/presentation/bloc/trending_videos_cubit.dart';
import 'package:artable_app/features/trending/data/repositories/videos_repository.dart';
import 'package:artable_app/core/utils/validators.dart';
import 'package:artable_app/data/datasources/music_api_service.dart';
import 'package:artable_app/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:artable_app/features/profile/presentation/bloc/my_videos_cubit.dart';

class StudioUploadScreen extends StatefulWidget {
  const StudioUploadScreen({super.key, this.challengeId, this.draftId});

  final String? challengeId;
  final String? draftId;

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
    final profileCubit = context.read<ProfileCubit>();
    final videosRepo = VideosRepository();

    try {
      // Step 0: Preparing Video
      // Collect all merged clips if multi-clip video
      List<String> mergedClips = [];
      if (studioCubit.state.mergedClipPaths != null && studioCubit.state.mergedClipPaths!.isNotEmpty) {
        mergedClips = List<String>.from(studioCubit.state.mergedClipPaths!);
      } else {
        final targetDraftId = widget.draftId ?? studioCubit.activeDraftId;
        if (targetDraftId != null && targetDraftId.isNotEmpty) {
          final draftMatch = studioCubit.drafts.where((d) => d['id'] == targetDraftId).firstOrNull;
          if (draftMatch != null && draftMatch['mergedClipPaths'] is List) {
            mergedClips = List<String>.from(draftMatch['mergedClipPaths'] as List);
          }
        }
      }

      String? videoPath = studioCubit.recordedVideoPath;

      // If we have multiple clips, use the first clip as the primary video and upload all clips in mergedClipPaths
      if (mergedClips.length > 1) {
        videoPath = mergedClips.first;
        studioCubit.setRecordedVideoPath(
          videoPath,
          mergedClipPaths: mergedClips,
          clearMergedClips: false,
        );
        debugPrint('StudioUploadScreen: Multi-clip upload prepared instantly: $videoPath (${mergedClips.length} clips)');
      }

      if (videoPath == null || videoPath.trim().isEmpty) {
        if (mergedClips.isNotEmpty) {
          videoPath = mergedClips.first;
        } else {
          throw Exception('No recorded video path found. Please re-record video.');
        }
      }

      setState(() {
        _percent = 15;
        _stepIndex = 0;
      });

      // Step 1 & 2: Get Presigned URL & Upload to Storage
      setState(() {
        _percent = 25;
        _stepIndex = 1;
      });

      String? manualThumbnail = studioCubit.selectedThumbnailPath;
      if (manualThumbnail != null &&
          (manualThumbnail.trim().isEmpty ||
              (!manualThumbnail.startsWith('http') && !File(manualThumbnail).existsSync()))) {
        manualThumbnail = null;
      }

      final title = (studioCubit.videoTitle != null && studioCubit.videoTitle!.trim().isNotEmpty)
          ? studioCubit.videoTitle!.trim()
          : 'Talent Performance Entry';
      final description = studioCubit.videoDescription;
      final categoryId = Validators.isRealDatabaseId(studioCubit.videoCategoryId)
          ? studioCubit.videoCategoryId
          : null;
      final hashtags = (studioCubit.videoHashtags != null && studioCubit.videoHashtags!.trim().isNotEmpty)
          ? studioCubit.videoHashtags!
          : '#dance #talent #artable';
      final rawChal = studioCubit.videoChallengeId ?? widget.challengeId;
      final challengeId = Validators.isRealDatabaseId(rawChal) ? rawChal : null;

      setState(() {
        _percent = 30;
        _stepIndex = 1;
      });

      // Call Repository createVideo (which executes Presigned URL + Storage PUT upload + Create Video API)
      final profileUser = profileCubit.state.data?.user;
      final realUsername = authCubit.username.isNotEmpty
          ? authCubit.username
          : (profileUser?.username ?? '');
      final realCreator = authCubit.fullName.isNotEmpty
          ? authCubit.fullName
          : (profileUser?.fullName ?? realUsername);
      final realAvatar = authCubit.avatarUrl.isNotEmpty
          ? authCubit.avatarUrl
          : (profileUser?.profilePhotoUrl ?? '');
      final realUserId = authCubit.userId ?? profileUser?.id;

      final selectedTrack = studioCubit.selectedTrack ??
          MusicApiService.resolveByName(studioCubit.selectedMusic);
      final resolvedMusicName = studioCubit.selectedMusic ??
          (selectedTrack != null ? '${selectedTrack.title} — ${selectedTrack.artist}' : null);
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
        videoTrimStartSeconds: studioCubit.state.videoTrimStartSeconds > 0
            ? studioCubit.state.videoTrimStartSeconds
            : null,
        videoTrimEndSeconds: studioCubit.state.videoTrimEndSeconds,
        mergedClipPaths: mergedClips.length > 1 ? mergedClips : null,
        onUploadProgress: (sent, total) {
          if (!mounted || total <= 0) return;
          final pct = 30 + ((sent / total) * 55).round();
          setState(() {
            if (pct > _percent) _percent = pct.clamp(30, 85);
            _stepIndex = 2;
          });
        },
        creator: realCreator,
        username: realUsername,
        handle: realUsername.isNotEmpty ? (realUsername.startsWith('@') ? realUsername : '@$realUsername') : null,
        avatarUrl: realAvatar,
        userId: realUserId,
        musicName: resolvedMusicName,
        musicUrl: selectedTrack?.audioUrl,
        musicStartSeconds: selectedTrack != null ? studioCubit.musicStartSeconds : null,
        musicCropDuration: selectedTrack != null ? studioCubit.musicCropDuration : null,
        filterId: studioCubit.recordingFilter,
        beautyOn: studioCubit.recordingBeautyOn,
        beautyIntensity: studioCubit.recordingBeautyIntensity,
      );

      // Step 3: Submitting Entry & Feed Refresh
      setState(() {
        _percent = 85;
        _stepIndex = 3;
      });

      debugPrint('Create Video API success: $res');

      final targetDraftId = widget.draftId ?? studioCubit.activeDraftId;
      if (targetDraftId != null && targetDraftId.trim().isNotEmpty) {
        debugPrint('Deleting uploaded draft $targetDraftId after successful upload...');
        try {
          await studioCubit.deleteDraft(targetDraftId);
          studioCubit.setActiveDraftId(null);
        } catch (e) {
          debugPrint('Error deleting uploaded draft $targetDraftId: $e');
        }
      }

      if (mounted) {
        final homeCubit = context.read<HomeCubit>();
        final trendingCubit = context.read<TrendingVideosCubit>();
        final profileCubit = context.read<ProfileCubit>();
        final myVideosCubit = context.read<MyVideosCubit>();
        Future<void>.delayed(const Duration(seconds: 6), () {
          unawaited(homeCubit.loadHomeDashboard(forceRefresh: true));
          unawaited(trendingCubit.loadTrendingVideos(forceRefresh: true));
        });
        try {
          profileCubit.loadProfile(forceRefresh: true);
        } catch (_) {}
        try {
          myVideosCubit.loadMyVideos(forceRefresh: true);
        } catch (_) {}
      }

      setState(() {
        _percent = 100;
        _stepIndex = 3;
      });

      if (mounted) {
        final successId = challengeId ??
            (Validators.isRealDatabaseId(studioCubit.videoChallengeId)
                ? studioCubit.videoChallengeId
                : null) ??
            studioCubit.state.studioSetup?.challenge.id;
        if (successId != null && successId.trim().isNotEmpty) {
          context.go('${AppRoutes.studioSuccess}?id=${successId.trim()}');
        } else {
          context.go(AppRoutes.studioSuccess);
        }
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
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final width = constraints.maxWidth *
                                  ((_percent.clamp(0, 100)) / 100);
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: SizedBox(
                                  height: 10,
                                  child: Stack(
                                    children: [
                                      const SizedBox.expand(
                                        child: ColoredBox(color: Color(0xFFF0ECFA)),
                                      ),
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 280),
                                        curve: Curves.easeOut,
                                        height: 10,
                                        width: width,
                                        color: _hasError
                                            ? Colors.red
                                            : const Color(0xFFFF3D77),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
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
