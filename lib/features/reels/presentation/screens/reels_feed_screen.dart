import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/features/reels/presentation/bloc/reels_cubit.dart';
import 'package:artable_app/features/trending/data/models/trending_videos_response.dart';
import 'package:artable_app/features/trending/presentation/bloc/trending_videos_cubit.dart';
import 'package:artable_app/features/home/presentation/bloc/home_cubit.dart';
import 'package:artable_app/data/datasources/mock_data.dart';
import 'package:artable_app/app/routes/app_routes.dart';
import 'package:artable_app/core/utils/reel_helpers.dart';
import 'package:artable_app/core/widgets/app_network_image.dart';
import 'package:artable_app/features/reels/presentation/widgets/creator_info_row.dart';
import 'package:artable_app/features/reels/presentation/widgets/talent_rating_slider.dart';
import 'package:artable_app/features/studio/data/services/studio_music_playback_service.dart';

class ReelsFeedScreen extends StatefulWidget {
  const ReelsFeedScreen({super.key, this.initialReelId});

  final String? initialReelId;

  @override
  State<ReelsFeedScreen> createState() => _ReelsFeedScreenState();
}

class _ReelsFeedScreenState extends State<ReelsFeedScreen> {
  late final PageController _pageController;
  int _currentPage = 0;
  String? _ratingReelId;
  bool _ratingSuccess = false;
  double _ratingValue = 5;
  double _playbackSpeed = 1.0;

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

    void addReels(List<Map<String, dynamic>> list) {
      for (final r in list) {
        final id = r['id']?.toString() ?? r['_id']?.toString() ?? '';
        if (id.isNotEmpty && !seenIds.contains(id)) {
          seenIds.add(id);
          rawList.add(r);
        }
      }
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
    if (rawList.isEmpty) {
      addReels(List<Map<String, dynamic>>.from(MockData.REELS));
    }

    final targetId = widget.initialReelId?.trim();
    if (targetId != null && targetId.isNotEmpty && !seenIds.contains(targetId)) {
      final singleItem = trendingCubit.getVideoById(targetId);
      if (singleItem != null) {
        rawList.insert(0, singleItem.toUiMap());
        seenIds.add(targetId);
      } else {
        final helperMatch = ReelHelpers.reelById(targetId, availableReels: rawList);
        if (helperMatch != null) {
          rawList.insert(0, helperMatch);
          seenIds.add(targetId);
        }
      }
    }

    final cards = rawList.map(_FeedItem.reel).toList();
    if (cards.length > 3) {
      cards.insert(3, const _FeedItem.ad());
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

  void _scrollToInitialIfNeeded(List<_FeedItem> items) {
    if (_hasScrolledToInitial) return;
    final targetId = widget.initialReelId?.trim();
    if (targetId == null || targetId.isEmpty) {
      _hasScrolledToInitial = true;
      _fetchCommentsForPage(_currentPage);
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final trendingCubit = context.read<TrendingVideosCubit>();
        if (!trendingCubit.hasLoaded && !trendingCubit.isLoading) {
          trendingCubit.loadTrendingVideos();
        }
        _fetchCommentsForPage(_currentPage);
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
    _pageController.dispose();
    super.dispose();
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
                          '${_playbackSpeed.toStringAsFixed(1)}x',
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
                      final isSelected = (_playbackSpeed - speed).abs() < 0.01;
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
                      value: _playbackSpeed.clamp(0.4, 4.0),
                      min: 0.4,
                      max: 4.0,
                      divisions: 36,
                      label: '${_playbackSpeed.toStringAsFixed(1)}x',
                      onChanged: (val) {
                        final rounded = double.parse(val.toStringAsFixed(1));
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

    return Scaffold(
      backgroundColor: const Color(0xFF0B0714),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (page) {
              setState(() {
                _currentPage = page;
              });
              _fetchCommentsForPage(page);
            },
            scrollDirection: Axis.vertical,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              if (item.isAd) return const _AdReelCard();
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
              final String creatorName = (reel['creator'] as String?)?.trim() ??
                  (reel['handle'] as String?)?.trim() ?? '';
              final String soundText = (musicName != null && musicName.isNotEmpty)
                  ? musicName
                  : (creatorName.isNotEmpty ? 'Original Sound — $creatorName' : 'Original Sound');

              return Stack(
                fit: StackFit.expand,
                children: [
                  _ReelVideoPlayer(
                    key: ValueKey(reel['id']),
                    videoUrl: videoUrl,
                    thumbnailUrl: imageUrl,
                    isActive: isActive,
                    playbackSpeed: _playbackSpeed,
                    trimStart: (reel['videoTrimStartSeconds'] as num?)?.toDouble(),
                    trimEnd: (reel['videoTrimEndSeconds'] as num?)?.toDouble(),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0x590A0514),
                          const Color(0x0D0A0514),
                          const Color(0x330A0514),
                          const Color(0xEB06030E),
                        ],
                        stops: const [0, 0.22, 0.55, 1],
                      ),
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
                    bottom: 108,
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
                          onTap: () => context
                              .push('${AppRoutes.shareReport}?id=$reelId'),
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
                    bottom: 26,
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
    this.playbackSpeed = 1.0,
    this.trimStart,
    this.trimEnd,
  });

  final String videoUrl;
  final String thumbnailUrl;
  final bool isActive;
  final double playbackSpeed;
  final double? trimStart;
  final double? trimEnd;

  @override
  State<_ReelVideoPlayer> createState() => _ReelVideoPlayerState();
}

class _ReelVideoPlayerState extends State<_ReelVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitializing = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _logDebugInfo();
    if (widget.isActive) {
      _initVideo();
    }
  }

  void _logDebugInfo() {
    debugPrint('=== TRENDING REEL VIDEO ===');
    debugPrint('Video URL: ${widget.videoUrl}');
    debugPrint('Thumbnail URL: ${widget.thumbnailUrl}');
  }

  String? _resolvePlayableUrl(String rawUrl) {
    final clean = rawUrl.trim();
    if (clean.isEmpty || clean == 'null') {
      return null;
    }
    final lower = clean.toLowerCase();
    if (lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif')) {
      return null;
    }

    var cleanFilePath = clean.startsWith('file://') ? clean.replaceFirst('file://', '') : clean;
    if (File(cleanFilePath).existsSync() || clean.startsWith('/data/') || clean.startsWith('/storage/')) {
      return clean;
    }

    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return clean;
    } else if (clean.startsWith('/')) {
      return 'http://server.keshavinfotechdemo2.com:3055$clean';
    } else {
      return 'http://server.keshavinfotechdemo2.com:3055/$clean';
    }
  }

  @override
  void didUpdateWidget(covariant _ReelVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.videoUrl != oldWidget.videoUrl) {
      _logDebugInfo();
      _disposeController();
      if (widget.isActive) {
        _initVideo();
      }
    } else if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        if (_controller == null) {
          _initVideo();
        } else if (_isInitialized) {
          _controller!.play();
          if (widget.playbackSpeed != 1.0) {
            _controller!.setPlaybackSpeed(widget.playbackSpeed);
          }
        }
      } else {
        if (_controller != null && _isInitialized) {
          _controller!.pause();
        }
      }
    } else if (widget.playbackSpeed != oldWidget.playbackSpeed) {
      if (_controller != null && _isInitialized) {
        _controller!.setPlaybackSpeed(widget.playbackSpeed);
      }
    }
  }

  Future<void> _initVideo() async {
    await StudioMusicPlaybackService.releaseForVideoPlayback();
    final resolvedUrl = _resolvePlayableUrl(widget.videoUrl);

    if (resolvedUrl == null || resolvedUrl.isEmpty) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _isInitialized = false;
        });
      }
      return;
    }

    debugPrint('=== VIDEO PLAYBACK === Playback videoUrl: $resolvedUrl');
    if (mounted) {
      setState(() {
        _isInitializing = true;
      });
    }

    try {
      VideoPlayerController controller;
      var cleanFilePath = resolvedUrl.startsWith('file://') ? resolvedUrl.replaceFirst('file://', '') : resolvedUrl;
      final localFile = File(cleanFilePath);

      if (resolvedUrl.startsWith('file://') || localFile.existsSync() || resolvedUrl.startsWith('/data/') || resolvedUrl.startsWith('/storage/')) {
        controller = VideoPlayerController.file(localFile);
      } else {
        final uri = Uri.parse(resolvedUrl);
        controller = VideoPlayerController.networkUrl(
          uri,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
      }

      _controller = controller;
      await controller.initialize().timeout(const Duration(seconds: 25));
      if (!mounted) return;
      controller.addListener(_onVideoControllerUpdate);
      final trimStart = widget.trimStart ?? 0.0;
      if (trimStart > 0) {
        await controller.seekTo(Duration(milliseconds: (trimStart * 1000).round()));
      }
      controller.setLooping(true);
      controller.setVolume(1.0);
      if (widget.playbackSpeed != 1.0) {
        await controller.setPlaybackSpeed(widget.playbackSpeed);
      }
      if (widget.isActive) {
        await controller.play();
      }
      debugPrint('=== VIDEO PLAYBACK === Network player initialized: true');
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isInitializing = false;
        });
      }
      return;
    } catch (e) {
      debugPrint('=== VIDEO PLAYBACK === Primary player error: $e');
    }

    if (mounted) {
      setState(() {
        _isInitializing = false;
        _isInitialized = false;
      });
    }
  }

  void _onVideoControllerUpdate() {
    final controller = _controller;
    if (controller == null || !mounted) return;

    final trimStart = widget.trimStart ?? 0.0;
    final trimEnd = widget.trimEnd;

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
  }

  void _disposeController() {
    _controller?.removeListener(_onVideoControllerUpdate);
    _controller?.pause();
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
    _isInitializing = false;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller != null && _isInitialized) {
      setState(() {
        if (_controller!.value.isPlaying) {
          _controller!.pause();
        } else {
          _controller!.play();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Thumbnail Image Preview (shown initially as background/preview)
          if (widget.thumbnailUrl.trim().isNotEmpty &&
              widget.thumbnailUrl.trim() != 'null')
            AppNetworkImage(
              url: widget.thumbnailUrl,
              fit: BoxFit.cover,
            )
          else
            const ColoredBox(color: Color(0xFF140A28)),

          // 2. Loading Indicator Overlay (Before Video Initialization)
          if (_isInitializing && !_isInitialized)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2.5,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),

          // 3. Actual Video Player View
          if (_isInitialized &&
              _controller != null &&
              _controller!.value.isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: _controller!.value.size.width > 0
                    ? _controller!.value.size.width
                    : 360,
                height: _controller!.value.size.height > 0
                    ? _controller!.value.size.height
                    : 640,
                child: VideoPlayer(_controller!),
              ),
            ),

          // 4. Play / Pause Overlay Icon
          if (_isInitialized &&
              _controller != null &&
              !_controller!.value.isPlaying)
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


        ],
      ),
    );
  }
}

class _FeedItem {
  const _FeedItem.reel(this.reel) : isAd = false;
  const _FeedItem.ad()
      : reel = null,
        isAd = true;

  final Map<String, dynamic>? reel;
  final bool isAd;
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

