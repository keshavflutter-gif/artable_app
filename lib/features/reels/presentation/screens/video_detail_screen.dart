import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';
import 'package:artable_app/core/widgets/app_back_header.dart';
import 'package:artable_app/core/widgets/app_image.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';
import 'package:artable_app/app/routes/app_routes.dart';
import 'package:artable_app/core/utils/reel_helpers.dart';
import 'package:artable_app/core/utils/app_filter_utils.dart';
import 'package:artable_app/core/utils/video_share_helper.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:artable_app/features/home/presentation/bloc/home_cubit.dart';
import 'package:artable_app/features/reels/presentation/bloc/reels_cubit.dart';
import 'package:artable_app/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:artable_app/features/trending/presentation/bloc/trending_videos_cubit.dart';
import 'package:artable_app/features/trending/data/models/trending_videos_response.dart';
import 'package:video_player/video_player.dart';
import 'package:artable_app/core/utils/video_cache_manager.dart';
import 'package:artable_app/core/utils/media_url_utils.dart';
import 'package:artable_app/core/services/video_interstitial_ad.dart';
import 'package:artable_app/data/datasources/music_api_service.dart';
import 'package:artable_app/features/reels/data/services/reel_bgm_playback_service.dart';
import 'package:artable_app/features/trending/data/repositories/videos_repository.dart';

class VideoDetailScreen extends StatefulWidget {
  const VideoDetailScreen({super.key, this.reelId, this.initialReelData});

  final String? reelId;
  final Map<String, dynamic>? initialReelData;

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  Map<String, dynamic>? _apiReel;
  bool _exitingWithAd = false;
  VideoPlayerController? _stageController;
  bool _isStageInitialized = false;
  bool _isStageLoading = false;
  bool _isStageUserPaused = false;
  bool _hasStageError = false;
  String? _currentLoadedVideoUrl;
  int _stageInitGeneration = 0;

  bool _mapHasPlayableVideo(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return false;
    final direct = map['videoUrl']?.toString().trim() ?? '';
    if (direct.isNotEmpty &&
        direct != 'null' &&
        !MediaUrlUtils.looksLikeImageUrl(direct)) {
      return true;
    }
    final path = map['videoPath']?.toString().trim() ?? '';
    if (path.isNotEmpty &&
        path != 'null' &&
        !MediaUrlUtils.looksLikeImageUrl(path)) {
      return true;
    }
    if (map['mergedClipPaths'] is List) {
      for (final raw in (map['mergedClipPaths'] as List)) {
        final clip = raw.toString().trim();
        if (clip.isEmpty || clip == 'null') continue;
        if (!MediaUrlUtils.looksLikeImageUrl(clip)) return true;
      }
    }
    return false;
  }

  Map<String, dynamic> get _reel {
    final initial = widget.initialReelData;
    // Always merge cubit/API onto the map we opened with, so a stub without
    // videoUrl cannot win over the profile extra payload.
    if (_apiReel != null && _apiReel!.isNotEmpty) {
      if (initial != null && initial.isNotEmpty) {
        return ReelHelpers.mergeReelMaps(_apiReel!, initial);
      }
      return _apiReel!;
    }

    if (initial != null && initial.isNotEmpty) {
      return initial;
    }

    final targetId = widget.reelId?.trim() ?? '';
    final trendingCubit = context.read<TrendingVideosCubit>();
    final homeCubit = context.read<HomeCubit>();
    final reelsCubit = context.read<ReelsCubit>();

    final available = [
      if (trendingCubit.hero != null) trendingCubit.hero!.toUiMap(),
      ...trendingCubit.videos.map((v) => v.toUiMap()),
      ...homeCubit.trendingReels,
      ...reelsCubit.videos,
    ];

    if (targetId.isNotEmpty) {
      final match = ReelHelpers.reelById(targetId, availableReels: available);
      if (match != null && _mapHasPlayableVideo(match)) return match;

      final singleItem = trendingCubit.getVideoById(targetId);
      if (singleItem != null && singleItem.playableVideoUrl.isNotEmpty) {
        return singleItem.toUiMap();
      }

      final reelsMatch = reelsCubit.getVideo(targetId);
      if (reelsMatch != null && _mapHasPlayableVideo(reelsMatch)) {
        return reelsMatch;
      }
      // Prefer any match even without URL so UI can still show metadata;
      // playback will wait for getVideoById.
      if (match != null) return match;
      if (reelsMatch != null) return reelsMatch;
      if (singleItem != null) return singleItem.toUiMap();
    }

    if (available.isEmpty) {
      return <String, dynamic>{
        if (targetId.isNotEmpty) 'id': targetId,
      };
    }

    // Never fall back to an unrelated first feed item when we have a target id.
    if (targetId.isNotEmpty) {
      return <String, dynamic>{'id': targetId};
    }

    final baseMap = available.first;
    final res = Map<String, dynamic>.from(baseMap);
    final id = res['id']?.toString() ?? res['_id']?.toString() ?? targetId;
    final vUrl = res['videoUrl']?.toString() ?? '';
    if (res['mergedClipPaths'] == null || (res['mergedClipPaths'] is List && (res['mergedClipPaths'] as List).isEmpty)) {
      final descClips = ReelHelpers.parseDescriptionClips(res['description']?.toString() ?? res['caption']?.toString()).clips;
      final cached = descClips ?? ReelHelpers.getCachedMergedClips(id) ?? ReelHelpers.getCachedMergedClips(vUrl);
      if (cached != null && cached.isNotEmpty) {
        res['mergedClipPaths'] = cached;
      }
    }
    return res;
  }

  @override
  void initState() {
    super.initState();
    final reelMap = _reel;
    _initStageVideo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final rId = reelMap['id']?.toString() ?? reelMap['_id']?.toString() ?? widget.reelId;
        if (rId != null && rId.isNotEmpty) {
          context.read<ReelsCubit>().fetchComments(rId);
          _fetchVideoDetail(rId);
        }
        unawaited(VideoInterstitialAd.instance.load());
      }
    });
  }

  bool _lastStageBuffering = false;
  bool _lastStagePlaying = false;
  int _lastStagePosMs = -1;
  DateTime? _lastStageBgmLoopAt;

  void _onStageControllerUpdate() {
    if (!mounted || _stageController == null) return;
    final value = _stageController!.value;
    final buffering = value.isBuffering;
    final playing = value.isPlaying;
    final posMs = value.position.inMilliseconds;
    final durMs = value.duration.inMilliseconds;

    // When native looping restarts the video, restart BGM with it.
    if (!_isStageUserPaused && _isStageInitialized) {
      final prev = _lastStagePosMs;
      _lastStagePosMs = posMs;
      final looped = prev >= 0 && (prev - posMs) >= 700 && posMs <= 450;
      final completedRestart =
          prev >= 0 && durMs > 0 && prev >= (durMs - 350) && posMs <= 450;
      if (looped || completedRestart) {
        final now = DateTime.now();
        if (_lastStageBgmLoopAt == null ||
            now.difference(_lastStageBgmLoopAt!) >=
                const Duration(milliseconds: 350)) {
          _lastStageBgmLoopAt = now;
          _syncStageBgm(play: true);
        }
      }
    } else {
      _lastStagePosMs = posMs;
    }

    if (buffering == _lastStageBuffering && playing == _lastStagePlaying) {
      return;
    }
    _lastStageBuffering = buffering;
    _lastStagePlaying = playing;
    setState(() {});
  }

  ReelMusicMeta? _resolveReelMusic([Map<String, dynamic>? reelMap]) {
    final reel = reelMap ?? _reel;
    return ReelHelpers.resolveMusic(
      description: (reel['description'] ?? reel['caption'])?.toString(),
      musicUrl: reel['musicUrl']?.toString() ?? reel['music_url']?.toString(),
      musicName: reel['musicName']?.toString() ?? reel['music']?.toString(),
      startSeconds: (reel['musicStartSeconds'] as num?)?.toDouble(),
      durationSeconds: (reel['musicCropDuration'] as num?)?.toDouble(),
      videoId: reel['id']?.toString() ?? reel['_id']?.toString() ?? widget.reelId,
      videoUrl: reel['videoUrl']?.toString(),
      resolveAudioUrl: (name) => MusicApiService.resolveByName(name)?.audioUrl,
    );
  }

  bool _isUsableStageUrl(String resolved) {
    if (resolved.isEmpty || MediaUrlUtils.looksLikeImageUrl(resolved)) {
      return false;
    }
    if (resolved.startsWith('http://') || resolved.startsWith('https://')) {
      return true;
    }
    try {
      return File(resolved).existsSync();
    } catch (_) {
      return false;
    }
  }

  String _stagePlayableUrl(Map<String, dynamic> reelMap) {
    final direct = (reelMap['videoUrl'] ?? reelMap['videoPath'])?.toString().trim() ?? '';
    if (direct.isNotEmpty && direct != 'null' && !MediaUrlUtils.looksLikeImageUrl(direct)) {
      final resolved = MediaUrlUtils.resolve(direct).trim();
      if (_isUsableStageUrl(resolved)) return resolved;
    }
    if (reelMap['mergedClipPaths'] is List) {
      for (final raw in (reelMap['mergedClipPaths'] as List)) {
        final clip = raw.toString().trim();
        if (clip.isEmpty || clip == 'null') continue;
        if (MediaUrlUtils.looksLikeImageUrl(clip)) continue;
        final resolved = MediaUrlUtils.resolve(clip).trim();
        if (_isUsableStageUrl(resolved)) return resolved;
      }
    }
    final id = reelMap['id']?.toString() ?? reelMap['_id']?.toString() ?? widget.reelId;
    final cached = ReelHelpers.getCachedMergedClips(id);
    if (cached != null) {
      for (final clip in cached) {
        if (clip.trim().isEmpty || MediaUrlUtils.looksLikeImageUrl(clip)) continue;
        final resolved = MediaUrlUtils.resolve(clip).trim();
        if (_isUsableStageUrl(resolved)) return resolved;
      }
    }
    return '';
  }

  void _syncStageBgm({required bool play}) {
    final music = _resolveReelMusic();
    final url = music?.url.trim() ?? '';
    final reelId = _reel['id']?.toString() ??
        _reel['_id']?.toString() ??
        widget.reelId ??
        'detail';
    if (!play || _isStageUserPaused || url.isEmpty) {
      ReelBgmPlaybackService.killNow();
      unawaited(ReelBgmPlaybackService.deactivate(reelId));
      return;
    }
    final posMs = _stageController?.value.isInitialized == true
        ? _stageController!.value.position.inMilliseconds
        : 0;
    unawaited(ReelBgmPlaybackService.sync(
      reelId: reelId,
      url: url,
      startMs: ((music?.startSeconds ?? 0) * 1000).round(),
      videoPositionMs: posMs,
      shouldPlay: true,
      forceSeek: true,
      cropDurationMs: ((music?.durationSeconds ?? 0) * 1000).round(),
    ));
  }

  Future<void> _releaseStagePlayer() async {
    _stageInitGeneration++;
    ReelBgmPlaybackService.killNow();
    unawaited(ReelBgmPlaybackService.halt());
    final old = _stageController;
    _stageController = null;
    _isStageInitialized = false;
    _currentLoadedVideoUrl = null;
    old?.removeListener(_onStageControllerUpdate);
    try {
      await old?.pause();
    } catch (_) {}
    try {
      await old?.dispose();
    } catch (_) {}
  }

  List<String> _stageUrlCandidates(Map<String, dynamic> reelMap) {
    final out = <String>[];
    void add(String? raw) {
      final v = raw?.trim() ?? '';
      if (v.isEmpty || v == 'null') return;
      if (MediaUrlUtils.looksLikeImageUrl(v)) return;
      final resolved = MediaUrlUtils.resolve(v).trim();
      if (resolved.isEmpty || MediaUrlUtils.looksLikeImageUrl(resolved)) return;
      if (!out.contains(resolved)) out.add(resolved);
    }

    add(reelMap['videoUrl']?.toString());
    add(reelMap['videoPath']?.toString());
    if (reelMap['mergedClipPaths'] is List) {
      for (final raw in (reelMap['mergedClipPaths'] as List)) {
        add(raw.toString());
      }
    }
    final id = reelMap['id']?.toString() ?? reelMap['_id']?.toString() ?? widget.reelId;
    final cached = ReelHelpers.getCachedMergedClips(id);
    if (cached != null) {
      for (final clip in cached) {
        add(clip);
      }
    }
    return out;
  }

  Future<void> _initStageVideo({bool force = false}) async {
    final reelMap = _reel;
    final candidates = _stageUrlCandidates(reelMap);

    if (candidates.isEmpty) {
      if (mounted) {
        setState(() {
          _isStageLoading = false;
          _hasStageError = true;
          _isStageInitialized = false;
        });
      }
      return;
    }

    final preferred = candidates.first;
    if (!force &&
        preferred == _currentLoadedVideoUrl &&
        _stageController != null &&
        _stageController!.value.isInitialized &&
        !_hasStageError) {
      return;
    }
    // Never kill an in-flight load of the same URL — getVideoById used to
    // force-restart and leave Retry Video on screen.
    if (_isStageLoading && preferred == _currentLoadedVideoUrl && !force) {
      return;
    }
    if (_isStageLoading &&
        preferred == _currentLoadedVideoUrl &&
        force &&
        !_hasStageError) {
      return;
    }

    final gen = ++_stageInitGeneration;
    _currentLoadedVideoUrl = preferred;
    final hadError = _hasStageError;

    if (mounted) {
      setState(() {
        _isStageLoading = true;
        _hasStageError = false;
      });
    }

    try {
      // Keep the previous controller on screen until a new one is ready so we
      // never flash Retry / empty stage during a refresh.
      final previous = _stageController;

      VideoPlayerController? controller;
      String? usedUrl;
      for (var i = 0; i < candidates.length; i++) {
        final url = candidates[i];
        if (gen != _stageInitGeneration || !mounted) {
          try {
            await controller?.dispose();
          } catch (_) {}
          return;
        }
        VideoCacheManager.cancelPrecache(url);
        debugPrint('[VideoDetailScreen] Trying stage URL: $url');
        // First attempt: cache OK. After a Retry / prior error: prefer network.
        controller = await VideoCacheManager.createAndInitController(
          url,
          timeout: const Duration(seconds: 25),
          preferNetwork: force || hadError || i > 0,
          primeBuffer: false,
        );
        if (controller != null && controller.value.isInitialized) {
          usedUrl = url;
          break;
        }
        controller = null;
      }

      if (gen != _stageInitGeneration || !mounted) {
        try {
          await controller?.dispose();
        } catch (_) {}
        return;
      }

      if (controller != null && controller.value.isInitialized) {
        previous?.removeListener(_onStageControllerUpdate);
        _stageController = controller;
        _currentLoadedVideoUrl = usedUrl ?? preferred;
        controller.addListener(_onStageControllerUpdate);
        await controller.setLooping(true);
        final hasBgm = _resolveReelMusic(reelMap)?.url.isNotEmpty == true;
        await controller.setVolume(hasBgm ? 0.0 : 1.0);
        await controller.play();

        if (!mounted || gen != _stageInitGeneration) {
          try {
            await controller.dispose();
          } catch (_) {}
          return;
        }
        setState(() {
          _isStageInitialized = true;
          _isStageLoading = false;
          _isStageUserPaused = false;
          _hasStageError = false;
        });
        _syncStageBgm(play: true);
        if (previous != null && !identical(previous, controller)) {
          try {
            await previous.pause();
          } catch (_) {}
          try {
            await previous.dispose();
          } catch (_) {}
        }
        return;
      }
    } catch (e) {
      debugPrint('[VideoDetailScreen] Video stage init error: $e');
    }

    if (mounted && gen == _stageInitGeneration) {
      setState(() {
        _isStageLoading = false;
        _hasStageError = true;
        _isStageInitialized = _stageController?.value.isInitialized == true;
      });
    }
  }

  @override
  void dispose() {
    ReelBgmPlaybackService.killNow();
    unawaited(ReelBgmPlaybackService.stop());
    _stageController?.removeListener(_onStageControllerUpdate);
    _stageController?.dispose();
    _stageController = null;
    super.dispose();
  }

  Future<void> _fetchVideoDetail(String videoId) async {
    try {
      final authCubit = context.read<AuthCubit>();
      final repo = VideosRepository(
        onTokensRefreshed: authCubit.applyRefreshedTokens,
        onSessionRefreshFailed: authCubit.handleSessionRefreshFailed,
      );
      final item = await repo.getVideoById(
        videoId,
        sessionToken: authCubit.sessionToken != 'design_preview' ? authCubit.sessionToken : null,
        refreshToken: authCubit.refreshToken != 'design_preview' ? authCubit.refreshToken : null,
      );
      if (item != null && mounted) {
        // Prefer the map we already opened with (profile/list) so a partial
        // API detail payload cannot wipe a working videoUrl / clips / music.
        final uiMap = ReelHelpers.mergeReelMaps(
          widget.initialReelData ?? _apiReel ?? item.toUiMap(),
          item.toUiMap(),
        );
        // Re-apply API fields that are authoritative when present.
        final apiMap = item.toUiMap();
        for (final key in ['title', 'description', 'caption', 'likes', 'likesCount', 'views', 'viewsCount', 'comments', 'commentsCount']) {
          final v = apiMap[key]?.toString().trim() ?? '';
          if (v.isNotEmpty && v != 'null') uiMap[key] = apiMap[key];
        }
        final existingVideo = uiMap['videoUrl']?.toString().trim() ?? '';
        final apiVideo = apiMap['videoUrl']?.toString().trim() ?? '';
        final existingPlayable = existingVideo.isNotEmpty &&
            existingVideo != 'null' &&
            !MediaUrlUtils.looksLikeImageUrl(existingVideo);
        if (!existingPlayable &&
            apiVideo.isNotEmpty &&
            apiVideo != 'null' &&
            !MediaUrlUtils.looksLikeImageUrl(apiVideo)) {
          uiMap['videoUrl'] = MediaUrlUtils.resolve(apiVideo);
        }
        final music = ReelHelpers.resolveMusic(
          description: (uiMap['description'] ?? uiMap['caption'])?.toString(),
          musicUrl: uiMap['musicUrl']?.toString(),
          musicName: uiMap['musicName']?.toString(),
          startSeconds: (uiMap['musicStartSeconds'] as num?)?.toDouble(),
          durationSeconds: (uiMap['musicCropDuration'] as num?)?.toDouble(),
          videoId: uiMap['id']?.toString(),
          videoUrl: uiMap['videoUrl']?.toString(),
          resolveAudioUrl: (name) => MusicApiService.resolveByName(name)?.audioUrl,
        );
        if (music != null && music.url.isNotEmpty) {
          uiMap['musicUrl'] = music.url;
          if (music.name.isNotEmpty) uiMap['musicName'] = music.name;
          ReelHelpers.cacheMusic(uiMap['id']?.toString(), music);
        }
        context.read<ReelsCubit>().syncVideos([uiMap]);
        setState(() {
          _apiReel = uiMap;
        });
        final playable = _stagePlayableUrl(uiMap);
        final alreadyPlaying = _isStageInitialized &&
            _stageController != null &&
            _stageController!.value.isInitialized &&
            !_hasStageError;
        final sameUrlLoading = _isStageLoading &&
            playable.isNotEmpty &&
            playable == _currentLoadedVideoUrl;
        if (alreadyPlaying) {
          if (!_isStageUserPaused) _syncStageBgm(play: true);
        } else if (sameUrlLoading) {
          // Let the first open finish — do not restart and show Retry Video.
        } else if (playable.isNotEmpty) {
          final urlChanged = playable != _currentLoadedVideoUrl;
          unawaited(_initStageVideo(force: _hasStageError || urlChanged));
        }
      }
    } catch (e) {
      debugPrint('Error fetching video detail: $e');
    }
  }

  String _getFormattedCount(dynamic rawCount, dynamic rawLabel) {
    if (rawLabel is String && rawLabel.trim().isNotEmpty) {
      return rawLabel.trim();
    }
    if (rawCount is String && rawCount.trim().isNotEmpty) {
      if (RegExp(r'[a-zA-Z]').hasMatch(rawCount)) {
        return rawCount.trim();
      }
    }
    final int count = TrendingVideoItem.parseCount(rawCount);
    return TrendingVideoItem.formatCount(count);
  }

  Color _categoryBadgeColor(String category) {
    switch (category) {
      case 'Dance':
        return const Color(0xFFE01D5C);
      case 'Comedy':
        return const Color(0xFF3450D6);
      case 'Fitness':
        return const Color(0xFF1FAE6A);
      case 'Singing':
        return const Color(0xFFFF3D77);
      case 'Magic':
        return const Color(0xFF7420E8);
      case 'Art':
        return const Color(0xFFE8631F);
      case 'Sports':
        return const Color(0xFFFF7A45);
      default:
        return const Color(0xFF8B3DFF);
    }
  }

  Future<void> _onBackRefresh() async {
    if (_exitingWithAd) return;
    _exitingWithAd = true;
    // Kill BGM immediately — interstitial / dispose must not leave music running.
    ReelBgmPlaybackService.killNow();
    await _releaseStagePlayer();
    await VideoInterstitialAd.instance.show();
    if (!mounted) return;
    context.read<TrendingVideosCubit>().loadTrendingVideos(forceRefresh: true);
    context.read<HomeCubit>().loadHomeDashboard(forceRefresh: true);
    if (context.canPop()) {
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reel = _reel;
    final challenge = ReelHelpers.challengeForReel(reel);
    final reelId = reel['id']?.toString() ?? reel['_id']?.toString() ?? '';
    final relatedReels = [
      if (context.read<TrendingVideosCubit>().hero != null)
        context.read<TrendingVideosCubit>().hero!.toUiMap(),
      ...context.read<TrendingVideosCubit>().videos.map((v) => v.toUiMap()),
      ...context.read<HomeCubit>().trendingReels,
      ...context.read<ReelsCubit>().videos,
    ].where((r) {
      final id = r['id']?.toString() ?? r['_id']?.toString() ?? '';
      return id.isNotEmpty && id != reelId;
    }).toList();
    final seenRelated = <String>{};
    relatedReels.retainWhere((r) {
      final id = r['id']?.toString() ?? r['_id']?.toString() ?? '';
      if (seenRelated.contains(id)) return false;
      seenRelated.add(id);
      return true;
    });
    final creator = <String, dynamic>{
      'id': reel['userId'] ?? reel['user_id'] ?? (reel['user'] is Map ? (reel['user'] as Map)['id'] : null),
      'name': reel['creator'],
      'handle': reel['handle'],
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        unawaited(_onBackRefresh());
      },
      child: AppScreen(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppBackHeader(
              title: 'Reel',
              onBack: _onBackRefresh,
            ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                  // 1. Main Video Stage Player Card
                  _buildVideoStage(reel),

                  const SizedBox(height: 14),

                  // 2. Creator Pill Card (Deep Purple Gradient)
                  _buildCreatorCard(reel, creator),

                  const SizedBox(height: 12),

                  // 3. Caption & Hashtags
                  if ((reel['caption'] as String?)?.isNotEmpty == true)
                    Text(
                      (reel['caption'] as String).replaceAll(RegExp(r'#+'), '#'),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.text,
                        height: 1.5,
                      ),
                    ),

                  const SizedBox(height: 14),

                  // 4. 4-Column Engagement Stats Row (Views, Likes, Comments, Shares)
                  _buildEngagementStats(reel),

                  const SizedBox(height: 14),

                  // 5. Avg. Talent Score Banner
                  _buildTalentScoreBanner(reel),

                  const SizedBox(height: 16),

                  // 6. Rate This Talent Button (Vivid Gradient)
                  _buildRateButton(reel),

                  const SizedBox(height: 10),

                  // 7. Challenge Button (White Pill with Trophy)
                  if (challenge != null)
                    _buildChallengeButton(challenge),

                  const SizedBox(height: 24),

                  // 8. "More Reels" Section Header
                  Text(
                    'More Reels',
                    style: AppTextStyles.displayBold.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 9. 2-Column Grid of More Reels
                  _buildMoreReelsGrid(relatedReels),

                  const SizedBox(height: 36),
                ],
              ),
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

  // --- Main Video Stage Player ---
  Widget _buildVideoStage(Map<String, dynamic> reel) {
    final rawCat = (reel['category'] as String?)?.trim();
    final category = (rawCat != null && rawCat.isNotEmpty)
        ? rawCat.toUpperCase()
        : 'TALENT';
    final badgeColor = _categoryBadgeColor(rawCat ?? 'TALENT');
    final reelId = reel['id']?.toString() ?? reel['_id']?.toString() ?? widget.reelId ?? '';
    final imageUrl = (reel['imageUrl'] as String?) ?? (reel['thumbnailUrl'] as String?) ?? '';
    final isSaved = context.watch<ReelsCubit>().isBookmarked(reelId);

    Future<void> openReelsFeed() async {
      if (reelId.isEmpty) return;
      final enriched = Map<String, dynamic>.from(reel);
      final music = _resolveReelMusic(enriched);
      if (music != null && music.url.isNotEmpty) {
        enriched['musicUrl'] = music.url;
        if (music.name.isNotEmpty) enriched['musicName'] = music.name;
        enriched['musicStartSeconds'] = music.startSeconds;
        enriched['musicCropDuration'] = music.durationSeconds;
        ReelHelpers.cacheMusic(reelId, music);
      }
      final playable = _stagePlayableUrl(enriched);
      if (playable.isNotEmpty) {
        enriched['videoUrl'] = playable;
      }
      final effectiveClips = enriched['mergedClipPaths'] is List
          ? List<String>.from(enriched['mergedClipPaths'] as List)
          : ReelHelpers.getCachedMergedClips(reelId);
      if (effectiveClips != null && effectiveClips.isNotEmpty) {
        enriched['mergedClipPaths'] = effectiveClips;
        ReelHelpers.cacheMergedClips(reelId, effectiveClips);
      }
      context.read<ReelsCubit>().syncVideos([enriched]);

      // Release the inset player so Full Reel / Challenge Arena can open the
      // same URL without decoder / file contention ("Tap to reload video").
      await _releaseStagePlayer();
      if (!mounted) return;
      // Give ExoPlayer a beat to free the decoder / file handle.
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;
      await context.push('${AppRoutes.reelsFeed}?id=$reelId', extra: enriched);
      if (mounted) {
        await _initStageVideo();
      }
    }

    return AspectRatio(
      aspectRatio: 3 / 3.8,
      child: GestureDetector(
        onTap: () {
          if (_stageController != null && _isStageInitialized) {
            setState(() {
              if (_stageController!.value.isPlaying) {
                _stageController!.pause();
                _isStageUserPaused = true;
                _syncStageBgm(play: false);
              } else {
                _stageController!.play();
                _isStageUserPaused = false;
                _syncStageBgm(play: true);
              }
            });
          } else if (!_isStageLoading) {
            unawaited(openReelsFeed());
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF15083C).withValues(alpha: 0.2),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Base Video Thumbnail Preview
                AppFilterUtils.wrap(
                  filterId: ReelHelpers.resolveFilter(
                    filterId: reel['filterId']?.toString(),
                    beautyOn: reel['beautyOn'] == true,
                    beautyIntensity: (reel['beautyIntensity'] as num?)?.toDouble(),
                    description: (reel['description'] ?? reel['caption'])?.toString(),
                    videoId: reelId,
                    videoUrl: (reel['videoUrl'] as String?) ?? (reel['videoPath'] as String?),
                  )?.filterId ?? reel['filterId']?.toString(),
                  beautyOn: reel['beautyOn'] == true,
                  beautyIntensity: (reel['beautyIntensity'] as num?)?.toDouble() ?? 0,
                  child: AppImage(
                    url: imageUrl,
                    videoUrl: (reel['videoUrl'] as String?) ?? (reel['videoPath'] as String?),
                    fit: BoxFit.cover,
                    isVideo: true,
                  ),
                ),

                // 2. Smooth Inline Video Player
                if (_isStageInitialized &&
                    _stageController != null &&
                    _stageController!.value.isInitialized)
                  AppFilterUtils.wrap(
                    filterId: ReelHelpers.resolveFilter(
                      filterId: reel['filterId']?.toString(),
                      beautyOn: reel['beautyOn'] == true,
                      beautyIntensity: (reel['beautyIntensity'] as num?)?.toDouble(),
                      description: (reel['description'] ?? reel['caption'])?.toString(),
                      videoId: reelId,
                      videoUrl: (reel['videoUrl'] as String?) ?? (reel['videoPath'] as String?),
                    )?.filterId ?? reel['filterId']?.toString(),
                    beautyOn: reel['beautyOn'] == true,
                    beautyIntensity: (reel['beautyIntensity'] as num?)?.toDouble() ?? 0,
                    child: FittedBox(
                    fit: BoxFit.cover,
                    clipBehavior: Clip.hardEdge,
                    child: SizedBox(
                      width: _stageController!.value.size.width > 0
                          ? _stageController!.value.size.width
                          : 360,
                      height: _stageController!.value.size.height > 0
                          ? _stageController!.value.size.height
                          : 640,
                      child: RepaintBoundary(
                        child: VideoPlayer(_stageController!),
                      ),
                    ),
                  ),
                  ),

                // 3. Subtle Gradient Overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.25),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.55),
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),

                // 4. Loading indicator while video initializes
                if (_isStageLoading && !_isStageInitialized)
                  const Center(
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),

                // 4b. Buffering indicator
                if (_isStageInitialized &&
                    _stageController != null &&
                    _stageController!.value.isBuffering &&
                    !_isStageUserPaused)
                  const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                      ),
                    ),
                  ),

                // 4c. Error Retry Button
                if (_hasStageError && !_isStageLoading && !_isStageInitialized)
                  Center(
                    child: GestureDetector(
                      onTap: () => unawaited(_initStageVideo(force: true)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Retry Video',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // 5. Category Badge (Top-Left)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: badgeColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                // 6. Top-Right Save / Bookmark Icon
                Positioned(
                  top: 12,
                  right: 12,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.read<ReelsCubit>().toggleBookmark(reelId),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSaved
                              ? const Color(0xFFFF3D77)
                              : Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),

                // 7. Center Play Button (Shown when paused or not loading)
                if (!_isStageLoading &&
                    !_hasStageError &&
                    ((!_isStageInitialized) ||
                        (_stageController != null &&
                            _isStageUserPaused &&
                            !_stageController!.value.isPlaying)))
                  Center(
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.55),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),

                // 8. Bottom-Right "Full Reel" / Expand Feed Button
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => unawaited(openReelsFeed()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24, width: 0.8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fullscreen_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Full Reel',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
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
        ),
      ),
    );
  }

  // --- Creator Card (Deep Purple Card) ---
  Widget _buildCreatorCard(Map<String, dynamic> reel, Map<String, dynamic> creator) {
    final authCubit = context.read<AuthCubit>();
    final profileUser = context.read<ProfileCubit>().user;
    final currentUsername = authCubit.username.isNotEmpty
        ? authCubit.username.trim().replaceAll('@', '')
        : (profileUser?.username?.isNotEmpty == true
            ? profileUser!.username!.trim().replaceAll('@', '')
            : '');
    final currentFullName = (authCubit.fullName.isNotEmpty
            ? authCubit.fullName
            : (profileUser?.fullName ?? ''))
        .trim();

    final userMap = reel['user'] is Map
        ? Map<String, dynamic>.from(reel['user'] as Map)
        : (reel['creator'] is Map ? Map<String, dynamic>.from(reel['creator'] as Map) : null);

    String rawUsername = (reel['username']?.toString() ??
        userMap?['username']?.toString() ??
        userMap?['handle']?.toString() ??
        (reel['handle']?.toString() != '@user' ? reel['handle']?.toString() : null) ??
        (creator['handle']?.toString() != '@user' ? creator['handle']?.toString() : null) ??
        '').trim().replaceAll('@', '');

    if (rawUsername.isEmpty || rawUsername == 'user' || rawUsername == 'You') {
      if (currentUsername.isNotEmpty) {
        rawUsername = currentUsername;
      } else if (currentFullName.isNotEmpty) {
        rawUsername = currentFullName;
      }
    }

    final handle = rawUsername.isNotEmpty ? '@$rawUsername' : '@user';
    final views = _getFormattedCount(
      reel['viewsCount'] ?? reel['viewCount'] ?? reel['views'],
      reel['viewsLabel'],
    );
    final isVerified = reel['verified'] == true || reel['isBlueTick'] == true;

    final targetUserId = reel['userId']?.toString() ??
        reel['user_id']?.toString() ??
        reel['creatorId']?.toString() ??
        (reel['user'] is Map ? (reel['user'] as Map)['id']?.toString() : null) ??
        creator['id']?.toString();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (targetUserId != null && targetUserId.isNotEmpty) {
            context.push('/public-profile?id=$targetUserId');
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF180B38),
                Color(0xFF2B1362),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B0E3E).withValues(alpha: 0.22),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar with subtle white border
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: AppImage(
                  url: (reel['avatarUrl'] as String?) ?? '',
                  width: 38,
                  height: 38,
                  borderRadius: BorderRadius.circular(19),
                ),
              ),
              const SizedBox(width: 10),

              // Handle & Views
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            handle,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            size: 14,
                            color: Color(0xFF2E90FA),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$views views',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 4-Column Engagement Stats Row ---
  Widget _buildEngagementStats(Map<String, dynamic> reel) {
    final reelId = reel['id']?.toString() ?? '';
    final reelsProvider = context.watch<ReelsCubit>();
    final isLiked = reelsProvider.isLiked(reelId, fallbackVideo: reel);
    final isSaved = reelsProvider.isBookmarked(reelId);

    final currentVideo = reelsProvider.getVideo(reelId) ?? reel;

    final views = _getFormattedCount(
      currentVideo['viewsCount'] ?? currentVideo['viewCount'] ?? currentVideo['views'],
      currentVideo['viewsLabel'],
    );

    final likes = _getFormattedCount(
      currentVideo['likesCount'] ?? currentVideo['likeCount'] ?? currentVideo['likes'],
      currentVideo['likesLabel'],
    );

    final int rawComments = TrendingVideoItem.parseCount(
      currentVideo['commentsCount'] ?? currentVideo['commentCount'] ?? currentVideo['comments'],
    );
    final int commentsVal = reelsProvider.getCommentsCount(reelId, rawComments);
    final comments = (currentVideo['commentsLabel'] is String && (currentVideo['commentsLabel'] as String).isNotEmpty)
        ? currentVideo['commentsLabel'] as String
        : TrendingVideoItem.formatCount(commentsVal);

    final shares = _getFormattedCount(
      currentVideo['sharesCount'] ?? currentVideo['shareCount'] ?? currentVideo['shares'],
      currentVideo['sharesLabel'],
    );

    final saves = _getFormattedCount(
      currentVideo['savesCount'] ?? currentVideo['saveCount'] ?? currentVideo['saves'],
      currentVideo['savesLabel'],
    );

    return Row(
      children: [
        _buildStatItem(
          icon: Icons.remove_red_eye_outlined,
          value: views,
          label: 'Views',
        ),
        const SizedBox(width: 5),
        _buildStatItem(
          icon: isLiked ? Icons.favorite : Icons.favorite_border,
          iconColor: isLiked ? const Color(0xFFFF3D77) : const Color(0xFF8B3DFF),
          value: likes,
          label: 'Likes',
          onTap: () => context.read<ReelsCubit>().toggleLike(reelId, fallbackVideo: reel),
        ),
        const SizedBox(width: 5),
        _buildStatItem(
          icon: Icons.chat_bubble_outline,
          value: comments,
          label: 'Comments',
          onTap: () => context.push('${AppRoutes.comments}?id=$reelId'),
        ),
        const SizedBox(width: 5),
        _buildStatItem(
          icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
          iconColor: isSaved ? const Color(0xFFFF3D77) : const Color(0xFF8B3DFF),
          value: saves,
          label: 'Saves',
          onTap: () => context.read<ReelsCubit>().toggleBookmark(reelId),
        ),
        const SizedBox(width: 5),
        _buildStatItem(
          icon: Icons.share_outlined,
          value: shares,
          label: 'Shares',
          onTap: () {
            final vUrl = _reel['videoUrl']?.toString() ?? _reel['video_url']?.toString() ?? '';
            unawaited(VideoShareHelper.precacheVideo(vUrl, videoId: reelId));
            context.push(
              '${AppRoutes.shareReport}?id=$reelId',
              extra: {
                'reelId': reelId,
                'videoUrl': vUrl,
                'title': _reel['title']?.toString(),
                'caption': _reel['caption']?.toString(),
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF8FE),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFECE8F5),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: iconColor ?? const Color(0xFF8B3DFF),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSoft,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Avg. Talent Score Banner ---
  Widget _buildTalentScoreBanner(Map<String, dynamic> reel) {
    final reelId = reel['id']?.toString() ?? '';
    final userRating = context.watch<ReelsCubit>().getUserRating(reelId);

    double score = userRating ?? 0.0;
    if (score == 0.0) {
      if (reel['userRating'] != null && (double.tryParse(reel['userRating'].toString()) ?? 0.0) > 0) {
        score = double.tryParse(reel['userRating'].toString()) ?? 0.0;
      } else if (reel['talentScore'] is num && (reel['talentScore'] as num) > 0) {
        score = (reel['talentScore'] as num).toDouble();
      } else if (reel['averageRating'] != null && (double.tryParse(reel['averageRating'].toString()) ?? 0.0) > 0) {
        score = double.tryParse(reel['averageRating'].toString()) ?? 0.0;
      } else if (reel['score'] != null && (double.tryParse(reel['score'].toString()) ?? 0.0) > 0) {
        score = double.tryParse(reel['score'].toString()) ?? 0.0;
      } else if (reel['rating'] != null && (double.tryParse(reel['rating'].toString()) ?? 0.0) > 0) {
        score = double.tryParse(reel['rating'].toString()) ?? 0.0;
      } else if (reel['ratings'] is List && (reel['ratings'] as List).isNotEmpty) {
        for (final item in (reel['ratings'] as List)) {
          if (item is Map && item['score'] != null) {
            final s = double.tryParse(item['score'].toString()) ?? 0.0;
            if (s > 0) {
              score = s;
              break;
            }
          }
        }
      }
    }

    final displayScore = score > 0
        ? score.toStringAsFixed(1)
        : (reel['score']?.toString() ?? reel['rating']?.toString() ?? reel['averageRating']?.toString() ?? '0.0');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFFFFF8EA),
            Color(0xFFFFEFD8),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFFFD566).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.star,
            size: 18,
            color: Color(0xFFFFB800),
          ),
          const SizedBox(width: 6),
          Text(
            displayScore,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Avg. Talent Score',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSoft,
            ),
          ),
        ],
      ),
    );
  }

  // --- Rate This Talent Action Button ---
  Widget _buildRateButton(Map<String, dynamic> reel) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('${AppRoutes.talentRating}?id=${reel['id']}'),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFFFF7A45),
                Color(0xFFFF3D77),
                Color(0xFF8B3DFF),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF3D77).withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Text(
            'Rate This Talent',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // --- Challenge Secondary Button ---
  Widget _buildChallengeButton(Map<String, dynamic> challenge) {
    final title = challenge['title'] as String? ?? 'Monthly Mega Dance Battle';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('${AppRoutes.challengeDetail}?id=${challenge['id']}'),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFECE8F5),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF15083C).withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.emoji_events_outlined,
                size: 18,
                color: AppColors.text,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 2-Column More Reels Grid ---
  Widget _buildMoreReelsGrid(List<Map<String, dynamic>> reels) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reels.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, index) {
        final item = reels[index];
        final category = (item['category'] as String? ?? '').toUpperCase();
        final badgeColor = _categoryBadgeColor(item['category'] as String? ?? '');
        final isVerified = item['verified'] == true;

        return GestureDetector(
          onTap: () => context.push('${AppRoutes.videoDetail}?id=${item['id']}'),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF15083C).withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Reel Thumbnail Cover
                  AppImage(
                    url: (item['imageUrl'] as String?) ?? (item['thumbnailUrl'] as String?) ?? '',
                    videoUrl: (item['videoUrl'] as String?) ?? (item['videoPath'] as String?),
                    fit: BoxFit.cover,
                    isVideo: true,
                  ),

                  // Bottom Gradient Overlay for High Contrast Text
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.15),
                          Colors.black.withValues(alpha: 0.85),
                        ],
                        stops: const [0.4, 0.65, 1.0],
                      ),
                    ),
                  ),

                  // Category Pill (Top-Left)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: badgeColor.withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),

                  // Bottom Info (Play Count + Creator Info)
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Play Icon + View count
                        Row(
                          children: [
                            const Icon(
                              Icons.play_arrow,
                              size: 13,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              item['views'] as String? ?? '856K',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Avatar + Handle + Verified Badge
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1),
                              ),
                              child: AppImage(
                                url: item['avatarUrl'] as String,
                                width: 18,
                                height: 18,
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                item['handle'] as String? ?? '',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isVerified) ...[
                              const SizedBox(width: 3),
                              const Icon(
                                Icons.verified,
                                size: 12,
                                color: Color(0xFF2E90FA),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
