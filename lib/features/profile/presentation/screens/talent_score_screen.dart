import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/core/utils/mock_helpers.dart';
import 'package:artable_app/core/widgets/app_back_header.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';
import 'package:artable_app/features/profile/presentation/bloc/stats_cubit.dart';
import 'package:artable_app/data/datasources/mock_data.dart';
import 'package:artable_app/features/profile/data/models/profile_stats_response.dart';

class TalentScoreScreen extends StatefulWidget {
  const TalentScoreScreen({super.key});

  @override
  State<TalentScoreScreen> createState() => _TalentScoreScreenState();
}

class _TalentScoreScreenState extends State<TalentScoreScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<StatsCubit>().loadStats();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final statsVm = context.watch<StatsCubit>();
    final data = statsVm.data;
    final isLoading = statsVm.isLoading && !statsVm.hasLoaded;
    final u = MockHelpers.currentUser;

    return AppScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pinned App Back Header
          const AppBackHeader(title: 'Talent Score'),

          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.purple),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => context
                        .read<StatsCubit>()
                        .loadStats(forceRefresh: true),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),

                            // 1. Hero Overall Talent Score Gradient Banner
                            _buildHeroBanner(data: data, u: u),
                            const SizedBox(height: 20),

                            // 2. 2-Column Grid of 6 Metric Cards
                            _buildMetricCardsGrid(data: data, u: u),
                            const SizedBox(height: 26),

                            // 3. Rating Breakdown (1–10) Section
                            const Text(
                              'Rating Breakdown (1–10)',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1B132C),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildRatingBreakdown(data: data),
                            const SizedBox(height: 26),

                            // 4. Recent Challenge Performance Section
                            const Text(
                              'Recent Challenge Performance',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1B132C),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildRecentPerformanceList(
                              context: context,
                              data: data,
                            ),
                            const SizedBox(height: 20),

                            // 5. Bottom Info Notice Card
                            _buildInfoNoticeCard(note: data?.note),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // --- 1. Hero Overall Talent Score Gradient Banner (Exact Design Match) ---
  Widget _buildHeroBanner({
    required ProfileStatsData? data,
    required Map<String, dynamic> u,
  }) {
    final scoreStr = data?.overallTalentScoreLabel.isNotEmpty == true
        ? data!.overallTalentScoreLabel
        : (data != null
            ? data.overallTalentScore.toStringAsFixed(1)
            : (u['talentScore'] as num?)?.toStringAsFixed(1) ?? '7.6');

    final avgRating = data?.avgRatingLabel.isNotEmpty == true
        ? data!.avgRatingLabel
        : (data != null ? data.avgRating.toStringAsFixed(1) : '7.3');

    final formattedVotes = data?.totalVotesLabel.isNotEmpty == true
        ? data!.totalVotesLabel
        : (data != null
            ? _formatNumberWithCommas(data.totalVotes.toInt())
            : ((u['votes'] ?? 1840).toString() == '1840'
                ? '1,840'
                : (u['votes'] ?? 1840).toString()));

    final trendStr = _formatRatingTrend(data?.ratingTrend);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.55, 1.0],
          colors: [
            Color(0xFF220854), // Deep Midnight Indigo
            Color(0xFF6B18D6), // Electric Vivid Purple
            Color(0xFFF4307B), // Radiant Neon Coral Pink
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF4307B).withValues(alpha: 0.38),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: const Color(0xFF220854).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'OVERALL TALENT SCORE',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.78),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            scoreStr,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 52,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBannerStatCol(avgRating, 'Avg Rating'),
                _buildBannerStatCol(formattedVotes, 'Total Votes'),
                _buildBannerStatCol(trendStr, 'Rating Trend'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatRatingTrend(String? trend) {
    if (trend == null || trend.isEmpty) return '↑ Trending';
    if (trend == 'NO_RECENT_RATINGS') return '-';
    if (trend.toUpperCase() == 'TRENDING' || trend.toUpperCase() == 'UP') {
      return '↑ Trending';
    }
    if (trend.toUpperCase() == 'DOWN') return '↓ Down';
    return trend;
  }

  Widget _buildBannerStatCol(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }

  // --- 2. 2-Column Grid of 6 Metric Cards ---
  Widget _buildMetricCardsGrid({
    required ProfileStatsData? data,
    required Map<String, dynamic> u,
  }) {
    final won = data?.stats.wins ?? u['challengesWon'] ?? 1;
    final videos = data?.stats.totalVideos ?? u['videos'] ?? 9;

    final winRate = data != null
        ? (data.winRate > 0
            ? '${data.winRate.round()}%'
            : (videos > 0 ? '${((won / videos) * 100).round()}%' : '0%'))
        : '${((won as num) / (videos as num) * 100).round()}%';

    final earnings = data != null
        ? data.stats.rewardEarnings.toInt().toString()
        : ((won as num) * 420).toString();

    final views = data != null
        ? _formatCompactNumber(data.stats.totalViews)
        : '128K';

    final likes = data != null
        ? _formatCompactNumber(data.stats.totalLikes)
        : (u['likes'] ?? '86K').toString();

    final metrics = [
      {
        'icon': Icons.emoji_events_outlined,
        'value': '$won',
        'label': 'Challenges Won',
      },
      {
        'icon': Icons.pie_chart_outline_rounded,
        'value': winRate,
        'label': 'Win Rate',
      },
      {
        'icon': Icons.card_giftcard_rounded,
        'value': '₹$earnings',
        'label': 'Reward Earnings',
      },
      {
        'icon': Icons.smart_display_outlined,
        'value': '$videos',
        'label': 'Total Videos',
      },
      {
        'icon': Icons.remove_red_eye_outlined,
        'value': views,
        'label': 'Total Views',
      },
      {
        'icon': Icons.favorite_border_rounded,
        'value': likes,
        'label': 'Total Likes',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.46,
      ),
      itemCount: metrics.length,
      itemBuilder: (_, i) {
        final m = metrics[i];
        return Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F3FC),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  m['icon'] as IconData,
                  size: 16,
                  color: AppColors.purple,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m['value'] as String,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1B132C),
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 1.5),
                  Text(
                    m['label'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSoft,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // --- 3. Rating Breakdown (1–10) Progress Bars ---
  Widget _buildRatingBreakdown({required ProfileStatsData? data}) {
    if (data != null && data.ratingBreakdown.isNotEmpty) {
      final breakdown = data.ratingBreakdown;
      final max = breakdown.map((e) => e.count).fold<int>(
            0,
            (prev, elem) => elem > prev ? elem : prev,
          );

      return Column(
        children: breakdown.map((item) {
          final pct = item.barPercent > 0
              ? (item.barPercent / 100).clamp(0.04, 1.0)
              : (max > 0 ? (item.count / max).clamp(0.04, 1.0) : 0.04);

          return Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  child: Text(
                    '${item.score}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8B849C),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final barWidth = constraints.maxWidth * pct;
                      return Container(
                        height: 7,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F2FA),
                          borderRadius: BorderRadius.circular(3.5),
                        ),
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: barWidth,
                          height: 7,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFF5E3A),
                                Color(0xFFFF2A6D),
                                Color(0xFF8B3DFF),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(3.5),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 24,
                  child: Text(
                    '${item.count}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8B849C),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    final max = MockData.RATING_DISTRIBUTION.reduce(
      (a, b) => a > b ? a : b,
    );

    return Column(
      children: List.generate(MockData.RATING_DISTRIBUTION.length, (i) {
        final count = MockData.RATING_DISTRIBUTION[i];
        final pct = (count / max).clamp(0.04, 1.0);

        return Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8B849C),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final barWidth = constraints.maxWidth * pct;
                    return Container(
                      height: 7,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F2FA),
                        borderRadius: BorderRadius.circular(3.5),
                      ),
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: barWidth,
                        height: 7,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFF5E3A),
                              Color(0xFFFF2A6D),
                              Color(0xFF8B3DFF),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(3.5),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 24,
                child: Text(
                  '$count',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8B849C),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // --- 4. Recent Challenge Performance Cards ---
  Widget _buildRecentPerformanceList({
    required BuildContext context,
    required ProfileStatsData? data,
  }) {
    if (data != null && data.recentChallengePerformance.isNotEmpty) {
      return Column(
        children: data.recentChallengePerformance.map((p) {
          final title = p.title;
          final result = p.result;
          final date = p.date.isNotEmpty ? p.date : 'Recent';
          final isPlaced = p.isPlaced;

          return GestureDetector(
            onTap: () {
              if (p.challengeId != null && p.challengeId!.isNotEmpty) {
                context.push('/challenge-detail?id=${p.challengeId}');
              }
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFECE8F5), width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A15083C),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1B132C),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          date,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4.5,
                    ),
                    decoration: BoxDecoration(
                      color: isPlaced
                          ? const Color(0xFFE8F8F0)
                          : const Color(0xFFF6F3FC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      result,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: isPlaced
                            ? const Color(0xFF00C853)
                            : const Color(0xFF8B849C),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    }

    return Column(
      children: MockData.RECENT_PERFORMANCE.map((p) {
        final title = p['title'] as String? ?? 'Challenge';
        final result = p['result'] as String? ?? 'Top 10';
        final date = p['date'] as String? ?? 'Jul 10, 2026';
        final isPlaced = p['score'] != null;

        return GestureDetector(
          onTap: () => context.push('/challenge-detail?id=${p['challengeId']}'),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFECE8F5), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A15083C),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B132C),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        date,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4.5,
                  ),
                  decoration: BoxDecoration(
                    color: isPlaced
                        ? const Color(0xFFE8F8F0)
                        : const Color(0xFFF6F3FC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    result,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: isPlaced
                          ? const Color(0xFF00C853)
                          : const Color(0xFF8B849C),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- 5. Bottom Info Notice Card ---
  Widget _buildInfoNoticeCard({String? note}) {
    final text = note != null && note.isNotEmpty
        ? note
        : 'Winners are decided by Talent Score';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE5FB), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFECE8F5), width: 1),
            ),
            child: const Icon(
              Icons.star_outline_rounded,
              size: 18,
              color: AppColors.purple,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B132C),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Likes and shares improve visibility.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSoft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumberWithCommas(int number) {
    final str = number.toString();
    final result = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        result.write(',');
      }
      result.write(str[i]);
    }
    return result.toString();
  }

  String _formatCompactNumber(num value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1).replaceAll('.0', '')}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1).replaceAll('.0', '')}K';
    }
    return value.toInt().toString();
  }
}
