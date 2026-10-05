import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';
import 'package:artable_app/features/studio/presentation/bloc/studio_cubit.dart';
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
  List<VideoPlayerController> _clipControllers = [];
  bool _isVideoInitialized = false;
  bool _videoError = false;
  bool _playing = false;
  List<String> _mergedClipPaths = [];
  int _currentClipIndex = 0;
  bool _isSwitchingClip = false;

  @override
  void initState() {
    super.initState();
    final studio = context.read<StudioCubit>();
    final draft = _draft;

    if (draft != null) {
      if (draft['mergedClipPaths'] is List && (draft['mergedClipPaths'] as List).isNotEmpty) {
        _mergedClipPaths = List<String>.from(draft['mergedClipPaths'] as List);
      } else {
        _mergedClipPaths = [];
      }
    } else {
      if (studio.state.mergedClipPaths != null && studio.state.mergedClipPaths!.isNotEmpty) {
        _mergedClipPaths = List<String>.from(studio.state.mergedClipPaths!);
      } else {
        _mergedClipPaths = [];
      }
    }

    if (draft != null) {
      String durStr = (draft['duration'] as String?) ?? '';
      if (durStr.isEmpty && draft['durationSeconds'] != null) {
        final sec = (draft['durationSeconds'] as num).toInt();
        durStr = '${sec ~/ 60}:${(sec % 60).toString().padLeft(2, '0')}';
      }
      if (durStr.isNotEmpty) {
        studio.setRecordedDuration(durStr);
      }

      double? trimEnd = (draft['videoTrimEndSeconds'] as num?)?.toDouble();
      if (trimEnd == null || trimEnd <= 0) {
        final parts = durStr.split(':');
        if (parts.length == 2) {
          final m = int.tryParse(parts[0]) ?? 0;
          final s = int.tryParse(parts[1]) ?? 0;
          final totalS = m * 60 + s;
          if (totalS > 0) trimEnd = totalS.toDouble();
        }
      }

      studio.restoreRecordingEffects(
        filterId: draft['filterId'] as String?,
        beautyOn: draft['beautyOn'] as bool?,
        beautyIntensity: (draft['beautyIntensity'] as num?)?.toDouble(),
        cropAspectRatio: draft['videoCropAspectRatio'] as String?,
        trimStart: (draft['videoTrimStartSeconds'] as num?)?.toDouble() ?? 0.0,
        trimEnd: trimEnd,
      );
      final path = (draft['videoPath'] as String?) ?? (draft['videoUrl'] as String?);
      if (path != null && path.isNotEmpty) {
        studio.setRecordedVideoPath(
          path,
          mergedClipPaths: _mergedClipPaths.isNotEmpty ? _mergedClipPaths : null,
          clearMergedClips: _mergedClipPaths.isEmpty,
        );
      }
    }
    _initVideoPlayer();
  }

  Future<void> _initVideoPlayer() async {
    final studio = context.read<StudioCubit>();
    await StudioMusicPlaybackService.preloadForStudio(studio);
    if (!mounted) return;

    for (final c in _clipControllers) {
      try {
        c.removeListener(_onVideoControllerUpdate);
        await c.pause();
        await c.dispose();
      } catch (_) {}
    }
    _clipControllers.clear();

    if (_videoController != null) {
      try {
        _videoController!.removeListener(_onVideoControllerUpdate);
        await _videoController!.pause();
        await _videoController!.dispose();
      } catch (_) {}
      _videoController = null;
    }

    setState(() {
      _isVideoInitialized = false;
      _videoError = false;
      _playing = false;
    });

    if (!mounted) return;

    String? path = studio.recordedVideoPath ??
        widget.videoPath ??
        _draft?['videoPath']?.toString() ??
        _draft?['videoUrl']?.toString();

    debugPrint('StudioPreviewScreen loading recorded video path: $path');

    bool hasSingleMergedFile = false;
    if (path != null && path.isNotEmpty) {
      final clean = path.replaceFirst('file://', '').trim();
      if (clean.startsWith('http') || File(clean).existsSync()) {
        hasSingleMergedFile = true;
      }
    }

    if (hasSingleMergedFile && path != null) {
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

      if (controller != null && controller.value.isInitialized) {
        final validController = controller;
        validController.setVolume(studio.isMuted ? 0.0 : 1.0);
        try {
          await validController.setPlaybackSpeed(studio.speedMultiplier);
        } catch (_) {}
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
        debugPrint('VideoPlayer successfully initialized merged file at $path');
        return;
      }
    }

    if (_mergedClipPaths.length > 1) {
      debugPrint('StudioPreviewScreen loading multi-clip playlist: ${_mergedClipPaths.length} clips');
      List<VideoPlayerController> loaded = [];
      for (final p in _mergedClipPaths) {
        final c = await StudioVideoPlayerUtils.initializeClipController(
          p,
          autoPlay: false,
          loop: false,
        );
        if (c != null) loaded.add(c);
      }

      if (!mounted) {
        for (final c in loaded) {
          await c.dispose();
        }
        return;
      }

      if (loaded.isNotEmpty) {
        _clipControllers = loaded;
        for (final c in _clipControllers) {
          c.setVolume(studio.isMuted ? 0.0 : 1.0);
          try {
            c.setPlaybackSpeed(studio.speedMultiplier);
          } catch (_) {}
        }
        _currentClipIndex = 0;
        _videoController = _clipControllers[0];
        _videoController!.addListener(_onVideoControllerUpdate);
        await _videoController!.play();
        setState(() {
          _isVideoInitialized = true;
          _videoError = false;
          _playing = true;
        });
        return;
      }
    }

    if (mounted) {
      setState(() {
        _isVideoInitialized = false;
        _videoError = true;
      });
    }
  }

  void _onVideoControllerUpdate() {
    final controller = _videoController;
    if (controller == null || !mounted || _isSwitchingClip) return;

    final isPlaying = controller.value.isPlaying;
    if (isPlaying != _playing) {
      setState(() => _playing = isPlaying);
    }

    if (_clipControllers.isNotEmpty) {
      final posMs = controller.value.position.inMilliseconds;
      final durMs = controller.value.duration.inMilliseconds;
      if (durMs > 0 && posMs >= durMs - 250) {
        _advanceToNextMergedClip();
        return;
      }
    } else {
      final studio = context.read<StudioCubit>();
      final trimStart = studio.state.videoTrimStartSeconds;
      final trimEnd = studio.state.videoTrimEndSeconds;

      if (trimEnd != null && trimEnd > trimStart) {
        final startMs = (trimStart * 1000).round();
        final endMs = (trimEnd * 1000).round();
        final posMs = controller.value.position.inMilliseconds;

        if (posMs >= endMs - 150 || posMs < startMs) {
          controller.seekTo(Duration(milliseconds: startMs));
          controller.play();
          if (mounted) setState(() => _playing = true);
        }
      }
    }
  }

  Future<void> _advanceToNextMergedClip() async {
    if (_isSwitchingClip || _clipControllers.isEmpty) return;
    _isSwitchingClip = true;

    try {
      final oldController = _videoController;
      oldController?.removeListener(_onVideoControllerUpdate);
      await oldController?.pause();

      _currentClipIndex = (_currentClipIndex + 1) % _clipControllers.length;
      final nextController = _clipControllers[_currentClipIndex];

      await nextController.seekTo(Duration.zero);
      nextController.addListener(_onVideoControllerUpdate);
      await nextController.play();

      if (mounted) {
        setState(() {
          _videoController = nextController;
          _isVideoInitialized = true;
          _playing = true;
        });
      }
    } catch (e) {
      debugPrint('Error advancing merged clip: $e');
    } finally {
      _isSwitchingClip = false;
    }
  }

  @override
  void dispose() {
    for (final c in _clipControllers) {
      try {
        c.removeListener(_onVideoControllerUpdate);
        c.pause();
        c.dispose();
      } catch (_) {}
    }
    _clipControllers.clear();

    try {
      _videoController?.removeListener(_onVideoControllerUpdate);
      _videoController?.pause();
      _videoController?.dispose();
    } catch (_) {}
    _videoController = null;

    unawaited(StudioMusicPlaybackService.stop());
    super.dispose();
  }

  void _togglePlayPause() {
    final controller = _videoController;
    if (controller != null && _isVideoInitialized) {
      final studio = context.read<StudioCubit>();
      if (controller.value.isPlaying) {
        controller.pause();
        StudioMusicPlaybackService.pause();
        setState(() => _playing = false);
      } else {
        if (_clipControllers.isNotEmpty &&
            controller.value.position.inMilliseconds >= controller.value.duration.inMilliseconds - 250) {
          _advanceToNextMergedClip();
        } else {
          controller.play();
          if (studio.selectedMusic != null || studio.selectedTrack != null) {
            final posMs = controller.value.position.inMilliseconds;
            StudioMusicPlaybackService.playForEditor(studio, posMs);
          }
          setState(() => _playing = true);
        }
      }
    }
  }

  Map<String, dynamic>? get _draft {
    if (widget.draftId == null) return null;
    final studioDrafts = context.read<StudioCubit>().state.drafts;
    for (final d in studioDrafts) {
      if (d['id'] == widget.draftId) return d;
    }
    return null;
  }

  Map<String, dynamic> get _challenge {
    final draft = _draft;
    if (draft != null && draft['challengeId'] != null) {
      return ReelHelpers.challengeById(draft['challengeId'] as String) ??
          ReelHelpers.challengeById(widget.challengeId ?? 'c1')!;
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
                      isMuted: studio.isMuted,
                    ),
                    const SizedBox(height: 12),
                    // Video Editing Options: Crop, Trim & Mute
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE5DDF5)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.purple.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.crop, size: 14, color: AppColors.purple),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            'Crop',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF231A38),
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            studio.videoCropAspectRatio,
                                            style: const TextStyle(
                                              fontSize: 10,
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
                          const SizedBox(width: 6),
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
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE5DDF5)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.purple.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.content_cut_rounded, size: 14, color: AppColors.purple),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            'Trim',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF231A38),
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            duration,
                                            style: const TextStyle(
                                              fontSize: 10,
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
                          const SizedBox(width: 6),
                          // Mute Option Tile
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                final studioCubit = context.read<StudioCubit>();
                                studioCubit.toggleMute();
                                final newMuted = studioCubit.isMuted;
                                _videoController?.setVolume(newMuted ? 0.0 : 1.0);
                                for (final c in _clipControllers) {
                                  c.setVolume(newMuted ? 0.0 : 1.0);
                                }
                                setState(() {});
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                                decoration: BoxDecoration(
                                  color: studio.isMuted
                                      ? AppColors.purple.withValues(alpha: 0.1)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: studio.isMuted
                                        ? AppColors.purple
                                        : const Color(0xFFE5DDF5),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: studio.isMuted
                                            ? AppColors.purple
                                            : AppColors.purple.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        studio.isMuted ? Icons.volume_off : Icons.volume_up,
                                        size: 14,
                                        color: studio.isMuted ? Colors.white : AppColors.purple,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            studio.isMuted ? 'Muted' : 'Audio',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              color: studio.isMuted
                                                  ? AppColors.purple
                                                  : const Color(0xFF231A38),
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            studio.isMuted ? 'Muted' : 'Sound On',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: studio.isMuted
                                                  ? AppColors.purple
                                                  : Colors.black54,
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

                    const SizedBox(height: 14),
                    SecondaryOutlineButton(
                      label: 'Edit Video',
                      icon: const Icon(Icons.edit_outlined, size: 17),
                      onPressed: () {
                        _videoController?.pause();
                        context.push(
                          '${AppRoutes.studioEditVideo}?id=${challenge['id']}$draftParam',
                        );
                      },
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
