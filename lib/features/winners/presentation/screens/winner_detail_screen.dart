import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/core/utils/mock_helpers.dart';
import 'package:artable_app/core/widgets/app_image.dart';

class WinnerDetailScreen extends StatelessWidget {
  const WinnerDetailScreen({super.key, this.winnerId});

  final String? winnerId;

  @override
  Widget build(BuildContext context) {
    final w = MockHelpers.winnerById(winnerId)!;
    final user = MockHelpers.creatorById(w['userId'] as String);
    final challenge = MockHelpers.challengeById(w['challengeId'] as String);
    final reel = MockHelpers.reelById(w['reelId'] as String?);

    // Use default values matching Figma if data is missing
    final userName = user?['name'] as String? ?? 'Maya R.';
    final userHandle = user?['handle'] as String? ?? '@dance_hero';
    final userAvatar = user?['avatarUrl'] as String? ?? 'https://i.pravatar.cc/120?u=dance_hero';
    
    // Figma image shows a boy smiling for winner details.
    final heroImage = 'https://images.unsplash.com/photo-1503919545889-aef636e10ad4?w=600&auto=format&fit=crop&q=80'; 

    final challengeTitle = challenge?['title'] as String? ?? 'MONTHLY MEGA DANCE BATTLE';
    final prizeText = w['prize'] as String? ?? '₹2,500 + Champion Badge';

    final positionText = '#${w['rank'] ?? 1}';
    final avgRating = (w['avgRating'] as num? ?? 9.4).toStringAsFixed(1);
    final totalVotes = (w['totalVotes'] as num? ?? 8420).toString();

    final winDate = w['winDate'] as String? ?? '2026-07-15';
    final talentScore = (w['talentScore'] as num? ?? 9.4).toStringAsFixed(1);

    final viewsCount = reel?['views'] as String? ?? '1.2M';
    final likesCount = reel?['likes'] as String? ?? '124K';
    final videoThumbnail = reel?['imageUrl'] as String? ?? 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=480&q=80';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Image Header
            SizedBox(
              height: 360,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Banner Image
                  AppImage(
                    url: heroImage,
                    fit: BoxFit.cover,
                  ),
                  // Dark Gradient Overlay for text readability
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.75),
                        ],
                        stops: const [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                  // Header Buttons (Back & Rank)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 12,
                    left: 20,
                    right: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back Button
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.chevron_left,
                              color: Color(0xFF241E38),
                              size: 24,
                            ),
                          ),
                        ),
                        // Rank Badge (#1)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF8F55), Color(0xFFFF5487)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF5487).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            positionText,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Creator Details Overlay
                  Positioned(
                    bottom: 24,
                    left: 20,
                    right: 20,
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: AppImage(
                              url: userAvatar,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Name & Handle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Text(
                                userHandle,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Content Layout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Prize Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5E2EAA).withValues(alpha: 0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFECE8F5), width: 1),
                    ),
                    child: Row(
                      children: [
                        // Trophy Icon inside gradient circle
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFFF8F55), Color(0xFFFF5487), Color(0xFF9652FF)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF5487).withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.emoji_events_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Prize Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                challengeTitle.toUpperCase(),
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  color: Color(0xFF8B849C),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                prizeText,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Color(0xFF241E38),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Winning Entry Title
                  const Text(
                    'Winning Entry',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Color(0xFF241E38),
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Video Thumbnail Container
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Thumbnail Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: AppImage(
                            url: videoThumbnail,
                            fit: BoxFit.cover,
                          ),
                        ),
                        // Play Button Overlay
                        Center(
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Color(0xFF8B3DFF),
                              size: 32,
                            ),
                          ),
                        ),
                        // Stats overlays (Views & Likes)
                        Positioned(
                          bottom: 12,
                          left: 16,
                          child: Row(
                            children: [
                              // Views
                              Row(
                                children: [
                                  const Icon(Icons.remove_red_eye_outlined, color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    viewsCount,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              // Likes
                              Row(
                                children: [
                                  const Icon(Icons.favorite_border_rounded, color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    likesCount,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Watch Video Button
                  Container(
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: AppGradients.button,
                      borderRadius: BorderRadius.circular(27),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF5487).withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (reel != null) {
                            context.push('/reel?id=${reel['id']}');
                          }
                        },
                        borderRadius: BorderRadius.circular(27),
                        child: const Center(
                          child: Text(
                            'Watch Winning Video',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Stats Grid (Position, Rating, Total Votes)
                  Row(
                    children: [
                      Expanded(
                        child: _StatGridCard(
                          value: positionText,
                          label: 'POSITION',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatGridCard(
                          value: avgRating,
                          label: 'AVG RATING',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatGridCard(
                          value: totalVotes,
                          label: 'TOTAL VOTES',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  
                  // Won on Calendar Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBF9FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFECE8F5), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF3EAFD),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.calendar_today_rounded,
                            color: Color(0xFF8B3DFF),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: Color(0xFF241E38),
                              ),
                              children: [
                                const TextSpan(
                                  text: 'Won on ',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                TextSpan(
                                  text: winDate,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                TextSpan(
                                  text: '\nTalent Score: $talentScore / 10',
                                  style: const TextStyle(
                                    color: Color(0xFF8B849C),
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // View Profile Button
                  OutlinedButton.icon(
                    onPressed: () {
                      if (user != null) {
                        context.push('/profile?id=${user['id']}');
                      }
                    },
                    icon: const Icon(Icons.person_outline_rounded, color: Color(0xFF8B3DFF), size: 18),
                    label: const Text(
                      'View Profile',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Color(0xFF8B3DFF),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFECE8F5), width: 1.5),
                      backgroundColor: const Color(0xFFF8F7FC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(27),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatGridCard extends StatelessWidget {
  const _StatGridCard({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECE8F5), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5E2EAA).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: Color(0xFF241E38),
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFFB7B1C6),
              fontWeight: FontWeight.w700,
              fontSize: 9,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
