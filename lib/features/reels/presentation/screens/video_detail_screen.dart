import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';
import 'package:artable_app/core/widgets/app_back_header.dart';
import 'package:artable_app/core/widgets/app_image.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';
import 'package:artable_app/data/datasources/mock_data.dart';
import 'package:artable_app/app/routes/app_routes.dart';
import 'package:artable_app/core/utils/reel_helpers.dart';
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
  VideoPlayerController? _stageController;
  bool _isStageInitialized = false;
  bool _isStageLoading = false;
  bool _isStageUserPaused = false;
  bool _hasStageError = false;
  String? _currentLoadedVideoUrl;

  Map<String, dynamic> get _reel {
    if (_apiReel != null && _apiReel!.isNotEmpty) {
      return _apiReel!;
    }

    if (widget.initialReelData != null && widget.initialReelData!.isNotEmpty) {
      return widget.initialReelData!;
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
      if (match != null) return match;

      final singleItem = trendingCubit.getVideoById(targetId);
      if (singleItem != null) return singleItem.toUiMap();

      final reelsMatch = reelsCubit.getVideo(targetId);
      if (reelsMatch != null) return reelsMatch;
    }

    final baseMap = available.isNotEmpty
        ? available.first
        : (MockData.REELS.isNotEmpty ? MockData.REELS.first : {});

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
      }
    });
  }

  void _onStageControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initStageVideo() async {
    final reelMap = _reel;
    final vUrl = (reelMap['videoUrl'] as String?) ?? (reelMap['videoPath'] as String?) ?? '';
    final cleanUrl = MediaUrlUtils.resolve(vUrl).trim();

    if (cleanUrl.isEmpty) return;
    if (cleanUrl == _currentLoadedVideoUrl && _stageController != null && _stageController!.value.isInitialized) {
      return;
    }
    _currentLoadedVideoUrl = cleanUrl;

    if (mounted) {
      setState(() {
        _isStageLoading = true;
        _hasStageError = false;
      });
    }

    try {
      final old = _stageController;
      _stageController = null;
      old?.removeListener(_onStageControllerUpdate);
      await old?.dispose();

      final controller = await VideoCacheManager.createAndInitController(cleanUrl);
      if (!mounted) {
        controller?.dispose();
        return;
      }

      if (controller != null && controller.value.isInitialized) {
        _stageController = controller;
        controller.addListener(_onStageControllerUpdate);
        await controller.setLooping(true);
        await controller.setVolume(1.0);
        await controller.play();

        if (mounted) {
          setState(() {
            _isStageInitialized = true;
            _isStageLoading = false;
            _isStageUserPaused = false;
            _hasStageError = false;
          });
        }
        return;
      }
    } catch (e) {
      debugPrint('[VideoDetailScreen] Video stage init error: $e');
    }

    if (mounted) {
      setState(() {
        _isStageLoading = false;
        _hasStageError = true;
      });
    }
  }

  @override
  void dispose() {
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
        final uiMap = item.toUiMap();
        context.read<ReelsCubit>().syncVideos([uiMap]);
        setState(() {
          _apiReel = uiMap;
        });
        final newUrl = MediaUrlUtils.resolve(uiMap['videoUrl']?.toString() ?? '').trim();
        if (newUrl.isNotEmpty && newUrl != _currentLoadedVideoUrl) {
          _initStageVideo();
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

  void _onBackRefresh() {
    context.read<TrendingVideosCubit>().loadTrendingVideos(forceRefresh: true);
    context.read<HomeCubit>().loadHomeDashboard(forceRefresh: true);
    if (context.canPop()) {
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reel = _reel;
    final challenge = ReelHelpers.challengeForReel(reel) ??
        (MockData.CHALLENGES.isNotEmpty ? MockData.CHALLENGES.first : null);
    final relatedReels = MockData.REELS.where((r) => r['id'] != reel['id']).toList();
    final creator = MockData.CREATORS.firstWhere(
      (c) => c['name'] == reel['creator'] || c['handle'] == reel['handle'],
      orElse: () => MockData.CREATORS.first,
    );

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          context.read<TrendingVideosCubit>().loadTrendingVideos(forceRefresh: true);
          context.read<HomeCubit>().loadHomeDashboard(forceRefresh: true);
        }
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

    void openReelsFeed() {
      _stageController?.pause();
      if (reelId.isNotEmpty) {
        final effectiveClips = reel['mergedClipPaths'] is List
            ? List<String>.from(reel['mergedClipPaths'] as List)
            : ReelHelpers.getCachedMergedClips(reelId);
        if (effectiveClips != null && effectiveClips.isNotEmpty) {
          ReelHelpers.cacheMergedClips(reelId, effectiveClips);
          context.read<ReelsCubit>().syncVideos([reel]);
        }
        context.push('${AppRoutes.reelsFeed}?id=$reelId', extra: reel).then((_) {
          if (mounted && _stageController != null && !_isStageUserPaused) {
            _stageController?.play();
          }
        });
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
              } else {
                _stageController!.play();
                _isStageUserPaused = false;
              }
            });
          } else {
            openReelsFeed();
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
                AppImage(
                  url: imageUrl,
                  videoUrl: (reel['videoUrl'] as String?) ?? (reel['videoPath'] as String?),
                  fit: BoxFit.cover,
                  isVideo: true,
                ),

                // 2. Smooth Inline Video Player
                if (_isStageInitialized &&
                    _stageController != null &&
                    _stageController!.value.isInitialized)
                  FittedBox(
                    fit: BoxFit.cover,
                    clipBehavior: Clip.hardEdge,
                    child: SizedBox(
                      width: _stageController!.value.size.width > 0
                          ? _stageController!.value.size.width
                          : 360,
                      height: _stageController!.value.size.height > 0
                          ? _stageController!.value.size.height
                          : 640,
                      child: VideoPlayer(_stageController!),
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
                      onTap: _initStageVideo,
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
                    onTap: openReelsFeed,
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
