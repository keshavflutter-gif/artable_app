import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/routes/app_routes.dart';
import 'package:artable_app/data/datasources/music_api_service.dart';
import 'package:artable_app/core/utils/reel_helpers.dart';
import 'package:artable_app/core/utils/studio_video_player_utils.dart';
import 'package:artable_app/features/studio/presentation/bloc/studio_cubit.dart';
import 'package:artable_app/features/studio/data/services/studio_music_playback_service.dart';
import 'package:artable_app/features/studio/presentation/widgets/video_crop_sheet.dart';
import 'package:artable_app/features/studio/presentation/widgets/video_speed_sheet.dart';
import 'package:artable_app/features/studio/presentation/widgets/video_trimmer_sheet.dart';
import 'package:artable_app/features/studio/presentation/widgets/editor_clip.dart';
import 'package:artable_app/features/studio/presentation/widgets/multi_video_timeline.dart';
import 'package:artable_app/features/studio/presentation/screens/studio_drafts_screen.dart';
import 'package:artable_app/core/widgets/app_image.dart';
import 'package:artable_app/features/studio/data/services/video_thumbnail_generator.dart';
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
  /// Ignore auto-advance briefly after play/seek so stale end positions don't stop playback.
  DateTime? _ignoreAdvanceUntil;

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

  // ── Unconfirmed edit tracking (revert on back/cancel) ─────────────────────
  late StudioCubit _studio;
  List<String>? _initialMergedClipPaths;
  List<double>? _initialMergedClipDurations;
  String _initialRecordedDuration = '0:15';
  double _initialVideoTrimStart = 0.0;
  double? _initialVideoTrimEnd;
  String? _initialRecordedVideoPath;
  FreeToUseTrack? _initialSelectedTrack;
  String? _initialSelectedMusic;
  double _initialMusicStartSeconds = 0.0;
  double _initialMusicCropDuration = 30.0;
  bool _initialIsMuted = false;
  String _initialSelectedSpeed = '1x';
  bool _confirmedChanges = false;
  bool _alreadyReverted = false;

  @override
  void initState() {
    super.initState();
    unawaited(WakelockPlus.enable());
    _studio = context.read<StudioCubit>();
    _initialMergedClipPaths = _studio.state.mergedClipPaths != null
        ? List<String>.from(_studio.state.mergedClipPaths!)
        : null;
    _initialMergedClipDurations = _studio.state.mergedClipDurations != null
        ? List<double>.from(_studio.state.mergedClipDurations!)
        : null;
    _initialRecordedDuration = _studio.state.recordedDuration;
    _initialVideoTrimStart = _studio.state.videoTrimStartSeconds;
    _initialVideoTrimEnd = _studio.state.videoTrimEndSeconds;
    _initialRecordedVideoPath = _studio.state.recordedVideoPath;
    _initialSelectedTrack = _studio.state.selectedTrack;
    _initialSelectedMusic = _studio.state.selectedMusic;
    _initialMusicStartSeconds = _studio.state.musicStartSeconds;
    _initialMusicCropDuration = _studio.state.musicCropDuration;
    _initialIsMuted = _studio.state.isMuted;
    _initialSelectedSpeed = _studio.state.selectedSpeed;
    _confirmedChanges = false;
    _alreadyReverted = false;
    _initAllClips();
  }

  void _revertChangesIfNotConfirmed() {
    if (_confirmedChanges || _alreadyReverted) return;
    _alreadyReverted = true;
    _studio.setMergedClipPaths(_initialMergedClipPaths, _initialMergedClipDurations);
    _studio.setRecordedDuration(_initialRecordedDuration);
    if (_initialVideoTrimEnd != null) {
      _studio.setVideoTrimRange(
        start: _initialVideoTrimStart,
        end: _initialVideoTrimEnd!,
        formattedDuration: _initialRecordedDuration,
      );
    }
    if (_initialRecordedVideoPath != null) {
      _studio.setRecordedVideoPath(
        _initialRecordedVideoPath,
        mergedClipPaths: _initialMergedClipPaths,
        clearMergedClips: _initialMergedClipPaths == null || _initialMergedClipPaths!.isEmpty,
      );
    }
    // Revert unconfirmed music changes
    if (_initialSelectedTrack != null) {
      _studio.setSelectedTrack(
        _initialSelectedTrack,
        start: _initialMusicStartSeconds,
        duration: _initialMusicCropDuration,
      );
    } else if (_initialSelectedMusic != null && _initialSelectedMusic!.isNotEmpty) {
      _studio.setSelectedMusic(_initialSelectedMusic);
      _studio.updateMusicCrop(_initialMusicStartSeconds, _initialMusicCropDuration);
    } else {
      _studio.setSelectedTrack(null);
    }
    _studio.setMuted(_initialIsMuted);
    _studio.setSpeed(_initialSelectedSpeed);
    final revertSpeedMultiplier = _studio.speedMultiplier;
    for (final c in _controllers.values) {
      if (c.value.isInitialized) {
        try {
          c.setPlaybackSpeed(revertSpeedMultiplier);
        } catch (_) {}
      }
    }
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
    final oldControllers = Map<String, VideoPlayerController>.from(_controllers);
    _controllers.clear();

    for (final c in oldControllers.values) {
      try {
        c.removeListener(_onVideoUpdate);
        await c.pause();
        await c.dispose();
      } catch (_) {}
    }

    if (!mounted) return;
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
    if (_mergedClipPaths.isNotEmpty) {
      for (final p in _mergedClipPaths) {
        final clean = p.trim();
        if (clean.isNotEmpty) {
          finalPaths.add(clean);
        }
      }
    } else {
      if (hasRec) {
        finalPaths.add(recPath);
      } else if (combinedPath != null && combinedPath.trim().isNotEmpty && !finalPaths.contains(combinedPath.trim())) {
        finalPaths.add(combinedPath.trim());
      }
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

    // Immediately populate timeline & UI so the screen layout appears with 0 delay!
    _clipNotifier.setClips(clips, selectedIndex: 0);
    _activePlayingIndex = 0;
    _prewarmThumbnails(clips);

    // ── 1. Fast path: Initialize first clip for immediate video preview ────────
    final firstClip = clips.first;
    final firstController = await _initController(firstClip.filePath);

    if (!mounted) {
      await firstController?.dispose();
      return;
    }

    if (firstController != null && firstController.value.isInitialized) {
      final realDur = firstController.value.duration;
      final durMs = realDur.inMilliseconds > 0 ? realDur.inMilliseconds : firstClip.originalDuration.inMilliseconds;

      // Restore trim for first clip if valid
      final startMs = (studio.state.videoTrimStartSeconds * 1000).round();
      final endMs = studio.state.videoTrimEndSeconds != null
          ? (studio.state.videoTrimEndSeconds! * 1000).round()
          : durMs;
      final trimLooksValid = durMs > 500 &&
          endMs > startMs + 400 &&
          endMs <= durMs + 250 &&
          startMs >= 0 &&
          startMs < durMs;

      final safeStart = trimLooksValid ? startMs.clamp(0, durMs > 400 ? durMs - 400 : 0) : 0;
      final safeEnd = trimLooksValid ? endMs.clamp(1, durMs) : durMs;

      final updatedFirst = firstClip.copyWith(
        originalDuration: realDur > Duration.zero ? realDur : firstClip.originalDuration,
        trimStart: Duration(milliseconds: safeStart),
        trimEnd: Duration(milliseconds: safeEnd),
      );
      clips[0] = updatedFirst;
      _clipNotifier.setClips(clips, selectedIndex: 0);
      _controllers[updatedFirst.id] = firstController;

      firstController.addListener(_onVideoUpdate);
      await _seekClipToTrimStart(0);

      // Music + original audio = echo; keep clips muted when BGM is selected.
      final shouldMute = studio.isMuted ||
          studio.selectedMusic != null ||
          studio.selectedTrack != null;
      if (shouldMute && !studio.isMuted) {
        studio.setMuted(true);
      }
      await _applyOriginalAudioMute(shouldMute);

      // Instantly show the screen!
      if (mounted) {
        setState(() {
          _isLoading = false;
          _videoError = false;
        });
      }
      _startPlaybackTimer();
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _videoError = true;
        });
      }
    }

    // ── 2. Parallel background initialization for remaining clips ────────────
    _syncClipsToStudioCubit();
    if (clips.length > 1) {
      final remaining = clips.sublist(1);
      unawaited(_loadRemainingClips(remaining));
    }
  }

  void _syncClipsToStudioCubit() {
    final clips = _clipNotifier.clips;
    if (clips.isEmpty || !mounted) return;
    final studio = context.read<StudioCubit>();
    final mergedPaths = clips.map((c) => c.filePath.trim()).toList();
    final mergedDurations = clips.map((c) => c.trimmedDuration.inMilliseconds / 1000.0).toList();
    final totalDur = _clipNotifier.totalTrimmedDuration;
    final formattedDur = _fmtDuration(totalDur);
    studio.setMergedClipPaths(mergedPaths, mergedDurations);
    studio.setRecordedDuration(formattedDur);
  }

  Future<void> _loadRemainingClips(List<EditorClip> remaining) async {
    await Future.wait(remaining.map((clip) async {
      try {
        final controller = await _initController(clip.filePath);
        if (controller != null && controller.value.isInitialized && mounted) {
          final realDur = controller.value.duration;
          _controllers[clip.id] = controller;
          if (realDur > Duration.zero && realDur != clip.originalDuration) {
            _clipNotifier.updateClipDuration(clip.id, realDur);
          }
          if (mounted) setState(() {});
        }
      } catch (e) {
        debugPrint('Error loading remaining clip ${clip.id}: $e');
      }
    }));
    if (mounted) {
      _syncClipsToStudioCubit();
      final studio = context.read<StudioCubit>();
      final hasBgm = studio.selectedMusic != null || studio.selectedTrack != null;
      if (hasBgm || studio.isMuted) {
        await _applyOriginalAudioMute(true);
      }
    }
  }

  void _prewarmThumbnails(List<EditorClip> clips) {
    for (final clip in clips) {
      final p = clip.filePath.trim().replaceFirst('file://', '');
      if (p.isNotEmpty) {
        VideoThumbnailGenerator.generateThumbnailFromVideo(p).then((file) {
          if (file != null && file.existsSync()) {
            file.readAsBytes().then((bytes) {
              if (bytes.isNotEmpty) {
                AppImage.cacheThumbnail(clip.filePath, bytes);
                AppImage.cacheThumbnail(p, bytes);
                AppImage.cacheThumbnail(file.path, bytes);
              }
            }).catchError((_) {});
          }
        }).catchError((_) {});
      }
    }
  }

  EditorClip _makeEditorClip(String path, Duration hintDuration) {
    final studio = context.read<StudioCubit>();
    String? thumbPath = (path == studio.recordedVideoPath || path == studio.state.recordedVideoPath)
        ? studio.state.selectedThumbnailPath
        : null;
    return EditorClip(
      id: '${path.hashCode}_${DateTime.now().microsecondsSinceEpoch}',
      filePath: path,
      originalDuration: hintDuration,
      trimStart: Duration.zero,
      trimEnd: hintDuration,
      thumbnailPath: thumbPath,
    );
  }

  Future<VideoPlayerController?> _initController(String path) async {
    try {
      // Fast path: try lightweight clip controller first (no file locking wait loops)
      var controller = await StudioVideoPlayerUtils.initializeClipController(
        path,
        loop: false,
        autoPlay: false,
      );
      if (controller == null || !controller.value.isInitialized) {
        controller = await StudioVideoPlayerUtils.initializeRecordedVideo(
          path,
          loop: false,
          autoPlay: false,
        );
      }
      if (controller != null && controller.value.isInitialized) {
        await controller.setLooping(false);
        if (!mounted) return controller;
        final studio = context.read<StudioCubit>();
        try {
          await controller.setPlaybackSpeed(studio.speedMultiplier);
        } catch (_) {}
        final hasBgm = studio.selectedMusic != null || studio.selectedTrack != null;
        if (studio.isMuted || hasBgm) {
          await controller.setVolume(0.0);
        }
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
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 20), (_) {
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

      // Auto-advance scaled by playback speed so high speeds (0.4x - 4.0x) never stutter or freeze
      final studio = context.read<StudioCubit>();
      final speed = studio.speedMultiplier.clamp(0.4, 4.0);
      final ignoreAdvance = _ignoreAdvanceUntil != null &&
          DateTime.now().isBefore(_ignoreAdvanceUntil!);
      final progressThreshold = (60 * speed).clamp(30, 160).round();
      final progressed = posMs > trimStartMs + progressThreshold;
      final leadMargin = (55 * speed).clamp(40, 220).round();
      final isNearEnd = progressed && posMs >= trimEndMs - leadMargin;
      final isCompleted = controller.value.isCompleted;
      final naturalEos = progressed &&
          !controller.value.isPlaying &&
          posMs >= trimEndMs - (leadMargin + 60);
      if (_playing &&
          !_isSwitchingClip &&
          !ignoreAdvance &&
          (isNearEnd || naturalEos || isCompleted)) {
        _advanceToNextClip();
      }
    }

    // Music sync (only during steady playback, never during clip transition)
    if (_playing && !_isSwitchingClip) {
      final ignoreSync = _ignoreAdvanceUntil != null &&
          DateTime.now().isBefore(_ignoreAdvanceUntil!);
      if (!ignoreSync) {
        final studio = context.read<StudioCubit>();
        if (studio.selectedMusic != null || studio.selectedTrack != null) {
          StudioMusicPlaybackService.checkAndSyncVideoPosition(studio, _globalPositionMs);
        }
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
      unawaited(oldController.pause());
    }

    final nextIndex = oldIndex + 1;

    if (nextIndex >= clips.length) {
      // Reached the end of full video sequence -> loop back to clip 0!
      if (!mounted) {
        _isSwitchingClip = false;
        return;
      }
      final studio = context.read<StudioCubit>();
      _activePlayingIndex = 0;
      _clipNotifier.selectClip(0);
      _globalPositionMs = 0;
      final firstClip = clips[0];
      var firstController = _controllers[firstClip.id];
      if (firstController == null || !firstController.value.isInitialized) {
        firstController = await _initController(firstClip.filePath);
        if (firstController != null && mounted) {
          _controllers[firstClip.id] = firstController;
        }
      }
      if (firstController != null && firstController.value.isInitialized) {
        final currentPos = firstController.value.position;
        final diff = (currentPos - firstClip.trimStart).inMilliseconds.abs();
        if (diff > 80) {
          await firstController.seekTo(firstClip.trimStart);
        }
        firstController.removeListener(_onVideoUpdate);
        firstController.addListener(_onVideoUpdate);
        final ignoreMs = (180 / studio.speedMultiplier).clamp(40, 200).round();
        _ignoreAdvanceUntil =
            DateTime.now().add(Duration(milliseconds: ignoreMs));
        final hasBgm = studio.selectedMusic != null || studio.selectedTrack != null;
        if (hasBgm || studio.isMuted) {
          await firstController.setVolume(0.0);
        }
        try {
          await firstController.setPlaybackSpeed(studio.speedMultiplier.clamp(0.4, 4.0));
        } catch (_) {}
        unawaited(firstController.play());
        if (hasBgm) {
          await StudioMusicPlaybackService.playForEditor(studio, 0);
        }
      }
      if (mounted) setState(() {});
      // Pre-seek upcoming clip in background
      if (clips.length > 1) {
        unawaited(_seekClipToTrimStart(1));
      }
    } else {
      if (!mounted) {
        _isSwitchingClip = false;
        return;
      }
      final studio = context.read<StudioCubit>();
      _activePlayingIndex = nextIndex;
      _clipNotifier.selectClip(nextIndex);

      int nextAccMs = 0;
      for (int i = 0; i < nextIndex; i++) {
        nextAccMs += clips[i].trimmedDuration.inMilliseconds;
      }
      _globalPositionMs = nextAccMs;

      final nextClip = clips[nextIndex];
      var nextController = _controllers[nextClip.id];
      if (nextController == null || !nextController.value.isInitialized) {
        nextController = await _initController(nextClip.filePath);
        if (nextController != null && mounted) {
          _controllers[nextClip.id] = nextController;
        }
      }
      if (nextController == null || !nextController.value.isInitialized) {
        _isSwitchingClip = false;
        return;
      }
      final currentPos = nextController.value.position;
      final diff = (currentPos - nextClip.trimStart).inMilliseconds.abs();
      if (diff > 80) {
        await nextController.seekTo(nextClip.trimStart);
      }
      nextController.removeListener(_onVideoUpdate);
      nextController.addListener(_onVideoUpdate);
      final ignoreMs = (180 / studio.speedMultiplier).clamp(40, 200).round();
      _ignoreAdvanceUntil =
          DateTime.now().add(Duration(milliseconds: ignoreMs));

      final hasBgm = studio.selectedMusic != null || studio.selectedTrack != null;
      if (hasBgm || studio.isMuted) {
        await nextController.setVolume(0.0);
      }
      try {
        await nextController.setPlaybackSpeed(studio.speedMultiplier.clamp(0.4, 4.0));
      } catch (_) {}
      unawaited(nextController.play());
      if (hasBgm) {
        // If music stopped for any reason, resume it; otherwise let it play smoothly without interruption
        if (!StudioMusicPlaybackService.isPlaying) {
          await StudioMusicPlaybackService.playForEditor(
            studio,
            _globalPositionMs,
          );
        }
      }
      if (mounted) setState(() {});

      // Pre-seek upcoming clip in background for instant transition
      final upcoming = (nextIndex + 1) % clips.length;
      unawaited(_seekClipToTrimStart(upcoming));
      final upCtrl = _controllers[clips[upcoming].id];
      if (upCtrl != null && upCtrl.value.isInitialized) {
        try {
          unawaited(upCtrl.setPlaybackSpeed(studio.speedMultiplier.clamp(0.4, 4.0)));
        } catch (_) {}
      }
      // Also reset old clip position for future loop in background
      unawaited(_seekClipToTrimStart(oldIndex));
    }

    _isSwitchingClip = false;
  }

  Future<void> _seekClipToTrimStart(int clipIndex) async {
    final clips = _clipNotifier.clips;
    if (clipIndex >= clips.length) return;
    final clip = clips[clipIndex];
    var controller = _controllers[clip.id];
    if (controller == null) {
      controller = await _initController(clip.filePath);
      if (controller != null && mounted) {
        _controllers[clip.id] = controller;
      }
    }
    if (controller != null && controller.value.isInitialized) {
      if (!mounted) return;
      final studio = _studio;
      try {
        unawaited(controller.setPlaybackSpeed(studio.speedMultiplier.clamp(0.4, 4.0)));
      } catch (_) {}
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
      final hasBgm = studio.selectedMusic != null || studio.selectedTrack != null;
      if (activeController != null) {
        final speed = studio.speedMultiplier.clamp(0.4, 4.0);
        final posMs = activeController.value.position.inMilliseconds;
        final trimEndMs = activeClip.trimEnd.inMilliseconds;
        final trimStartMs = activeClip.trimStart.inMilliseconds;
        final restartMargin = (100 * speed).clamp(80, 300).round();
        // Restart this clip if finished; don't auto-jump to next on play tap.
        if (posMs >= trimEndMs - restartMargin || posMs < trimStartMs) {
          await _seekClipToTrimStart(_activePlayingIndex);
        }
        activeController.removeListener(_onVideoUpdate);
        activeController.addListener(_onVideoUpdate);
        final ignoreMs = (180 / speed).clamp(40, 200).round();
        _ignoreAdvanceUntil =
            DateTime.now().add(Duration(milliseconds: ignoreMs));
        try {
          await activeController.setPlaybackSpeed(speed);
        } catch (_) {}
        unawaited(activeController.play());
        // Re-apply after play — keep muted under BGM so it does not echo.
        await _applyOriginalAudioMute(studio.isMuted || hasBgm);
      }

      if (hasBgm) {
        await StudioMusicPlaybackService.playForEditor(studio, _globalPositionMs);
        await _applyOriginalAudioMute(true);
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
    final existingPaths = _clipNotifier.clips
        .map((c) => c.filePath.trim().replaceFirst('file://', ''))
        .where((p) => p.isNotEmpty)
        .toSet();

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
      final clean = p.trim().replaceFirst('file://', '');
      if (clean.isNotEmpty && !existingPaths.contains(clean)) {
        pathsToAdd.add(p.trim());
      }
    }

    if (pathsToAdd.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selected video is already in the timeline.'),
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
      _syncClipsToStudioCubit();
      _prewarmThumbnails(_clipNotifier.clips);
      final studio = context.read<StudioCubit>();
      final hasBgm = studio.selectedMusic != null || studio.selectedTrack != null;
      if (hasBgm || studio.isMuted) {
        await _applyOriginalAudioMute(true);
      }
      if (!mounted) return;
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
    _syncClipsToStudioCubit();

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
    _syncClipsToStudioCubit();
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
    if (!mounted) return;
    setState(() => _playing = false);

    switch (id) {
      case 'crop':
        if (!mounted) return;
        VideoCropSheet.show(context);
        break;

      case 'trim':
        if (!mounted) return;
        final activeCtrl = _activeController;
        await VideoTrimmerSheet.show(
          context,
          videoController: activeCtrl,
        );
        if (mounted && _clipNotifier.clips.isNotEmpty) {
          final studioCubit = context.read<StudioCubit>();
          final trimStartSec = studioCubit.state.videoTrimStartSeconds;
          final trimEndSec = studioCubit.state.videoTrimEndSeconds;
          if (trimEndSec != null && trimEndSec > trimStartSec) {
            final activeIndex = _activePlayingIndex.clamp(0, _clipNotifier.clips.length - 1);
            _clipNotifier.updateTrim(
              activeIndex,
              Duration(milliseconds: (trimStartSec * 1000).round()),
              Duration(milliseconds: (trimEndSec * 1000).round()),
            );
            _syncClipsToStudioCubit();
            await _seekClipToTrimStart(activeIndex);
            setState(() {});
          }
        }
        break;

      case 'speed':
        if (!mounted) return;
        VideoSpeedSheet.show(
          context,
          onSpeedChanged: (speedStr, multiplier) async {
            if (!mounted) return;
            final speed = multiplier.clamp(0.4, 4.0);
            for (final c in _controllers.values) {
              if (c.value.isInitialized) {
                try {
                  await c.setPlaybackSpeed(speed);
                } catch (_) {}
              }
            }
            try {
              await StudioMusicPlaybackService.setPlaybackSpeed(speed);
            } catch (_) {}
            if (mounted) setState(() {});
          },
        );
        break;

      case 'mute':
        await _toggleOriginalAudioMute(showSnack: true);
        break;

      case 'music':
        // Synchronize all editor clips & full duration to StudioCubit before opening music picker
        final clips = _clipNotifier.clips;
        if (clips.isNotEmpty) {
          final studio = context.read<StudioCubit>();
          final mergedPaths = clips.map((c) => c.filePath.trim()).toList();
          final mergedDurations = clips.map((c) => c.trimmedDuration.inMilliseconds / 1000.0).toList();
          final totalDur = _clipNotifier.totalTrimmedDuration;
          final formattedDur = _fmtDuration(totalDur);
          studio.setMergedClipPaths(mergedPaths, mergedDurations);
          studio.setRecordedDuration(formattedDur);
        }

        final cid = widget.challengeId ?? 'c1';
        final dp = widget.draftId != null ? '&draft=${widget.draftId}' : '';
        if (!mounted) return;
        await context.push('${AppRoutes.studioMusic}?id=$cid$dp');
        if (!mounted) return;
        final studio = context.read<StudioCubit>();
        StudioMusicPlaybackService.invalidateLoadedTrack();
        if (studio.selectedMusic != null || studio.selectedTrack != null) {
          try {
            // Music + original clip audio together causes an echo — mute clips.
            if (!studio.isMuted) {
              studio.setMuted(true);
            }
            await _applyOriginalAudioMute(true);
            await StudioMusicPlaybackService.preloadForStudio(studio);

            // If at end of sequence, rewind to start
            if (_globalPositionMs >= _clipNotifier.totalTrimmedDuration.inMilliseconds - 100) {
              _activePlayingIndex = 0;
              _clipNotifier.selectClip(0);
              _globalPositionMs = 0;
              await _seekClipToTrimStart(0);
            }

            final activeClip = _clipNotifier.clips.isNotEmpty
                ? _clipNotifier.clips[
                    _activePlayingIndex.clamp(0, _clipNotifier.clips.length - 1)]
                : null;
            final c =
                activeClip != null ? _controllers[activeClip.id] : null;
            if (c != null && c.value.isInitialized) {
              _ignoreAdvanceUntil =
                  DateTime.now().add(const Duration(milliseconds: 500));
              await c.play();
              await _applyOriginalAudioMute(true);
              await StudioMusicPlaybackService.playForEditor(
                studio,
                _globalPositionMs,
              );
              if (mounted) setState(() => _playing = true);
            }
          } catch (e) {
            debugPrint('Music reload after picker failed: $e');
          }
        } else {
          await StudioMusicPlaybackService.stop();
        }
        if (mounted) setState(() {});
        break;

      case 'retake':
        for (final c in _controllers.values) {
          await c.pause();
        }
        await StudioMusicPlaybackService.stop();
        _revertChangesIfNotConfirmed();
        if (!mounted) return;
        final cid = _challenge['id'] ?? widget.challengeId ?? 'c1';
        if (context.canPop()) {
          context.pop();
        } else {
          context.pushReplacement('${AppRoutes.studioCamera}?id=$cid');
        }
        break;
    }
  }

  Future<void> _removeSelectedMusic() async {
    await StudioMusicPlaybackService.stop();
    _studio.setSelectedTrack(null);
    await _applyOriginalAudioMute(false);
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Music removed'),
          duration: Duration(seconds: 1),
          backgroundColor: Color(0xFF2C2C2E),
        ),
      );
    }
  }

  Future<void> _toggleOriginalAudioMute({bool showSnack = false}) async {
    final studio = context.read<StudioCubit>();
    studio.toggleMute();
    final muted = studio.isMuted;
    await _applyOriginalAudioMute(muted);
    if (!mounted) return;
    setState(() {});
    if (!showSnack) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          muted
              ? 'Original video audio muted (no echo)'
              : 'Original video audio unmuted',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: muted ? Colors.deepOrange : const Color(0xFF8B5CF6),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Mutes/unmutes recorded clip audio only. Background music is unchanged.
  Future<void> _applyOriginalAudioMute(bool muted) async {
    final volume = muted ? 0.0 : 1.0;
    for (final ctrl in _controllers.values) {
      if (!ctrl.value.isInitialized) continue;
      try {
        await ctrl.setVolume(volume);
      } catch (_) {}
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Dispose
  // ─────────────────────────────────────────────────────────────────────────
  @override
  void dispose() {
    if (!_confirmedChanges) {
      _revertChangesIfNotConfirmed();
    }
    unawaited(WakelockPlus.disable());
    _playbackTimer?.cancel();
    final oldControllers = Map<String, VideoPlayerController>.from(_controllers);
    _controllers.clear();

    for (final c in oldControllers.values) {
      try {
        c.removeListener(_onVideoUpdate);
        c.pause();
        c.dispose();
      } catch (_) {}
    }
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

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!_confirmedChanges) {
          _revertChangesIfNotConfirmed();
        }
      },
      child: Scaffold(
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
    _confirmedChanges = true;

    try {
      // 1. Pause video controllers & music preview
      for (final c in _controllers.values) {
        await c.pause();
      }
      await StudioMusicPlaybackService.pause();
      if (mounted) setState(() => _playing = false);

      if (!mounted) return;
      // 2. Collect merged paths & clip durations
      final studio = context.read<StudioCubit>();
      final mergedPaths = clips.map((c) => c.filePath.trim()).toList();
      final mergedDurations = clips.map((c) => c.trimmedDuration.inMilliseconds / 1000.0).toList();
      final totalDur = _clipNotifier.totalTrimmedDuration;
      final formattedDur = _fmtDuration(totalDur);

      // 3. Save editor state to StudioCubit
      studio.setMergedClipPaths(mergedPaths, mergedDurations);
      studio.setRecordedDuration(formattedDur);

      // Skip slow Mp4 merge here — Details/Preview play clips as a playlist.
      // Actual file merge runs only on Upload.
      final finalEditedVideoPath = mergedPaths.first;
      debugPrint(
        'FINAL OUTPUT PATH (playlist, ${mergedPaths.length} clips): $finalEditedVideoPath',
      );
      studio.setRecordedVideoPath(
        finalEditedVideoPath,
        mergedClipPaths: mergedPaths.length > 1 ? mergedPaths : null,
        clearMergedClips: mergedPaths.length <= 1,
      );

      if (widget.draftId != null && _draft != null) {
        final updatedDraft = Map<String, dynamic>.from(_draft!);
        updatedDraft['videoPath'] = finalEditedVideoPath;
        updatedDraft['videoUrl'] = finalEditedVideoPath;
        updatedDraft['mergedClipPaths'] = mergedPaths;
        updatedDraft['mergedClipDurations'] = mergedDurations;
        updatedDraft['duration'] = formattedDur;
        studio.updateDraftMap(updatedDraft);
      }

      // Generate real frame thumbnail from edited video
      try {
        final thumbFile =
            await VideoThumbnailGenerator.generateThumbnailFromVideo(finalEditedVideoPath);
        if (thumbFile != null && await thumbFile.exists()) {
          studio.setSelectedThumbnailPath(thumbFile.path);
          final bytes = await thumbFile.readAsBytes();
          AppImage.cacheThumbnail(finalEditedVideoPath, bytes);
          AppImage.cacheThumbnail(thumbFile.path, bytes);
        }
      } catch (e) {
        debugPrint('Thumbnail generation warning on edit video next: $e');
      }

      if (!mounted) return;

      // 4. Navigate to StudioDetailsScreen (Video Details)
      final cid = _challenge['id'] ?? widget.challengeId ?? 'c1';
      final dp = widget.draftId != null ? '&draft=${widget.draftId}' : '';
      await context.push('${AppRoutes.studioDetails}?id=$cid$dp');
    } catch (e) {
      _confirmedChanges = false;
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
              _revertChangesIfNotConfirmed();
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
                          child: VideoPlayer(
                            key: ValueKey(c),
                            c,
                          ),
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
                        onTap: () => unawaited(_toggleOriginalAudioMute()),
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
          child: _MusicTrackStrip(
            music: music,
            onRemove: _removeSelectedMusic,
          ),
        ),
      ],
    );
  }

  // ─── Bottom Toolbar ────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    final studio = context.watch<StudioCubit>();
    final isMuted = studio.isMuted;
    final currentSpeed = studio.state.selectedSpeed;
    final isCustomSpeed = currentSpeed != '1x' && currentSpeed != '1.0x';

    final items = [
      const _BarItem(id: 'crop', icon: Icons.crop_rounded, label: 'Crop'),
      const _BarItem(id: 'trim', icon: Icons.content_cut_rounded, label: 'Trim'),
      _BarItem(
        id: 'speed',
        icon: Icons.speed_rounded,
        label: isCustomSpeed ? currentSpeed : 'Speed',
        isActive: isCustomSpeed,
      ),
      _BarItem(
        id: 'mute',
        icon: isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
        label: isMuted ? 'Muted' : 'Mute',
        isActive: isMuted,
      ),
      const _BarItem(id: 'music', icon: Icons.music_note_rounded, label: 'Music'),
      const _BarItem(id: 'retake', icon: Icons.refresh_rounded, label: 'Retake'),
    ];

    return Container(
      color: const Color(0xFF000000),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: MediaQuery.sizeOf(context).width),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () => _onToolbarAction(item.id),
                  child: SizedBox(
                    width: 58,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: item.isActive
                                ? AppColors.purple.withValues(alpha: 0.25)
                                : const Color(0xFF1C1C1E),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: item.isActive
                                  ? AppColors.purple
                                  : AppColors.purple.withValues(alpha: 0.7),
                              width: item.isActive ? 1.8 : 1.2,
                            ),
                          ),
                          child: Icon(
                            item.icon,
                            color: item.isActive ? Colors.white : Colors.white70,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: item.isActive ? AppColors.purple : Colors.white70,
                            fontSize: 11.5,
                            fontFamily: 'Inter',
                            fontWeight: item.isActive ? FontWeight.w600 : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private data class for bottom bar
// ─────────────────────────────────────────────────────────────────────────────
class _BarItem {
  const _BarItem({
    required this.id,
    required this.icon,
    required this.label,
    this.isActive = false,
  });
  final String id;
  final IconData icon;
  final String label;
  final bool isActive;
}

// ─────────────────────────────────────────────────────────────────────────────
// Music Track Strip
// ─────────────────────────────────────────────────────────────────────────────
class _MusicTrackStrip extends StatelessWidget {
  const _MusicTrackStrip({
    required this.music,
    this.onRemove,
  });
  final String? music;
  final VoidCallback? onRemove;

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
          if (hasMusic) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                6,
                (i) => Container(
                  width: 2,
                  height: (i % 3 == 0 ? 16 : (i % 2 == 0 ? 9 : 18)).toDouble(),
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white12,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white70,
                  size: 15,
                ),
              ),
            ),
          ],
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

