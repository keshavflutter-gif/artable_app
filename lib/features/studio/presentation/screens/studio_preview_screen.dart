import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';
import 'package:artable_app/features/studio/presentation/bloc/studio_cubit.dart';
import 'package:artable_app/data/datasources/mock_data.dart';
import 'package:artable_app/app/routes/app_routes.dart';
import 'package:artable_app/features/studio/data/services/studio_music_playback_service.dart';
import 'package:artable_app/core/utils/reel_helpers.dart';
import 'package:artable_app/core/utils/studio_video_player_utils.dart';
import 'package:artable_app/core/widgets/app_screen_header.dart';
import 'package:artable_app/core/widgets/gradient_button.dart';
import 'package:artable_app/core/widgets/secondary_outline_button.dart';
import 'package:artable_app/features/studio/presentation/widgets/recorded_video_preview.dart';
import 'package:artable_app/features/studio/presentation/widgets/song_trimmer_sheet.dart';
import 'package:artable_app/features/studio/presentation/widgets/video_crop_sheet.dart';
import 'package:artable_app/features/studio/presentation/widgets/video_trimmer_sheet.dart';

class StudioPreviewScreen extends StatefulWidget {
  const StudioPreviewScreen({
    super.key,
    this.challengeId,
    this.draftId,
    this.videoPath,
  });

  final String? challengeId;
  final String? draftId;
  final String? videoPath;

  @override
  State<StudioPreviewScreen> createState() => _StudioPreviewScreenState();
}

class _StudioPreviewScreenState extends State<StudioPreviewScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _videoError = false;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    final draft = _draft;
    if (draft != null) {
      final studio = context.read<StudioCubit>();
      studio.restoreRecordingEffects(
        filterId: draft['filterId'] as String?,
        beautyOn: draft['beautyOn'] as bool?,
        beautyIntensity: (draft['beautyIntensity'] as num?)?.toDouble(),
        cropAspectRatio: draft['videoCropAspectRatio'] as String?,
        trimStart: (draft['videoTrimStartSeconds'] as num?)?.toDouble(),
        trimEnd: (draft['videoTrimEndSeconds'] as num?)?.toDouble(),
      );
      final path = draft['videoPath']?.toString();
      if (path != null && path.isNotEmpty) {
        studio.setRecordedVideoPath(path);
      }
    }
    _initVideoPlayer();
  }

  Future<void> _initVideoPlayer() async {
    await StudioMusicPlaybackService.releaseForVideoPlayback();
    if (!mounted) return;

    setState(() {
      _isVideoInitialized = false;
      _videoError = false;
      _playing = false;
    });

    final studio = context.read<StudioCubit>();
    String? path = studio.recordedVideoPath ??
        widget.videoPath ??
        _draft?['videoPath']?.toString();

    debugPrint('StudioPreviewScreen loading recorded video path: $path');

    if (path == null || path.isEmpty) {
      debugPrint('No recorded video path provided for preview.');
      if (mounted) setState(() => _videoError = true);
      return;
    }

    if (_videoController != null) {
      try {
        await _videoController!.dispose();
      } catch (_) {}
      _videoController = null;
    }

    VideoPlayerController? controller;
    try {
      controller = await StudioVideoPlayerUtils.initializeRecordedVideo(path);
    } catch (e) {
      debugPrint('StudioPreviewScreen video init error: $e');
      controller = null;
    }

    if (!mounted) {
      await controller?.dispose();
      return;
    }

    if (controller != null) {
      final validController = controller;
      validController.addListener(_onVideoControllerUpdate);
      final trimStart = studio.state.videoTrimStartSeconds;
      if (trimStart > 0) {
        validController.seekTo(Duration(milliseconds: (trimStart * 1000).round()));
      }
      setState(() {
        _videoController = validController;
        _isVideoInitialized = true;
        _videoError = false;
        _playing = validController.value.isPlaying;
      });
      debugPrint('VideoPlayer successfully initialized at $path');
    } else {
      setState(() {
        _isVideoInitialized = false;
        _videoError = true;
      });
      debugPrint('StudioPreviewScreen failed to initialize video at $path');
    }
  }

  void _onVideoControllerUpdate() {
    final controller = _videoController;
    if (controller == null || !mounted) return;

    final studio = context.read<StudioCubit>();
    final trimStart = studio.state.videoTrimStartSeconds;
    final trimEnd = studio.state.videoTrimEndSeconds;

    if (trimEnd != null && trimEnd > trimStart) {
      final startMs = (trimStart * 1000).round();
      final endMs = (trimEnd * 1000).round();
      final posMs = controller.value.position.inMilliseconds;

      if (posMs >= endMs || posMs < startMs) {
        controller.seekTo(Duration(milliseconds: startMs));
        if (controller.value.isPlaying) {
          controller.play();
        }
      }
    }

    final isPlaying = controller.value.isPlaying;
    if (isPlaying != _playing) {
      setState(() => _playing = isPlaying);
    }
  }

  @override
  void dispose() {
    _videoController?.removeListener(_onVideoControllerUpdate);
    _videoController?.pause();
    _videoController?.dispose();
    unawaited(StudioMusicPlaybackService.stop());
    super.dispose();
  }

  void _togglePlayPause() {
    final controller = _videoController;
    if (controller != null && _isVideoInitialized) {
      final studio = context.read<StudioCubit>();
      final trimStart = studio.state.videoTrimStartSeconds;
      final trimEnd = studio.state.videoTrimEndSeconds;

      if (controller.value.isPlaying) {
        controller.pause();
        setState(() => _playing = false);
      } else {
        if (trimEnd != null && trimEnd > trimStart) {
          final startMs = (trimStart * 1000).round();
          final endMs = (trimEnd * 1000).round();
          final posMs = controller.value.position.inMilliseconds;

          if (posMs >= endMs || posMs < startMs) {
            controller.seekTo(Duration(milliseconds: startMs));
          }
        }
        controller.play();
        setState(() => _playing = true);
      }
    }
  }

  Map<String, dynamic>? get _draft {
    if (widget.draftId == null) return null;
    for (final d in MockData.DRAFTS) {
      if (d['id'] == widget.draftId) return d;
    }
    return null;
  }

  Map<String, dynamic> get _challenge {
    final draft = _draft;
    if (draft != null) {
      return ReelHelpers.challengeById(draft['challengeId'] as String)!;
    }
    return ReelHelpers.challengeById(widget.challengeId ?? 'c1')!;
  }

  String _getDuration(StudioCubit studio) {
    if (studio.recordedDuration.isNotEmpty && studio.recordedDuration != '0:00') {
      return studio.recordedDuration;
    }
    final draft = _draft;
    if (draft != null) return draft['duration'] as String? ?? '0:00';
    return studio.recordedDuration;
  }

  Future<void> _saveDraft(StudioCubit studio) async {
    final challenge = _challenge;
    final existingDraftId = widget.draftId ?? _draft?['id'] as String?;

    final res = (existingDraftId != null && existingDraftId.isNotEmpty)
        ? await studio.updateDraftDetails(
            videoId: existingDraftId,
            challenge: challenge,
          )
        : await studio.saveDraftFromPreview(
            challenge: challenge,
          );

    if (!mounted) return;

    if (res != null) {
      _videoController?.pause();
      await StudioMusicPlaybackService.stop();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Draft saved successfully'),
          backgroundColor: AppColors.purple,
          duration: Duration(seconds: 2),
        ),
      );
      context.push('${AppRoutes.studioDrafts}?id=${challenge['id']}');
    } else {
      final errorMsg = studio.state.saveDraftError ?? 'Failed to save draft';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final studio = context.watch<StudioCubit>();
    final challenge = _challenge;
    final duration = _getDuration(studio);
    final music = studio.selectedMusic;
    final selectedTrack = studio.selectedTrack;
    final isFrontCamera = studio.isFrontCamera;
    final draftParam = widget.draftId != null ? '&draft=${widget.draftId}' : '';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            const AppScreenHeader(title: 'Preview'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RecordedVideoPreview(
                      videoController: _videoController,
                      isVideoInitialized: _isVideoInitialized,
                      hasError: _videoError,
                      onRetry: _initVideoPlayer,
                      playing: _playing,
                      onTogglePlayPause: _togglePlayPause,
                      duration: duration,
                      isFrontCamera: isFrontCamera,
                      filterId: studio.recordingFilter,
                      beautyOn: studio.recordingBeautyOn,
                      beautyIntensity: studio.recordingBeautyIntensity,
                      cropAspectRatio: studio.videoCropAspectRatio,
                    ),
                    const SizedBox(height: 12),
                    // Video Editing Options: Crop & Trim
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F3FC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFECE6F8)),
                      ),
                      child: Row(
                        children: [
                          // Crop Option Tile
                          Expanded(
                            child: InkWell(
                              onTap: () => VideoCropSheet.show(context),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE5DDF5)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: AppColors.purple.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.crop, size: 15, color: AppColors.purple),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            'Crop Video',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF231A38),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Ratio: ${studio.videoCropAspectRatio}',
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.purple,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Trim Option Tile
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final studioCubit = context.read<StudioCubit>();
                                await VideoTrimmerSheet.show(
                                  context,
                                  videoController: _videoController,
                                );
                                if (mounted && _videoController != null) {
                                  final trimStart = studioCubit.state.videoTrimStartSeconds;
                                  await _videoController!.seekTo(
                                    Duration(milliseconds: (trimStart * 1000).round()),
                                  );
                                  _videoController!.play();
                                  setState(() => _playing = true);
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE5DDF5)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: AppColors.purple.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.content_cut_rounded, size: 15, color: AppColors.purple),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            'Trim Video',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF231A38),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            duration,
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.purple,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (music != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F2FC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE9E4F7)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: AppColors.purple,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.music_note, size: 16, color: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    music,
                                    style: AppTextStyles.bodySemiBold13.copyWith(fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Cropped clip duration: ${studio.musicCropDuration.toInt()}s',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: AppColors.purple,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (selectedTrack != null)
                              TextButton(
                                onPressed: () {
                                  SongTrimmerSheet.show(context, track: selectedTrack);
                                },
                                child: const Text(
                                  'Edit Crop',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.purple,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: SecondaryOutlineButton(
                            label: 'Retake',
                            icon: const Icon(Icons.refresh, size: 17),
                            onPressed: () {
                              _videoController?.pause();
                              context.push(
                                '${AppRoutes.studioCamera}?id=${challenge['id']}',
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GradientButton(
                            label: 'Next',
                            icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                            onPressed: () {
                              _videoController?.pause();
                              context.push(
                                '${AppRoutes.studioDetails}?id=${challenge['id']}$draftParam',
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SecondaryOutlineButton(
                      label: studio.state.isSavingDraft ? 'Saving Draft...' : 'Save Draft',
                      icon: studio.state.isSavingDraft
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.purple),
                            )
                          : const Icon(Icons.save_outlined, size: 17),
                      onPressed: studio.state.isSavingDraft ? null : () => _saveDraft(studio),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.info_outline, size: 14, color: AppColors.purple),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            'Review your entry before adding details.',
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
