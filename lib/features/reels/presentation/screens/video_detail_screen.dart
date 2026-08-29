import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';
import 'package:artable_app/core/widgets/app_back_header.dart';
import 'package:artable_app/core/widgets/app_image.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';
import 'package:artable_app/data/datasources/mock_data.dart';
import 'package:artable_app/app/routes/app_routes.dart';
import 'package:artable_app/core/utils/reel_helpers.dart';
import 'package:artable_app/features/home/presentation/bloc/home_cubit.dart';
import 'package:artable_app/features/reels/presentation/bloc/reels_cubit.dart';
import 'package:artable_app/features/trending/presentation/bloc/trending_videos_cubit.dart';
import 'package:artable_app/features/trending/data/models/trending_videos_response.dart';

class VideoDetailScreen extends StatefulWidget {
  const VideoDetailScreen({super.key, this.reelId});

  final String? reelId;

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isPlaying = false;

  Map<String, dynamic> get _reel {
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

    return available.isNotEmpty
        ? available.first
        : (MockData.REELS.isNotEmpty ? MockData.REELS.first : {});
  }

  @override
  void initState() {
    super.initState();
    final reelMap = _reel;
    final rawVideoUrl = reelMap['videoUrl'] as String? ?? '';
    final rawThumbUrl = reelMap['thumbnailUrl'] as String? ?? (reelMap['imageUrl'] as String? ?? '');

    debugPrint('=== TRENDING REEL VIDEO ===');
    debugPrint('Video URL: $rawVideoUrl');
    debugPrint('Thumbnail URL: $rawThumbUrl');

    final resolvedVideoUrl = _resolvePlayableUrl(rawVideoUrl);
    if (resolvedVideoUrl != null && resolvedVideoUrl.isNotEmpty) {
      debugPrint('Initializing video with videoUrl only');
      _initVideoPlayer(resolvedVideoUrl);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final rId = reelMap['id']?.toString() ?? reelMap['_id']?.toString() ?? widget.reelId;
        if (rId != null && rId.isNotEmpty) {
          context.read<ReelsCubit>().fetchComments(rId);
        }
      }
    });
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

    String fullUrl;
    if (clean.startsWith('http://') || clean.startsWith('https://') || clean.startsWith('file://')) {
      fullUrl = clean;
    } else if (clean.startsWith('/')) {
      fullUrl = 'http://server.keshavinfotechdemo2.com:3055$clean';
    } else {
      fullUrl = 'http://server.keshavinfotechdemo2.com:3055/$clean';
    }
    try {
      return Uri.encodeFull(fullUrl);
    } catch (_) {
      return fullUrl;
    }
  }

  Future<void> _initVideoPlayer(String videoUrl) async {
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      _videoController = controller;
      await controller.initialize();
      if (!mounted) return;
      controller.setLooping(true);
      controller.setVolume(1.0);
      await controller.play();
      setState(() {
        _isVideoInitialized = true;
        _isPlaying = true;
      });
    } catch (e) {
      debugPrint('VideoDetailScreen video player error: $e');
      if (videoUrl != 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4') {
        _initVideoPlayer('https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4');
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_videoController != null && _isVideoInitialized) {
      setState(() {
        if (_videoController!.value.isPlaying) {
          _videoController!.pause();
          _isPlaying = false;
        } else {
          _videoController!.play();
          _isPlaying = true;
        }
      });
    }
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

    return AppScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppBackHeader(title: 'Reel'),
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
);
}

  // --- Main Video Stage Player ---
  Widget _buildVideoStage(Map<String, dynamic> reel) {
    final rawCat = (reel['category'] as String?)?.trim();
    final category = (rawCat != null && rawCat.isNotEmpty)
        ? rawCat.toUpperCase()
        : 'TALENT';
    final badgeColor = _categoryBadgeColor(rawCat ?? 'TALENT');

    return AspectRatio(
      aspectRatio: 3 / 3.8,
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
              // Video Thumbnail
              AppImage(
                url: reel['imageUrl'] as String,
                fit: BoxFit.cover,
              ),

              if (_isVideoInitialized && _videoController != null && _videoController!.value.isInitialized)
                FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: _videoController!.value.size.width > 0 ? _videoController!.value.size.width : 360,
                    height: _videoController!.value.size.height > 0 ? _videoController!.value.size.height : 640,
                    child: VideoPlayer(_videoController!),
                  ),
                ),

              // Category Badge (Top-Left)
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

              // Center Frosted Glass Play / Pause Button
              Center(
                child: GestureDetector(
                  onTap: _togglePlayPause,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: _isPlaying ? 0.15 : 0.24),
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
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Creator Card (Deep Purple Card) ---
  // --- Creator Card (Deep Purple Card) ---
  Widget _buildCreatorCard(Map<String, dynamic> reel, Map<String, dynamic> creator) {
    final handle = reel['handle'] as String? ?? (creator['handle'] as String? ?? '');
    final views = (reel['views'] as String?)?.isNotEmpty == true ? reel['views'] as String : '0';
    final isVerified = reel['verified'] == true || reel['isBlueTick'] == true;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/public-profile?id=${creator['id']}'),
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

    final currentVideo = reelsProvider.getVideo(reelId) ?? reel;

    final views = (currentVideo['views'] as String?)?.isNotEmpty == true
        ? currentVideo['views'] as String
        : '0';
    final likes = (currentVideo['likes'] as String?)?.isNotEmpty == true
        ? currentVideo['likes'] as String
        : '0';
    final int rawComments = currentVideo['commentsCount'] is int
        ? currentVideo['commentsCount'] as int
        : (int.tryParse(currentVideo['comments']?.toString() ?? '') ?? 0);
    final int commentsVal = reelsProvider.getCommentsCount(reelId, rawComments);
    final comments = TrendingVideoItem.formatCount(commentsVal);
    final shares = (currentVideo['shares'] as String?)?.isNotEmpty == true
        ? currentVideo['shares'] as String
        : '0';

    return Row(
      children: [
        _buildStatItem(
          icon: Icons.remove_red_eye_outlined,
          value: views,
          label: 'Views',
        ),
        const SizedBox(width: 8),
        _buildStatItem(
          icon: isLiked ? Icons.favorite : Icons.favorite_border,
          iconColor: isLiked ? const Color(0xFFFF3D77) : const Color(0xFF8B3DFF),
          value: likes,
          label: 'Likes',
          onTap: () => context.read<ReelsCubit>().toggleLike(reelId, fallbackVideo: reel),
        ),
        const SizedBox(width: 8),
        _buildStatItem(
          icon: Icons.chat_bubble_outline,
          value: comments,
          label: 'Comments',
          onTap: () => context.push('${AppRoutes.comments}?id=$reelId'),
        ),
        const SizedBox(width: 8),
        _buildStatItem(
          icon: Icons.share_outlined,
          value: shares,
          label: 'Shares',
          onTap: () => context.push('${AppRoutes.shareReport}?id=$reelId'),
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
      if (reel['userRating'] != null) {
        score = double.tryParse(reel['userRating'].toString()) ?? 0.0;
      } else if (reel['score'] != null) {
        score = double.tryParse(reel['score'].toString()) ?? 0.0;
      } else if (reel['rating'] != null) {
        score = double.tryParse(reel['rating'].toString()) ?? 0.0;
      } else if (reel['talentScore'] is num) {
        score = (reel['talentScore'] as num).toDouble();
      } else if (reel['ratings'] is List && (reel['ratings'] as List).isNotEmpty) {
        for (final item in (reel['ratings'] as List)) {
          if (item is Map && item['score'] != null) {
            score = double.tryParse(item['score'].toString()) ?? 0.0;
            if (score > 0) break;
          }
        }
      }
    }

    final displayScore = score > 0 ? score.toStringAsFixed(1) : (reel['rating']?.toString() ?? '8.5');

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
                    url: item['imageUrl'] as String,
                    fit: BoxFit.cover,
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
