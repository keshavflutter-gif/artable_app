import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/features/reels/presentation/bloc/reels_cubit.dart';
import 'package:artable_app/features/trending/data/models/trending_videos_response.dart';
import 'package:artable_app/features/trending/presentation/bloc/trending_videos_cubit.dart';
import 'package:artable_app/features/home/presentation/bloc/home_cubit.dart';
import 'package:artable_app/app/routes/app_routes.dart';
import 'package:artable_app/core/utils/reel_helpers.dart';
import 'package:artable_app/core/widgets/app_image.dart';
import 'package:artable_app/core/widgets/app_network_image.dart';
import 'package:artable_app/features/reels/presentation/widgets/creator_info_row.dart';
import 'package:artable_app/features/reels/presentation/widgets/feed_banner_ad.dart';
import 'package:artable_app/features/reels/presentation/widgets/feed_native_ad.dart';
import 'package:artable_app/features/reels/presentation/widgets/talent_rating_slider.dart';
import 'package:artable_app/features/studio/data/services/studio_music_playback_service.dart';
import 'package:artable_app/features/reels/data/services/reel_bgm_playback_service.dart';
import 'package:artable_app/core/utils/video_share_helper.dart';
import 'package:artable_app/core/utils/video_cache_manager.dart';
import 'package:artable_app/core/utils/media_url_utils.dart';
import 'package:artable_app/core/utils/app_filter_utils.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ReelsFeedScreen extends StatefulWidget {
  const ReelsFeedScreen({super.key, this.initialReelId, this.initialReelData});

  final String? initialReelId;
  final Map<String, dynamic>? initialReelData;

  @override
  State<ReelsFeedScreen> createState() => _ReelsFeedScreenState();
}

class _ReelsFeedScreenState extends State<ReelsFeedScreen>
    with WidgetsBindingObserver {
  late final PageController _pageController;
  int _currentPage = 0;
  String? _ratingReelId;
  bool _ratingSuccess = false;
  double _ratingValue = 5;
  double _playbackSpeed = 1.0;
  final Set<String> _pausedReelIds = {};
  bool _appInBackground = false;
  Timer? _precacheDelayTimer;
  final ValueNotifier<VideoPlayerController?> _seekController =
      ValueNotifier<VideoPlayerController?>(null);

  bool _hasScrolledToInitial = false;

  List<_FeedItem> _getItems(BuildContext context, {bool listen = true}) {
    final trendingCubit = listen
        ? context.watch<TrendingVideosCubit>()
        : context.read<TrendingVideosCubit>();
    final apiTrendingVideos = trendingCubit.videos;

    final homeCubit = listen
        ? context.watch<HomeCubit>()
        : context.read<HomeCubit>();
    final homeTrendingReels = homeCubit.trendingReels;

    final reelsCubit = listen
        ? context.watch<ReelsCubit>()
        : context.read<ReelsCubit>();

    final Set<String> seenIds = {};
    final List<Map<String, dynamic>> rawList = [];

    bool isReelLive(Map<String, dynamic> r) {
      final status = r['status']?.toString().trim().toLowerCase();
      if (status != null && (status == 'draft' || status.contains('draft'))) {
        return false;
      }
      if (r['canContinueDraft'] == true ||
          r['isDraft'] == true ||
          r['draft'] == true ||
          r['type']?.toString().trim().toLowerCase() == 'draft') {
        return false;
      }
      final statusLabel = r['statusLabel']?.toString().trim().toLowerCase();
      if (statusLabel != null && (statusLabel == 'draft' || statusLabel.contains('draft'))) {
        return false;
      }
      final badgeLabel = (r['statusBadge'] is Map ? r['statusBadge']['label'] : null)?.toString().trim().toLowerCase();
      if (badgeLabel != null && (badgeLabel == 'draft' || badgeLabel.contains('draft'))) {
        return false;
      }

      if (status == 'rejected' ||
          status == 'deleted' ||
          status == 'inactive' ||
          status == 'under_review' ||
          status == 'pending_review' ||
          status == 'archived') {
        return false;
      }

      if (r['isLive'] == true || r['is_live'] == true) {
        return true;
      }
      if (status == 'live' || status == 'approved' || status == 'published' || status == 'active') {
        return true;
      }

      final vUrl = r['videoUrl']?.toString() ?? '';
      final hasClips = r['mergedClipPaths'] is List && (r['mergedClipPaths'] as List).isNotEmpty;
      if (vUrl.isEmpty && !hasClips) {
        return false;
      }

      return true;
    }

    void addReels(List<Map<String, dynamic>> list) {
      for (final r in list) {
        if (!isReelLive(r)) continue;
        final id = r['id']?.toString() ?? r['_id']?.toString() ?? '';
        final vUrl = r['videoUrl']?.toString() ?? '';
        if (r['mergedClipPaths'] == null || (r['mergedClipPaths'] is List && (r['mergedClipPaths'] as List).isEmpty)) {
          final descClips = ReelHelpers.parseDescriptionClips(r['description']?.toString() ?? r['caption']?.toString()).clips;
          final cached = descClips ?? ReelHelpers.getCachedMergedClips(id) ?? ReelHelpers.getCachedMergedClips(vUrl);
          if (cached != null && cached.isNotEmpty) {
            r['mergedClipPaths'] = cached;
          }
        }
        if (id.isNotEmpty && !seenIds.contains(id)) {
          seenIds.add(id);
          rawList.add(r);
        }
      }
    }

    if (widget.initialReelData != null && widget.initialReelData!.isNotEmpty) {
      addReels([widget.initialReelData!]);
    }
    if (trendingCubit.hero != null) {
      addReels([trendingCubit.hero!.toUiMap()]);
    }
    if (apiTrendingVideos.isNotEmpty) {
      addReels(apiTrendingVideos.map((v) => v.toUiMap()).toList());
    }
    if (homeTrendingReels.isNotEmpty) {
      addReels(homeTrendingReels);
    }
    if (reelsCubit.videos.isNotEmpty) {
      addReels(reelsCubit.videos);
    }

    final targetId = widget.initialReelId?.trim();
    if (targetId != null && targetId.isNotEmpty) {
      final existingIndex = rawList.indexWhere(
        (r) => r['id']?.toString() == targetId || r['_id']?.toString() == targetId,
      );
      if (existingIndex > 0) {
        final targetItem = rawList.removeAt(existingIndex);
        rawList.insert(0, targetItem);
      } else if (existingIndex == -1) {
        final singleItem = trendingCubit.getVideoById(targetId);
        if (singleItem != null && singleItem.isVideoLive && !singleItem.isDraft) {
          rawList.insert(0, singleItem.toUiMap());
          seenIds.add(targetId);
        } else {
          final helperMatch = ReelHelpers.reelById(targetId, availableReels: rawList);
          if (helperMatch != null && isReelLive(helperMatch)) {
            rawList.insert(0, helperMatch);
            seenIds.add(targetId);
          }
        }
      }
    }

    final cards = <_FeedItem>[];
    var sinceAd = 0;
    var nextNative = true;
    for (final reel in rawList) {
      cards.add(_FeedItem.reel(reel));
      sinceAd++;
      if (sinceAd == 3) {
        cards.add(
          nextNative ? const _FeedItem.nativeAd() : const _FeedItem.bannerAd(),
        );
        nextNative = !nextNative;
        sinceAd = 0;
      }
    }
    return cards;
  }

  void _fetchCommentsForPage(int page) {
    final items = _getItems(context, listen: false);
    if (page >= 0 && page < items.length) {
      final item = items[page];
      if (!item.isAd && item.reel != null) {
        final rId = item.reel!['id']?.toString() ?? item.reel!['_id']?.toString() ?? '';
        if (rId.isNotEmpty) {
          context.read<ReelsCubit>().fetchComments(rId);
        }
      }
    }
  }

  void _precacheUpcomingReels(int page, List<_FeedItem> items) {
    // Delay so the visible reel can stream without competing downloads.
    _precacheDelayTimer?.cancel();
    _precacheDelayTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      unawaited(() async {
        for (final nextIdx in [page + 2, page + 3]) {
          if (!mounted) return;
          if (nextIdx >= 0 && nextIdx < items.length) {
            final nextItem = items[nextIdx];
            if (!nextItem.isAd && nextItem.reel != null) {
              final vUrl = nextItem.reel!['videoUrl']?.toString();
              if (vUrl != null && vUrl.isNotEmpty) {
                await VideoCacheManager.precacheVideo(vUrl);
              }
            }
          }
        }
      }());
    });
  }

  void _scrollToInitialIfNeeded(List<_FeedItem> items) {
    if (_hasScrolledToInitial) return;
    final targetId = widget.initialReelId?.trim();
    if (targetId == null || targetId.isEmpty) {
      _hasScrolledToInitial = true;
      _fetchCommentsForPage(_currentPage);
      _precacheUpcomingReels(_currentPage, items);
      return;
    }
    final found = items.indexWhere(
      (item) =>
          !item.isAd &&
          (item.reel?['id']?.toString() == targetId ||
           item.reel?['_id']?.toString() == targetId),
    );
    if (found != -1) {
      _hasScrolledToInitial = true;
      _fetchCommentsForPage(found);
      _precacheUpcomingReels(found, items);
      if (found != _currentPage) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _pageController.hasClients) {
            _pageController.jumpToPage(found);
            setState(() {
              _currentPage = found;
            });
          }
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(WakelockPlus.enable());
    unawaited(StudioMusicPlaybackService.releaseForVideoPlayback());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final trendingCubit = context.read<TrendingVideosCubit>();
        if (!trendingCubit.hasLoaded && !trendingCubit.isLoading) {
          trendingCubit.loadTrendingVideos();
        }
        _fetchCommentsForPage(_currentPage);
        _precacheUpcomingReels(_currentPage, _getItems(context, listen: false));
      }
    });

    int initialIndex = 0;
    if (widget.initialReelId != null && widget.initialReelId!.trim().isNotEmpty) {
      final targetId = widget.initialReelId!.trim();
      final items = _getItems(context, listen: false);
      final found = items.indexWhere(
        (item) =>
            !item.isAd &&
            (item.reel?['id']?.toString() == targetId ||
             item.reel?['_id']?.toString() == targetId),
      );
      if (found != -1) {
        initialIndex = found;
      }
    }
    _currentPage = initialIndex;
    _pageController = PageController(initialPage: initialIndex);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _precacheDelayTimer?.cancel();
    _seekController.value = null;
    _seekController.dispose();
    _pageController.dispose();
    unawaited(ReelBgmPlaybackService.stop());
    unawaited(WakelockPlus.disable());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final background = state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden;
    if (background) {
      unawaited(WakelockPlus.disable());
      if (mounted) setState(() => _appInBackground = true);
    } else if (state == AppLifecycleState.resumed) {
      unawaited(WakelockPlus.enable());
      if (mounted) setState(() => _appInBackground = false);
    }
  }

  String? _currentReelIdFrom(List<_FeedItem> items) {
    if (_currentPage < 0 || _currentPage >= items.length) return null;
    final reel = items[_currentPage].reel;
    return reel?['id']?.toString() ?? reel?['_id']?.toString();
  }

  void _onSeekScrubStart() {
    _seekController.value?.pause();
    unawaited(ReelBgmPlaybackService.pause());
  }

  void _onSeekScrubEnd(List<_FeedItem> items) {
    final controller = _seekController.value;
    if (controller == null) return;
    final reelId = _currentReelIdFrom(items);
    final paused =
        _appInBackground || (reelId != null && _pausedReelIds.contains(reelId));
    if (!paused) {
      unawaited(controller.play());
    }
    final reel = (_currentPage >= 0 && _currentPage < items.length)
        ? items[_currentPage].reel
        : null;
    if (reel == null || paused) return;
    final direct = (reel['musicUrl'] as String?)?.trim();
    final parsed = ReelHelpers.parseDescriptionMusic(
      (reel['caption'] ?? reel['description'])?.toString(),
    );
    final url = (direct != null && direct.isNotEmpty && direct != 'null')
        ? direct
        : parsed?.url;
    if (url == null || url.isEmpty) return;
    final start = (reel['musicStartSeconds'] as num?)?.toDouble() ??
        parsed?.startSeconds ??
        0;
    unawaited(ReelBgmPlaybackService.sync(
      reelId: reelId ?? url,
      url: url,
      startMs: (start * 1000).round(),
      videoPositionMs: controller.value.position.inMilliseconds,
      shouldPlay: true,
      speed: _playbackSpeed,
    ));
  }

  void _toggleReelPause(String reelId) {
    if (reelId.isEmpty) return;
    setState(() {
      if (_pausedReelIds.contains(reelId)) {
        _pausedReelIds.remove(reelId);
      } else {
        _pausedReelIds.add(reelId);
      }
    });
  }

  void _openRating(String reelId, [Map<String, dynamic>? reelMap]) {
    final reelsCubit = context.read<ReelsCubit>();
    final userRating = reelsCubit.getUserRating(reelId);
    final video = reelsCubit.getVideo(reelId) ?? reelMap;

    double initialRating = userRating ?? 5.0;
    if (userRating == null && video != null) {
      if (video['userRating'] != null) {
        initialRating = double.tryParse(video['userRating'].toString()) ?? 5.0;
      } else if (video['score'] != null) {
        initialRating = double.tryParse(video['score'].toString()) ?? 5.0;
      } else if (video['rating'] != null) {
        initialRating = double.tryParse(video['rating'].toString()) ?? 5.0;
      } else if (video['talentScore'] is num) {
        initialRating = (video['talentScore'] as num).toDouble();
      } else if (video['ratings'] is List && (video['ratings'] as List).isNotEmpty) {
        for (final item in (video['ratings'] as List)) {
          if (item is Map && item['score'] != null) {
            final parsed = double.tryParse(item['score'].toString());
            if (parsed != null && parsed > 0) {
              initialRating = parsed;
              break;
            }
          }
        }
      }
    }

    setState(() {
      _ratingReelId = reelId;
      _ratingSuccess = false;
      _ratingValue = initialRating.clamp(0.0, 10.0);
    });
  }

  void _closeRating() {
    setState(() {
      _ratingReelId = null;
      _ratingSuccess = false;
    });
  }

  void _openSpeedBottomSheet() {
    double modalSpeed = _playbackSpeed;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final speedOptions = [0.4, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 3.0, 4.0];
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              decoration: BoxDecoration(
                color: const Color(0xFF140A28),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: const Color(0xFF332059)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 24,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.speed,
                            color: Color(0xFFFF5487),
                            size: 22,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Playback Speed',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: AppGradients.button,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${modalSpeed.toStringAsFixed(1)}x',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: speedOptions.map((speed) {
                      final isSelected = (modalSpeed - speed).abs() < 0.01;
                      final label = speed == 1.0 ? '1.0x Normal' : '${speed}x';
                      return ChoiceChip(
                        label: Text(label),
                        selected: isSelected,
                        selectedColor: const Color(0xFFFF5487),
                        backgroundColor: const Color(0xFF231442),
                        labelStyle: TextStyle(
                          color: Colors.white,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 12.5,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFFFF5487)
                              : Colors.white.withValues(alpha: 0.15),
                        ),
                        onSelected: (bool selected) {
                          if (selected) {
                            modalSpeed = speed;
                            setState(() {
                              _playbackSpeed = speed;
                            });
                            setModalState(() {});
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        '0.4x',
                        style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Adjust Playback Speed (0.4x - 4.0x)',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '4.0x',
                        style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: const Color(0xFFFF5487),
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
                      thumbColor: Colors.white,
                      overlayColor: const Color(0xFFFF5487).withValues(alpha: 0.2),
                      valueIndicatorColor: const Color(0xFFFF5487),
                      valueIndicatorTextStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: Slider(
                      value: modalSpeed.clamp(0.4, 4.0),
                      min: 0.4,
                      max: 4.0,
                      divisions: 36,
                      label: '${modalSpeed.toStringAsFixed(1)}x',
                      onChanged: (val) {
                        final rounded = double.parse(val.toStringAsFixed(1));
                        setModalState(() {
                          modalSpeed = rounded;
                        });
                      },
                      onChangeEnd: (val) {
                        final rounded = double.parse(val.toStringAsFixed(1));
                        modalSpeed = rounded;
                        setState(() {
                          _playbackSpeed = rounded;
                        });
                        setModalState(() {});
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final reelsProvider = context.watch<ReelsCubit>();
    final items = _getItems(context);
    _scrollToInitialIfNeeded(items);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    const sliderHitHeight = 20.0;
    const viewsSliderGap = 18.0;
    final sliderBottom = bottomInset;
    final captionBottom = sliderBottom + sliderHitHeight + viewsSliderGap;
    final actionsBottom = captionBottom + 78;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0714),
      body: Stack(
        children: [
          if (items.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.movie_filter_outlined,
                      size: 52,
                      color: Color(0xFF8B849C),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No trending videos available right now.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
          PageView.builder(
            controller: _pageController,
            // Keep the adjacent pages built so the next reel can pre-initialize
            // its player while the current one is being watched.
            allowImplicitScrolling: true,
            onPageChanged: (page) {
              setState(() {
                _currentPage = page;
                _pausedReelIds.clear();
              });
              _fetchCommentsForPage(page);
              _precacheUpcomingReels(page, items);
            },
            scrollDirection: Axis.vertical,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              if (item.isNativeAd) {
                return const FeedNativeAd(fallback: _AdReelCard());
              }
              if (item.isBannerAd) {
                return const FeedBannerAd(fallback: _AdReelCard());
              }
              final rawReel = item.reel!;
              final reelId = rawReel['id']?.toString() ?? rawReel['_id']?.toString() ?? '';
              final reel = reelsProvider.getVideo(reelId) ?? rawReel;
              final challenge = ReelHelpers.challengeForReel(reel);
              final liked = reelsProvider.isLiked(reelId, fallbackVideo: reel);
              final saved = reelsProvider.isBookmarked(reelId);
              final videoUrl = (reel['videoUrl'] as String?)?.isNotEmpty == true && reel['videoUrl'] != 'null'
                  ? reel['videoUrl'] as String
                  : '';
              final imageUrl = reel['imageUrl'] as String? ?? reel['thumbnailUrl'] as String? ?? '';
              final isActive = index == _currentPage;
              final preloadNext = index == _currentPage + 1;
              final preloadPrev = index == _currentPage - 1;
              final forcePaused =
                  _appInBackground || _pausedReelIds.contains(reelId);

              final int rawLikes = TrendingVideoItem.parseCount(reel['likesCount'] ?? reel['likes']);
              final String likesText = TrendingVideoItem.formatCount(rawLikes);

              final int rawComments = reel['commentsCount'] is int
                  ? reel['commentsCount'] as int
                  : (int.tryParse(reel['comments']?.toString() ?? '') ?? 0);
              final int displayCommentsVal = reelsProvider.getCommentsCount(reelId, rawComments);
              final String commentsText = _formatCount(displayCommentsVal);

              final int rawShares = reel['sharesCount'] is int
                  ? reel['sharesCount'] as int
                  : (int.tryParse(reel['shares']?.toString() ?? '') ?? 0);
              final String sharesText = (reel['shares'] as String?)?.isNotEmpty == true
                  ? reel['shares'] as String
                  : _formatCount(rawShares);

              final String viewsText = (reel['views'] as String?)?.isNotEmpty == true
                  ? reel['views'] as String
                  : _formatCount(reel['viewsCount'] is int ? reel['viewsCount'] as int : 0);

              final String? categoryName = (reel['category'] as String?)?.trim();
              final String? challengeTitle = (reel['challengeTitle'] as String?)?.trim() ??
                  (challenge?['title'] as String?)?.trim();
              final String? musicName = (reel['musicName'] as String?)?.trim();
              final String? embeddedMusicName =
                  ReelHelpers.parseDescriptionMusic((reel['caption'] ?? reel['description'])?.toString())?.name;
              final String creatorName = (reel['creator'] as String?)?.trim() ??
                  (reel['handle'] as String?)?.trim() ?? '';
              final String soundText = (embeddedMusicName != null && embeddedMusicName.isNotEmpty)
                  ? embeddedMusicName
                  : ((musicName != null && musicName.isNotEmpty)
                      ? musicName
                      : (creatorName.isNotEmpty ? 'Original Sound — $creatorName' : 'Original Sound'));

              return Stack(
                fit: StackFit.expand,
                children: [
                  _ReelVideoPlayer(
                    key: ValueKey(reel['id']),
                    videoUrl: videoUrl,
                    thumbnailUrl: imageUrl,
                    isActive: isActive,
                    preloadNext: preloadNext,
                    preloadPrev: preloadPrev,
                    forcePaused: forcePaused,
                    userPaused: _pausedReelIds.contains(reelId),
                    playbackSpeed: _playbackSpeed,
                    reelId: reel['id']?.toString() ?? reel['_id']?.toString(),
                    caption: (reel['description'] ?? reel['caption'])?.toString(),
                    filterId: reel['filterId']?.toString(),
                    beautyOn: reel['beautyOn'] == true,
                    beautyIntensity: (reel['beautyIntensity'] as num?)?.toDouble() ?? 0,
                    trimStart: (reel['videoTrimStartSeconds'] as num?)?.toDouble(),
                    trimEnd: (reel['videoTrimEndSeconds'] as num?)?.toDouble(),
                    mergedClipPaths: (reel['mergedClipPaths'] is List)
                        ? List<String>.from(reel['mergedClipPaths'] as List)
                        : null,
                    musicUrl: (reel['musicUrl'] as String?)?.trim(),
                    musicStartSeconds: (reel['musicStartSeconds'] as num?)?.toDouble(),
                    seekController: _seekController,
                  ),
                  const IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x590A0514),
                            Color(0x0D0A0514),
                            Color(0x330A0514),
                            Color(0xEB06030E),
                          ],
                          stops: [0, 0.22, 0.55, 1],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 24,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => _toggleReelPause(reelId),
                    ),
                  ),
                  Positioned(
                    top: 50,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            if (context.canPop()) ...[
                              GestureDetector(
                                onTap: () => context.pop(),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black.withValues(alpha: 0.35),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            const Text(
                              '🏆 Challenge Arena',
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black45,
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => context.push(AppRoutes.search),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.18),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.search,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () => context.push(AppRoutes.notifications),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.18),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.notifications_none_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (categoryName != null && categoryName.isNotEmpty)
                    Positioned(
                      top: 92,
                      left: 18,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 4),
                        decoration: BoxDecoration(
                          color: ReelHelpers.categoryTint(categoryName),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: ReelHelpers.categoryTint(categoryName)
                                  .withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          categoryName.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    right: 14,
                    bottom: actionsBottom,
                    child: Column(
                      children: [
                        _ActionBtn(
                          icon: liked ? Icons.favorite : Icons.favorite_border,
                          count: likesText,
                          active: liked,
                          onTap: () => context
                              .read<ReelsCubit>()
                              .toggleLike(reelId, fallbackVideo: reel),
                        ),
                        const SizedBox(height: 14),
                        _ActionBtn(
                          icon: Icons.chat_bubble_outline,
                          count: commentsText,
                          onTap: () => context
                              .push('${AppRoutes.comments}?id=$reelId'),
                        ),
                        const SizedBox(height: 14),
                        _ActionBtn(
                          icon: Icons.star,
                          count: 'Rate',
                          rateStyle: true,
                          onTap: () => _openRating(reelId, reel),
                        ),
                        const SizedBox(height: 14),
                        _ActionBtn(
                          icon: Icons.speed,
                          count: _playbackSpeed == 1.0 ? 'Speed' : '${_playbackSpeed.toStringAsFixed(1)}x',
                          active: _playbackSpeed != 1.0,
                          onTap: _openSpeedBottomSheet,
                        ),
                        const SizedBox(height: 14),
                        _ActionBtn(
                          icon: Icons.share_outlined,
                          count: sharesText,
                          onTap: () {
                            final rawUrl = reel['videoUrl'] ??
                                reel['video_url'] ??
                                reel['video'] ??
                                reel['mediaUrl'];
                            final vUrl = (rawUrl is String && rawUrl.isNotEmpty && rawUrl != 'null')
                                ? rawUrl
                                : '';
                            unawaited(VideoShareHelper.precacheVideo(vUrl, videoId: reelId));
                            context.push(
                              '${AppRoutes.shareReport}?id=$reelId',
                              extra: {
                                'reelId': reelId,
                                'videoUrl': vUrl,
                                'title': reel['title']?.toString(),
                                'caption': reel['caption']?.toString(),
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        _ActionBtn(
                          icon: saved ? Icons.bookmark : Icons.bookmark_border,
                          count: saved ? 'Saved' : 'Save',
                          active: saved,
                          onTap: () => context
                              .read<ReelsCubit>()
                              .toggleBookmark(reelId),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 78,
                    bottom: captionBottom,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CreatorInfoRow(reel: reel, lightText: true),
                        GestureDetector(
                          onTap: () => context
                              .push('${AppRoutes.videoDetail}?id=$reelId'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (challengeTitle != null && challengeTitle.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                _MetaRow(
                                  icon: Icons.emoji_events_outlined,
                                  text: challengeTitle,
                                ),
                              ],
                              const SizedBox(height: 8),
                              _MetaRow(
                                icon: Icons.music_note,
                                text: soundText,
                              ),
                              if ((reel['caption'] as String?)?.isNotEmpty == true ||
                                  (reel['description'] as String?)?.isNotEmpty == true) ...[
                                const SizedBox(height: 8),
                                Text(
                                  ((reel['caption'] as String?)?.isNotEmpty == true
                                          ? reel['caption'] as String
                                          : reel['description'] as String)
                                      .replaceAll(RegExp(r'#+'), '#'),
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    height: 1.4,
                                    color: Colors.white.withValues(alpha: 0.92),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              _MetaRow(
                                icon: Icons.remove_red_eye_outlined,
                                text: '$viewsText views',
                                muted: true,
                              ),
                              const SizedBox(height: 6),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          if (items.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: sliderBottom,
              child: ValueListenableBuilder<VideoPlayerController?>(
                valueListenable: _seekController,
                builder: (context, controller, _) {
                  if (controller == null || !controller.value.isInitialized) {
                    return const IgnorePointer(
                      child: SizedBox(
                        height: sliderHitHeight,
                        width: double.infinity,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: SizedBox(
                            height: 3,
                            width: double.infinity,
                            child: ColoredBox(color: Color(0x47FFFFFF)),
                          ),
                        ),
                      ),
                    );
                  }
                  final reel = items[_currentPage.clamp(0, items.length - 1)].reel;
                  final trimStart =
                      (reel?['videoTrimStartSeconds'] as num?)?.toDouble() ?? 0;
                  final trimEnd =
                      (reel?['videoTrimEndSeconds'] as num?)?.toDouble();
                  return _InstagramSeekBar(
                    key: ObjectKey(controller),
                    controller: controller,
                    enabled: !_appInBackground,
                    trimStart: trimStart > 0
                        ? Duration(milliseconds: (trimStart * 1000).round())
                        : Duration.zero,
                    trimEnd: trimEnd != null
                        ? Duration(milliseconds: (trimEnd * 1000).round())
                        : null,
                    onScrubStart: _onSeekScrubStart,
                    onScrubEnd: () => _onSeekScrubEnd(items),
                  );
                },
              ),
            ),
          if (_ratingReelId != null) ...[
            GestureDetector(
              onTap: _closeRating,
              child: Container(color: Colors.black.withValues(alpha: 0.6)),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF140A28),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFF332059)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Rate Talent Performance',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            onPressed: _closeRating,
                            icon: const Icon(Icons.close, color: Colors.white70),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TalentRatingSlider(
                        initialValue: _ratingValue,
                        onChanged: (val) => setState(() => _ratingValue = val),
                      ),
                      const SizedBox(height: 16),
                      if (_ratingSuccess)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A2B),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, color: Color(0xFF3CD98A), size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Rating Submitted Successfully!',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF3CD98A),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: () {
                            context.read<ReelsCubit>().rateVideo(_ratingReelId!, _ratingValue);
                            setState(() {
                              _ratingSuccess = true;
                            });
                            Future.delayed(const Duration(milliseconds: 1200), _closeRating);
                          },
                          child: Container(
                            width: double.infinity,
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: AppGradients.button,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Text(
                              'Submit Rating',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReelVideoPlayer extends StatefulWidget {
  const _ReelVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.isActive,
    this.preloadNext = false,
    this.preloadPrev = false,
    this.forcePaused = false,
    this.userPaused = false,
    this.playbackSpeed = 1.0,
    this.reelId,
    this.caption,
    this.trimStart,
    this.trimEnd,
    this.mergedClipPaths,
    this.musicUrl,
    this.musicStartSeconds,
    this.seekController,
    this.filterId,
    this.beautyOn = false,
    this.beautyIntensity = 0,
  });

  final String videoUrl;
  final String thumbnailUrl;
  final bool isActive;
  /// True when this reel is the one directly after the active reel. Its player
  /// is initialized (paused) ahead of time so that swiping to it plays instantly.
  final bool preloadNext;
  final bool preloadPrev;
  final bool forcePaused;
  final bool userPaused;
  final double playbackSpeed;
  final String? reelId;
  final String? caption;
  final double? trimStart;
  final double? trimEnd;
  final List<String>? mergedClipPaths;
  final String? musicUrl;
  final double? musicStartSeconds;
  final ValueNotifier<VideoPlayerController?>? seekController;
  final String? filterId;
  final bool beautyOn;
  final double beautyIntensity;

  @override
  State<_ReelVideoPlayer> createState() => _ReelVideoPlayerState();
}

class _ReelVideoPlayerState extends State<_ReelVideoPlayer>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive =>
      widget.isActive || widget.preloadNext || widget.preloadPrev;

  VideoPlayerController? _controller;
  final Map<int, VideoPlayerController> _clipControllers = {};
  bool _isInitializing = false;
  bool _isInitialized = false;
  bool _hasError = false;
  int _currentClipIndex = 0;
  bool _isSwitchingClip = false;
  Timer? _playbackTimer;
  Timer? _loadingHintTimer;
  bool _showSlowLoading = false;
  bool _isSeekingToStart = false;
  /// Incremented whenever controllers are disposed; lets an in-flight
  /// _initVideo detect that its result is stale and discard it.
  int _initGeneration = 0;

  /// Whether this reel should hold an initialized player right now.
  bool get _shouldHoldPlayer =>
      widget.isActive || widget.preloadNext || widget.preloadPrev;

  VideoPlayerController? get _activeController =>
      _hasMultiClips ? _clipControllers[_currentClipIndex] : _controller;

  void _publishSeekController() {
    final notifier = widget.seekController;
    if (notifier == null) return;
    if (widget.isActive && _isInitialized) {
      final active = _activeController;
      if (active != null && active.value.isInitialized) {
        if (!identical(notifier.value, active)) {
          notifier.value = active;
        }
        return;
      }
    }
    if (identical(notifier.value, _controller) ||
        identical(notifier.value, _activeController) ||
        _clipControllers.values.any((c) => identical(notifier.value, c))) {
      notifier.value = null;
    }
  }

  List<String> get _effectiveMergedClips {
    if (widget.mergedClipPaths != null && widget.mergedClipPaths!.length > 1) {
      return widget.mergedClipPaths!;
    }
    if (widget.reelId != null && widget.reelId!.isNotEmpty) {
      final cachedById = ReelHelpers.getCachedMergedClips(widget.reelId);
      if (cachedById != null && cachedById.length > 1) {
        return cachedById;
      }
    }
    final cached = ReelHelpers.getCachedMergedClips(widget.videoUrl);
    if (cached != null && cached.length > 1) {
      return cached;
    }
    if (widget.caption != null && widget.caption!.isNotEmpty) {
      final descClips = ReelHelpers.parseDescriptionClips(widget.caption).clips;
      if (descClips != null && descClips.length > 1) {
        return descClips;
      }
    }
    return widget.mergedClipPaths ?? const [];
  }

  bool get _hasMultiClips => _effectiveMergedClips.length > 1;

  String? get _bgmUrl {
    final direct = widget.musicUrl?.trim();
    if (direct != null && direct.isNotEmpty && direct != 'null') return direct;
    return ReelHelpers.parseDescriptionMusic(widget.caption)?.url;
  }

  double get _bgmStartSeconds =>
      widget.musicStartSeconds ??
      ReelHelpers.parseDescriptionMusic(widget.caption)?.startSeconds ??
      0;

  bool get _hasBgm => _bgmUrl != null && _bgmUrl!.isNotEmpty;

  double get _videoVolume => _hasBgm ? 0.0 : 1.0;

  ({String filterId, bool beautyOn, double beautyIntensity})? _filterMeta;

  void _refreshFilterMeta() {
    _filterMeta = ReelHelpers.resolveFilter(
      filterId: widget.filterId,
      beautyOn: widget.beautyOn,
      beautyIntensity: widget.beautyIntensity,
      description: widget.caption,
      videoId: widget.reelId,
      videoUrl: widget.videoUrl,
    );
  }

  Widget _withRecordingFilter(Widget child) {
    final meta = _filterMeta;
    if (meta == null) return child;
    return RepaintBoundary(
      child: AppFilterUtils.buildFilteredView(
        filterId: meta.filterId,
        beautyOn: meta.beautyOn,
        beautyIntensity: meta.beautyIntensity,
        performanceMode: true,
        child: child,
      ),
    );
  }

  String get _bgmReelKey =>
      (widget.reelId != null && widget.reelId!.isNotEmpty)
          ? widget.reelId!
          : widget.videoUrl;

  void _syncBgm({bool play = true}) {
    final url = _bgmUrl;
    if (url == null || url.isEmpty) return;
    if (!widget.isActive || !play || widget.forcePaused) {
      unawaited(ReelBgmPlaybackService.pause());
      return;
    }
    final pos = _activeController?.value.position.inMilliseconds ?? 0;
    unawaited(ReelBgmPlaybackService.sync(
      reelId: _bgmReelKey,
      url: url,
      startMs: (_bgmStartSeconds * 1000).round(),
      videoPositionMs: pos,
      shouldPlay: true,
      speed: widget.playbackSpeed,
    ));
  }

  @override
  void initState() {
    super.initState();
    _refreshFilterMeta();
    _logDebugInfo();
    // Initialize if this reel is visible, or is the next one up (pre-warm).
    if (_shouldHoldPlayer) {
      _initVideo();
    }
  }

  void _logDebugInfo() {
    debugPrint('=== TRENDING REEL VIDEO ===');
    debugPrint('Video URL: ${widget.videoUrl}');
    debugPrint('Thumbnail URL: ${widget.thumbnailUrl}');
    if (widget.mergedClipPaths != null) {
      debugPrint('Merged Clips: ${widget.mergedClipPaths!.length}');
    }
  }

  Duration get _playbackStart {
    if (_hasMultiClips) return Duration.zero;
    final trimStart = widget.trimStart ?? 0.0;
    if (trimStart > 0) {
      return Duration(milliseconds: (trimStart * 1000).round());
    }
    return Duration.zero;
  }

  /// Rewind to clip/trim start so a swipe-back always plays from the beginning.
  Future<void> _resetToStart({required bool thenPlay}) async {
    if (_hasMultiClips && _currentClipIndex != 0) {
      final old = _clipControllers[_currentClipIndex];
      old?.removeListener(_onVideoControllerUpdate);
      unawaited(old?.pause());
      unawaited(old?.seekTo(Duration.zero));
      _currentClipIndex = 0;
      final first = _clipControllers[0];
      if (first != null && first.value.isInitialized) {
        first.removeListener(_onVideoControllerUpdate);
        first.addListener(_onVideoControllerUpdate);
      }
      if (mounted) setState(() {});
    }

    final active = _activeController;
    if (active == null || !active.value.isInitialized) return;
    try {
      await active.seekTo(_playbackStart);
    } catch (_) {}
    if (!mounted) return;
    if (thenPlay && widget.isActive && !widget.forcePaused) {
      unawaited(active.play());
      _syncBgm(play: true);
    } else {
      unawaited(active.pause());
      _syncBgm(play: false);
    }
  }

  String? _resolvePlayableUrl(String rawUrl) {
    final clean = rawUrl.trim();
    if (clean.isEmpty || clean == 'null') {
      return null;
    }
    if (MediaUrlUtils.looksLikeImageUrl(clean)) {
      return null;
    }
    return MediaUrlUtils.resolve(clean);
  }

  @override
  void didUpdateWidget(covariant _ReelVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filterId != oldWidget.filterId ||
        widget.beautyOn != oldWidget.beautyOn ||
        widget.beautyIntensity != oldWidget.beautyIntensity ||
        widget.caption != oldWidget.caption ||
        widget.videoUrl != oldWidget.videoUrl) {
      _refreshFilterMeta();
    }
    if (widget.videoUrl != oldWidget.videoUrl ||
        widget.mergedClipPaths != oldWidget.mergedClipPaths) {
      _logDebugInfo();
      _currentClipIndex = 0;
      _disposeControllers();
      if (_shouldHoldPlayer) {
        _initVideo();
      }
    } else if (widget.isActive != oldWidget.isActive ||
        widget.preloadNext != oldWidget.preloadNext ||
        widget.preloadPrev != oldWidget.preloadPrev ||
        widget.forcePaused != oldWidget.forcePaused) {
      final active = _activeController;
      if (widget.isActive) {
        _hasError = false;
        if (active == null) {
          // If a pre-warm init is still running it will play on completion.
          if (!_isInitializing) _initVideo();
        } else if (_isInitialized) {
          if (widget.forcePaused) {
            active.pause();
            _syncBgm(play: false);
          } else if (!oldWidget.isActive) {
            // Swiped onto this reel — always start from the beginning.
            unawaited(active.setVolume(_videoVolume));
            unawaited(_resetToStart(thenPlay: true));
          } else {
            unawaited(active.play());
            unawaited(active.setVolume(_videoVolume));
            if (widget.playbackSpeed != 1.0) {
              try {
                active.setPlaybackSpeed(widget.playbackSpeed);
              } catch (_) {}
            }
            _syncBgm(play: true);
          }
        }
      } else if (widget.preloadNext || widget.preloadPrev) {
        _syncBgm(play: false);
        if (active != null && _isInitialized) {
          if (oldWidget.isActive) {
            unawaited(_resetToStart(thenPlay: false));
          } else {
            unawaited(active.pause());
          }
        } else if (active == null && !_isInitializing) {
          _initVideo();
        }
      } else {
        _syncBgm(play: false);
        if (active != null && _isInitialized) {
          active.pause();
        }
        _disposeControllers();
      }
    } else if (widget.playbackSpeed != oldWidget.playbackSpeed) {
      unawaited(_applyPlaybackSpeed(widget.playbackSpeed));
    }
    updateKeepAlive();
    _publishSeekController();
  }

  Future<void> _applyPlaybackSpeed(double speed) async {
    Future<void> applyTo(VideoPlayerController c) async {
      try {
        await c.setPlaybackSpeed(speed);
      } catch (_) {}
    }

    final active = _activeController;
    if (active != null && active.value.isInitialized) {
      await applyTo(active);
      if (!mounted) return;
      if (widget.isActive && !widget.forcePaused) {
        unawaited(active.play());
        _syncBgm(play: true);
      }
    }
    for (final c in _clipControllers.values) {
      if (identical(c, active) || !c.value.isInitialized) continue;
      unawaited(applyTo(c));
    }
  }

  Future<VideoPlayerController?> _createAndInitController(String resolvedUrl) async {
    // If this video is already being precached, reuse that download rather than
    // opening a competing network stream. A pre-warm (not yet visible) can afford
    // to wait for it; a visible reel only waits briefly before streaming.
    return VideoCacheManager.createAndInitController(
      resolvedUrl,
      waitForInFlightDownload: Duration.zero,
    );
  }

  /// Disposes [controller] if the player state was reset while it was being
  /// created, returning true when the caller should bail out.
  bool _discardIfStale(int generation, VideoPlayerController? controller) {
    if (generation == _initGeneration && mounted) return false;
    controller?.dispose();
    return true;
  }

  Future<void> _initVideo() async {
    final generation = _initGeneration;

    if (!_hasMultiClips) {
      final targetUrl = widget.videoUrl.isNotEmpty
          ? widget.videoUrl
          : (_effectiveMergedClips.isNotEmpty ? _effectiveMergedClips.first : '');
      var resolvedUrl = _resolvePlayableUrl(targetUrl);

      if (resolvedUrl == null || resolvedUrl.isEmpty) {
        if (mounted) {
          setState(() {
            _isInitializing = false;
            _isInitialized = false;
            _hasError = true;
          });
        }
        return;
      }

      debugPrint('=== VIDEO PLAYBACK === Playback videoUrl: $resolvedUrl');
      if (mounted) {
        setState(() {
          _isInitializing = true;
          _hasError = false;
          _showSlowLoading = false;
        });
        _loadingHintTimer?.cancel();
        _loadingHintTimer = Timer(const Duration(milliseconds: 1800), () {
          if (mounted && _isInitializing && !_isInitialized) {
            setState(() => _showSlowLoading = true);
          }
        });
      }

      try {
        final controller = await _createAndInitController(resolvedUrl);
        if (_discardIfStale(generation, controller)) return;

        if (controller != null && controller.value.isInitialized) {
          _controller = controller;
          controller.addListener(_onVideoControllerUpdate);
          unawaited(controller.setLooping(true));
          unawaited(controller.setVolume(_videoVolume));

          final trimStart = widget.trimStart ?? 0.0;
          if (trimStart > 0) {
            unawaited(controller.seekTo(Duration(milliseconds: (trimStart * 1000).round())));
          }
          if (widget.playbackSpeed != 1.0) {
            unawaited(controller.setPlaybackSpeed(widget.playbackSpeed));
          }
          unawaited(controller.setVolume(_videoVolume));
          unawaited(controller.pause());

          _loadingHintTimer?.cancel();
          if (mounted) {
            setState(() {
              _isInitialized = true;
              _isInitializing = false;
              _hasError = false;
              _showSlowLoading = false;
            });
            _publishSeekController();
          }
          if (widget.isActive && !widget.forcePaused) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || generation != _initGeneration) return;
              if (!widget.isActive || widget.forcePaused) return;
              final ready = _controller;
              if (ready == null || !ready.value.isInitialized) return;
              unawaited(ready.setVolume(_videoVolume));
              unawaited(ready.play());
              _syncBgm(play: true);
            });
          }
          debugPrint('=== VIDEO PLAYBACK === Single player initialized: true');
          return;
        }
      } catch (e) {
        debugPrint('=== VIDEO PLAYBACK === Single player error: $e');
      }

      // Only report the failure if this init is still the current one.
      if (mounted && generation == _initGeneration) {
        setState(() {
          _isInitializing = false;
          _isInitialized = false;
          _hasError = true;
        });
      }
      return;
    }

    // MULTI-CLIP (MERGED) PLAYLIST PATH:
    final clips = _effectiveMergedClips;
    _currentClipIndex = 0;
    if (mounted) {
      setState(() {
        _isInitializing = true;
      });
    }

    // 1. Initialize Clip 0 immediately so playback starts instantly
    final firstUrl = _resolvePlayableUrl(clips[0]);
    if (firstUrl != null && firstUrl.isNotEmpty) {
      try {
        final c0 = await _createAndInitController(firstUrl);
        if (_discardIfStale(generation, c0)) return;
        if (c0 != null && c0.value.isInitialized) {
          _clipControllers[0] = c0;
          c0.addListener(_onVideoControllerUpdate);
          c0.setLooping(false);
          c0.setVolume(_videoVolume);

          // Mount VideoPlayer immediately on screen!
          if (mounted) {
            setState(() {
              _isInitialized = true;
              _isInitializing = false;
            });
            _publishSeekController();
          }

          if (widget.playbackSpeed != 1.0) {
            unawaited(c0.setPlaybackSpeed(widget.playbackSpeed));
          }
          unawaited(c0.pause());
          if (widget.isActive && !widget.forcePaused) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || generation != _initGeneration) return;
              if (!widget.isActive || widget.forcePaused) return;
              final ready = _clipControllers[0];
              if (ready == null || !ready.value.isInitialized) return;
              unawaited(ready.setVolume(_videoVolume));
              unawaited(ready.play());
              _syncBgm(play: true);
            });
          }
          _startPlaybackTimer();
        } else if (mounted) {
          // Don't leave the spinner up forever; offer the retry button.
          setState(() {
            _isInitializing = false;
            _isInitialized = false;
            _hasError = true;
          });
          return;
        }
      } catch (e) {
        debugPrint('Error initializing first clip: $e');
        if (mounted && generation == _initGeneration) {
          setState(() {
            _isInitializing = false;
            _isInitialized = false;
            _hasError = true;
          });
        }
        return;
      }
    }

    // Bail if this reel was reset (scrolled away) while clip 0 was loading.
    if (!mounted || generation != _initGeneration) return;

    // 2. Preload only the immediately next clip (clip 1) into VideoPlayerController to preserve hardware decoders
    if (clips.length > 1) {
      final nextUrl = _resolvePlayableUrl(clips[1]);
      if (nextUrl != null && nextUrl.isNotEmpty) {
        unawaited(_preloadClip(1, nextUrl));
      }
    }
    // Pre-cache all subsequent clips to disk in background (zero decoder overhead!)
    for (int i = 2; i < clips.length; i++) {
      final clipUrl = _resolvePlayableUrl(clips[i]);
      if (clipUrl != null && clipUrl.isNotEmpty) {
        unawaited(VideoCacheManager.precacheVideo(clipUrl));
      }
    }
  }

  Future<void> _preloadClip(int index, String url) async {
    final generation = _initGeneration;
    try {
      final c = await _createAndInitController(url);
      if (_discardIfStale(generation, c)) return;
      if (c != null && c.value.isInitialized) {
        c.setLooping(false);
        c.setVolume(_videoVolume);
        if (widget.playbackSpeed != 1.0) {
          try {
            await c.setPlaybackSpeed(widget.playbackSpeed);
          } catch (_) {}
        }
        await c.pause();
        await c.seekTo(Duration.zero);
        if (_discardIfStale(generation, c)) return;
        _clipControllers[index] = c;
        debugPrint('Preloaded clip #$index successfully: $url');
      }
    } catch (e) {
      debugPrint('Error preloading clip #$index ($url): $e');
    }
  }

  void _startPlaybackTimer() {
    _playbackTimer?.cancel();
    if (!_hasMultiClips) return;
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted || _isSwitchingClip || !_hasMultiClips || !widget.isActive) {
        return;
      }
      final controller = _activeController;
      if (controller != null && controller.value.isInitialized) {
        final posMs = controller.value.position.inMilliseconds;
        final durMs = controller.value.duration.inMilliseconds;
        final isPlaying = controller.value.isPlaying;
        final isCompleted = controller.value.isCompleted;
        final leadMargin = (55 * widget.playbackSpeed).clamp(40, 200).round();

        if (durMs > 0 && (isCompleted || posMs >= durMs - leadMargin || (!isPlaying && posMs >= durMs - (leadMargin + 80) && posMs > 0))) {
          _advanceToNextClip();
        }
      }
    });
  }

  void _onVideoControllerUpdate() {
    final controller = _activeController;
    if (controller == null || !mounted || _isSwitchingClip) return;

    final trimStart = widget.trimStart ?? 0.0;
    final trimEnd = widget.trimEnd;

    // Smooth bounded looping for trimmed reels:
    // Only seek back to trimStart when playback has genuinely reached or exceeded trimEnd
    if (trimEnd != null && trimEnd > trimStart && !_hasMultiClips) {
      final startMs = (trimStart * 1000).round();
      final endMs = (trimEnd * 1000).round();
      final posMs = controller.value.position.inMilliseconds;

      if (!_isSeekingToStart && posMs >= endMs - 50 && posMs > startMs + 300) {
        _isSeekingToStart = true;
        controller.seekTo(Duration(milliseconds: startMs)).then((_) {
          if (mounted) {
            Future.delayed(const Duration(milliseconds: 150), () {
              if (mounted) _isSeekingToStart = false;
            });
            if (controller.value.isPlaying) {
              controller.play();
            }
          }
        }).catchError((_) {
          if (mounted) _isSeekingToStart = false;
        });
      }
    }

    if (_hasMultiClips && widget.isActive && !widget.forcePaused) {
      final durMs = controller.value.duration.inMilliseconds;
      final posMs = controller.value.position.inMilliseconds;
      final isPlaying = controller.value.isPlaying;
      final isCompleted = controller.value.isCompleted;
      final leadMargin = (55 * widget.playbackSpeed).clamp(40, 200).round();
      if (durMs > 0 && (isCompleted || posMs >= durMs - leadMargin || (!isPlaying && posMs >= durMs - (leadMargin + 80) && posMs > 0))) {
        _advanceToNextClip();
      }
    }
  }

  Future<void> _advanceToNextClip() async {
    final clips = _effectiveMergedClips;
    if (_isSwitchingClip || clips.isEmpty || !_hasMultiClips) return;
    _isSwitchingClip = true;

    final oldIndex = _currentClipIndex;
    final nextIndex = (_currentClipIndex + 1) % clips.length;
    final oldController = _clipControllers[oldIndex];
    var nextController = _clipControllers[nextIndex];

    try {
      if (nextController == null || !nextController.value.isInitialized) {
        final nextUrl = _resolvePlayableUrl(clips[nextIndex]);
        if (nextUrl != null && nextUrl.isNotEmpty) {
          nextController = await _createAndInitController(nextUrl);
          if (nextController != null && mounted) {
            _clipControllers[nextIndex] = nextController;
          }
        }
      }

      if (nextController != null && nextController.value.isInitialized && mounted) {
        oldController?.removeListener(_onVideoControllerUpdate);

        nextController.removeListener(_onVideoControllerUpdate);
        nextController.addListener(_onVideoControllerUpdate);
        nextController.setLooping(false);
        nextController.setVolume(_videoVolume);
        if (widget.playbackSpeed != 1.0) {
          try {
            unawaited(nextController.setPlaybackSpeed(widget.playbackSpeed));
          } catch (_) {}
        }

        // Start playing immediately before awaiting background seeks!
        if (widget.isActive && !widget.forcePaused) {
          unawaited(nextController.play());
          _syncBgm(play: true);
        }

        _currentClipIndex = nextIndex;
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          _publishSeekController();
        }

        // Background maintenance on old controller
        unawaited(oldController?.pause());
        unawaited(oldController?.seekTo(Duration.zero));

        // Background maintenance: ensure upcoming clip is primed at 0
        final upcomingIndex = (nextIndex + 1) % clips.length;
        final upcomingController = _clipControllers[upcomingIndex];
        if (upcomingController != null && upcomingController.value.isInitialized) {
          if (widget.playbackSpeed != 1.0) {
            try {
              unawaited(upcomingController.setPlaybackSpeed(widget.playbackSpeed));
            } catch (_) {}
          }
          unawaited(upcomingController.seekTo(Duration.zero));
        } else {
          final upcomingUrl = _resolvePlayableUrl(clips[upcomingIndex]);
          if (upcomingUrl != null && upcomingUrl.isNotEmpty) {
            unawaited(_preloadClip(upcomingIndex, upcomingUrl));
          }
        }
      }
    } catch (e) {
      debugPrint('Error advancing reel clip: $e');
    } finally {
      final cooldownMs = (60 / widget.playbackSpeed).clamp(25, 70).round();
      Future.delayed(Duration(milliseconds: cooldownMs), () {
        if (mounted) _isSwitchingClip = false;
      });
    }
  }

  void _disposeControllers() {
    final notifier = widget.seekController;
    if (notifier != null &&
        (identical(notifier.value, _controller) ||
            identical(notifier.value, _activeController) ||
            _clipControllers.values.any((c) => identical(notifier.value, c)))) {
      notifier.value = null;
    }
    _syncBgm(play: false);
    _initGeneration++;
    _loadingHintTimer?.cancel();
    _loadingHintTimer = null;
    _showSlowLoading = false;
    _playbackTimer?.cancel();
    _playbackTimer = null;
    _controller?.removeListener(_onVideoControllerUpdate);
    _controller?.pause();
    _controller?.dispose();
    _controller = null;

    for (final c in _clipControllers.values) {
      c.removeListener(_onVideoControllerUpdate);
      c.pause();
      c.dispose();
    }
    _clipControllers.clear();
    _isInitialized = false;
    _isInitializing = false;
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
        fit: StackFit.expand,
        children: [
          // 1. Thumbnail Image Preview (shown initially as background/preview)
          if (widget.thumbnailUrl.trim().isNotEmpty &&
              widget.thumbnailUrl.trim() != 'null')
            _withRecordingFilter(
              AppImage(
                url: widget.thumbnailUrl,
                videoUrl: widget.videoUrl,
                fit: BoxFit.cover,
                isVideo: true,
              ),
            )
          else
            const ColoredBox(color: Color(0xFF140A28)),

          // 2. Loading overlay only if init is actually slow (thumbnail stays visible).
          if (_showSlowLoading && _isInitializing && !_isInitialized)
            const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                  strokeWidth: 2.2,
                ),
              ),
            ),

          // 3. Actual Video Player View
          if (_isInitialized &&
              _activeController != null &&
              _activeController!.value.isInitialized)
            _withRecordingFilter(
              FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: _activeController!.value.size.width > 0
                      ? _activeController!.value.size.width
                      : 360,
                  height: _activeController!.value.size.height > 0
                      ? _activeController!.value.size.height
                      : 640,
                  child: RepaintBoundary(
                    child: VideoPlayer(
                      key: ValueKey(_activeController),
                      _activeController!,
                    ),
                  ),
                ),
              ),
            ),

          // 4. Play / Pause Overlay Icon (Only when user explicitly paused)
          if (_isInitialized &&
              _activeController != null &&
              widget.userPaused &&
              !_activeController!.value.isPlaying)
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.45),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.8), width: 2),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),

          // 4c. Error Retry Overlay
          if (_hasError && widget.isActive && !_isInitialized && !_isInitializing)
            Center(
              child: GestureDetector(
                onTap: _initVideo,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white38),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Tap to reload video',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
    );
  }
}

class _InstagramSeekBar extends StatefulWidget {
  const _InstagramSeekBar({
    super.key,
    required this.controller,
    required this.enabled,
    this.trimStart = Duration.zero,
    this.trimEnd,
    this.onScrubStart,
    this.onScrubEnd,
  });

  final VideoPlayerController controller;
  final bool enabled;
  final Duration trimStart;
  final Duration? trimEnd;
  final VoidCallback? onScrubStart;
  final VoidCallback? onScrubEnd;

  @override
  State<_InstagramSeekBar> createState() => _InstagramSeekBarState();
}

class _InstagramSeekBarState extends State<_InstagramSeekBar> {
  bool _dragging = false;
  double? _dragValue;

  Duration get _start => widget.trimStart;
  Duration get _end {
    final trim = widget.trimEnd;
    final dur = widget.controller.value.duration;
    if (trim != null && trim > _start) return trim;
    return dur;
  }

  double _progressFromController() {
    final range = _end.inMilliseconds - _start.inMilliseconds;
    if (range <= 0) return 0;
    final pos = widget.controller.value.position.inMilliseconds - _start.inMilliseconds;
    return (pos / range).clamp(0.0, 1.0);
  }

  Future<void> _seekTo(double t) async {
    final range = _end.inMilliseconds - _start.inMilliseconds;
    if (range <= 0) return;
    final ms = _start.inMilliseconds + (t.clamp(0.0, 1.0) * range).round();
    try {
      await widget.controller.seekTo(Duration(milliseconds: ms));
    } catch (_) {}
  }

  void _handleDragStart(DragStartDetails details, double width) {
    if (!widget.enabled || width <= 0) return;
    setState(() {
      _dragging = true;
      _dragValue = (details.localPosition.dx / width).clamp(0.0, 1.0);
    });
    widget.onScrubStart?.call();
    unawaited(_seekTo(_dragValue!));
  }

  void _handleDragUpdate(DragUpdateDetails details, double width) {
    if (!_dragging || width <= 0) return;
    setState(() {
      _dragValue = (details.localPosition.dx / width).clamp(0.0, 1.0);
    });
    unawaited(_seekTo(_dragValue!));
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_dragging) return;
    final value = _dragValue ?? _progressFromController();
    setState(() {
      _dragging = false;
      _dragValue = null;
    });
    unawaited(() async {
      await _seekTo(value);
      widget.onScrubEnd?.call();
    }());
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (d) => _handleDragStart(d, width),
          onHorizontalDragUpdate: (d) => _handleDragUpdate(d, width),
          onHorizontalDragEnd: _handleDragEnd,
          onTapUp: widget.enabled
              ? (d) {
                  final t = (d.localPosition.dx / width).clamp(0.0, 1.0);
                  unawaited(() async {
                    await _seekTo(t);
                    widget.onScrubEnd?.call();
                  }());
                }
              : null,
          child: SizedBox(
            height: 20,
            width: double.infinity,
            child: Align(
              alignment: Alignment.topCenter,
              child: ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: widget.controller,
                builder: (context, value, _) {
                  final progress = _dragging
                      ? (_dragValue ?? 0)
                      : _progressFromController();
                  final barHeight = _dragging ? 6.0 : 3.5;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 80),
                    height: barHeight,
                    width: double.infinity,
                    color: Colors.white.withValues(alpha: 0.28),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FeedItem {
  const _FeedItem.reel(this.reel)
      : isAd = false,
        isBannerAd = false,
        isNativeAd = false;

  const _FeedItem.bannerAd()
      : reel = null,
        isAd = true,
        isBannerAd = true,
        isNativeAd = false;

  const _FeedItem.nativeAd()
      : reel = null,
        isAd = true,
        isBannerAd = false,
        isNativeAd = true;

  final Map<String, dynamic>? reel;
  final bool isAd;
  final bool isBannerAd;
  final bool isNativeAd;
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.count,
    this.active = false,
    this.rateStyle = false,
    required this.onTap,
  });

  final IconData icon;
  final String count;
  final bool active;
  final bool rateStyle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: rateStyle ? AppGradients.button : null,
              color: rateStyle ? null : Colors.black.withValues(alpha: 0.4),
              border: Border.all(
                color: rateStyle
                    ? const Color(0xFFFF5487)
                    : Colors.white.withValues(alpha: 0.25),
              ),
            ),
            child: Icon(
              icon,
              size: 22,
              color: active
                  ? (icon == Icons.favorite ? const Color(0xFFFF3D77) : Colors.white)
                  : Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: active ? const Color(0xFFFF5487) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.text,
    this.muted = false,
  });

  final IconData icon;
  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        Icon(
          icon,
          size: 13,
          color: muted ? Colors.white70 : const Color(0xFFFF5487),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: muted ? FontWeight.w500 : FontWeight.w700,
              color: muted ? Colors.white70 : Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _AdReelCard extends StatelessWidget {
  const _AdReelCard();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AppNetworkImage(
          url:
              'https://images.unsplash.com/photo-1519389950473-47ba0277781c?w=700&h=1200&q=80&auto=format&fit=crop',
          fit: BoxFit.cover,
          alt: 'ad',
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0x590A0514),
                const Color(0xEB06030E),
              ],
            ),
          ),
        ),
        Positioned(
          top: 68,
          left: 18,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Ad',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFF170B33),
              ),
            ),
          ),
        ),
        Positioned(
          left: 18,
          right: 18,
          bottom: 96,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Go Prime — Ad-Free Viewing',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Remove ads and get the diamond badge',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                decoration: BoxDecoration(
                  gradient: AppGradients.button,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF3D77).withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Text(
                  'Upgrade Now',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _formatCount(int count) {
  if (count >= 1000000) {
    final val = count / 1000000;
    return '${val.toStringAsFixed(1).replaceAll('.0', '')}M';
  }
  if (count >= 1000) {
    final val = count / 1000;
    return '${val.toStringAsFixed(1).replaceAll('.0', '')}K';
  }
  return count.toString();
}

