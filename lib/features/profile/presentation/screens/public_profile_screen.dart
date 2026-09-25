import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/core/widgets/app_image.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';
import 'package:artable_app/core/widgets/secondary_outline_button.dart';
import 'package:artable_app/features/profile/presentation/widgets/profile_reward_widgets.dart';
import 'package:artable_app/app/routes/app_routes.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:artable_app/features/auth/data/models/user_info.dart';
import 'package:artable_app/features/home/presentation/bloc/home_cubit.dart';
import 'package:artable_app/features/profile/presentation/bloc/my_videos_cubit.dart';
import 'package:artable_app/features/reels/presentation/bloc/reels_cubit.dart';
import 'package:artable_app/features/trending/presentation/bloc/trending_videos_cubit.dart';

class PublicProfileScreen extends StatefulWidget {
  const PublicProfileScreen({
    super.key,
    this.userId,
    this.showBackButton = true,
  });

  final String? userId;
  final bool showBackButton;

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  UserInfo? _user;
  bool _isLoading = true;
  String? _errorMessage;
  bool _following = false;
  bool _isFollowLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserProfile();
      if (mounted) {
        final homeCubit = context.read<HomeCubit>();
        if (!homeCubit.hasLoaded && !homeCubit.isLoading) {
          homeCubit.loadHomeDashboard();
        }
        final trendingCubit = context.read<TrendingVideosCubit>();
        if (!trendingCubit.hasLoaded && !trendingCubit.isLoading) {
          trendingCubit.loadTrendingVideos();
        }
      }
    });
  }

  Future<void> _loadUserProfile() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final targetId = widget.userId?.trim();
    final authCubit = context.read<AuthCubit>();

    try {
      final userInfo = await authCubit.fetchUserDetails(targetUserId: targetId);
      if (mounted) {
        setState(() {
          _user = userInfo;
          _following = userInfo?.isFollowing ?? false;
          _isLoading = false;
          if (userInfo == null) {
            _errorMessage = 'User profile details could not be loaded.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load profile details.';
        });
      }
    }
  }

  Future<void> _handleFollowToggle(String profileId) async {
    final targetId = profileId.trim();
    if (_isFollowLoading || targetId.isEmpty) return;

    final previousState = _following;
    setState(() {
      _isFollowLoading = true;
      _following = !_following;
    });

    try {
      final response = await context.read<AuthCubit>().toggleFollow(targetId);
      if (mounted) {
        setState(() {
          _following = response.following;
          _isFollowLoading = false;
        });
        if (response.message.isNotEmpty) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _following = previousState;
          _isFollowLoading = false;
        });
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update follow status: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.pink,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AppScreen(
        child: Center(
          child: CircularProgressIndicator(color: AppColors.purple),
        ),
      );
    }

    if (_user == null) {
      return AppScreen(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.showBackButton)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppColors.text),
                        onPressed: () => context.pop(),
                      ),
                    ),
                  const Spacer(),
                  const Icon(Icons.person_off_outlined, size: 64, color: AppColors.textSoft),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage ?? 'User profile not found',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadUserProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Try Again', style: TextStyle(color: Colors.white)),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final u = _user!;
    final name = u.displayName.isNotEmpty ? u.displayName : (u.fullName.isNotEmpty ? u.fullName : 'User');
    final handle = u.username != null && u.username!.isNotEmpty
        ? (u.username!.startsWith('@') ? u.username! : '@${u.username}')
        : '';
    final bio = u.bio ?? '';
    final category = (u.category != null && u.category!.isNotEmpty) ? u.category!.toUpperCase() : 'TALENT';
    final avatarUrl = u.profilePhotoUrl ?? '';
    final coverUrl = u.coverImageUrl ?? '';
    final isVerified = u.isVerified == true || u.isBlueTick == true;

    final reelsCubit = context.watch<ReelsCubit>();
    final trendingCubit = context.watch<TrendingVideosCubit>();
    final homeCubit = context.watch<HomeCubit>();
    final myVideosCubit = context.watch<MyVideosCubit>();

    final authCubit = context.watch<AuthCubit>();
    final authState = authCubit.state;
    final currentUserId = (authState.userId ?? authCubit.userId ?? authState.currentUser['id']?.toString())?.trim();
    final currentUsername = authCubit.username.isNotEmpty
        ? authCubit.username.trim().replaceAll('@', '')
        : (authState.currentUser['username']?.toString() ?? '').trim().replaceAll('@', '');
    final currentEmail = (authState.currentUser['email']?.toString() ?? '').trim();

    final targetUserId = (u.id.isNotEmpty ? u.id : widget.userId)?.trim();
    final targetUsername = u.username?.trim().replaceAll('@', '');
    final targetEmail = u.email?.trim();

    final bool isSelf = (currentUserId != null && currentUserId.isNotEmpty && targetUserId != null && targetUserId.isNotEmpty && currentUserId == targetUserId) ||
        (currentUsername.isNotEmpty && targetUsername != null && targetUsername.isNotEmpty && currentUsername.toLowerCase() == targetUsername.toLowerCase()) ||
        (currentEmail.isNotEmpty && targetEmail != null && targetEmail.isNotEmpty && currentEmail.toLowerCase() == targetEmail.toLowerCase());

    final displayReels = <Map<String, dynamic>>[];
    final seenIds = <String>{};

    // 1. Populate videos strictly from u.videos returned by GET /user/{userId} API response
    if (u.videos.isNotEmpty) {
      for (final v in u.videos) {
        final id = v['id']?.toString() ?? '';
        if (id.isNotEmpty && !seenIds.contains(id)) {
          seenIds.add(id);
          final rawThumb = v['thumbnailUrl']?.toString() ?? v['thumbnail']?.toString() ?? '';
          final videoUrl = v['videoUrl']?.toString() ?? v['video_url']?.toString() ?? '';
          final imgUrl = (rawThumb.isNotEmpty && !rawThumb.contains('storage.example')) ? rawThumb : videoUrl;

          displayReels.add({
            'id': id,
            'userId': targetUserId,
            'title': v['title']?.toString() ?? '',
            'description': v['description']?.toString() ?? '',
            'imageUrl': imgUrl,
            'thumbnailUrl': rawThumb,
            'videoUrl': videoUrl,
            'views': v['views'] ?? 0,
            'likes': v['likes'] ?? 0,
            'likesCount': v['likes'] ?? 0,
            'averageRating': v['averageRating']?.toString() ?? '0',
            'talentScore': double.tryParse(v['averageRating']?.toString() ?? '') ?? 0.0,
            'score': v['averageRating']?.toString(),
            'handle': handle,
            'creator': name,
          });
        }
      }
    } else {
      // 2. Only if u.videos from API is empty, fallback to searching local feeds for matching userId
      final isCurrentLoggedInUser = isSelf;

      void collectMatchingReels(List<Map<String, dynamic>> list) {
        for (final r in list) {
          final id = r['id']?.toString() ?? r['_id']?.toString() ?? '';
          if (id.isNotEmpty && !seenIds.contains(id)) {
            final userMap = r['user'] is Map ? Map<String, dynamic>.from(r['user'] as Map) : null;

            final rUserId = (r['userId']?.toString() ??
                r['user_id']?.toString() ??
                r['creatorId']?.toString() ??
                userMap?['id']?.toString() ??
                userMap?['_id']?.toString())?.trim();

            final isUserIdMatch = targetUserId != null &&
                targetUserId.isNotEmpty &&
                rUserId != null &&
                rUserId.isNotEmpty &&
                rUserId == targetUserId;

            if (isUserIdMatch) {
              seenIds.add(id);
              displayReels.add(r);
            }
          }
        }
      }

      if (homeCubit.trendingReels.isNotEmpty) collectMatchingReels(homeCubit.trendingReels);
      if (trendingCubit.videos.isNotEmpty) collectMatchingReels(trendingCubit.videos.map((v) => v.toUiMap()).toList());
      if (trendingCubit.hero != null) collectMatchingReels([trendingCubit.hero!.toUiMap()]);
      if (reelsCubit.videos.isNotEmpty) collectMatchingReels(reelsCubit.videos);
      if (isCurrentLoggedInUser && myVideosCubit.videos.isNotEmpty) {
        collectMatchingReels(myVideosCubit.videos.map((v) => {
          'id': v.id,
          'userId': targetUserId,
          'user_id': targetUserId,
          'title': v.title,
          'description': v.description,
          'imageUrl': v.thumbnailUrl,
          'thumbnailUrl': v.thumbnailUrl,
          'videoUrl': v.videoUrl,
          'views': v.viewsLabel,
          'likes': v.likesLabel,
          'talentScore': double.tryParse(v.talentScoreLabel) ?? 0.0,
          'score': v.talentScoreLabel,
          'handle': handle,
          'creator': name,
        }).toList());
      }
    }

    // 3. Top Performing Video: Check API's u.topVideo first, fallback to displayReels
    Map<String, dynamic>? topReelItem;
    if (u.topVideo != null && u.topVideo!.isNotEmpty) {
      final tv = u.topVideo!;
      final rawThumb = tv['thumbnailUrl']?.toString() ?? tv['thumbnail']?.toString() ?? '';
      final videoUrl = tv['videoUrl']?.toString() ?? tv['video_url']?.toString() ?? '';
      final imgUrl = (rawThumb.isNotEmpty && !rawThumb.contains('storage.example')) ? rawThumb : videoUrl;
      topReelItem = {
        'id': tv['id']?.toString() ?? '',
        'title': tv['title']?.toString() ?? '',
        'description': tv['description']?.toString() ?? '',
        'imageUrl': imgUrl,
        'thumbnailUrl': rawThumb,
        'videoUrl': videoUrl,
        'views': tv['views'] ?? 0,
        'likes': tv['likes'] ?? 0,
        'likesCount': tv['likes'] ?? 0,
        'talentScore': tv['averageRating']?.toString() ?? '0.0',
        'score': tv['averageRating']?.toString(),
      };
    } else if (displayReels.isNotEmpty) {
      final sorted = [...displayReels]..sort((a, b) {
        final scoreA = (a['talentScore'] as num?)?.toDouble() ?? (double.tryParse(a['score']?.toString() ?? '') ?? 0.0);
        final scoreB = (b['talentScore'] as num?)?.toDouble() ?? (double.tryParse(b['score']?.toString() ?? '') ?? 0.0);
        return scoreB.compareTo(scoreA);
      });
      topReelItem = sorted.first;
    }

    final topReel = topReelItem != null ? [topReelItem] : <Map<String, dynamic>>[];

    final numVideos = u.totalVideos > 0 ? u.totalVideos : displayReels.length;

    int totalLikes = u.totalLikes;
    if (totalLikes <= 0) {
      for (final r in displayReels) {
        final l = r['likesCount'] is int
            ? r['likesCount'] as int
            : (int.tryParse(r['likes']?.toString() ?? '') ?? 0);
        totalLikes += l;
      }
    }

    String talentScore = u.talentScore ?? '0';
    if ((talentScore == '0' || talentScore == '0.0') && displayReels.isNotEmpty) {
      double totalScore = 0.0;
      int scoreCount = 0;
      for (final r in displayReels) {
        final scoreVal = (r['talentScore'] as num?)?.toDouble() ??
            (double.tryParse(r['score']?.toString() ?? '') ??
            double.tryParse(r['averageRating']?.toString() ?? '') ??
            0.0);
        if (scoreVal > 0) {
          totalScore += scoreVal;
          scoreCount++;
        }
      }
      if (scoreCount > 0) {
        talentScore = (totalScore / scoreCount).toStringAsFixed(1);
      }
    }
    final challengesWon = u.challengesWon ?? 0;

    return AppScreen(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: widget.showBackButton ? 22 : 86,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover and Avatar Header
            ProfileCoverHeader(
              coverUrl: coverUrl,
              avatarUrl: avatarUrl,
              showBackButton: widget.showBackButton,
            ),
            AppContent(
              noBottomPad: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),

                  // Name & Verified Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      if (isVerified) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified_rounded,
                          color: AppColors.blue,
                          size: 17,
                        ),
                      ],
                    ],
                  ),
                  if (handle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      handle,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSoft,
                      ),
                    ),
                  ],

                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 270,
                      child: Text(
                        bio,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSoft,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Category Badge Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F0FE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                        color: AppColors.purple,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Profile Stats Grid (Videos, Likes, Talent Score, Won)
                  ProfileStatsGrid(
                    videos: numVideos,
                    likes: totalLikes,
                    talentScore: talentScore,
                    challengesWon: challengesWon,
                  ),

                  const SizedBox(height: 18),

                  // Follow & Share Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: isSelf
                            ? SecondaryOutlineButton(
                                label: 'Edit Profile',
                                onPressed: () => context.push(AppRoutes.editProfile),
                                icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.purple),
                              )
                            : _following
                                ? SecondaryOutlineButton(
                                    label: _isFollowLoading ? 'Updating...' : 'Following',
                                    onPressed: _isFollowLoading
                                        ? null
                                        : () {
                                            if (targetUserId != null && targetUserId.isNotEmpty) {
                                              _handleFollowToggle(targetUserId);
                                            }
                                          },
                                    icon: _isFollowLoading
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.purple),
                                          )
                                        : const Icon(Icons.check, size: 16),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(28),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF8B3DFF).withValues(alpha: 0.20),
                                          blurRadius: 14,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _isFollowLoading
                                            ? null
                                            : () {
                                                if (targetUserId != null && targetUserId.isNotEmpty) {
                                                  _handleFollowToggle(targetUserId);
                                                }
                                              },
                                        borderRadius: BorderRadius.circular(28),
                                        child: Container(
                                          height: 48,
                                          decoration: BoxDecoration(
                                            gradient: AppGradients.button,
                                            borderRadius: BorderRadius.circular(28),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              if (_isFollowLoading)
                                                const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                                )
                                              else ...[
                                                const Icon(
                                                  Icons.person_add_outlined,
                                                  size: 16,
                                                  color: Colors.white,
                                                ),
                                                const SizedBox(width: 8),
                                                const Text(
                                                  'Follow',
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 14.5,
                                                    fontWeight: FontWeight.w800,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                      ),
                      const SizedBox(width: 10),

                      // Share Button
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => context.push(AppRoutes.shareReport),
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.inputBorder,
                                  width: 1.5,
                                ),
                                color: Colors.white,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x0D15083C),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.share_outlined,
                                  size: 18,
                                  color: AppColors.text,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Top Performing Video (if available)
                  if (topReel.isNotEmpty) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Top Performing Video',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => context.push(
                        '${AppRoutes.videoDetail}?id=${topReel.first['id']}',
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              AppImage(
                                url: topReel.first['imageUrl'] as String? ?? '',
                                fit: BoxFit.cover,
                              ),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.15),
                                      Colors.black.withValues(alpha: 0.65),
                                    ],
                                  ),
                                ),
                              ),

                              // Top Left Tag
                              Positioned(
                                top: 10,
                                left: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFF3D77), Color(0xFFFF5487)],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    category,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),

                              // Top Right Talent Score Rating Badge
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        size: 11,
                                        color: Color(0xFFFFC93D),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${topReel.first['talentScore'] ?? topReel.first['score'] ?? '0.0'}',
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Bottom Left Views & Creator Info
                              Positioned(
                                left: 12,
                                bottom: 10,
                                right: 12,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.remove_red_eye_outlined,
                                      size: 13,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${topReel.first['views'] ?? topReel.first['viewsCount'] ?? 0}',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    CircleAvatar(
                                      radius: 9,
                                      backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                                      child: avatarUrl.isEmpty ? const Icon(Icons.person, size: 10, color: Colors.white) : null,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      handle.isNotEmpty ? handle : name,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (isVerified) ...[
                                      const SizedBox(width: 3),
                                      const Icon(
                                        Icons.verified_rounded,
                                        size: 12,
                                        color: AppColors.blue,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],

                  // Videos Section
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Videos',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (displayReels.isNotEmpty)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: displayReels.length,
                      itemBuilder: (_, i) {
                        final r = displayReels[i];
                        return GestureDetector(
                          onTap: () => context.push(
                            '${AppRoutes.videoDetail}?id=${r['id']}',
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                AppImage(
                                  url: r['imageUrl'] as String? ?? r['thumbnailUrl'] as String? ?? '',
                                  fit: BoxFit.cover,
                                ),
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.65),
                                      ],
                                    ),
                                  ),
                                ),

                                // Category Badge
                                Positioned(
                                  top: 6,
                                  left: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFFF3D77), Color(0xFFFF5487)],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      category,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 7.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),

                                // Bottom Overlay info
                                Positioned(
                                  left: 6,
                                  bottom: 6,
                                  right: 6,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.play_arrow_rounded,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                          Text(
                                            '${r['views'] ?? r['viewsCount'] ?? 0}',
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 6.5,
                                            backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                                            child: avatarUrl.isEmpty ? const Icon(Icons.person, size: 7, color: Colors.white) : null,
                                          ),
                                          const SizedBox(width: 3),
                                          Expanded(
                                            child: Text(
                                              handle.isNotEmpty ? handle : name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 8,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          if (isVerified) ...[
                                            Container(
                                              width: 12,
                                              height: 12,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: AppColors.blue,
                                              ),
                                              child: const Icon(
                                                Icons.check_rounded,
                                                size: 8,
                                                color: Colors.white,
                                              ),
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
                        );
                      },
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBF9FE),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEFE8FA)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.video_library_outlined, size: 36, color: AppColors.textSoft),
                          SizedBox(height: 8),
                          Text(
                            'No videos posted yet',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSoft,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
