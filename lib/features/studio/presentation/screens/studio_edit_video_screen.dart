import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/routes/app_routes.dart';
import 'package:artable_app/data/datasources/music_api_service.dart';
import 'package:artable_app/core/utils/reel_helpers.dart';
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
import 'package:artable_app/core/utils/media_url_utils.dart';
import 'package:artable_app/core/utils/app_filter_utils.dart';
import 'package:artable_app/core/utils/studio_video_player_utils.dart';
import 'package:artable_app/core/utils/validators.dart';

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

class _StudioEditVideoScreenState extends State<StudioEditVideoScreen>
    with WidgetsBindingObserver {
  // ── Clip state ─────────────────────────────────────────────────────────────
  final EditorClipListNotifier _clipNotifier = EditorClipListNotifier();

  // ── Per-clip VideoPlayerControllers (indexed by EditorClip.id) ────────────
  final Map<String, VideoPlayerController> _controllers = {};

  // ── Playback state ─────────────────────────────────────────────────────────
  bool _playing = false;
  int _playEpoch = 0;
  bool _suppressPauseGuard = false;
  bool _isLoading = true;
  bool _videoError = false;
  bool _videoFrameReady = false;
  /// Ignore auto-advance briefly after play/seek so stale end positions don't stop playback.
  DateTime? _ignoreAdvanceUntil;

  /// Global position in ms (sum of all previous trimmed clips + current pos in active clip)
  int _globalPositionMs = 0;
  final ValueNotifier<int> _positionNotifier = ValueNotifier<int>(0);

  void _setPosition(int ms, {bool rebuild = false}) {
    _globalPositionMs = ms;
    if (_positionNotifier.value != ms) {
      _positionNotifier.value = ms;
    }
    if (rebuild && mounted) setState(() {});
  }

  /// Which clip is actively playing/previewing
  int _activePlayingIndex = 0;

  /// Timer for timeline progress tick + auto-advance
  Timer? _playbackTimer;

  /// Guard against concurrent clip switches
  bool _isSwitchingClip = false;
  DateTime? _lastVideoKickAt;
  int _stuckPosMs = -1;
  int _stuckTicks = 0;

  /// Guard against double tap navigation to details
  bool _isNavigating = false;

  /// Players were disposed so Video Details can open the same files.
  bool _awaitingPlayerRestore = false;
  bool _restoringPlayers = false;

  /// Guard and loader state while importing and mounting merged clips
  bool _isImportingClip = false;

  // ── Legacy compat (mergedClipPaths from draft/state) ──────────────────────
  List<String> _mergedClipPaths = [];
  List<double> _mergedClipDurations = [];
  List<String> _mergedClipFilterIds = [];
  List<String> _mergedClipThumbnails = [];

  // ── Unconfirmed edit tracking (revert on back/cancel) ─────────────────────
  late StudioCubit _studio;
  List<String>? _initialMergedClipPaths;
  List<double>? _initialMergedClipDurations;
  List<String>? _initialMergedClipFilterIds;
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
    WidgetsBinding.instance.addObserver(this);
    unawaited(WakelockPlus.enable());
    _studio = context.read<StudioCubit>();
    _initialMergedClipPaths = _studio.state.mergedClipPaths != null
        ? List<String>.from(_studio.state.mergedClipPaths!)
        : null;
    _initialMergedClipDurations = _studio.state.mergedClipDurations != null
        ? List<double>.from(_studio.state.mergedClipDurations!)
        : null;
    _initialMergedClipFilterIds = _studio.state.mergedClipFilterIds != null
        ? List<String>.from(_studio.state.mergedClipFilterIds!)
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
    final openingDraft = _draft;
    if (openingDraft != null) {
      _studio.applyDraftFilterToSession(openingDraft);
    }
    _initAllClips();
  }

  void _revertChangesIfNotConfirmed() {
    if (_confirmedChanges || _alreadyReverted) return;
    _alreadyReverted = true;
    _studio.setMergedClipPaths(
      _initialMergedClipPaths,
      _initialMergedClipDurations,
      _initialMergedClipFilterIds,
    );
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Android fires `inactive` during audio-focus / sheet transitions and was
    // pausing the editor while the user was still on this screen.
    final shouldPause = state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        (Platform.isIOS && state == AppLifecycleState.inactive);
    if (shouldPause) {
      unawaited(_pauseAllPlayback());
      unawaited(WakelockPlus.disable());
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
      _videoFrameReady = false;
      _playing = false;
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
      _mergedClipFilterIds = StudioCubit.clipFilterIdsOfDraft(
        draft,
        pathCount: _mergedClipPaths.isNotEmpty ? _mergedClipPaths.length : null,
      );
      _mergedClipThumbnails = (draft['mergedClipThumbnails'] is List)
          ? List<String>.from(draft['mergedClipThumbnails'] as List)
          : [];
    } else {
      _mergedClipPaths = studio.state.mergedClipPaths != null ? List<String>.from(studio.state.mergedClipPaths!) : [];
      _mergedClipDurations = studio.state.mergedClipDurations != null
          ? List<double>.from(studio.state.mergedClipDurations!)
          : [];
      _mergedClipFilterIds = studio.state.mergedClipFilterIds != null
          ? List<String>.from(studio.state.mergedClipFilterIds!)
          : [];
      _mergedClipThumbnails = [];
      for (final p in _mergedClipPaths) {
        _mergedClipThumbnails.add(studio.getThumbnailForClip(p) ?? '');
      }
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
      final rawPath = finalPaths[i];
      final resolved = MediaUrlUtils.resolve(rawPath).trim();
      final path = resolved.isNotEmpty ? resolved : rawPath;
      final hintDur = (i < _mergedClipDurations.length && _mergedClipDurations[i] > 0)
          ? Duration(milliseconds: (_mergedClipDurations[i] * 1000).round())
          : const Duration(seconds: 15);
      final draftThumb = i < _mergedClipThumbnails.length ? _mergedClipThumbnails[i] : null;
      clips.add(_makeEditorClip(
        path,
        hintDur,
        filterId: i < _mergedClipFilterIds.length
            ? _mergedClipFilterIds[i]
            : studio.recordingFilter,
        beautyOn: studio.recordingBeautyOn,
        beautyIntensity: studio.recordingBeautyIntensity,
        preferredThumbPath: (draftThumb != null && draftThumb.trim().isNotEmpty)
            ? draftThumb.trim()
            : null,
      ));
    }

    if (clips.isEmpty) {
      if (mounted) setState(() { _isLoading = false; _videoError = true; });
      return;
    }

    // Immediately populate timeline & UI so the screen layout appears with 0 delay!
    _clipNotifier.setClips(clips, selectedIndex: 0);
    _activePlayingIndex = 0;

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

      final cleanVideo = firstClip.filePath.trim().replaceFirst('file://', '');
      Uint8List? initialThumb = firstClip.thumbnailBytes ??
          AppImage.getCachedThumbnail(firstClip.filePath) ??
          AppImage.getCachedThumbnail(cleanVideo);

      if (initialThumb == null) {
        final isCurrentRec = firstClip.filePath == studio.recordedVideoPath ||
            firstClip.filePath == studio.state.recordedVideoPath;
        final tp = firstClip.thumbnailPath ?? (isCurrentRec ? studio.state.selectedThumbnailPath : null);
        if (tp != null && tp.isNotEmpty && !tp.startsWith('http')) {
          try {
            final f = File(tp.replaceFirst('file://', ''));
            if (f.existsSync() && f.lengthSync() > 200) {
              initialThumb = f.readAsBytesSync();
            }
          } catch (_) {}
        }
      }

      if (initialThumb == null || initialThumb.isEmpty) {
        try {
          initialThumb = await VideoThumbnailGenerator.extractFrameBytes(
            cleanVideo,
            timeMs: safeStart,
            maxWidth: 360,
            maxHeight: 360,
            quality: 70,
          );
        } catch (_) {}
      }

      if (initialThumb != null && initialThumb.isNotEmpty) {
        AppImage.cacheThumbnail(firstClip.filePath, initialThumb);
        AppImage.cacheThumbnail(cleanVideo, initialThumb);
        if (mounted) {
          try {
            await precacheImage(MemoryImage(initialThumb), context);
          } catch (_) {}
        }
      }

      final updatedFirst = firstClip.copyWith(
        originalDuration: realDur > Duration.zero ? realDur : firstClip.originalDuration,
        trimStart: Duration(milliseconds: safeStart),
        trimEnd: Duration(milliseconds: safeEnd),
        thumbnailBytes: initialThumb,
      );
      clips[0] = updatedFirst;
      _clipNotifier.setClips(clips, selectedIndex: 0);
      _controllers[updatedFirst.id] = firstController;

      firstController.addListener(_onVideoUpdate);

      // Attach VideoPlayer first — play/pause before the surface exists leaves
      // ExoPlayer stuck on the first frame of a just-recorded clip.
      try {
        await firstController.seekTo(Duration(milliseconds: safeStart));
      } catch (_) {}

      await _applyOriginalAudioMute(studio.isMuted ||
          studio.selectedMusic != null ||
          studio.selectedTrack != null);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _videoError = false;
        });
      }

      final thumbsReady = Completer<void>();
      unawaited(VideoThumbnailGenerator.extractFilmstripFrames(
        cleanVideo,
        targetCount: 8,
        trimStart: Duration(milliseconds: safeStart),
        trimEnd: Duration(milliseconds: safeEnd),
        duration: realDur,
        cacheKeyExtra: updatedFirst.id,
        onPartial: (frames) {
          if (frames.length >= 2 && !thumbsReady.isCompleted) {
            thumbsReady.complete();
          }
          if (mounted) setState(() {});
        },
      ).then((frames) {
        if (!thumbsReady.isCompleted) thumbsReady.complete();
      }));
      await thumbsReady.future.timeout(
        const Duration(milliseconds: 2800),
        onTimeout: () {},
      );
      if (!mounted) return;
      if (mounted) setState(() {});

      _startPlaybackTimer();
      await _startPreviewPlayback();
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _videoError = true;
        });
      }
    }

    // ── 2. Background initialization of controllers for remaining clips ──────
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
    final mergedFilters = clips.map((c) => c.filterId).toList();
    final totalDur = _clipNotifier.totalTrimmedDuration;
    final formattedDur = _fmtDuration(totalDur);
    studio.setMergedClipPaths(mergedPaths, mergedDurations, mergedFilters);
    studio.setRecordedDuration(formattedDur);
  }

  Future<void> _loadRemainingClips(List<EditorClip> remaining) async {
    await Future.wait(remaining.map((clip) async {
      try {
        final controller = await _initController(clip.filePath);
        final realDur = (controller != null && controller.value.isInitialized)
            ? controller.value.duration
            : clip.originalDuration;
        if (controller != null && controller.value.isInitialized && mounted) {
          _controllers[clip.id] = controller;
        }

        if (mounted) {
          final updated = clip.copyWith(
            originalDuration: realDur > Duration.zero ? realDur : clip.originalDuration,
            trimEnd: realDur > Duration.zero ? realDur : clip.trimEnd,
          );
          _clipNotifier.updateClip(clip.id, updated);
          setState(() {});
          unawaited(VideoThumbnailGenerator.extractFilmstripFrames(
            clip.filePath,
            targetCount: 8,
            trimStart: updated.trimStart,
            trimEnd: updated.trimEnd,
            duration: updated.originalDuration,
            cacheKeyExtra: updated.id,
          ));
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

  EditorClip _makeEditorClip(
    String path,
    Duration hintDuration, {
    String? filterId,
    bool? beautyOn,
    double? beautyIntensity,
    String? preferredThumbPath,
  }) {
    final studio = context.read<StudioCubit>();
    String? thumbPath = preferredThumbPath;
    if (thumbPath == null || thumbPath.isEmpty) {
      thumbPath = studio.getThumbnailForClip(path);
    }
    if (thumbPath == null || thumbPath.isEmpty) {
      if (path == studio.recordedVideoPath || path == studio.state.recordedVideoPath) {
        thumbPath = studio.state.selectedThumbnailPath;
      }
    }
    if (thumbPath != null && thumbPath.isNotEmpty) {
      final resolvedThumb = MediaUrlUtils.resolve(thumbPath).trim();
      if (resolvedThumb.isNotEmpty) thumbPath = resolvedThumb;
    }
    Uint8List? cachedBytes = AppImage.getCachedThumbnail(path);
    if (cachedBytes == null &&
        thumbPath != null &&
        thumbPath.isNotEmpty &&
        !thumbPath.startsWith('http://') &&
        !thumbPath.startsWith('https://') &&
        !thumbPath.toLowerCase().endsWith('.mp4') &&
        !thumbPath.toLowerCase().endsWith('.mov')) {
      try {
        final f = File(thumbPath.replaceFirst('file://', ''));
        if (f.existsSync() && f.lengthSync() > 200) {
          cachedBytes = f.readAsBytesSync();
          AppImage.cacheThumbnail(path, cachedBytes);
        }
      } catch (_) {}
    }

    return EditorClip(
      id: '${path.hashCode}_${DateTime.now().microsecondsSinceEpoch}',
      filePath: path,
      originalDuration: hintDuration,
      trimStart: Duration.zero,
      trimEnd: hintDuration,
      thumbnailPath: thumbPath,
      thumbnailBytes: cachedBytes,
      filterId: StudioCubit.normalizeFilterId(filterId ?? studio.recordingFilter),
      beautyOn: beautyOn ?? studio.recordingBeautyOn,
      beautyIntensity: beautyIntensity ?? studio.recordingBeautyIntensity,
    );
  }

  Future<VideoPlayerController?> _initController(String path) async {
    var cleanPath = path.trim();
    if (cleanPath.startsWith('file://')) {
      cleanPath = cleanPath.replaceFirst('file://', '');
    }
    cleanPath = MediaUrlUtils.resolve(cleanPath).trim();
    if (cleanPath.isEmpty) return null;

    final isRemote = cleanPath.startsWith('http://') || cleanPath.startsWith('https://');
    if (!isRemote) {
      final ready = await StudioVideoPlayerUtils.prepareLocalRecordingForPlayback(
        cleanPath,
        copyToStableTemp: false,
      );
      if (ready != null && ready.isNotEmpty) {
        cleanPath = ready;
      }
    }

    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        final mix = VideoPlayerOptions(mixWithOthers: true);
        final controller = isRemote
            ? VideoPlayerController.networkUrl(
                Uri.parse(cleanPath),
                videoPlayerOptions: mix,
              )
            : VideoPlayerController.file(
                File(cleanPath),
                videoPlayerOptions: mix,
              );

        if (!isRemote) {
          final f = File(cleanPath);
          if (!f.existsSync() || f.lengthSync() <= 0) {
            debugPrint('_initController: file does not exist at $cleanPath');
            await controller.dispose();
            if (attempt < 3) {
              await Future<void>.delayed(Duration(milliseconds: 180 * attempt));
              continue;
            }
            return null;
          }
        }

        await controller.initialize().timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('Controller init timed out'),
        );

        if (controller.value.isInitialized &&
            controller.value.duration.inMilliseconds > 0) {
          await controller.setLooping(false);
          if (!mounted) return controller;
          final studio = context.read<StudioCubit>();
          try {
            await controller.setPlaybackSpeed(studio.speedMultiplier.clamp(0.4, 4.0));
          } catch (_) {}
          final hasBgm = studio.selectedMusic != null || studio.selectedTrack != null;
          if (studio.isMuted || hasBgm) {
            await controller.setVolume(0.0);
          }
          return controller;
        }
        await controller.dispose();
      } catch (e) {
        debugPrint('_initController attempt $attempt error for $path: $e');
        if (attempt < 3) {
          await Future<void>.delayed(Duration(milliseconds: 180 * attempt));
        }
      }
    }
    return null;
  }

  Future<void> _releasePlayersForDetails() async {
    _playbackTimer?.cancel();
    _playEpoch++;
    _playing = false;
    _awaitingPlayerRestore = true;
    final old = Map<String, VideoPlayerController>.from(_controllers);
    _controllers.clear();
    if (mounted) setState(() {});
    for (final c in old.values) {
      try {
        c.removeListener(_onVideoUpdate);
        await c.pause();
        await c.dispose();
      } catch (_) {}
    }
  }

  Future<void> _restorePlayersAfterDetails() async {
    if (!_awaitingPlayerRestore || _restoringPlayers || !mounted) return;
    _restoringPlayers = true;
    _awaitingPlayerRestore = false;
    _playbackTimer?.cancel();
    _playing = false;
    // Details may still be disposing — stop leftover BGM so it cannot
    // keep playing while video controllers are recreated.
    StudioMusicPlaybackService.directPause();
    await StudioMusicPlaybackService.pause();
    try {
      await Future<void>.delayed(const Duration(milliseconds: 220));
      if (!mounted) return;

      final clips = _clipNotifier.clips;
      if (clips.isEmpty) return;

      _activePlayingIndex = _activePlayingIndex.clamp(0, clips.length - 1);
      _setPosition(0);
      _clipNotifier.selectClip(_activePlayingIndex);
      final first = clips[_activePlayingIndex];

      VideoPlayerController? firstController;
      for (int attempt = 0; attempt < 3; attempt++) {
        firstController = await _initController(first.filePath);
        if (!mounted) return;
        if (firstController != null && firstController.value.isInitialized) {
          firstController.addListener(_onVideoUpdate);
          _controllers[first.id] = firstController;
          break;
        }
        await Future<void>.delayed(Duration(milliseconds: 120 * (attempt + 1)));
        if (!mounted) return;
      }
      if (firstController == null || !firstController.value.isInitialized) {
        if (mounted) setState(() => _playing = false);
        return;
      }

      try {
        await firstController.seekTo(first.trimStart);
      } catch (_) {}
      if (!mounted) return;

      final studio = context.read<StudioCubit>();
      final epoch = ++_playEpoch;
      _suppressPauseGuard = true;
      _playing = true;
      if (mounted) {
        setState(() {
          _playing = true;
          _videoFrameReady = true;
        });
      }

      final ok = await _ensureClipPlaying(
        epoch: epoch,
        controller: firstController,
        studio: studio,
        musicPositionMs: 0,
      );
      _suppressPauseGuard = false;
      if (!mounted) return;

      if (!ok || !firstController.value.isPlaying) {
        _playing = false;
        StudioMusicPlaybackService.directPause();
        unawaited(StudioMusicPlaybackService.pause());
        if (mounted) setState(() => _playing = false);
        return;
      }

      _startPlaybackTimer();
      if (mounted) setState(() => _playing = true);

      unawaited(() async {
        for (final clip in clips) {
          if (clip.id == first.id) continue;
          if (!mounted) return;
          final existing = _controllers[clip.id];
          if (existing != null && existing.value.isInitialized) continue;
          final c = await _initController(clip.filePath);
          if (!mounted) return;
          if (c != null) {
            c.addListener(_onVideoUpdate);
            _controllers[clip.id] = c;
          }
        }
      }());
    } finally {
      _suppressPauseGuard = false;
      _restoringPlayers = false;
    }
  }

  Future<void> _pauseAllPlayback() async {
    _playEpoch++;
    _playing = false;
    StudioMusicPlaybackService.directPause();
    for (final c in _controllers.values) {
      if (c.value.isInitialized && c.value.isPlaying) {
        unawaited(c.pause());
      }
    }
    await StudioMusicPlaybackService.pause();
    if (mounted) setState(() => _playing = false);
  }

  /// Play the active clip and BGM together. Music is preloaded first so
  /// audio-session setup cannot pause ExoPlayer mid-frame.
  Future<bool> _ensureClipPlaying({
    required int epoch,
    required VideoPlayerController controller,
    required StudioCubit studio,
    int musicPositionMs = 0,
  }) async {
    if (!mounted || epoch != _playEpoch) return false;
    final hasBgm = studio.selectedMusic != null || studio.selectedTrack != null;
    await _applyOriginalAudioMute(studio.isMuted || hasBgm);
    try {
      await controller.setPlaybackSpeed(studio.speedMultiplier.clamp(0.4, 4.0));
    } catch (_) {}
    if (!mounted || epoch != _playEpoch) return false;
    if (hasBgm) {
      await StudioMusicPlaybackService.preloadForStudio(studio);
    }
    if (!mounted || epoch != _playEpoch) return false;
    _ignoreAdvanceUntil =
        DateTime.now().add(const Duration(milliseconds: 900));
    _stuckPosMs = -1;
    _stuckTicks = 0;
    try {
      await controller.play();
    } catch (e) {
      debugPrint('_ensureClipPlaying play error: $e');
    }
    for (int i = 0; i < 16; i++) {
      if (!mounted || epoch != _playEpoch) return false;
      if (controller.value.isPlaying) break;
      try {
        await controller.play();
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
    if (!mounted || epoch != _playEpoch) return false;
    // Start BGM only after video is actually playing — otherwise music
    // keeps going while the preview stays paused (e.g. after Details back).
    if (hasBgm && controller.value.isPlaying) {
      await StudioMusicPlaybackService.playForEditor(studio, musicPositionMs);
      StudioMusicPlaybackService.ensurePlaying();
    }
    return mounted &&
        epoch == _playEpoch &&
        controller.value.isInitialized &&
        controller.value.isPlaying;
  }

  Future<void> _resumePlaybackAfterMusic() async {
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    final studio = context.read<StudioCubit>();
    final clips = _clipNotifier.clips;
    if (clips.isEmpty) return;

    final epoch = ++_playEpoch;
    _suppressPauseGuard = true;
    _playing = true;
    _videoFrameReady = true;
    _activePlayingIndex = 0;
    _setPosition(0);
    _clipNotifier.selectClip(0);
    if (mounted) setState(() {});

    try {
      await _seekClipToTrimStart(0);
      if (!mounted || epoch != _playEpoch) return;

      final clip = clips[0];
      var controller = _controllers[clip.id];
      if (controller == null || !controller.value.isInitialized) {
        controller = await _initController(clip.filePath);
        if (controller != null && mounted) {
          _controllers[clip.id] = controller;
          controller.addListener(_onVideoUpdate);
        }
      }
      if (controller == null || !controller.value.isInitialized) return;
      if (!mounted || epoch != _playEpoch) {
        unawaited(controller.pause());
        return;
      }

      final ok = await _ensureClipPlaying(
        epoch: epoch,
        controller: controller,
        studio: studio,
        musicPositionMs: 0,
      );
      if (ok && mounted && epoch == _playEpoch) {
        setState(() {
          _playing = true;
          _videoFrameReady = true;
        });
      }
    } finally {
      _suppressPauseGuard = false;
    }
  }

  Future<void> _startPreviewPlayback() async {
    if (!mounted || _playing) return;
    final epoch = ++_playEpoch;
    _suppressPauseGuard = true;
    _playing = true;
    if (mounted) setState(() => _playing = true);
    final clips = _clipNotifier.clips;
    if (clips.isEmpty) return;
    final clip = clips[_activePlayingIndex.clamp(0, clips.length - 1)];
    var controller = _controllers[clip.id];
    if (controller == null || !controller.value.isInitialized) {
      controller = await _initController(clip.filePath);
      if (controller != null && mounted) {
        _controllers[clip.id] = controller;
        controller.addListener(_onVideoUpdate);
      }
    }
    if (controller == null || !controller.value.isInitialized || !mounted) {
      _suppressPauseGuard = false;
      return;
    }
    if (epoch != _playEpoch) {
      _suppressPauseGuard = false;
      return;
    }

    final studio = context.read<StudioCubit>();
    try {
      await controller.seekTo(clip.trimStart);
    } catch (_) {}
    if (!mounted || epoch != _playEpoch) {
      unawaited(controller.pause());
      _suppressPauseGuard = false;
      return;
    }
    final ok = await _ensureClipPlaying(
      epoch: epoch,
      controller: controller,
      studio: studio,
      musicPositionMs: _globalPositionMs,
    );
    _suppressPauseGuard = false;
    if (!ok) {
      if (epoch == _playEpoch) {
        unawaited(controller.pause());
        StudioMusicPlaybackService.directPause();
      }
      return;
    }
    if (mounted) {
      setState(() {
        _playing = true;
        _videoFrameReady = true;
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Playback Timer
  // ─────────────────────────────────────────────────────────────────────────
  void _startPlaybackTimer() {
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (!mounted) return;
      _tickPlayback();
    });
  }

  void _tickPlayback() {
    if (!_playing) {
      if (_suppressPauseGuard) return;
      for (final c in _controllers.values) {
        if (c.value.isInitialized && c.value.isPlaying) {
          unawaited(c.pause());
        }
      }
      return;
    }
    if (_isSwitchingClip) return;
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
        _setPosition(newGlobal);
      }

      // If ExoPlayer silently paused (audio focus) or position froze, kick it.
      final remainingForKick = trimEndMs - posMs;
      if (remainingForKick > 300) {
        final frozen = posMs == _stuckPosMs;
        _stuckPosMs = posMs;
        if (frozen || !controller.value.isPlaying) {
          _stuckTicks++;
          if (_stuckTicks >= 10) {
            _stuckTicks = 0;
            unawaited(controller.play());
            StudioMusicPlaybackService.ensurePlaying();
          }
        } else {
          _stuckTicks = 0;
        }
      } else {
        _stuckTicks = 0;
      }

      // Auto-advance only at the real clip end. Ignore lone isCompleted /
      // audio-focus pauses — those used to stop a 4s clip after ~1s.
      final studio = context.read<StudioCubit>();
      final speed = studio.speedMultiplier.clamp(0.4, 4.0);
      final ignoreAdvance = _ignoreAdvanceUntil != null &&
          DateTime.now().isBefore(_ignoreAdvanceUntil!);
      final trimmedMs = activeClip.trimmedDuration.inMilliseconds;
      final minPlayed = (trimmedMs * 0.82).round().clamp(250, trimmedMs);
      final remaining = trimEndMs - posMs;
      final playedEnough = localMs >= minPlayed && posMs > trimStartMs + 200;
      final atRealEnd = playedEnough && remaining <= (80 * speed).clamp(60, 200);
      final completedAtEnd = controller.value.isCompleted && playedEnough;
      if (_playing &&
          !_isSwitchingClip &&
          !ignoreAdvance &&
          (atRealEnd || completedAtEnd)) {
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
    if (!_playing || _suppressPauseGuard || _isSwitchingClip) return;
    final clips = _clipNotifier.clips;
    if (_activePlayingIndex >= clips.length) return;
    final clip = clips[_activePlayingIndex];
    final c = _controllers[clip.id];
    if (c == null || !c.value.isInitialized) return;

    final remaining = clip.trimEnd.inMilliseconds - c.value.position.inMilliseconds;
    if (!c.value.isPlaying && !c.value.isCompleted && remaining > 250) {
      final now = DateTime.now();
      if (_lastVideoKickAt == null ||
          now.difference(_lastVideoKickAt!) > const Duration(milliseconds: 180)) {
        _lastVideoKickAt = now;
        unawaited(c.play());
      }
    }
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
      // End of sequence: loop back to clip 0 and keep playing.
      // Pause only if the user already paused.
      if (!mounted || !_playing) {
        _isSwitchingClip = false;
        return;
      }
      final studio = context.read<StudioCubit>();
      _activePlayingIndex = 0;
      _clipNotifier.selectClip(0);
      _setPosition(0);

      final firstClip = clips[0];
      var firstController = _controllers[firstClip.id];
      if (firstController == null || !firstController.value.isInitialized) {
        firstController = await _initController(firstClip.filePath);
        if (firstController != null && mounted) {
          _controllers[firstClip.id] = firstController;
        }
      }
      if (firstController == null || !firstController.value.isInitialized) {
        _isSwitchingClip = false;
        return;
      }
      if (!_playing || !mounted) {
        _isSwitchingClip = false;
        return;
      }

      try {
        await firstController.seekTo(firstClip.trimStart);
      } catch (_) {}
      firstController.removeListener(_onVideoUpdate);
      firstController.addListener(_onVideoUpdate);
      final ignoreMs = (400 / studio.speedMultiplier).clamp(250, 800).round();
      _ignoreAdvanceUntil =
          DateTime.now().add(Duration(milliseconds: ignoreMs));

      final hasBgm = studio.selectedMusic != null || studio.selectedTrack != null;
      if (hasBgm || studio.isMuted) {
        await firstController.setVolume(0.0);
      }
      try {
        await firstController.setPlaybackSpeed(studio.speedMultiplier.clamp(0.4, 4.0));
      } catch (_) {}
      if (!_playing) {
        unawaited(firstController.pause());
        _isSwitchingClip = false;
        return;
      }
      unawaited(firstController.play());
      if (hasBgm) {
        final musicStartMs = (studio.musicStartSeconds * 1000).round();
        unawaited(StudioMusicPlaybackService.seekToMs(musicStartMs));
        StudioMusicPlaybackService.ensurePlaying();
      }
      if (mounted) setState(() => _playing = true);

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
      _setPosition(nextAccMs);

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
      final ignoreMs = (400 / studio.speedMultiplier).clamp(250, 800).round();
      _ignoreAdvanceUntil =
          DateTime.now().add(Duration(milliseconds: ignoreMs));

      final hasBgm = studio.selectedMusic != null || studio.selectedTrack != null;
      if (hasBgm || studio.isMuted) {
        await nextController.setVolume(0.0);
      }
      try {
        await nextController.setPlaybackSpeed(studio.speedMultiplier.clamp(0.4, 4.0));
      } catch (_) {}
      if (!_playing) {
        unawaited(nextController.pause());
        _isSwitchingClip = false;
        return;
      }
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
    if (clips.isEmpty || _isLoading || _isImportingClip || _restoringPlayers) return;
    final studio = context.read<StudioCubit>();

    if (_playing) {
      await _pauseAllPlayback();
      return;
    }

    final epoch = ++_playEpoch;
    _suppressPauseGuard = true;
    _playing = true;
    if (mounted) setState(() => _playing = true);

    final totalMs = _clipNotifier.totalTrimmedDuration.inMilliseconds;
    // If at end of sequence, restart from clip 0
    if (_globalPositionMs >= totalMs - 100) {
      _activePlayingIndex = 0;
      _setPosition(0);
      await _seekClipToTrimStart(0);
    }

    if (!mounted || epoch != _playEpoch) {
      _suppressPauseGuard = false;
      return;
    }
    if (_activePlayingIndex >= clips.length) _activePlayingIndex = 0;

    final activeClip = clips[_activePlayingIndex];
    var activeController = _controllers[activeClip.id];
    if (activeController == null || !activeController.value.isInitialized) {
      activeController = await _initController(activeClip.filePath);
      if (activeController != null && mounted) {
        _controllers[activeClip.id] = activeController;
      }
    }
    if (!mounted || epoch != _playEpoch) {
      unawaited(activeController?.pause());
      _suppressPauseGuard = false;
      return;
    }
    if (activeController == null || !activeController.value.isInitialized) {
      _suppressPauseGuard = false;
      return;
    }
    final speed = studio.speedMultiplier.clamp(0.4, 4.0);
    final posMs = activeController.value.position.inMilliseconds;
    final trimEndMs = activeClip.trimEnd.inMilliseconds;
    final trimStartMs = activeClip.trimStart.inMilliseconds;
    final restartMargin = (100 * speed).clamp(80, 300).round();
    if (posMs >= trimEndMs - restartMargin || posMs < trimStartMs) {
      await _seekClipToTrimStart(_activePlayingIndex);
    }
    if (!mounted || epoch != _playEpoch) {
      unawaited(activeController.pause());
      _suppressPauseGuard = false;
      return;
    }
    activeController.removeListener(_onVideoUpdate);
    activeController.addListener(_onVideoUpdate);

    final ok = await _ensureClipPlaying(
      epoch: epoch,
      controller: activeController,
      studio: studio,
      musicPositionMs: _globalPositionMs,
    );
    _suppressPauseGuard = false;
    if (!ok) {
      if (epoch == _playEpoch) {
        unawaited(activeController.pause());
        StudioMusicPlaybackService.directPause();
      }
      return;
    }
    if (mounted && epoch == _playEpoch) {
      setState(() {
        _playing = true;
        _videoFrameReady = true;
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Select Clip (tap in timeline)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _selectClip(int clipIndex) async {
    if (_isImportingClip) return;
    final clips = _clipNotifier.clips;
    if (clipIndex >= clips.length) return;
    final studio = context.read<StudioCubit>();

    if (_playing) {
      await _pauseAllPlayback();
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
    _setPosition(accMs, rebuild: true);

    if (studio.selectedMusic != null || studio.selectedTrack != null) {
      final musicStartMs = (studio.musicStartSeconds * 1000).round();
      await StudioMusicPlaybackService.seekToMs(musicStartMs + accMs);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Seek from timeline scrub
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _onGlobalSeek(int globalMs) async {
    if (_isImportingClip) return;
    final clips = _clipNotifier.clips;
    if (clips.isEmpty) return;
    final studio = context.read<StudioCubit>();

    final resolved = _clipNotifier.resolveGlobalMs(globalMs);
    final clipIndex = resolved.clipIndex;
    final seekPos = resolved.seekPosition;

    final clip = clips[clipIndex];

    // 1. Immediately pause any inactive controllers to avoid desync/echo
    for (final entry in _controllers.entries) {
      if (entry.key != clip.id) {
        try {
          entry.value.pause();
        } catch (_) {}
      }
    }

    // 2. Ensure target controller is active and seeks to the exact frame
    var controller = _controllers[clip.id];
    if (controller == null || !controller.value.isInitialized) {
      controller = await _initController(clip.filePath);
      if (controller != null && mounted) {
        _controllers[clip.id] = controller;
      }
    }

    if (controller != null && controller.value.isInitialized) {
      await controller.seekTo(seekPos);
      if (_playing) {
        final hasBgm = studio.selectedMusic != null || studio.selectedTrack != null;
        if (hasBgm || studio.isMuted) {
          await controller.setVolume(0.0);
        }
        try {
          await controller.setPlaybackSpeed(studio.speedMultiplier.clamp(0.4, 4.0));
        } catch (_) {}
        unawaited(controller.play());
      } else {
        await controller.pause();
      }
    }

    _ignoreAdvanceUntil = DateTime.now().add(const Duration(milliseconds: 300));
    _activePlayingIndex = clipIndex;
    _clipNotifier.selectClip(clipIndex);
    if (mounted) _setPosition(globalMs, rebuild: true);

    if (studio.selectedMusic != null || studio.selectedTrack != null) {
      final musicStartMs = (studio.musicStartSeconds * 1000).round();
      await StudioMusicPlaybackService.seekToMs(musicStartMs + globalMs);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Add Video via ImagePicker
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _addVideo() async {
    if (_isImportingClip) return;
    if (_clipNotifier.clips.length >= EditorClipListNotifier.maxClips) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 10 clips allowed in timeline.'),
          backgroundColor: Colors.deepOrange,
          duration: Duration(milliseconds: 1000),
        ),
      );
      return;
    }

    await _pauseAllPlayback();

    if (!mounted) return;

    // Open cached drafts immediately — list refresh happens in the background.
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
    if (!mounted) return;

    List<String> rawPaths = [];
    List<String> rawThumbs = [];
    List<double> rawDurs = [];
    if (draft['mergedClipPaths'] is List && (draft['mergedClipPaths'] as List).isNotEmpty) {
      rawPaths = List<String>.from(draft['mergedClipPaths'] as List);
      if (draft['mergedClipThumbnails'] is List) {
        rawThumbs = List<String>.from(draft['mergedClipThumbnails'] as List);
      }
      if (draft['mergedClipDurations'] is List) {
        rawDurs = (draft['mergedClipDurations'] as List)
            .map((e) => (e as num).toDouble())
            .toList();
      }
    } else {
      final String? path = (draft['videoPath'] as String?) ?? (draft['videoUrl'] as String?);
      if (path != null && path.trim().isNotEmpty) {
        rawPaths.add(path.trim());
        final String? t = (draft['thumbnailPath'] as String?) ?? (draft['thumbnailUrl'] as String?);
        if (t != null && t.isNotEmpty) rawThumbs.add(t);
        final ds = (draft['durationSeconds'] as num?)?.toDouble();
        if (ds != null && ds > 0) rawDurs.add(ds);
      }
    }
    final rawFilters = StudioCubit.clipFilterIdsOfDraft(draft, pathCount: rawPaths.length);
    final draftBeautyOn = draft['beautyOn'] == true || draft['beauty_on'] == true;
    final draftBeautyIntensity = (draft['beautyIntensity'] as num?)?.toDouble() ??
        (draft['beauty_intensity'] as num?)?.toDouble() ??
        50.0;

    final List<String> pathsToAdd = [];
    final List<String?> thumbsToAdd = [];
    final List<double> dursToAdd = [];
    final List<String> filtersToAdd = [];
    for (int i = 0; i < rawPaths.length; i++) {
      final p = rawPaths[i].trim();
      if (p.isEmpty) continue;
      pathsToAdd.add(p);
      thumbsToAdd.add(i < rawThumbs.length ? rawThumbs[i] : null);
      dursToAdd.add(i < rawDurs.length && rawDurs[i] > 0 ? rawDurs[i] : 15.0);
      filtersToAdd.add(
        i < rawFilters.length ? rawFilters[i] : StudioCubit.filterIdOfDraft(draft),
      );
    }

    if (pathsToAdd.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No valid video found in the selected draft.'),
          backgroundColor: Colors.deepOrange,
          duration: Duration(milliseconds: 1000),
        ),
      );
      return;
    }

    final studio = context.read<StudioCubit>();
    final added = <EditorClip>[];
    for (int i = 0; i < pathsToAdd.length; i++) {
      if (_clipNotifier.clips.length >= EditorClipListNotifier.maxClips) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reached maximum limit of 10 clips.'),
            backgroundColor: Colors.deepOrange,
            duration: Duration(milliseconds: 1000),
          ),
        );
        break;
      }

      final path = MediaUrlUtils.resolve(pathsToAdd[i]).trim().isNotEmpty
          ? MediaUrlUtils.resolve(pathsToAdd[i]).trim()
          : pathsToAdd[i];
      final candidateThumb = thumbsToAdd[i];
      String? thumbPath;
      Uint8List? thumbBytes;

      if (candidateThumb != null && candidateThumb.isNotEmpty) {
        final resolvedThumb = MediaUrlUtils.resolve(candidateThumb).trim();
        if (resolvedThumb.isNotEmpty &&
            !resolvedThumb.startsWith('http://') &&
            !resolvedThumb.startsWith('https://')) {
          try {
            final f = File(resolvedThumb.replaceFirst('file://', ''));
            if (f.existsSync() && f.lengthSync() > 300) {
              thumbBytes = f.readAsBytesSync();
              thumbPath = resolvedThumb;
            }
          } catch (_) {}
        }
      }

      if (thumbBytes == null) {
        final cubitThumb = studio.getThumbnailForClip(path) ??
            studio.getThumbnailForClip(pathsToAdd[i]);
        if (cubitThumb != null && cubitThumb.isNotEmpty) {
          final resolvedCubit = MediaUrlUtils.resolve(cubitThumb).trim();
          if (resolvedCubit.isNotEmpty &&
              !resolvedCubit.startsWith('http://') &&
              !resolvedCubit.startsWith('https://')) {
            try {
              final f = File(resolvedCubit.replaceFirst('file://', ''));
              if (f.existsSync() && f.lengthSync() > 300) {
                thumbBytes = f.readAsBytesSync();
                thumbPath = resolvedCubit;
              }
            } catch (_) {}
          }
        }
      }
      thumbBytes ??= AppImage.getCachedThumbnail(path) ??
          AppImage.getCachedThumbnail(pathsToAdd[i]);

      // Draft merge often has no saved thumb — extract a frame from the video.
      if (thumbBytes == null || thumbBytes.isEmpty) {
        try {
          final generated = await VideoThumbnailGenerator.generateThumbnailFromVideo(
            path,
            timeMs: 200,
          );
          if (generated != null && await generated.exists()) {
            thumbBytes = await generated.readAsBytes();
            thumbPath = generated.path;
          } else {
            thumbBytes = await VideoThumbnailGenerator.extractFrameBytes(path, timeMs: 200);
          }
        } catch (_) {}
      }

      if (thumbBytes != null && thumbBytes.isNotEmpty) {
        AppImage.cacheThumbnail(path, thumbBytes);
        AppImage.cacheThumbnail(pathsToAdd[i], thumbBytes);
      }

      final durSecs = dursToAdd[i];
      final duration = Duration(milliseconds: (durSecs * 1000).round());
      final clip = EditorClip(
        id: '${path.hashCode}_${DateTime.now().microsecondsSinceEpoch}_$i',
        filePath: path,
        originalDuration: duration,
        trimStart: Duration.zero,
        trimEnd: duration,
        thumbnailPath: thumbPath ?? candidateThumb,
        thumbnailBytes: thumbBytes,
        filterId: i < filtersToAdd.length
            ? filtersToAdd[i]
            : StudioCubit.filterIdOfDraft(draft),
        beautyOn: draftBeautyOn,
        beautyIntensity: draftBeautyIntensity,
      );
      _clipNotifier.addClip(clip);
      added.add(clip);
    }

    if (added.isEmpty) return;

    _syncClipsToStudioCubit();
    if (mounted) setState(() {});
    unawaited(_loadRemainingClips(added));
    for (final clip in added) {
      unawaited(VideoThumbnailGenerator.extractFilmstripFrames(
        clip.filePath,
        targetCount: 8,
        trimStart: clip.trimStart,
        trimEnd: clip.trimEnd,
        duration: clip.originalDuration,
        cacheKeyExtra: clip.id,
        onPartial: (_) {
          if (mounted) setState(() {});
        },
      ).then((_) {
        if (mounted) setState(() {});
      }));
    }

    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Successfully merged ${_clipNotifier.clips.length} clips into 1 video!'),
        backgroundColor: const Color(0xFF8B5CF6),
        duration: const Duration(milliseconds: 1000),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Remove Clip
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _removeClip(int clipIndex) async {
    final clips = _clipNotifier.clips;
    if (clipIndex >= clips.length) return;
    if (clips.length <= 1) {
      // Cannot remove the only clip
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one video clip is required.'),
          backgroundColor: Colors.deepOrange,
          duration: Duration(milliseconds: 1000),
        ),
      );
      return;
    }

    final clip = clips[clipIndex];

    await _pauseAllPlayback();

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
    // Seek controller to new trimStart so preview surface immediately updates to match the new start frame
    final clips = _clipNotifier.clips;
    if (clipIndex < clips.length) {
      final clip = clips[clipIndex];
      final ctrl = _controllers[clip.id];
      if (ctrl != null && ctrl.value.isInitialized) {
        ctrl.seekTo(trimStart);
      }
    }
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
    await _pauseAllPlayback();
    if (!mounted) return;

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
          final mergedFilters = clips.map((c) => c.filterId).toList();
          final totalDur = _clipNotifier.totalTrimmedDuration;
          final formattedDur = _fmtDuration(totalDur);
          studio.setMergedClipPaths(mergedPaths, mergedDurations, mergedFilters);
          studio.setRecordedDuration(formattedDur);
        }

        final cid = widget.challengeId ?? 'c1';
        final dp = widget.draftId != null ? '&draft=${widget.draftId}' : '';
        if (!mounted) return;
        await context.push('${AppRoutes.studioMusic}?id=$cid$dp');
        if (!mounted) return;
        final studio = context.read<StudioCubit>();
        if (studio.selectedMusic != null || studio.selectedTrack != null) {
          await _resumePlaybackAfterMusic();
        } else {
          await StudioMusicPlaybackService.stop();
          await _applyOriginalAudioMute(studio.isMuted);
          if (mounted) setState(() {});
        }
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
    // Clear cubit first so the playback timer cannot restart BGM.
    _studio.setSelectedTrack(null);
    await StudioMusicPlaybackService.stop();
    await _applyOriginalAudioMute(_studio.isMuted);
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
  void deactivate() {
    // Stay mounted under Video Details (push). Stop the pause-tick so it
    // cannot kill BGM on the details screen.
    _playbackTimer?.cancel();
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    if (!mounted) return;
    if (_awaitingPlayerRestore) {
      // Details may still be disposing (file locks + BGM). Do not start
      // music/video here — _onNextPressed restores after push returns.
      _playbackTimer?.cancel();
      StudioMusicPlaybackService.directPause();
      return;
    }
    _startPlaybackTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (!_confirmedChanges) {
      _revertChangesIfNotConfirmed();
    }
    unawaited(WakelockPlus.disable());
    _playbackTimer?.cancel();
    _positionNotifier.dispose();
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

  String _routeChallengeId() {
    final fromRoute = widget.challengeId?.trim() ?? '';
    if (Validators.isRealDatabaseId(fromRoute)) return fromRoute;
    try {
      final studio = context.read<StudioCubit>();
      final setupId = studio.state.studioSetup?.challenge.id.trim() ?? '';
      if (Validators.isRealDatabaseId(setupId)) return setupId;
      final stored = studio.videoChallengeId?.trim() ?? '';
      if (Validators.isRealDatabaseId(stored)) return stored;
    } catch (_) {}
    return fromRoute;
  }

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
  void _navigateBackFromEditor() {
    _revertChangesIfNotConfirmed();
    StudioMusicPlaybackService.stop();
    for (final c in _controllers.values) {
      try {
        c.pause();
      } catch (_) {}
    }
    if (!mounted) return;
    if (context.canPop()) {
      Navigator.of(context).popUntil((route) {
        if (route.isFirst) return true;
        final path = (route.settings.name ?? '').split('?').first;
        return path == AppRoutes.studioStart ||
            path == AppRoutes.submitEntry ||
            path == AppRoutes.studioDrafts ||
            path == AppRoutes.home;
      });
      return;
    }
    final String? cid = (widget.challengeId != null && widget.challengeId!.isNotEmpty)
        ? widget.challengeId
        : ((_draft?['challengeId'] as String?)?.isNotEmpty == true
            ? _draft!['challengeId'] as String
            : (context.read<StudioCubit>().state.videoChallengeId?.isNotEmpty == true
                ? context.read<StudioCubit>().state.videoChallengeId
                : (_challenge['id'] as String?)));
    final draftId = widget.draftId;
    if (draftId != null && draftId.isNotEmpty) {
      context.go(
        cid != null && cid.isNotEmpty
            ? '${AppRoutes.studioDrafts}?id=$cid'
            : AppRoutes.studioDrafts,
      );
      return;
    }
    context.go(
      cid != null && cid.isNotEmpty
          ? '${AppRoutes.studioStart}?id=$cid'
          : AppRoutes.studioStart,
    );
  }

  @override
  Widget build(BuildContext context) {
    final studio = context.watch<StudioCubit>();
    final music = studio.selectedMusic;
    final totalDuration = _clipNotifier.totalTrimmedDuration;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _navigateBackFromEditor();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // ── 1. Top Bar ─────────────────────────────────────────────────
                  _buildTopBar(_challenge),

                  // ── 2. Video Preview ───────────────────────────────────────────
                  _buildVideoPreview(studio),

                  // ── 3+4. Controls + timeline (position ticks without rebuilding video)
                  ValueListenableBuilder<int>(
                    valueListenable: _positionNotifier,
                    builder: (context, pos, _) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildControls(pos, totalDuration.inMilliseconds),
                          _buildMultiTimeline(music, pos),
                        ],
                      );
                    },
                  ),

                  // ── 5. Bottom Toolbar ──────────────────────────────────────────
                  _buildBottomBar(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onNextPressed() async {
    if (_isNavigating || _isImportingClip) return;

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
      await _pauseAllPlayback();
      _playbackTimer?.cancel();
      await _releasePlayersForDetails();

      if (!mounted) return;
      // 2. Collect merged paths & clip durations
      final studio = context.read<StudioCubit>();
      final mergedPaths = clips.map((c) => c.filePath.trim()).toList();
      final mergedDurations = clips.map((c) => c.trimmedDuration.inMilliseconds / 1000.0).toList();
      final mergedFilters = clips.map((c) => c.filterId).toList();
      final totalDur = _clipNotifier.totalTrimmedDuration;
      final formattedDur = _fmtDuration(totalDur);

      // 3. Save editor state to StudioCubit
      studio.setMergedClipPaths(mergedPaths, mergedDurations, mergedFilters);
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
        updatedDraft['mergedClipFilterIds'] = mergedFilters;
        updatedDraft['duration'] = formattedDur;
        studio.updateDraftMap(updatedDraft);
      }

      // Generate real frame thumbnail from edited video matching actual start frame
      try {
        final startMs = clips.first.trimStart.inMilliseconds;
        final thumbFile = await VideoThumbnailGenerator.generateThumbnailFromVideo(
          finalEditedVideoPath,
          timeMs: startMs > 0 ? startMs : null,
        );
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
      final cid = _routeChallengeId();
      final dp = widget.draftId != null ? '&draft=${widget.draftId}' : '';
      final detailsQuery = cid.isNotEmpty ? '?id=$cid$dp' : (dp.isNotEmpty ? '?${dp.substring(1)}' : '');
      await context.push('${AppRoutes.studioDetails}$detailsQuery');
      // Push completes only after Details is popped — safe to reopen files.
      if (mounted && _awaitingPlayerRestore) {
        await _restorePlayersAfterDetails();
      }
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
            onTap: _navigateBackFromEditor,
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
  Widget _buildVideoPreview(StudioCubit studio) {
    final isMuted = studio.isMuted;
    final c = _activeController;
    final isInit = c != null && c.value.isInitialized;
    final activeClip = _clipNotifier.clips.isNotEmpty
        ? _clipNotifier.clips[_activePlayingIndex.clamp(0, _clipNotifier.clips.length - 1)]
        : null;
    final activeThumb = activeClip?.thumbnailBytes ??
        (activeClip != null ? AppImage.getCachedThumbnail(activeClip.filePath) : null);

    return Expanded(
      flex: 5,
      child: Center(
        child: GestureDetector(
          onTap: _togglePlay,
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AppFilterUtils.buildFilteredView(
                filterId: StudioCubit.normalizeFilterId(
                  activeClip?.filterId ?? studio.recordingFilter,
                ),
                beautyOn: activeClip?.beautyOn ?? studio.recordingBeautyOn,
                beautyIntensity: activeClip?.beautyIntensity ?? studio.recordingBeautyIntensity,
                performanceMode: true,
                child: Stack(
                fit: StackFit.expand,
                children: [
                  // Video or placeholder with smooth fallback
                  if (isInit)
                    Container(
                      color: Colors.black,
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: c.value.aspectRatio > 0 ? c.value.aspectRatio : 9 / 16,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              RepaintBoundary(
                                // No ValueKey(controller) — remount breaks draft-continue playback.
                                child: VideoPlayer(c),
                              ),
                              if (!_videoFrameReady && activeThumb != null)
                                Image.memory(
                                  activeThumb,
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true,
                                ),
                            ],
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
                            : (activeThumb != null
                                ? Image.memory(activeThumb, fit: BoxFit.cover, gaplessPlayback: true)
                                : const CircularProgressIndicator(color: AppColors.purple, strokeWidth: 2)),
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
  Widget _buildMultiTimeline(String? music, int posMs) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Video multi-clip timeline
        MultiVideoTimeline(
          notifier: _clipNotifier,
          globalPositionMs: posMs,
          onGlobalSeek: _onGlobalSeek,
          onAddVideo: _addVideo,
          onClipSelected: _selectClip,
          onClipRemoved: _removeClip,
          onTrimChanged: _onTrimChanged,
          isPlaying: _playing,
          isMerging: false,
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

