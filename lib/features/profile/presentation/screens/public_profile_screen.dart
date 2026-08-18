import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/core/utils/mock_helpers.dart';
import 'package:artable_app/core/widgets/app_image.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';
import 'package:artable_app/core/widgets/secondary_outline_button.dart';
import 'package:artable_app/features/profile/presentation/widgets/profile_reward_widgets.dart';
import 'package:artable_app/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:artable_app/data/datasources/mock_data.dart';
import 'package:artable_app/app/routes/app_routes.dart';

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
  var _following = false;

  @override
  Widget build(BuildContext context) {
    final u = MockHelpers.creatorById(widget.userId) ??
        MockHelpers.creatorById(MockData.CURRENT_USER_ID) ??
        MockData.CREATORS.first;
    final reels = MockData.REELS.where((r) => r['handle'] == u['handle']).toList();
    final displayReels = reels.isNotEmpty ? reels : MockData.REELS.take(3).toList();
    final topReel = [...displayReels]
      ..sort((a, b) => (b['talentScore'] as num).compareTo(a['talentScore'] as num));
    final earnedBadges =
        MockData.BADGES.where((b) => b['earned'] == true).take(4).toList();

    final category = (u['category'] as String? ?? 'DANCE').toUpperCase();
    final handle = u['handle'] as String? ?? '@dance_hero';
    final name = u['name'] as String? ?? 'Maya R.';
    final bio = u['bio'] as String? ??
        'Contemporary + street dance. Chasing clean lines and bigger stages.';

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
              coverUrl: u['coverUrl'] as String,
              avatarUrl: u['avatarUrl'] as String,
              showBackButton: widget.showBackButton,
            ),
            AppContent(
              noBottomPad: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),

                  // Name & Verified & Prime Badges
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
                      if (u['verified'] == true) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified_rounded,
                          color: AppColors.blue,
                          size: 17,
                        ),
                      ],
                      if (u['prime'] == true) ...[
                        const SizedBox(width: 8),
                        const PrimeBadge(compact: true),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Handle
                  Text(
                    handle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSoft,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Bio Description
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
                    videos: u['videos'],
                    likes: u['likes'],
                    talentScore: (u['talentScore'] as num).toStringAsFixed(1),
                    challengesWon: u['challengesWon'],
                  ),

                  const SizedBox(height: 18),

                  // Follow & Share Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _following
                            ? SecondaryOutlineButton(
                                label: 'Following',
                                onPressed: () =>
                                    setState(() => _following = !_following),
                                icon: const Icon(Icons.check, size: 16),
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
                                    onTap: () =>
                                        setState(() => _following = !_following),
                                    borderRadius: BorderRadius.circular(28),
                                    child: Container(
                                      height: 48,
                                      decoration: BoxDecoration(
                                        gradient: AppGradients.button,
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Icon(
                                            Icons.person_add_outlined,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Follow',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
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

                  // Section Header: Top Performing Video
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

                  // Top Performing Video Card
                  if (topReel.isNotEmpty)
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
                                url: topReel.first['imageUrl'] as String,
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

                              // Top Left Tag (e.g. DANCE)
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
                                        '${topReel.first['talentScore']}',
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
                                      '${topReel.first['views']}',
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
                                      backgroundImage: NetworkImage(
                                        u['avatarUrl'] as String,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      handle,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (u['verified'] == true) ...[
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

                  // Section Header: Videos
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

                  // Videos Grid
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
                                url: r['imageUrl'] as String,
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
                                          '${r['views']}',
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
                                          backgroundImage: NetworkImage(
                                            u['avatarUrl'] as String,
                                          ),
                                        ),
                                        const SizedBox(width: 3),
                                        Expanded(
                                          child: Text(
                                            handle,
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
                                        if (u['verified'] == true) ...[
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
                  ),

                  const SizedBox(height: 22),

                  // Section Header: Achievements
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Achievements',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Achievements Badges Row - 4 equal columns fitting across screen
                  Row(
                    children: earnedBadges
                        .map(
                          (b) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2.5),
                              child: BadgeCard(badge: b),
                            ),
                          ),
                        )
                        .toList(),
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

