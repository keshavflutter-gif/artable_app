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
import 'package:artable_app/features/studio/presentation/widgets/editor_clip.dart';
import 'package:artable_app/features/studio/presentation/widgets/multi_video_timeline.dart';
import 'package:artable_app/features/studio/presentation/screens/studio_drafts_screen.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

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
  // ── Clip state ─────────────────────────────────────────────────────────────
  final EditorClipListNotifier _clipNotifier = EditorClipListNotifier();

  // ── Per-clip VideoPlayerControllers (indexed by EditorClip.id) ────────────
  final Map<String, VideoPlayerController> _controllers = {};

  // ── Playback state ─────────────────────────────────────────────────────────
  bool _playing = false;
  bool _isLoading = true;
  bool _videoError = false;

  /// Global position in ms (sum of all previous trimmed clips + current pos in active clip)
  int _globalPositionMs = 0;

  /// Which clip is actively playing/previewing
  int _activePlayingIndex = 0;

  /// Timer for timeline progress tick + auto-advance
  Timer? _playbackTimer;

  /// Guard against concurrent clip switches
  bool _isSwitchingClip = false;

  /// Guard against double tap navigation to details
  bool _isNavigating = false;

  // ── Legacy compat (mergedClipPaths from draft/state) ──────────────────────
  List<String> _mergedClipPaths = [];
  List<double> _mergedClipDurations = [];

  @override
  void initState() {
    super.initState();
    unawaited(WakelockPlus.enable());
    _initAllClips();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Init / Load
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _initAllClips() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _videoError = false;
    });

    // Dispose existing
    _playbackTimer?.cancel();
    for (final c in _controllers.values) {
      c.removeListener(_onVideoUpdate);
      await c.pause();
      await c.dispose();
    }
    _controllers.clear();

    final studio = context.read<StudioCubit>();
    final draft = _draft;

    // ── Collect clip paths ─────────────────────────────────────────────────
    if (draft != null) {
      _mergedClipPaths = (draft['mergedClipPaths'] is List)
          ? List<String>.from(draft['mergedClipPaths'] as List)
          : [];
      _mergedClipDurations = (draft['mergedClipDurations'] is List)
          ? (draft['mergedClipDurations'] as List).map((e) => (e as num).toDouble()).toList()
          : [];
    } else {
      _mergedClipPaths = studio.state.mergedClipPaths != null ? List<String>.from(studio.state.mergedClipPaths!) : [];
      _mergedClipDurations = studio.state.mergedClipDurations != null
          ? List<double>.from(studio.state.mergedClipDurations!)
          : [];
    }

    // Single combined path (may already be merged)
    final String? combinedPath = (draft?['videoPath'] as String?) ??
        (draft?['videoUrl'] as String?) ??
        studio.recordedVideoPath;

    // ── Build clips list ──────────────────────────────────────────────────
    List<EditorClip> clips = [];

    final String? recPath = studio.recordedVideoPath?.trim();
    final bool hasRec = recPath != null && recPath.isNotEmpty;

    final List<String> finalPaths = [];
    if (hasRec) {
      finalPaths.add(recPath);
    }

    if (_mergedClipPaths.isNotEmpty) {
      for (final p in _mergedClipPaths) {
        final clean = p.trim();
        if (clean.isNotEmpty && !finalPaths.contains(clean)) {
          finalPaths.add(clean);
        }
      }
    } else if (combinedPath != null && combinedPath.trim().isNotEmpty && !finalPaths.contains(combinedPath.trim())) {
      finalPaths.add(combinedPath.trim());
    }

    for (int i = 0; i < finalPaths.length; i++) {
      final path = finalPaths[i];
      final hintDur = (i < _mergedClipDurations.length && _mergedClipDurations[i] > 0)
          ? Duration(milliseconds: (_mergedClipDurations[i] * 1000).round())
          : const Duration(seconds: 15);
      clips.add(_makeEditorClip(path, hintDur));
    }

    if (clips.isEmpty) {
      if (mounted) setState(() { _isLoading = false; _videoError = true; });
      return;
    }

    // ── Initialize controllers for each clip ──────────────────────────────
    for (final clip in clips) {
      final controller = await _initController(clip.filePath);
      if (controller != null) {
        final realDur = controller.value.duration;
        // Update original duration from actual video
        final updatedClip = EditorClip(
          id: clip.id,
          filePath: clip.filePath,
          originalDuration: realDur > Duration.zero ? realDur : clip.originalDuration,
          trimStart: Duration.zero,
          trimEnd: realDur > Duration.zero ? realDur : clip.originalDuration,
        );
        // Replace clip in list with real duration
        clips[clips.indexWhere((c) => c.id == clip.id)] = updatedClip;
        _controllers[updatedClip.id] = controller;
      }
    }

    // Restore trimStart/trimEnd from studio state for first clip
    if (clips.isNotEmpty) {
      final startMs = (studio.state.videoTrimStartSeconds * 1000).round();
      final endMs = studio.state.videoTrimEndSeconds != null
          ? (studio.state.videoTrimEndSeconds! * 1000).round()
          : clips.first.originalDuration.inMilliseconds;
      final first = clips.first;
      final safeEnd = endMs.clamp(0, first.originalDuration.inMilliseconds);
      final safeStart = startMs.clamp(0, safeEnd - 500);
      clips[0] = first.copyWith(
        trimStart: Duration(milliseconds: safeStart),
        trimEnd: Duration(milliseconds: safeEnd),
      );
    }

    if (!mounted) return;
    _clipNotifier.setClips(clips, selectedIndex: 0);
    _activePlayingIndex = 0;

    // Attach listener to first controller
    final firstClip = _clipNotifier.clips.firstOrNull;
    if (firstClip != null) {
      _controllers[firstClip.id]?.addListener(_onVideoUpdate);
      await _seekClipToTrimStart(0);
      await _controllers[firstClip.id]?.setVolume(studio.isMuted ? 0.0 : 1.0);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _videoError = _controllers.isEmpty;
      });
    }
    _startPlaybackTimer();
  }

  EditorClip _makeEditorClip(String path, Duration hintDuration) {
    return EditorClip(
      id: '${path.hashCode}_${DateTime.now().microsecondsSinceEpoch}',
      filePath: path,
      originalDuration: hintDuration,
      trimStart: Duration.zero,
      trimEnd: hintDuration,
    );
  }

  Future<VideoPlayerController?> _initController(String path) async {
    try {
      final controller = await StudioVideoPlayerUtils.initializeRecordedVideo(
        path,
        loop: false,
        autoPlay: false,
      );
      if (controller != null && controller.value.isInitialized) {
        await controller.setLooping(false);
        return controller;
      }
    } catch (e) {
      debugPrint('_initController error for $path: $e');
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Playback Timer
  // ─────────────────────────────────────────────────────────────────────────
  void _startPlaybackTimer() {
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 40), (_) {
      if (!mounted) return;
      _tickPlayback();
    });
  }

  void _tickPlayback() {
    if (!_playing || _isSwitchingClip) return;
    final clips = _clipNotifier.clips;
    if (clips.isEmpty) return;

    // Calculate global position from currently active clip's position
    int accumulatedMs = 0;
    for (int i = 0; i < _activePlayingIndex && i < clips.length; i++) {
      accumulatedMs += clips[i].trimmedDuration.inMilliseconds;
    }

    final activeClip = _activePlayingIndex < clips.length ? clips[_activePlayingIndex] : null;
    final controller = activeClip != null ? _controllers[activeClip.id] : null;

    if (controller != null && controller.value.isInitialized) {
      final posMs = controller.value.position.inMilliseconds;
      final trimEndMs = activeClip!.trimEnd.inMilliseconds;
      final trimStartMs = activeClip.trimStart.inMilliseconds;

      final localMs = (posMs - trimStartMs).clamp(0, activeClip.trimmedDuration.inMilliseconds);
      final newGlobal = accumulatedMs + localMs;

      if (newGlobal != _globalPositionMs) {
        setState(() => _globalPositionMs = newGlobal);
      }

      // Auto-advance near trimEnd (tolerance) or when player hits natural EOS.
      final nearEnd = posMs >= trimEndMs - 200;
      final naturalEos = !controller.value.isPlaying &&
          posMs >= trimEndMs - 250 &&
          posMs > trimStartMs;
      if (_playing && !_isSwitchingClip && (nearEnd || naturalEos)) {
        _advanceToNextClip();
      }
    }

    // Music sync
    if (_playing) {
      final studio = context.read<StudioCubit>();
      if (studio.selectedMusic != null || studio.selectedTrack != null) {
        final musicStartMs = (studio.musicStartSeconds * 1000).round();
        StudioMusicPlaybackService.checkAndSyncPosition(musicStartMs + _globalPositionMs);
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Video Controller Listener
  // ─────────────────────────────────────────────────────────────────────────
  void _onVideoUpdate() {
    // Intentionally minimal — we do not sync _playing from isPlaying
    // (prevents auto-pause from internal video engine transitions).
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Clip Advance (auto-advance during playback)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _advanceToNextClip() async {
    if (_isSwitchingClip) return;
    final clips = _clipNotifier.clips;
    if (clips.isEmpty) return;

    _isSwitchingClip = true;

    final oldIndex = _activePlayingIndex;
    final oldClip = oldIndex < clips.length ? clips[oldIndex] : null;
    final oldController = oldClip != null ? _controllers[oldClip.id] : null;

    if (oldController != null) {
      oldController.removeListener(_onVideoUpdate);
      await oldController.pause();
    }

    final nextIndex = oldIndex + 1;

    if (nextIndex >= clips.length) {
      // Reached the end of full video sequence
      _activePlayingIndex = clips.length - 1;
      final lastClip = clips.last;
      final lastController = _controllers[lastClip.id];
      if (lastController != null && lastController.value.isInitialized) {
        try {
          await lastController.seekTo(lastClip.trimEnd);
        } catch (_) {}
      }
      final totalMs = _clipNotifier.totalTrimmedDuration.inMilliseconds;
      if (mounted) {
        setState(() {
          _globalPositionMs = totalMs;
          _playing = false;
        });
      }
      await StudioMusicPlaybackService.pause();
    } else {
      final studio = context.read<StudioCubit>();
      _activePlayingIndex = nextIndex;
      final nextClip = clips[nextIndex];
      final nextController = _controllers[nextClip.id];
      if (nextController == null) {
        _isSwitchingClip = false;
        return;
      }
      await nextController.setVolume(studio.isMuted ? 0.0 : 1.0);
      await _seekClipToTrimStart(nextIndex);
      nextController.addListener(_onVideoUpdate);
      await nextController.play();
      if (mounted) setState(() {});
    }

    _isSwitchingClip = false;
  }

  Future<void> _seekClipToTrimStart(int clipIndex) async {
    final clips = _clipNotifier.clips;
    if (clipIndex >= clips.length) return;
    final clip = clips[clipIndex];
    final controller = _controllers[clip.id];
    if (controller != null && controller.value.isInitialized) {
      await controller.seekTo(clip.trimStart);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Toggle Play / Pause
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _togglePlay() async {
    final clips = _clipNotifier.clips;
    if (clips.isEmpty || _isLoading) return;
    final studio = context.read<StudioCubit>();

    if (_playing) {
      // Pause all
      for (final c in _controllers.values) {
        await c.pause();
      }
      await StudioMusicPlaybackService.pause();
      if (mounted) setState(() => _playing = false);
    } else {
      final totalMs = _clipNotifier.totalTrimmedDuration.inMilliseconds;
      // If at end of sequence, restart from clip 0
      if (_globalPositionMs >= totalMs - 100) {
        _activePlayingIndex = 0;
        _globalPositionMs = 0;
        await _seekClipToTrimStart(0);
      }

      if (_activePlayingIndex >= clips.length) _activePlayingIndex = 0;

      final activeClip = clips[_activePlayingIndex];
      final activeController = _controllers[activeClip.id];
      if (activeController != null) {
        final posMs = activeController.value.position.inMilliseconds;
        final trimEndMs = activeClip.trimEnd.inMilliseconds;
        // If current clip already finished, continue to next (or restart this clip).
        if (posMs >= trimEndMs - 200) {
          if (_activePlayingIndex < clips.length - 1) {
            if (mounted) setState(() => _playing = true);
            await _advanceToNextClip();
            if (studio.selectedMusic != null || studio.selectedTrack != null) {
              await StudioMusicPlaybackService.playForEditor(studio, _globalPositionMs);
            }
            return;
          }
          await _seekClipToTrimStart(_activePlayingIndex);
        }
        await activeController.setVolume(studio.isMuted ? 0.0 : 1.0);
        activeController.addListener(_onVideoUpdate);
        await activeController.play();
      }

      if (studio.selectedMusic != null || studio.selectedTrack != null) {
        await StudioMusicPlaybackService.playForEditor(studio, _globalPositionMs);
      }
      if (mounted) setState(() => _playing = true);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Select Clip (tap in timeline)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _selectClip(int clipIndex) async {
    final clips = _clipNotifier.clips;
    if (clipIndex >= clips.length) return;
    final studio = context.read<StudioCubit>();

    // Pause if playing
    if (_playing) {
      for (final c in _controllers.values) {
        await c.pause();
      }
      await StudioMusicPlaybackService.pause();
      setState(() => _playing = false);
    }

    _clipNotifier.selectClip(clipIndex);
    _activePlayingIndex = clipIndex;

    // Seek preview to trimStart of selected clip
    await _seekClipToTrimStart(clipIndex);

    // Update global position display
    int accMs = 0;
    for (int i = 0; i < clipIndex; i++) {
      accMs += clips[i].trimmedDuration.inMilliseconds;
    }
    setState(() => _globalPositionMs = accMs);

    if (studio.selectedMusic != null || studio.selectedTrack != null) {
      final musicStartMs = (studio.musicStartSeconds * 1000).round();
      await StudioMusicPlaybackService.seekToMs(musicStartMs + accMs);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Seek from timeline scrub
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _onGlobalSeek(int globalMs) async {
    final clips = _clipNotifier.clips;
    if (clips.isEmpty) return;
    final studio = context.read<StudioCubit>();

    final resolved = _clipNotifier.resolveGlobalMs(globalMs);
    final clipIndex = resolved.clipIndex;
    final seekPos = resolved.seekPosition;

    final clip = clips[clipIndex];
    final controller = _controllers[clip.id];

    if (controller != null && controller.value.isInitialized) {
      await controller.seekTo(seekPos);
    }

    _activePlayingIndex = clipIndex;
    _clipNotifier.selectClip(clipIndex);
    setState(() => _globalPositionMs = globalMs);

    if (studio.selectedMusic != null || studio.selectedTrack != null) {
      final musicStartMs = (studio.musicStartSeconds * 1000).round();
      await StudioMusicPlaybackService.seekToMs(musicStartMs + globalMs);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Add Video via ImagePicker
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _addVideo() async {
    if (_clipNotifier.clips.length >= EditorClipListNotifier.maxClips) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 10 clips allowed in timeline.'),
          backgroundColor: Colors.deepOrange,
        ),
      );
      return;
    }

    final studio = context.read<StudioCubit>();

    // Pause first
    for (final c in _controllers.values) {
      await c.pause();
    }
    await StudioMusicPlaybackService.pause();
    if (mounted) setState(() => _playing = false);

    // Fetch latest drafts
    await studio.fetchDraftsList();

    if (!mounted) return;

    // Navigate to full-screen StudioDraftsScreen page
    final selectedDraft = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => StudioDraftsScreen(
          challengeId: widget.challengeId,
          selectForMerge: true,
        ),
      ),
    );

    if (selectedDraft != null && mounted) {
      await _importDraftToTimeline(selectedDraft);
    }
  }

  Future<void> _importDraftToTimeline(Map<String, dynamic> draft) async {
    final existingPaths = _clipNotifier.clips.map((c) => c.filePath.trim()).toSet();

    List<String> rawPaths = [];
    if (draft['mergedClipPaths'] is List && (draft['mergedClipPaths'] as List).isNotEmpty) {
      rawPaths = List<String>.from(draft['mergedClipPaths'] as List);
    } else {
      final String? path = (draft['videoPath'] as String?) ?? (draft['videoUrl'] as String?);
      if (path != null && path.trim().isNotEmpty) {
        rawPaths.add(path.trim());
      }
    }

    final List<String> pathsToAdd = [];
    for (final p in rawPaths) {
      final clean = p.trim();
      if (clean.isNotEmpty && !existingPaths.contains(clean)) {
        pathsToAdd.add(clean);
      }
    }

    if (pathsToAdd.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selected draft clip(s) already exist in timeline.'),
            backgroundColor: Colors.deepOrange,
          ),
        );
      }
      return;
    }

    int addedCount = 0;
    for (final path in pathsToAdd) {
      if (_clipNotifier.clips.length >= EditorClipListNotifier.maxClips) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reached maximum limit of 10 clips.'),
              backgroundColor: Colors.deepOrange,
            ),
          );
        }
        break;
      }

      final controller = await _initController(path);
      if (controller == null) continue;

      final duration = controller.value.duration > Duration.zero
          ? controller.value.duration
          : const Duration(seconds: 15);

      final newClip = EditorClip(
        id: '${path.hashCode}_${DateTime.now().microsecondsSinceEpoch}_$addedCount',
        filePath: path,
        originalDuration: duration,
        trimStart: Duration.zero,
        trimEnd: duration,
      );

      _controllers[newClip.id] = controller;
      final added = _clipNotifier.addClip(newClip);
      if (added) {
        addedCount++;
      } else {
        await controller.dispose();
        _controllers.remove(newClip.id);
      }
    }

    if (mounted) {
      setState(() {});
      if (addedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added $addedCount draft clip(s) to timeline!'),
            backgroundColor: const Color(0xFF8B5CF6),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Remove Clip
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _removeClip(int clipIndex) async {
    final clips = _clipNotifier.clips;
    if (clipIndex >= clips.length) return;
    if (clips.length <= 1) {
      // Cannot remove the only clip
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one video clip is required.'),
          backgroundColor: Colors.deepOrange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final clip = clips[clipIndex];

    // Pause
    for (final c in _controllers.values) {
      await c.pause();
    }
    setState(() => _playing = false);

    // Dispose controller
    final controller = _controllers.remove(clip.id);
    controller?.removeListener(_onVideoUpdate);
    await controller?.pause();
    await controller?.dispose();

    _clipNotifier.removeClip(clipIndex);

    // Clamp active playing index
    if (_activePlayingIndex >= _clipNotifier.clips.length) {
      _activePlayingIndex = (_clipNotifier.clips.length - 1).clamp(0, 9);
    }

    await _seekClipToTrimStart(_activePlayingIndex);
    setState(() {});
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Trim changed from timeline handles
  // ─────────────────────────────────────────────────────────────────────────
  void _onTrimChanged(int clipIndex, Duration trimStart, Duration trimEnd) {
    // Already applied in notifier; sync StudioCubit for first clip
    if (clipIndex == 0) {
      final studio = context.read<StudioCubit>();
      studio.setVideoTrimRange(
        start: trimStart.inMilliseconds / 1000.0,
        end: trimEnd.inMilliseconds / 1000.0,
        formattedDuration: _fmtDuration(trimEnd - trimStart),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Toolbar Actions
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _onToolbarAction(String id) async {
    // Pause
    for (final c in _controllers.values) {
      await c.pause();
    }
    await StudioMusicPlaybackService.pause();
    setState(() => _playing = false);

    switch (id) {
      case 'crop':
        if (!mounted) return;
        VideoCropSheet.show(context);
        break;

      case 'mute':
        final studio = context.read<StudioCubit>();
        studio.toggleMute();
        final newMuted = studio.isMuted;
        for (final ctrl in _controllers.values) {
          await ctrl.setVolume(newMuted ? 0.0 : 1.0);
        }
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                newMuted ? 'All video clips muted' : 'All video clips unmuted',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              backgroundColor: newMuted ? Colors.deepOrange : const Color(0xFF8B5CF6),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        break;

      case 'music':
        final cid = widget.challengeId ?? 'c1';
        final dp = widget.draftId != null ? '&draft=${widget.draftId}' : '';
        if (!mounted) return;
        await context.push('${AppRoutes.studioMusic}?id=$cid$dp');
        if (!mounted) return;
        final studio = context.read<StudioCubit>();
        if (studio.selectedMusic != null || studio.selectedTrack != null) {
          await StudioMusicPlaybackService.preloadForStudio(studio);
          final activeClip = _clipNotifier.selectedClip;
          if (activeClip != null) {
            final c = _controllers[activeClip.id];
            await c?.setVolume(studio.isMuted ? 0.0 : 1.0);
            await c?.play();
          }
          await StudioMusicPlaybackService.playForEditor(studio, _globalPositionMs);
          if (mounted) setState(() => _playing = true);
        } else {
          await StudioMusicPlaybackService.stop();
        }
        if (mounted) setState(() {});
        break;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Dispose
  // ─────────────────────────────────────────────────────────────────────────
  @override
  void dispose() {
    unawaited(WakelockPlus.disable());
    _playbackTimer?.cancel();
    for (final c in _controllers.values) {
      c.removeListener(_onVideoUpdate);
      c.pause();
      c.dispose();
    }
    _controllers.clear();
    _clipNotifier.dispose();
    unawaited(StudioMusicPlaybackService.stop());
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────
  Map<String, dynamic>? get _draft {
    if (widget.draftId == null) return null;
    for (final d in context.read<StudioCubit>().state.drafts) {
      if (d['id'] == widget.draftId) return d;
    }
    return null;
  }

  Map<String, dynamic> get _challenge =>
      ReelHelpers.challengeById(widget.challengeId ?? 'c1')!;

  String _fmt(int ms) {
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    final sec = s % 60;
    return '$m:${sec.toString().padLeft(2, '0')}';
  }

  String _fmtDuration(Duration d) {
    final s = d.inSeconds;
    final m = s ~/ 60;
    final sec = s % 60;
    return '$m:${sec.toString().padLeft(2, '0')}';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Active preview controller
  // ─────────────────────────────────────────────────────────────────────────
  VideoPlayerController? get _activeController {
    final clips = _clipNotifier.clips;
    if (clips.isEmpty) return null;
    final idx = _activePlayingIndex.clamp(0, clips.length - 1);
    return _controllers[clips[idx].id];
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final studio = context.watch<StudioCubit>();
    final music = studio.selectedMusic;
    final totalDuration = _clipNotifier.totalTrimmedDuration;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ── 1. Top Bar ─────────────────────────────────────────────────
            _buildTopBar(_challenge),

            // ── 2. Video Preview ───────────────────────────────────────────
            _buildVideoPreview(studio.isMuted),

            // ── 3. Playback Controls ───────────────────────────────────────
            _buildControls(_globalPositionMs, totalDuration.inMilliseconds),

            // ── 4. Multi-Video Horizontal Timeline ─────────────────────────
            _buildMultiTimeline(music),

            // ── 5. Bottom Toolbar ──────────────────────────────────────────
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Future<void> _onNextPressed() async {
    if (_isNavigating) return;

    final clips = _clipNotifier.clips;
    debugPrint('EDITOR CLIP COUNT: ${clips.length}');
    for (int i = 0; i < clips.length; i++) {
      debugPrint(
        'CLIP $i path=${clips[i].filePath} '
        'start=${clips[i].trimStart} '
        'end=${clips[i].trimEnd}'
      );
    }

    if (clips.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one video clip is required to proceed.'),
          backgroundColor: Colors.deepOrange,
        ),
      );
      return;
    }

    setState(() => _isNavigating = true);

    try {
      // 1. Pause video controllers & music preview
      for (final c in _controllers.values) {
        await c.pause();
      }
      await StudioMusicPlaybackService.pause();
      if (mounted) setState(() => _playing = false);

      // 2. Collect merged paths & clip durations
      final studio = context.read<StudioCubit>();
      final mergedPaths = clips.map((c) => c.filePath.trim()).toList();
      final mergedDurations = clips.map((c) => c.trimmedDuration.inMilliseconds / 1000.0).toList();
      final totalDur = _clipNotifier.totalTrimmedDuration;
      final formattedDur = _fmtDuration(totalDur);

      // 3. Save editor state to StudioCubit
      studio.setMergedClipPaths(mergedPaths, mergedDurations);
      studio.setRecordedDuration(formattedDur);

      String? finalEditedVideoPath;

      if (mergedPaths.length == 1) {
        finalEditedVideoPath = mergedPaths.first;
      } else {
        // Try merge for upload later; Details prefers playlist if merge is unplayable.
        final combinedFile =
            await StudioVideoPlayerUtils.combineVideoFiles(mergedPaths);
        if (combinedFile != null &&
            await combinedFile.exists() &&
            (await combinedFile.length()) > 0) {
          finalEditedVideoPath = combinedFile.path;
          debugPrint('Multi-clip merge OK: $finalEditedVideoPath');
        } else {
          debugPrint(
            'Multi-clip merge unavailable/unplayable — Details will use clip playlist',
          );
          finalEditedVideoPath = mergedPaths.first;
        }
      }

      debugPrint('FINAL OUTPUT PATH: $finalEditedVideoPath');
      // Always keep individual clip paths for multi-clip playlist playback.
      studio.setRecordedVideoPath(
        finalEditedVideoPath,
        mergedClipPaths: mergedPaths.length > 1 ? mergedPaths : null,
        clearMergedClips: mergedPaths.length <= 1,
      );

      if (!mounted) return;

      // 4. Navigate to StudioDetailsScreen (Video Details)
      final cid = _challenge['id'] ?? widget.challengeId ?? 'c1';
      final dp = widget.draftId != null ? '&draft=${widget.draftId}' : '';
      await context.push('${AppRoutes.studioDetails}?id=$cid$dp');
    } catch (e) {
      debugPrint('_onNextPressed error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error preparing video details: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isNavigating = false);
      }
    }
  }

  // ─── Top Bar ──────────────────────────────────────────────────────────────
  Widget _buildTopBar(Map<String, dynamic> challenge) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      child: Row(
        children: [
          _CircleBtn(
            icon: Icons.keyboard_arrow_down_rounded,
            size: 28,
            onTap: () {
              StudioMusicPlaybackService.stop();
              context.pop();
            },
          ),
          const Spacer(),
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
                Text(
                  'Try Edits  •  ${_clipNotifier.clips.length} clip${_clipNotifier.clips.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          _CircleBtn(
            icon: _isNavigating ? Icons.hourglass_top_rounded : Icons.arrow_forward_rounded,
            size: 20,
            filled: true,
            onTap: _isNavigating ? () {} : _onNextPressed,
          ),
        ],
      ),
    );
  }

  // ─── Video Preview ─────────────────────────────────────────────────────────
  Widget _buildVideoPreview(bool isMuted) {
    final c = _activeController;
    final isInit = c != null && c.value.isInitialized;

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
                  // Video or placeholder
                  if (isInit)
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

                  // Muted badge
                  if (isMuted)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: () {
                          final studio = context.read<StudioCubit>();
                          studio.toggleMute();
                          for (final ctrl in _controllers.values) {
                            ctrl.setVolume(studio.isMuted ? 0.0 : 1.0);
                          }
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
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Play overlay
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
                          border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                      ),
                    ),
                  ),

                  // Clip counter badge
                  if (_clipNotifier.clips.length > 1)
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Clip ${_activePlayingIndex + 1}/${_clipNotifier.clips.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
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

  // ─── Playback Controls ─────────────────────────────────────────────────────
  Widget _buildControls(int posMs, int totalMs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(color: Colors.white12, shape: BoxShape.circle),
              child: Icon(
                _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const Spacer(),
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
          _SmallBtn(icon: Icons.undo_rounded, onTap: () {}),
          const SizedBox(width: 10),
          _SmallBtn(icon: Icons.redo_rounded, onTap: () {}),
        ],
      ),
    );
  }

  // ─── Multi-Video Timeline ──────────────────────────────────────────────────
  Widget _buildMultiTimeline(String? music) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Video multi-clip timeline
        MultiVideoTimeline(
          notifier: _clipNotifier,
          globalPositionMs: _globalPositionMs,
          onGlobalSeek: _onGlobalSeek,
          onAddVideo: _addVideo,
          onClipSelected: _selectClip,
          onClipRemoved: _removeClip,
          onTrimChanged: _onTrimChanged,
          isPlaying: _playing,
        ),

        const SizedBox(height: 5),

        // Music track row (unchanged)
        GestureDetector(
          onTap: () => _onToolbarAction('music'),
          child: _MusicTrackStrip(music: music),
        ),
      ],
    );
  }

  // ─── Bottom Toolbar ────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    final studio = context.watch<StudioCubit>();
    final isMuted = studio.isMuted;

    final items = [
      const _BarItem(id: 'crop', icon: Icons.crop_rounded, label: 'Crop'),
      _BarItem(
        id: 'mute',
        icon: isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
        label: isMuted ? 'Muted' : 'Mute',
      ),
      const _BarItem(id: 'music', icon: Icons.music_note_rounded, label: 'Music'),
    ];

    return Container(
      color: const Color(0xFF000000),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items.map((item) {
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
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.purple, width: 1.2),
                    ),
                    child: Icon(item.icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.label,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
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
// Music Track Strip
// ─────────────────────────────────────────────────────────────────────────────
class _MusicTrackStrip extends StatelessWidget {
  const _MusicTrackStrip({required this.music});
  final String? music;

  @override
  Widget build(BuildContext context) {
    final hasMusic = music != null && music!.isNotEmpty;
    final trackColor = hasMusic ? const Color(0xFF381447) : const Color(0xFF22162E);
    final accentColor = hasMusic ? const Color(0xFFAB47BC) : const Color(0xFF6B477D);

    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor, width: 1.2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(Icons.music_note_rounded, color: hasMusic ? AppColors.purple : Colors.white54, size: 16),
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
                (i) => Container(
                  width: 2,
                  height: (i % 3 == 0 ? 18 : (i % 2 == 0 ? 10 : 20)).toDouble(),
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
    );
  }
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
        child: Icon(icon, color: filled ? Colors.black : Colors.white, size: size),
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

// ─────────────────────────────────────────────────────────────────────────────
// Full-Screen Select Draft to Merge Page
// ─────────────────────────────────────────────────────────────────────────────
class SelectDraftToMergeScreen extends StatelessWidget {
  const SelectDraftToMergeScreen({
    super.key,
    required this.currentTimelineClipCount,
  });

  final int currentTimelineClipCount;

  void _onSelectDraft(BuildContext context, Map<String, dynamic> draft) {
    int draftClipsCount = 1;
    if (draft['mergedClipPaths'] is List && (draft['mergedClipPaths'] as List).isNotEmpty) {
      draftClipsCount = (draft['mergedClipPaths'] as List).length;
    }

    final availableSlots = 10 - currentTimelineClipCount;

    if (draftClipsCount > availableSlots) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You can add up to 10 clips. This draft contains $draftClipsCount clip${draftClipsCount > 1 ? "s" : ""}, but only $availableSlots slot${availableSlots == 1 ? "" : "s"} ${availableSlots == 1 ? "is" : "are"} available.',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    Navigator.of(context).pop(draft);
  }

  @override
  Widget build(BuildContext context) {
    final studio = context.watch<StudioCubit>();
    final drafts = studio.state.drafts;
    final isLoading = studio.state.isLoadingDrafts;

    return Scaffold(
      backgroundColor: const Color(0xFF111113),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111113),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Draft to Merge',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Tap any draft to add its clip(s) to timeline',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(color: Colors.white12, height: 1.0),
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
              )
            : drafts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.movie_creation_outlined,
                          size: 56,
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No drafts available',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Recorded videos saved as drafts will appear here',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: drafts.length,
                    itemBuilder: (context, index) {
                      final draft = drafts[index];
                      final title = (draft['title'] as String?) ??
                          (draft['challengeTitle'] as String?) ??
                          'Studio Draft';
                      final duration = (draft['duration'] as String?) ?? '0:15';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C26),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.play_circle_fill_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                          title: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter',
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Duration: $duration',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                          trailing: ElevatedButton.icon(
                            onPressed: () => _onSelectDraft(context, draft),
                            icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                            label: const Text(
                              'Add',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Inter',
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B5CF6),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                          ),
                          onTap: () => _onSelectDraft(context, draft),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

