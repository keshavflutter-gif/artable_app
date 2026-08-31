import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';
import 'package:artable_app/core/widgets/app_back_header.dart';
import 'package:artable_app/core/widgets/app_image.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';
import 'package:artable_app/core/widgets/filter_pills.dart';
import 'package:artable_app/features/home/presentation/bloc/home_cubit.dart';
import 'package:artable_app/features/trending/presentation/bloc/trending_videos_cubit.dart';
import 'package:artable_app/features/trending/data/models/trending_videos_response.dart';

class TrendingVideosScreen extends StatefulWidget {
  const TrendingVideosScreen({super.key});

  @override
  State<TrendingVideosScreen> createState() => _TrendingVideosScreenState();
}

class _TrendingVideosScreenState extends State<TrendingVideosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TrendingVideosCubit>().loadTrendingVideos(forceRefresh: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final trendingProvider = context.watch<TrendingVideosCubit>();
    final homeCubitTrendingReels = context.select<HomeCubit, List<Map<String, dynamic>>>(
      (vm) => vm.trendingReels,
    );
    final hero = trendingProvider.hero;
    final apiVideos = trendingProvider.videos;

    final List<TrendingVideoItem> videos = [];
    final Set<String> seenIds = {};

    if (hero != null && hero.id.isNotEmpty) {
      seenIds.add(hero.id);
    }

    for (final itemMap in homeCubitTrendingReels) {
      final id = itemMap['id']?.toString() ?? '';
      if (id.isNotEmpty && !seenIds.contains(id)) {
        seenIds.add(id);
        videos.add(TrendingVideoItem.fromJson(itemMap));
      }
    }

    for (final v in apiVideos) {
      if (v.id.isNotEmpty && !seenIds.contains(v.id)) {
        seenIds.add(v.id);
        videos.add(v);
      }
    }

    final isLoading = trendingProvider.isLoading && !trendingProvider.hasLoaded;

    return AppScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppBackHeader(title: 'Trending Videos'),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.purple,
              onRefresh: () =>
                  trendingProvider.loadTrendingVideos(forceRefresh: true),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    FilterPills(
                      items: trendingProvider.availableTabs,
                      selected: trendingProvider.selectedTab,
                      onSelected: (tab) => trendingProvider.selectTab(tab),
                    ),
                    const SizedBox(height: 16),
                    if (isLoading)
                      const _LoadingSkeleton()
                    else ...[
                      // Hero Featured Video Card
                      if (hero != null) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: _FeaturedHeroCard(
                            hero: hero,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Section Header: More Trending Talent
                      if (videos.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: Text(
                            'More Trending Talent',
                            style: AppTextStyles.displayBold.copyWith(
                              fontSize: 16.5,
                              color: AppColors.text,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.62,
                            ),
                            itemCount: videos.length,
                            itemBuilder: (context, index) {
                              final item = videos[index];
                              return _TrendingVideoItemCard(
                                video: item,
                                onTap: () => _navigateToVideo(item.id),
                              );
                            },
                          ),
                        ),
                      ] else if (hero == null) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 22, vertical: 40),
                          child: Center(
                            child: Text(
                              'No trending videos available.',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: Color(0xFF8B849C),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToVideo(String videoId) {
    if (videoId.isNotEmpty) {
      context.push('/video-detail?id=$videoId').then((_) {
        if (mounted) {
          context.read<TrendingVideosCubit>().loadTrendingVideos(forceRefresh: true);
          context.read<HomeCubit>().loadHomeDashboard(forceRefresh: true);
        }
      });
    }
  }
}

/// Color helper for Category Badges matching Figma design
Color _getCategoryBadgeColor(String category) {
  final cat = category.toLowerCase().trim();
  if (cat.contains('dance')) return const Color(0xFFE01D5C);
  if (cat.contains('comedy')) return const Color(0xFF3450D6);
  if (cat.contains('fitness') || cat.contains('gym')) {
    return const Color(0xFF1FAE6A);
  }
  if (cat.contains('singing') ||
      cat.contains('sing') ||
      cat.contains('music')) {
    return const Color(0xFFFF3D77);
  }
  if (cat.contains('magic')) return const Color(0xFF7420E8);
  if (cat.contains('art') || cat.contains('paint')) {
    return const Color(0xFFE8631F);
  }
  if (cat.contains('sport')) return const Color(0xFFFF7A45);
  return const Color(0xFF8B3DFF);
}

/// Hero Featured Video Card
class _FeaturedHeroCard extends StatelessWidget {
  const _FeaturedHeroCard({
    required this.hero,
  });

  final TrendingVideoItem hero;

  @override
  Widget build(BuildContext context) {
    final id = hero.id;
    final imageUrl = hero.displayThumbnail;
    final category = hero.displayCategoryName.isNotEmpty
        ? hero.displayCategoryName
        : 'TALENT';
    final rating = hero.displayRating;
    final views = hero.displayViews;
    final handle = hero.displayHandle;
    final avatarUrl = hero.displayAvatar;
    final isVerified = hero.isVerifiedUser;

    final badgeColor = _getCategoryBadgeColor(category);

    return GestureDetector(
      onTap: () {
        if (id.isNotEmpty) {
          context.push('/video-detail?id=$id').then((_) {
            if (context.mounted) {
              context.read<TrendingVideosCubit>().loadTrendingVideos(forceRefresh: true);
              context.read<HomeCubit>().loadHomeDashboard(forceRefresh: true);
            }
          });
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 215,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1B2E),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AppImage(
                url: imageUrl,
                fit: BoxFit.cover,
              ),

              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.25),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),

              // Top Left Category Badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: badgeColor.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    category.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              // Top Right Play Icon & Rating Badge
              Positioned(
                top: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Play circle icon
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Rating Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFB800),
                            size: 12.5,
                          ),
                          const SizedBox(width: 2.5),
                          Text(
                            rating,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Left: Views and Creator Info
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Views Row
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.visibility_outlined,
                          color: Colors.white,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          views,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // User Info Row
                    Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: ClipOval(
                            child: AppImage(
                              url: avatarUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            handle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF3897F0),
                            size: 13.5,
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
  }
}

/// Grid Video Card for TrendingVideoItem
class _TrendingVideoItemCard extends StatelessWidget {
  const _TrendingVideoItemCard({
    required this.video,
    required this.onTap,
  });

  final TrendingVideoItem video;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final badgeColor = _getCategoryBadgeColor(video.displayCategoryName);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1B2E),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AppImage(
                url: video.displayThumbnail,
                fit: BoxFit.cover,
              ),

              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),

              // Top Left Category Badge
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: badgeColor.withValues(alpha: 0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 1.5),
                      ),
                    ],
                  ),
                  child: Text(
                    video.displayCategoryName.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),

              // Top Right Play Icon & Rating Badge
              Positioned(
                top: 10,
                right: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5.5, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFB800),
                            size: 11,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            video.displayRating,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Left: Views and Creator Info
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Views
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.visibility_outlined,
                          color: Colors.white,
                          size: 11.5,
                        ),
                        const SizedBox(width: 3.5),
                        Text(
                          video.displayViews,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // User Info
                    Row(
                      children: [
                        Container(
                          width: 17,
                          height: 17,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 0.8),
                          ),
                          child: ClipOval(
                            child: AppImage(
                              url: video.displayAvatar,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            video.displayHandle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (video.isVerifiedUser) ...[
                          const SizedBox(width: 3),
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF3897F0),
                            size: 12,
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
  }
}



/// Loading skeleton placeholder
class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        children: [
          Container(
            height: 215,
            decoration: BoxDecoration(
              color: const Color(0xFFF0EDF7),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.purple,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 160,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EDF7),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.62,
            ),
            itemCount: 4,
            itemBuilder: (context, index) => Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0EDF7),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
