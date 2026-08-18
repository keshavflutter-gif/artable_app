import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/core/utils/mock_helpers.dart';
import 'package:artable_app/core/widgets/app_back_header.dart';
import 'package:artable_app/core/widgets/app_image.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';
import 'package:artable_app/data/datasources/mock_data.dart';

class WinnersScreen extends StatefulWidget {
  const WinnersScreen({super.key});

  @override
  State<WinnersScreen> createState() => _WinnersScreenState();
}

class _WinnersScreenState extends State<WinnersScreen> {
  static const _periods = ['Challenge', 'Weekly', 'Monthly'];
  var _period = 'Challenge';

  @override
  Widget build(BuildContext context) {
    // Filter winners based on active period selection
    final winnersList = MockData.WINNERS.where((w) {
      final p = (w['period'] as String);
      return _period.toLowerCase() == p;
    }).toList();

    // Sort: Rank 1 first, then 2, then 3 etc.
    winnersList.sort((a, b) => (a['rank'] as int).compareTo(b['rank'] as int));

    final featuredWinner = winnersList.isNotEmpty ? winnersList.first : null;
    final otherWinners = winnersList.length > 1 ? winnersList.sublist(1) : <Map<String, dynamic>>[];

    return AppScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppBackHeader(title: 'Winners'),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  // Filter Pills Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _periods.map((p) {
                        final isSelected = _period == p;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _period = p),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: isSelected ? AppGradients.button : null,
                                color: isSelected ? null : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: isSelected ? null : Border.all(color: const Color(0xFFECE8F5), width: 1.2),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFFFF5487).withValues(alpha: 0.2),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  p,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: isSelected ? Colors.white : const Color(0xFF8B849C),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Featured Winner Banner
                  if (featuredWinner != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _FeaturedWinnerCard(winner: featuredWinner),
                    ),

                  const SizedBox(height: 24),

                  // "More Winners" Section
                  if (otherWinners.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'More Winners',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Color(0xFF241E38),
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: otherWinners.map((w) => _WinnerRowCard(winner: w)).toList(),
                      ),
                    ),
                  ] else if (featuredWinner == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                      child: Center(
                        child: Text(
                          'No winners in this category yet.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFF8B849C),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedWinnerCard extends StatelessWidget {
  const _FeaturedWinnerCard({required this.winner});

  final Map<String, dynamic> winner;

  @override
  Widget build(BuildContext context) {
    final user = MockHelpers.creatorById(winner['userId'] as String);
    final challenge = MockHelpers.challengeById(winner['challengeId'] as String);

    final userName = user?['name'] as String? ?? 'Theo B.';
    final userHandle = user?['handle'] as String? ?? '@funny_banda';
    final userAvatar = user?['avatarUrl'] as String? ?? 'https://i.pravatar.cc/120?u=funny_banda';
    final rating = (winner['talentScore'] as num? ?? 8.7).toStringAsFixed(1);

    final challengeTitle = challenge?['title'] as String? ?? 'Stand-Up Spotlight';
    final prizeText = winner['prize'] as String? ?? '₹1,500 + Rising Star Badge';

    const backgroundUrl = 'https://images.unsplash.com/photo-1517486808906-6ca8b3f04846?w=600&auto=format&fit=crop&q=80';

    return GestureDetector(
      onTap: () => context.push('/winner-detail?id=${winner['id']}'),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0,      0,      0,      1, 0,
                ]),
                child: const AppImage(
                  url: backgroundUrl,
                  fit: BoxFit.cover,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.75),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1),
                  ),
                  child: Text(
                    '#${winner['rank']}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFFFF8F55), Color(0xFFFF5487)],
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 1),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: AppImage(
                                url: userAvatar,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
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
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                userHandle,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                challengeTitle,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  color: Color(0xFFFF5487),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                prizeText,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 14),
                              const SizedBox(width: 4),
                              Text(
                                rating,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ],
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
      ),
    );
  }
}

class _WinnerRowCard extends StatelessWidget {
  const _WinnerRowCard({required this.winner});

  final Map<String, dynamic> winner;

  @override
  Widget build(BuildContext context) {
    final user = MockHelpers.creatorById(winner['userId'] as String);
    final challenge = MockHelpers.challengeById(winner['challengeId'] as String);

    final userName = user?['name'] as String? ?? 'Kofi A.';
    final userAvatar = user?['avatarUrl'] as String? ?? 'https://i.pravatar.cc/120?u=kofi_streets';
    final rating = (winner['talentScore'] as num? ?? 7.0).toStringAsFixed(1);
    
    final challengeTitle = challenge?['title'] as String? ?? 'Street Sports Showdown';
    final prizeText = winner['prize'] as String? ?? 'Nike Sponsor Kit';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECE8F5), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5E2EAA).withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AppImage(
                  url: userAvatar,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                bottom: -2,
                right: -4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Color(0xFFCD7F32),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '#${winner['rank']}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 8,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Color(0xFF241E38),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  challengeTitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF8B849C),
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  prizeText,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF8B3DFF),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 14),
                  const SizedBox(width: 2),
                  Text(
                    rating,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Color(0xFF241E38),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => context.push('/winner-detail?id=${winner['id']}'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3EAFD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'View',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Color(0xFF8B3DFF),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
