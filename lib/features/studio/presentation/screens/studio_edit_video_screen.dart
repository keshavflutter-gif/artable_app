import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/routes/app_routes.dart';
import 'package:artable_app/core/utils/reel_helpers.dart';
import 'package:artable_app/core/utils/studio_video_player_utils.dart';
import 'package:artable_app/features/studio/presentation/bloc/studio_cubit.dart';
import 'package:artable_app/features/studio/data/services/studio_music_playback_service.dart';
import 'package:artable_app/features/studio/presentation/widgets/video_crop_sheet.dart';
import 'package:artable_app/features/studio/presentation/widgets/video_trimmer_sheet.dart';

enum TimelineTrackType { none, video, music }

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class StudioEditVideoScreen extends StatefulWidget {
  const StudioEditVideoScreen({
    super.key,
    this.challengeId,
    this.draftId,
  });

  final String? challengeId;
  final String? draftId;

  @override
  State<StudioEditVideoScreen> createState() => _StudioEditVideoScreenState();
}

class _StudioEditVideoScreenState extends State<StudioEditVideoScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _playing = false;
  bool _videoError = false;
  double _timelinePosition = 0.0;
  Timer? _timelineTimer;

  // Track selection state
  TimelineTrackType _selectedTrack = TimelineTrackType.video;
  List<String> _mergedClipPaths = [];
  List<double> _mergedClipDurations = [];

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    if (!mounted) return;

    final studio = context.read<StudioCubit>();
    final draft = _draft;

    if (draft != null) {
      if (draft['mergedClipPaths'] is List && (draft['mergedClipPaths'] as List).isNotEmpty) {
        _mergedClipPaths = List<String>.from(draft['mergedClipPaths'] as List);
      } else {
        _mergedClipPaths = [];
      }
      if (draft['mergedClipDurations'] is List && (draft['mergedClipDurations'] as List).isNotEmpty) {
        _mergedClipDurations = (draft['mergedClipDurations'] as List).map((e) => (e as num).toDouble()).toList();
      } else {
        _mergedClipDurations = [];
      }
    } else {
      if (studio.state.mergedClipPaths != null && studio.state.mergedClipPaths!.isNotEmpty) {
        _mergedClipPaths = List<String>.from(studio.state.mergedClipPaths!);
      } else {
        _mergedClipPaths = [];
      }
      if (studio.state.mergedClipDurations != null && studio.state.mergedClipDurations!.isNotEmpty) {
        _mergedClipDurations = List<double>.from(studio.state.mergedClipDurations!);
      } else {
        _mergedClipDurations = [];
      }
    }

    final String? path = (draft?['videoPath'] as String?) ??
        (draft?['videoUrl'] as String?) ??
        studio.recordedVideoPath;

    if (path == null || path.isEmpty) {
      if (mounted) setState(() => _videoError = true);
      return;
    }

    VideoPlayerController? controller;
    try {
      controller = await StudioVideoPlayerUtils.initializeRecordedVideo(path);
    } catch (_) {
      controller = null;
    }

    if (!mounted) {
      await controller?.dispose();
      return;
    }

    if (controller != null && controller.value.isInitialized) {
      controller.addListener(_onVideoUpdate);
      controller.setVolume(studio.isMuted ? 0.0 : 1.0);
      setState(() {
        _videoController = controller;
        _isVideoInitialized = true;
        _videoError = false;
      });
      _startTimer();

      if (studio.selectedMusic != null || studio.selectedTrack != null) {
        await StudioMusicPlaybackService.preloadForStudio(studio);
        if (_videoController?.value.isPlaying ?? false) {
          await StudioMusicPlaybackService.playForRecording(studio);
        }
      }
    } else {
      await controller?.dispose();
      if (mounted) setState(() => _videoError = true);
    }
  }

  int _lastVideoPosMs = 0;

  void _startTimer() {
    _timelineTimer?.cancel();
    _timelineTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      final c = _videoController;
      if (c == null || !c.value.isInitialized || !mounted) return;
      final studio = context.read<StudioCubit>();
      final totalMs = c.value.duration.inMilliseconds;
      final trimStartMs = (studio.state.videoTrimStartSeconds * 1000).round();
      final trimEndMs = (studio.state.videoTrimEndSeconds != null)
          ? (studio.state.videoTrimEndSeconds! * 1000).round()
          : totalMs;
      final effectiveDurationMs = (trimEndMs - trimStartMs).clamp(1, totalMs > 0 ? totalMs : 1);
      final currentPosMs = c.value.position.inMilliseconds;

      final elapsedMs = (currentPosMs - trimStartMs).clamp(0, effectiveDurationMs);
      if (effectiveDurationMs > 0) {
        setState(() => _timelinePosition = (elapsedMs / effectiveDurationMs).clamp(0.0, 1.0));
      }

      if (c.value.isPlaying && (studio.selectedMusic != null || studio.selectedTrack != null)) {
        final musicStartMs = (studio.musicStartSeconds * 1000).round();
        final targetMusicMs = musicStartMs + elapsedMs;
        StudioMusicPlaybackService.checkAndSyncPosition(targetMusicMs);
      }
    });
  }

  void _onVideoUpdate() {
    if (!mounted) return;
    final c = _videoController;
    if (c != null && c.value.isInitialized) {
      final playing = c.value.isPlaying;
      if (playing != _playing) setState(() => _playing = playing);

      final studio = context.read<StudioCubit>();
      final totalMs = c.value.duration.inMilliseconds;
      final trimStartMs = (studio.state.videoTrimStartSeconds * 1000).round();
      final trimEndMs = (studio.state.videoTrimEndSeconds != null)
          ? (studio.state.videoTrimEndSeconds! * 1000).round()
          : totalMs;
      final currentPosMs = c.value.position.inMilliseconds;

      final hasLooped = playing &&
          (_lastVideoPosMs > currentPosMs + 300 || currentPosMs >= trimEndMs || currentPosMs < trimStartMs);

      if (hasLooped) {
        if (currentPosMs >= trimEndMs || currentPosMs < trimStartMs) {
          c.seekTo(Duration(milliseconds: trimStartMs));
        }
        if (studio.selectedMusic != null || studio.selectedTrack != null) {
          final musicStartMs = (studio.musicStartSeconds * 1000).round();
          StudioMusicPlaybackService.seekToMs(musicStartMs);
        }
      }

      _lastVideoPosMs = currentPosMs;
    }
  }

  Future<void> _togglePlay() async {
    final c = _videoController;
    if (c == null || !_isVideoInitialized) return;
    final studio = context.read<StudioCubit>();

    if (c.value.isPlaying) {
      await c.pause();
      await StudioMusicPlaybackService.pause();
      setState(() => _playing = false);
    } else {
      await c.setVolume(studio.isMuted ? 0.0 : 1.0);
      await c.play();
      if (studio.selectedMusic != null || studio.selectedTrack != null) {
        await StudioMusicPlaybackService.playForRecording(studio);
      }
      setState(() => _playing = true);
    }
  }

  void _seekToRatio(double ratio) {
    final c = _videoController;
    if (c == null || !c.value.isInitialized) return;
    final studio = context.read<StudioCubit>();
    final totalMs = c.value.duration.inMilliseconds;
    final trimStartMs = (studio.state.videoTrimStartSeconds * 1000).round();
    final trimEndMs = (studio.state.videoTrimEndSeconds != null)
        ? (studio.state.videoTrimEndSeconds! * 1000).round()
        : totalMs;
    final effectiveDurationMs = (trimEndMs - trimStartMs).clamp(1, totalMs > 0 ? totalMs : 1);

    final targetOffsetMs = (effectiveDurationMs * ratio).round();
    final targetVideoMs = trimStartMs + targetOffsetMs;
    c.seekTo(Duration(milliseconds: targetVideoMs));

    if (studio.selectedMusic != null || studio.selectedTrack != null) {
      final musicStartMs = (studio.musicStartSeconds * 1000).round();
      StudioMusicPlaybackService.seekToMs(musicStartMs + targetOffsetMs);
    }

    setState(() => _timelinePosition = ratio.clamp(0.0, 1.0));
  }

  String _fmt(int ms) {
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    final sec = s % 60;
    return '$m:${sec.toString().padLeft(2, '0')}';
  }

  Future<void> _onToolbarAction(String id) async {
    _videoController?.pause();
    await StudioMusicPlaybackService.pause();
    setState(() => _playing = false);

    switch (id) {
      case 'crop':
        setState(() => _selectedTrack = TimelineTrackType.video);
        if (!mounted) return;
        VideoCropSheet.show(context);
        break;

      case 'trim':
        setState(() => _selectedTrack = TimelineTrackType.video);
        if (!mounted) return;
        await VideoTrimmerSheet.show(context, videoController: _videoController);
        if (!mounted) return;
        final studio = context.read<StudioCubit>();
        final start = studio.state.videoTrimStartSeconds;
        await _videoController?.seekTo(Duration(milliseconds: (start * 1000).round()));
        _videoController?.setVolume(studio.isMuted ? 0.0 : 1.0);
        _videoController?.play();
        if (studio.selectedMusic != null || studio.selectedTrack != null) {
          await StudioMusicPlaybackService.playForRecording(studio);
        }
        if (mounted) setState(() => _playing = true);
        break;

      case 'music':
        setState(() => _selectedTrack = TimelineTrackType.music);
        final cid = widget.challengeId ?? 'c1';
        final dp = widget.draftId != null ? '&draft=${widget.draftId}' : '';
        if (!mounted) return;
        await context.push('${AppRoutes.studioMusic}?id=$cid$dp');
        if (!mounted) return;
        final studio = context.read<StudioCubit>();
        if (studio.selectedMusic != null || studio.selectedTrack != null) {
          await StudioMusicPlaybackService.preloadForStudio(studio);
          await _videoController?.setVolume(studio.isMuted ? 0.0 : 1.0);
          await _videoController?.play();
          await StudioMusicPlaybackService.playForRecording(studio);
          if (mounted) setState(() => _playing = true);
        }
        setState(() {});
        break;
    }
  }

  @override
  void dispose() {
    _timelineTimer?.cancel();
    _videoController?.removeListener(_onVideoUpdate);
    _videoController?.pause();
    _videoController?.dispose();
    unawaited(StudioMusicPlaybackService.stop());
    super.dispose();
  }

  Map<String, dynamic>? get _draft {
    if (widget.draftId == null) return null;
    for (final d in context.read<StudioCubit>().state.drafts) {
      if (d['id'] == widget.draftId) return d;
    }
    return null;
  }

  Map<String, dynamic> get _challenge =>
      ReelHelpers.challengeById(widget.challengeId ?? 'c1')!;

  String get _dp => widget.draftId != null ? '&draft=${widget.draftId}' : '';

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final studio = context.watch<StudioCubit>();
    final music = studio.selectedMusic;
    final c = _videoController;
    final totalMs = c?.value.duration.inMilliseconds ?? 0;
    final trimStartMs = (studio.state.videoTrimStartSeconds * 1000).round();
    final trimEndMs = (studio.state.videoTrimEndSeconds != null)
        ? (studio.state.videoTrimEndSeconds! * 1000).round()
        : totalMs;
    final effectiveTotalMs = (trimEndMs - trimStartMs).clamp(1, totalMs > 0 ? totalMs : 1);
    final rawPosMs = c?.value.position.inMilliseconds ?? 0;
    final elapsedMs = (rawPosMs - trimStartMs).clamp(0, effectiveTotalMs);
    final challenge = _challenge;

    // Apply volume according to studio.isMuted
    if (c != null && c.value.isInitialized) {
      c.setVolume(studio.isMuted ? 0.0 : 1.0);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ── 1. Top Bar ────────────────────────────────────────────────
            _buildTopBar(challenge),

            // ── 2. Video Preview (with Muted Badge) ───────────────────────
            _buildVideoPreview(c, studio.isMuted),

            // ── 3. Playback Controls Row ──────────────────────────────────
            _buildControls(elapsedMs, effectiveTotalMs),

            // ── 4. Timeline Editor (Video Track + Music Track + Playhead) ─
            _buildTimeline(music, effectiveTotalMs),

            // ── 5. Bottom Toolbar (ONLY Crop | Trim | Music) ──────────────
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ─── Top Bar ─────────────────────────────────────────────────────────────
  Widget _buildTopBar(Map<String, dynamic> challenge) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      child: Row(
        children: [
          // Left back arrow icon inside dark circle
          _CircleBtn(
            icon: Icons.keyboard_arrow_down_rounded,
            size: 28,
            onTap: () {
              StudioMusicPlaybackService.stop();
              context.pop();
            },
          ),
          const Spacer(),
          // Center "Try Edits" pill button header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: const LinearGradient(
                      colors: [AppColors.purple, Color(0xFFAB47BC)],
                    ),
                  ),
                  child: const Icon(Icons.video_settings_rounded, color: Colors.white, size: 14),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Try Edits',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Right white circular button with arrow
          _CircleBtn(
            icon: Icons.arrow_forward_rounded,
            size: 20,
            filled: true,
            onTap: () {
              _videoController?.pause();
              StudioMusicPlaybackService.pause();
              context.push(
                '${AppRoutes.studioPreview}?id=${_challenge['id']}$_dp',
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Video Preview ────────────────────────────────────────────────────────
  Widget _buildVideoPreview(VideoPlayerController? c, bool isMuted) {
    return Expanded(
      flex: 5,
      child: Center(
        child: GestureDetector(
          onTap: _togglePlay,
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Video / Loading
                  if (_isVideoInitialized && c != null && c.value.isInitialized)
                    Container(
                      color: Colors.black,
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: c.value.aspectRatio > 0 ? c.value.aspectRatio : 9 / 16,
                          child: VideoPlayer(c),
                        ),
                      ),
                    )
                  else
                    Container(
                      color: const Color(0xFF0F0F0F),
                      child: Center(
                        child: _videoError
                            ? const Icon(Icons.error_outline, color: Colors.white38, size: 36)
                            : const CircularProgressIndicator(color: AppColors.purple, strokeWidth: 2),
                      ),
                    ),

                  // Muted Badge Top Right (matching preview screen)
                  if (isMuted)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: () {
                          final studio = context.read<StudioCubit>();
                          studio.toggleMute();
                          _videoController?.setVolume(studio.isMuted ? 0.0 : 1.0);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD32F2F),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.volume_off_rounded, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Muted',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Play overlay button
                  Center(
                    child: AnimatedOpacity(
                      opacity: _playing ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 180),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.45),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Playback Controls ────────────────────────────────────────────────────
  Widget _buildControls(int posMs, int totalMs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // Play / Pause circle button
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.white12,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const Spacer(),
          // Duration display
          Text(
            '${_fmt(posMs)} / ${_fmt(totalMs)}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          // Undo button
          _SmallBtn(icon: Icons.undo_rounded, onTap: () {}),
          const SizedBox(width: 10),
          // Redo button
          _SmallBtn(icon: Icons.redo_rounded, onTap: () {}),
        ],
      ),
    );
  }

  // ─── Timeline Section ─────────────────────────────────────────────────────
  Widget _buildTimeline(String? music, int effectiveTotalMs) {
    return LayoutBuilder(builder: (ctx, box) {
      final w = box.maxWidth;
      final trackWidth = (w - 86.0).clamp(1.0, 10000.0);
      final playheadX = (24.0 + (trackWidth * _timelinePosition)).clamp(24.0, w - 62.0);

      return Container(
        color: const Color(0xFF111113),
        padding: const EdgeInsets.only(top: 4, bottom: 8),
        child: GestureDetector(
          onPanUpdate: (details) {
            final dx = details.localPosition.dx;
            final ratio = ((dx - 24.0) / trackWidth).clamp(0.0, 1.0);
            _seekToRatio(ratio);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Time Ruler ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 62),
                child: SizedBox(
                  height: 20,
                  child: CustomPaint(
                    size: Size(trackWidth, 20),
                    painter: _RulerPainter(
                      totalDurationSeconds: (effectiveTotalMs / 1000.0).clamp(1.0, 3600.0),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // ── Multi-Track Rows + Playhead Line ──────────────────────────
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Track Rows Column
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Video Track Strip (Yellow Handle Brackets)
                        GestureDetector(
                          onTap: () => setState(() => _selectedTrack = TimelineTrackType.video),
                          child: _VideoTrackStrip(
                            controller: _videoController,
                            isInitialized: _isVideoInitialized,
                            isSelected: _selectedTrack == TimelineTrackType.video,
                            mergedClipPaths: _mergedClipPaths,
                            mergedClipDurations: _mergedClipDurations,
                            onAddClip: () async {
                              _videoController?.pause();
                              await StudioMusicPlaybackService.pause();
                              if (mounted) setState(() => _playing = false);
                              if (!mounted) return;
                              context.push('${AppRoutes.studioDrafts}?selectForMerge=true');
                            },
                          ),
                        ),

                        const SizedBox(height: 5),

                        // Row 2: Music Track Strip (Purple / Magenta Handles)
                        GestureDetector(
                          onTap: () async {
                            setState(() => _selectedTrack = TimelineTrackType.music);
                            _videoController?.pause();
                            await StudioMusicPlaybackService.pause();
                            if (mounted) setState(() => _playing = false);
                            final cid = widget.challengeId ?? 'c1';
                            final dp = widget.draftId != null ? '&draft=${widget.draftId}' : '';
                            if (!mounted) return;
                            await context.push('${AppRoutes.studioMusic}?id=$cid$dp');
                            if (!mounted) return;
                            final studio = context.read<StudioCubit>();
                            if (studio.selectedMusic != null || studio.selectedTrack != null) {
                              await StudioMusicPlaybackService.preloadForStudio(studio);
                              await _videoController?.setVolume(studio.isMuted ? 0.0 : 1.0);
                              await _videoController?.play();
                              await StudioMusicPlaybackService.playForRecording(studio);
                              if (mounted) setState(() => _playing = true);
                            }
                            if (mounted) setState(() {});
                          },
                          child: _MusicTrackStrip(
                            music: music,
                            isSelected: _selectedTrack == TimelineTrackType.music,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // White Vertical Playhead Line across all tracks
                  Positioned(
                    left: playheadX,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(1),
                        boxShadow: const [
                          BoxShadow(color: Colors.white38, blurRadius: 3),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  // ─── Bottom Editing Toolbar (ONLY Crop | Trim | Music) ─────────────────────
  Widget _buildBottomBar() {
    const items = [
      _BarItem(id: 'crop', icon: Icons.crop_rounded, label: 'Crop'),
      _BarItem(id: 'trim', icon: Icons.content_cut_rounded, label: 'Trim'),
      _BarItem(id: 'music', icon: Icons.music_note_rounded, label: 'Music'),
    ];

    return Container(
      color: const Color(0xFF000000),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items.map((item) {
          final isSelected = (_selectedTrack == TimelineTrackType.music && item.id == 'music') ||
              (_selectedTrack == TimelineTrackType.video && (item.id == 'crop' || item.id == 'trim'));
          return GestureDetector(
            onTap: () => _onToolbarAction(item.id),
            child: SizedBox(
              width: 80,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF2C1C3E) : const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.purple,
                        width: isSelected ? 2.0 : 1.2,
                      ),
                    ),
                    child: Icon(
                      item.icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private data class for bottom bar
// ─────────────────────────────────────────────────────────────────────────────
class _BarItem {
  const _BarItem({required this.id, required this.icon, required this.label});
  final String id;
  final IconData icon;
  final String label;
}

// ─────────────────────────────────────────────────────────────────────────────
// Video Track Strip (Yellow Handles)
// ─────────────────────────────────────────────────────────────────────────────
class _VideoTrackStrip extends StatelessWidget {
  const _VideoTrackStrip({
    required this.controller,
    required this.isInitialized,
    required this.isSelected,
    this.mergedClipPaths = const [],
    this.mergedClipDurations = const [],
    this.onAddClip,
  });

  final VideoPlayerController? controller;
  final bool isInitialized;
  final bool isSelected;
  final List<String> mergedClipPaths;
  final List<double> mergedClipDurations;
  final VoidCallback? onAddClip;

  @override
  Widget build(BuildContext context) {
    final clipCount = mergedClipPaths.isNotEmpty ? mergedClipPaths.length : 1;

    final bool hasValidDurations = mergedClipDurations.length == clipCount &&
        mergedClipDurations.every((d) => d > 0);

    final double totalDuration = hasValidDurations
        ? mergedClipDurations.reduce((a, b) => a + b)
        : (controller?.value.duration.inMilliseconds.toDouble() ?? 10000.0) / 1000.0;

    return SizedBox(
      height: 54,
      child: Row(
        children: [
          // Left Trim Handle Bracket (Yellow)
          _TrimHandle(isLeft: true, isSelected: isSelected),

          // Video thumbnail strip with separate clip segments & yellow line dividers
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C),
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFFFFD54F),
                    width: isSelected ? 2.0 : 1.2,
                  ),
                  bottom: BorderSide(
                    color: const Color(0xFFFFD54F),
                    width: isSelected ? 2.0 : 1.2,
                  ),
                ),
              ),
              child: isInitialized && controller != null && controller!.value.isInitialized
                  ? Row(
                      children: List.generate(clipCount, (index) {
                        final double clipDur = hasValidDurations
                            ? mergedClipDurations[index]
                            : (totalDuration / clipCount);
                        final int flexValue = (clipDur * 100).round().clamp(1, 100000);

                        return Expanded(
                          flex: flexValue,
                          child: Container(
                            decoration: BoxDecoration(
                              border: index < clipCount - 1
                                  ? const Border(
                                      right: BorderSide(
                                        color: Color(0xFFFFD54F),
                                        width: 2.5,
                                      ),
                                    )
                                  : null,
                            ),
                            child: Row(
                              children: List.generate(
                                ((clipDur / (totalDuration > 0 ? totalDuration : 1.0)) * 14)
                                    .round()
                                    .clamp(1, 14),
                                (i) => Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.all(1.0),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2E2E44),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    )
                  : const Center(
                      child: Text(
                        'Video Clip',
                        style: TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                    ),
            ),
          ),

          // Right Trim Handle Bracket (Yellow)
          _TrimHandle(isLeft: false, isSelected: isSelected),

          // "+" Add Clip Button
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onAddClip,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24, width: 1.0),
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Trim Handle Widget (Yellow Brackets for Video)
// ─────────────────────────────────────────────────────────────────────────────
class _TrimHandle extends StatelessWidget {
  const _TrimHandle({required this.isLeft, required this.isSelected});
  final bool isLeft;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFFFFD54F),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isLeft ? 6 : 0),
          bottomLeft: Radius.circular(isLeft ? 6 : 0),
          topRight: Radius.circular(isLeft ? 0 : 6),
          bottomRight: Radius.circular(isLeft ? 0 : 6),
        ),
      ),
      child: Center(
        child: Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Music Track Strip (App Theme Purple/Magenta Row)
// ─────────────────────────────────────────────────────────────────────────────
class _MusicTrackStrip extends StatelessWidget {
  const _MusicTrackStrip({
    required this.music,
    required this.isSelected,
  });

  final String? music;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final hasMusic = music != null && music!.isNotEmpty;
    final trackColor = hasMusic ? const Color(0xFF381447) : const Color(0xFF22162E);
    final accentColor = isSelected ? AppColors.purple : (hasMusic ? const Color(0xFFAB47BC) : const Color(0xFF6B477D));

    return SizedBox(
      height: 46,
      child: Row(
        children: [
          // Left handle bracket for Music Track
          Container(
            width: 14,
            height: 46,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                bottomLeft: Radius.circular(6),
              ),
            ),
            child: const Center(
              child: Icon(Icons.music_note_rounded, color: Colors.white, size: 10),
            ),
          ),

          // Music Track Content Body
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: trackColor,
                border: Border(
                  top: BorderSide(color: accentColor, width: isSelected ? 2.0 : 1.2),
                  bottom: BorderSide(color: accentColor, width: isSelected ? 2.0 : 1.2),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.music_note_rounded,
                    color: hasMusic ? AppColors.purple : Colors.white54,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasMusic ? music! : '+ Add Music / Audio Track',
                      style: TextStyle(
                        color: hasMusic ? Colors.white : Colors.white60,
                        fontSize: 12,
                        fontWeight: hasMusic ? FontWeight.w700 : FontWeight.w500,
                        fontFamily: 'Inter',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasMusic)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        10,
                        (index) => Container(
                          width: 2,
                          height: (index % 3 == 0 ? 18 : (index % 2 == 0 ? 10 : 20)).toDouble(),
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.purple.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Right handle bracket for Music Track
          Container(
            width: 14,
            height: 46,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(6),
                bottomRight: Radius.circular(6),
              ),
            ),
            child: const Center(
              child: Icon(Icons.tune_rounded, color: Colors.white, size: 10),
            ),
          ),

          // Offset alignment space to match video track layout
          const SizedBox(width: 38),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ruler Painter
// ─────────────────────────────────────────────────────────────────────────────
class _RulerPainter extends CustomPainter {
  _RulerPainter({this.totalDurationSeconds = 15.0});
  final double totalDurationSeconds;

  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()
      ..color = Colors.white38
      ..style = PaintingStyle.fill;
    final line = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1;
    final tp = TextPainter(textDirection: TextDirection.ltr);

    const steps = 5;
    for (int i = 0; i <= steps; i++) {
      final x = size.width * i / steps;
      canvas.drawCircle(Offset(x, size.height - 3), 2.0, dot);
      final sec = ((totalDurationSeconds * i) / steps).round();
      if (i > 0 && i < steps) {
        tp.text = TextSpan(
          text: '${sec}s',
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 9.5,
            fontFamily: 'Inter',
          ),
        );
        tp.layout();
        tp.paint(canvas, Offset(x - tp.width / 2, 0));
      }
    }
    canvas.drawLine(Offset(0, size.height - 1), Offset(size.width, size.height - 1), line);
  }

  @override
  bool shouldRepaint(_RulerPainter old) => old.totalDurationSeconds != totalDurationSeconds;
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable Buttons
// ─────────────────────────────────────────────────────────────────────────────
class _CircleBtn extends StatelessWidget {
  const _CircleBtn({
    required this.icon,
    required this.onTap,
    this.size = 22,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: filled ? Colors.white : Colors.white12,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: filled ? Colors.black : Colors.white,
          size: size,
        ),
      ),
    );
  }
}

class _SmallBtn extends StatelessWidget {
  const _SmallBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white60, size: 18),
      ),
    );
  }
}
