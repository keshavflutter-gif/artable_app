import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/core/widgets/app_image.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';
import 'package:artable_app/features/shell/presentation/widgets/bottom_nav_layout.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:artable_app/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:artable_app/features/profile/data/models/my_videos_response.dart';
import 'package:artable_app/app/routes/app_routes.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  String _selectedTab = 'Videos';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProfileCubit>().loadProfile(forceRefresh: true);
        context.read<AuthCubit>().fetchUserDetails();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileState = context.watch<ProfileCubit>();
    final auth = context.watch<AuthCubit>();
    final user = profileState.user;

    final fullName = user?.fullName ?? auth.fullName;
    final authUsername = user?.username ?? auth.username;
    final userName = auth.userName;
    final currentUser = auth.currentUser;
    final name = fullName.isNotEmpty
        ? fullName
        : (authUsername.isNotEmpty
            ? authUsername
            : (userName.isNotEmpty ? userName : 'User'));
    final handle = authUsername.isNotEmpty
        ? '@$authUsername'
        : ((currentUser['handle'] as String?)?.isNotEmpty == true
            ? currentUser['handle'] as String
            : (userName.isNotEmpty ? '@$userName' : ''));
    final bio = (user?.bio != null && user!.bio!.isNotEmpty)
        ? user.bio!
        : (auth.bio.isNotEmpty
            ? auth.bio
            : ((currentUser['bio'] as String?)?.trim() ?? ''));
    final category = (user?.talentCategory != null && user!.talentCategory!.isNotEmpty)
        ? user.talentCategory!
        : (auth.category.isNotEmpty
            ? auth.category
            : ((currentUser['category'] as String?)?.trim() ?? ''));
    final coverUrl = (user?.coverImageUrl != null && user!.coverImageUrl!.isNotEmpty)
        ? user.coverImageUrl!
        : (auth.coverUrl.isNotEmpty
            ? auth.coverUrl
            : ((currentUser['coverUrl'] as String?)?.isNotEmpty == true
                ? currentUser['coverUrl'] as String
                : ''));
    final avatarUrl = (user?.profilePhotoUrl != null && user!.profilePhotoUrl!.isNotEmpty)
        ? user.profilePhotoUrl!
        : (auth.avatarUrl.isNotEmpty
            ? auth.avatarUrl
            : ((currentUser['avatarUrl'] as String?)?.isNotEmpty == true
                ? currentUser['avatarUrl'] as String
                : ''));

    final isPrime = user?.isPrime ?? false;

    final dynamic socialSource = user?.socialLinks ?? auth.socialLinks ?? currentUser['socialLinks'];
    String socialLabel = 'Website';
    String? socialUrl;
    if (socialSource is List && socialSource.isNotEmpty) {
      final first = socialSource.first;
      if (first is Map) {
        socialUrl = first['url']?.toString() ?? first['websiteUrl']?.toString();
        final p = first['platform']?.toString();
        if (p != null && p.isNotEmpty) {
          socialLabel = p.replaceAll('Url', '').replaceAll('_url', '');
          socialLabel = socialLabel.isNotEmpty
              ? socialLabel[0].toUpperCase() + socialLabel.substring(1)
              : 'Website';
        } else if (socialUrl != null && socialUrl.contains('instagram')) {
          socialLabel = 'Instagram';
        } else if (socialUrl != null && (socialUrl.contains('youtube') || socialUrl.contains('youtu.be'))) {
          socialLabel = 'YouTube';
        }
      }
    } else if (socialSource is Map && socialSource.isNotEmpty) {
      if (socialSource['websiteUrl'] != null && socialSource['websiteUrl'].toString().isNotEmpty) {
        socialUrl = socialSource['websiteUrl'].toString();
        socialLabel = 'Website';
      } else if (socialSource['instagramUrl'] != null && socialSource['instagramUrl'].toString().isNotEmpty) {
        socialUrl = socialSource['instagramUrl'].toString();
        socialLabel = 'Instagram';
      } else if (socialSource['youtubeUrl'] != null && socialSource['youtubeUrl'].toString().isNotEmpty) {
        socialUrl = socialSource['youtubeUrl'].toString();
        socialLabel = 'YouTube';
      } else {
        final firstKey = socialSource.keys.first.toString();
        socialUrl = socialSource[firstKey]?.toString();
        socialLabel = firstKey.replaceAll('Url', '').replaceAll('_url', '');
        socialLabel = socialLabel.isNotEmpty
            ? socialLabel[0].toUpperCase() + socialLabel.substring(1)
            : 'Website';
      }
    }

    final recentVideosTitle = profileState.data?.recentVideosTitle ?? 'Recent Videos';

    return AppScreen(
      bottomNav: AppBottomNav(current: AppRoutes.myProfile),
      child: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            context.read<ProfileCubit>().loadProfile(forceRefresh: true),
            context.read<AuthCubit>().fetchUserDetails(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Cover Banner & Overlapping Circular Avatar
              _buildCoverAndAvatar(coverUrl, avatarUrl),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    // 2. Name & ★ PRIME Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                        if (isPrime) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF3D77), Color(0xFF8B3DFF)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF3D77).withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star, size: 10, color: Colors.white),
                                SizedBox(width: 3),
                                Text(
                                  'PRIME',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Handle
                    if (handle.isNotEmpty)
                      Text(
                        handle,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSoft,
                        ),
                      ),
                    const SizedBox(height: 6),

                    // Bio Text
                    if (bio.isNotEmpty) ...[
                      Text(
                        bio,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF4A435A),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Category Pill
                    if (category.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F3FC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFECE8F5), width: 1),
                        ),
                        child: Text(
                          category.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.purple,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Social Link Pill Button
                    if (socialUrl != null && socialUrl.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7.5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFECE8F5), width: 1.2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0815083C),
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.link_rounded, size: 17, color: Color(0xFF8B3DFF)),
                            const SizedBox(width: 6),
                            Text(
                              socialLabel,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1B132C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),

                    // 3. Stats Grid (4 Cards Row)
                    _buildStatsRow(context),
                    const SizedBox(height: 18),

                    // 4. Edit Profile Button
                    _buildEditProfileButton(context),
                    const SizedBox(height: 16),

                    // 5. Quick Links (Wallet, Stats, Settings)
                    _buildQuickActionCards(context),
                    const SizedBox(height: 22),

                    // 6. Tab Selector Pills
                    _buildSegmentedTabs(),
                    const SizedBox(height: 22),

                    // 7. Recent Videos Section Header
                    Row(
                      children: [
                        Text(
                          recentVideosTitle,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => context.push('/my-videos'),
                          child: const Text(
                            'See All',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.purple,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 8. 2-Column Grid of Recent Videos
                    _buildRecentVideosGrid(context),
                    const SizedBox(height: 26),

                    // 9. Badges Section Header
                    Row(
                      children: [
                        const Text(
                          'Badges',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => context.push('/achievements'),
                          child: const Text(
                            'See All',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.purple,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 10. Horizontal Badges Row
                    _buildBadgesRow(context),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 1. Cover and Circular Avatar Header ---
  Widget _buildCoverAndAvatar(String coverUrl, String avatarUrl) {
    return SizedBox(
      height: 155 + 46,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Cover Banner
          SizedBox(
            height: 155,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppImage(
                  url: coverUrl,
                  fit: BoxFit.cover,
                  placeholderIcon: Icons.panorama_outlined,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0x100A0514),
                        const Color(0x500A0514),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Overlapping Avatar
          Positioned(
            left: 0,
            right: 0,
            top: 155 - 46,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3315083C),
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ],
                  border: Border.all(color: Colors.white, width: 4.5),
                ),
                child: AppImage(
                  url: avatarUrl,
                  width: 90,
                  height: 90,
                  borderRadius: BorderRadius.circular(45),
                  placeholderIcon: Icons.person_rounded,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. Stats Grid ---
  Widget _buildStatsRow(BuildContext context) {
    final profileState = context.watch<ProfileCubit>();
    final statCards = profileState.statCards;
    final stats = profileState.stats;

    if (statCards.isNotEmpty) {
      return Row(
        children: statCards.map((card) {
          return _buildStatCard(card.displayValue, card.label.toUpperCase());
        }).toList(),
      );
    }

    final videos = stats?.totalVideos ?? 0;
    final likes = stats?.totalLikes ?? 0;
    final talentScore = stats?.talentScore.toStringAsFixed(1) ?? '0.0';
    final wins = stats?.wins ?? 0;

    return Row(
      children: [
        _buildStatCard('$videos', 'VIDEOS'),
        const SizedBox(width: 8),
        _buildStatCard('$likes', 'LIKES'),
        const SizedBox(width: 8),
        _buildStatCard(talentScore, 'TALENT SCORE'),
        const SizedBox(width: 8),
        _buildStatCard('$wins', 'WON'),
      ],
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F8FC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFECE8F5),
            width: 1.2,
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textSoft,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 3. Edit Profile Button ---
  Widget _buildEditProfileButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await context.push('/edit-profile');
        if (context.mounted) {
          context.read<ProfileCubit>().loadProfile(forceRefresh: true);
          context.read<AuthCubit>().fetchUserDetails();
        }
      },
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFFFF5E3A),
              Color(0xFFFF2A6D),
              Color(0xFF8B3DFF),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF3D77).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_outlined, color: Colors.white, size: 17),
            SizedBox(width: 8),
            Text(
              'Edit Profile',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 4. Quick Action Cards (Wallet, Stats, Settings) ---
  Widget _buildQuickActionCards(BuildContext context) {
    return Row(
      children: [
        _buildActionCard(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Wallet',
          onTap: () => context.push('/wallet'),
        ),
        const SizedBox(width: 12),
        _buildActionCard(
          icon: Icons.bar_chart_rounded,
          label: 'Stats',
          onTap: () => context.push('/talent-score'),
        ),
        const SizedBox(width: 12),
        _buildActionCard(
          icon: Icons.settings_outlined,
          label: 'Settings',
          onTap: () => context.push('/settings'),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFECE8F5), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A15083C),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F4FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: AppColors.purple),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 5. Segmented Tab Selector Pills ---
  Widget _buildSegmentedTabs() {
    return Row(
      children: [
        _buildTabPill('Videos', isSelected: _selectedTab == 'Videos', onTap: () {
          setState(() => _selectedTab = 'Videos');
        }),
        const SizedBox(width: 10),
        _buildTabPill('Achievements', isSelected: _selectedTab == 'Achievements', onTap: () {
          context.push('/achievements');
        }),
        const SizedBox(width: 10),
        _buildTabPill('Stats', isSelected: _selectedTab == 'Stats', onTap: () {
          context.push('/talent-score');
        }),
      ],
    );
  }

  Widget _buildTabPill(String title, {required bool isSelected, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF6F3FC) : const Color(0xFFFAF9FD),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? const Color(0xFF8B3DFF).withValues(alpha: 0.10)
                    : const Color(0x0615083C),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.purple : AppColors.textSoft,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- 6. Recent Videos Grid ---
  Widget _buildRecentVideosGrid(BuildContext context) {
    final profileState = context.watch<ProfileCubit>();
    final videos = profileState.recentVideos;

    if (profileState.isLoading && videos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.purple),
        ),
      );
    }

    if (videos.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F8FC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFECE8F5), width: 1.2),
        ),
        child: const Column(
          children: [
            Icon(Icons.video_library_outlined, size: 36, color: AppColors.textSoft),
            SizedBox(height: 8),
            Text(
              'No Recent Videos',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Your uploaded videos will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSoft,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.54,
      ),
      itemCount: videos.length,
      itemBuilder: (context, i) {
        return _buildFigmaVideoCard(context, videos[i]);
      },
    );
  }

  Widget _buildFigmaVideoCard(BuildContext context, MyVideoItem video) {
    final status = video.status.toLowerCase();
    final title = video.title.isNotEmpty ? video.title : 'Challenge Video';
    final thumbnailUrl = video.thumbnailUrl;
    final views = video.viewsLabel;
    final likes = video.likesLabel;
    final date = video.dateLabel;
    final rejectReason = video.rejectionReason ?? 'Video did not meet content guidelines.';

    Color badgeColor;
    String badgeLabel = video.statusLabel ?? video.statusBadge?.label ?? video.status;

    if (status == 'approved' || status == 'live' || video.isLive) {
      badgeColor = const Color(0xFF00C853);
      badgeLabel = badgeLabel.isNotEmpty ? badgeLabel.toUpperCase() : 'LIVE';
    } else if (status == 'pending_review' || status == 'under_review') {
      badgeColor = const Color(0xFFFF9800);
      badgeLabel = badgeLabel.isNotEmpty ? badgeLabel.toUpperCase() : 'UNDER REVIEW';
    } else if (status == 'draft') {
      badgeColor = const Color(0xFF5E2EAA);
      badgeLabel = badgeLabel.isNotEmpty ? badgeLabel.toUpperCase() : 'DRAFT';
    } else {
      badgeColor = const Color(0xFFFF3B30);
      badgeLabel = badgeLabel.isNotEmpty ? badgeLabel.toUpperCase() : 'REJECTED';
    }

    final challengeObj = video.challenge;
    final challengeId = challengeObj?['id']?.toString() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECE8F5), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D15083C),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail with top rounded corners and Status Badge
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14.8)),
            child: SizedBox(
              height: 135,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppImage(url: thumbnailUrl, fit: BoxFit.cover),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        badgeLabel,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Card Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Stats row (Views, Likes, Date)
                  Row(
                    children: [
                      const Icon(Icons.remove_red_eye_outlined, size: 10.5, color: AppColors.textSoft),
                      const SizedBox(width: 2.5),
                      Text(
                        views,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSoft,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.favorite_border_rounded, size: 10.5, color: AppColors.textSoft),
                      const SizedBox(width: 2.5),
                      Text(
                        likes,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSoft,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        date,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 8.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textFaint,
                        ),
                      ),
                    ],
                  ),

                  // Rejected warning note
                  if (status == 'rejected') ...[
                    const SizedBox(height: 4),
                    Text(
                      rejectReason,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF3B30),
                        height: 1.15,
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Bottom Action Buttons
                  if (status == 'draft' || video.canContinueDraft)
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildSmallActionButton(
                            icon: Icons.edit_outlined,
                            label: 'Continue Draft',
                            onTap: () => context.push('/studio-drafts'),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          flex: 2,
                          child: _buildSmallActionButton(
                            icon: Icons.share_outlined,
                            label: 'Share',
                            onTap: () {},
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _buildSmallActionButton(
                            icon: Icons.remove_red_eye_outlined,
                            label: 'View',
                            onTap: () {
                              final routeId = challengeId.isNotEmpty ? challengeId : video.id;
                              context.push('/video-detail?id=$routeId');
                            },
                          ),
                        ),
                        if (video.canShare) ...[
                          const SizedBox(width: 5),
                          Expanded(
                            child: _buildSmallActionButton(
                              icon: Icons.share_outlined,
                              label: 'Share',
                              onTap: () {},
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 26,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F5FC),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0xFFECE8F5), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 11, color: AppColors.text),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 7. Badges Horizontal Row ---
  Widget _buildBadgesRow(BuildContext context) {
    final profileState = context.watch<ProfileCubit>();
    final badges = profileState.data?.badges ?? [];

    if (badges.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F8FC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFECE8F5), width: 1.2),
        ),
        child: const Center(
          child: Text(
            'No badges earned yet',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSoft,
            ),
          ),
        ),
      );
    }

    return Row(
      children: badges.map((badge) {
        final title = badge.title;
        const iconData = Icons.military_tech_rounded;

        return Expanded(
          child: GestureDetector(
            onTap: () => context.push('/achievements'),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.fromLTRB(4, 18, 4, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFECE8F5),
                  width: 1.2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0C15083C),
                    blurRadius: 16,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFF4860),
                          Color(0xFF8B2BE2),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF3868).withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: badge.badgeUrl != null && badge.badgeUrl!.isNotEmpty
                        ? AppImage(url: badge.badgeUrl!, width: 22, height: 22)
                        : const Icon(iconData, size: 22, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B132C),
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
