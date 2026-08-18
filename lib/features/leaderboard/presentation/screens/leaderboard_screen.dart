import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';
import 'package:artable_app/core/utils/mock_helpers.dart';
import 'package:artable_app/core/widgets/app_back_header.dart';
import 'package:artable_app/core/widgets/app_image.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:artable_app/features/leaderboard/presentation/bloc/leaderboard_cubit.dart';
import 'package:artable_app/features/leaderboard/data/models/leaderboard_response.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key, this.challengeId});

  final String? challengeId;

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<LeaderboardCubit>();
        if (widget.challengeId != null && widget.challengeId!.isNotEmpty) {
          provider.setChallengeId(widget.challengeId);
        } else {
          provider.loadLeaderboard();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final leaderboard = context.watch<LeaderboardCubit>();
    final auth = context.watch<AuthCubit>();
    final isLoading = leaderboard.isLoading && !leaderboard.hasLoaded;

    final podiumList = leaderboard.podium;
    final rankingsList = leaderboard.rankings;
    final fallbackTop3 = leaderboard.top3PodiumAsUiMaps;
    final fallbackRest = leaderboard.restRankingsAsUiMaps;

    final yourRankItem = leaderboard.yourRank;
    final currentUserId = auth.currentUser['id']?.toString() ?? auth.userId;

    return AppScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppBackHeader(title: 'Leaderboard'),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.purple,
              onRefresh: () => leaderboard.loadLeaderboard(forceRefresh: true),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // Period Tabs (Global, Challenge, Weekly, Monthly)
                    _buildPeriodTabs(leaderboard),

                    const SizedBox(height: 12),

                    // Category Filter Chips
                    _buildCategoryChips(leaderboard),

                    const SizedBox(height: 24),

                    if (isLoading)
                      const _LeaderboardSkeleton()
                    else ...[
                      // Top 3 Podium
                      if (podiumList.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildApiPodium(podiumList),
                        )
                      else if (fallbackTop3.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildFallbackPodium(fallbackTop3),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 32,
                          ),
                          child: Center(
                            child: Text(
                              'No creators found for this filter.',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: AppColors.textSoft,
                              ),
                            ),
                          ),
                        ),

                      // YOUR RANK Card
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: _buildYourRankCard(
                          yourRankItem: yourRankItem,
                          auth: auth,
                          fallbackRankings: leaderboard.fallbackRankedCreators,
                        ),
                      ),

                      // Full Rankings Section Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                        child: Text(
                          'Full Rankings',
                          style: AppTextStyles.displayBold.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Ranked List
                      if (rankingsList.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              for (var i = 0; i < rankingsList.length; i++)
                                _buildApiRankRow(
                                  item: rankingsList[i],
                                  rank: rankingsList[i].rank > 0
                                      ? rankingsList[i].rank
                                      : i + 1,
                                  isCurrentUser:
                                      currentUserId != null &&
                                      rankingsList[i].user?.id == currentUserId,
                                ),
                            ],
                          ),
                        )
                      else if (fallbackRest.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              for (var i = 0; i < fallbackRest.length; i++)
                                _buildFallbackRankRow(
                                  user: fallbackRest[i],
                                  rank: i + 4,
                                  isCurrentUser:
                                      fallbackRest[i]['id'] == currentUserId,
                                ),
                            ],
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
                          child: Center(
                            child: Text(
                              'No more creators in this ranking.',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: AppColors.textSoft,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 36),
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

  Widget _buildPeriodTabs(LeaderboardCubit provider) {
    final tabs = provider.availableTabs;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: tabs.map((tab) {
          final active =
              tab.toLowerCase() == provider.selectedTab.toLowerCase();
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => provider.selectTab(tab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: active
                      ? const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0xFFFF5E5E), Color(0xFFB330FF)],
                        )
                      : null,
                  color: active ? null : Colors.white,
                  border: active
                      ? null
                      : Border.all(color: const Color(0xFFECE8F5), width: 1.2),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFFFF5E5E,
                            ).withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  tab,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                    color: active ? Colors.white : const Color(0xFF8B849C),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryChips(LeaderboardCubit provider) {
    final categories = provider.availableCategoryNames;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: categories.map((cat) {
          final active =
              cat.toLowerCase() == provider.selectedCategory.toLowerCase();
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => provider.selectCategory(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: active
                      ? const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0xFFFF5E5E), Color(0xFFB330FF)],
                        )
                      : null,
                  color: active ? null : const Color(0xFFFAFAFD),
                  border: active
                      ? null
                      : Border.all(color: const Color(0xFFECE8F5), width: 1.2),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFFFF5E5E,
                            ).withValues(alpha: 0.22),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                    color: active ? Colors.white : const Color(0xFF8B849C),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildApiPodium(List<LeaderboardRankItem> top3) {
    final rank1 = top3.firstWhere((p) => p.rank == 1, orElse: () => top3.first);
    final rank2 = top3.length > 1
        ? top3.firstWhere((p) => p.rank == 2, orElse: () => top3[1])
        : null;
    final rank3 = top3.length > 2
        ? top3.firstWhere((p) => p.rank == 3, orElse: () => top3[2])
        : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Rank 2 (Left)
        if (rank2 != null)
          Expanded(
            child: _ApiPodiumCard(
              item: rank2,
              rank: 2,
              badgeGradient: const LinearGradient(
                colors: [Color(0xFFFF3D77), Color(0xFF8B3DFF)],
              ),
            ),
          )
        else
          const Expanded(child: SizedBox()),

        const SizedBox(width: 10),

        // Rank 1 (Center - Prominent)
        Expanded(
          child: _ApiPodiumCard(
            item: rank1,
            rank: 1,
            isFirst: true,
            badgeGradient: const LinearGradient(
              colors: [Color(0xFFFFD65C), Color(0xFFFF9500)],
            ),
          ),
        ),

        const SizedBox(width: 10),

        // Rank 3 (Right)
        if (rank3 != null)
          Expanded(
            child: _ApiPodiumCard(
              item: rank3,
              rank: 3,
              badgeGradient: const LinearGradient(
                colors: [Color(0xFFFF7A45), Color(0xFFFF3D77)],
              ),
            ),
          )
        else
          const Expanded(child: SizedBox()),
      ],
    );
  }

  Widget _buildFallbackPodium(List<Map<String, dynamic>> top3) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (top3.length > 1)
          Expanded(
            child: _FallbackPodiumCard(
              user: top3[1],
              rank: 2,
              badgeGradient: const LinearGradient(
                colors: [Color(0xFFFF3D77), Color(0xFF8B3DFF)],
              ),
            ),
          )
        else
          const Expanded(child: SizedBox()),

        const SizedBox(width: 10),

        if (top3.isNotEmpty)
          Expanded(
            child: _FallbackPodiumCard(
              user: top3[0],
              rank: 1,
              isFirst: true,
              badgeGradient: const LinearGradient(
                colors: [Color(0xFFFFD65C), Color(0xFFFF9500)],
              ),
            ),
          )
        else
          const Expanded(child: SizedBox()),

        const SizedBox(width: 10),

        if (top3.length > 2)
          Expanded(
            child: _FallbackPodiumCard(
              user: top3[2],
              rank: 3,
              badgeGradient: const LinearGradient(
                colors: [Color(0xFFFF7A45), Color(0xFFFF3D77)],
              ),
            ),
          )
        else
          const Expanded(child: SizedBox()),
      ],
    );
  }

  Widget _buildYourRankCard({
    required LeaderboardRankItem? yourRankItem,
    required AuthCubit auth,
    required List<Map<String, dynamic>> fallbackRankings,
  }) {
    final you = MockHelpers.currentUser;
    final int rank;
    final String name;
    final String avatarUrl;
    final String category;
    final String score;

    if (yourRankItem != null) {
      rank = yourRankItem.rank;
      name = yourRankItem.displayName;
      avatarUrl = yourRankItem.displayAvatar;
      category = yourRankItem.displayCategory;
      score = yourRankItem.displayScore;
    } else {
      final user = auth.currentUser;
      final rawName = auth.fullName.isNotEmpty
          ? auth.fullName
          : (user['name']?.toString() ?? you['name'] as String);
      name = rawName.isNotEmpty ? rawName : (you['name'] as String);
      final rawAvatar =
          user['avatarUrl']?.toString() ??
          user['profilePhotoUrl']?.toString() ??
          (you['avatarUrl'] as String);
      avatarUrl = rawAvatar.isNotEmpty
          ? rawAvatar
          : (you['avatarUrl'] as String);
      final rawCat =
          user['talentCategory']?.toString() ??
          user['category']?.toString() ??
          (you['category'] as String);
      category = rawCat.isNotEmpty ? rawCat : (you['category'] as String);
      score = (you['talentScore'] as num).toStringAsFixed(1);
      final userId = user['id']?.toString() ?? auth.userId;
      final index = fallbackRankings.indexWhere((u) => u['id'] == userId);
      rank = index >= 0 ? index + 1 : 12;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFAF6FF), Color(0xFFFFF7FA)],
        ),
        border: Border.all(
          color: const Color(0xFF8B3DFF).withValues(alpha: 0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B3DFF).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR RANK',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF8B3DFF),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '#$rank',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                  height: 1,
                ),
              ),
              const SizedBox(width: 14),
              AppImage(
                url: avatarUrl,
                width: 44,
                height: 44,
                borderRadius: BorderRadius.circular(22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      category,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSoft,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5E2EAA).withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: Color(0xFFFFB800),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      score,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApiRankRow({
    required LeaderboardRankItem item,
    required int rank,
    required bool isCurrentUser,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isCurrentUser) {
              context.push('/my-profile');
            } else if (item.user?.id != null && item.user!.id.isNotEmpty) {
              context.push('/public-profile?id=${item.user!.id}');
            }
          },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: isCurrentUser
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFAF7FF), Color(0xFFFFF9FB)],
                    )
                  : null,
              color: isCurrentUser ? null : Colors.white,
              border: Border.all(
                color: isCurrentUser
                    ? const Color(0xFF8B3DFF).withValues(alpha: 0.35)
                    : const Color(0xFF5E2EAA).withValues(alpha: 0.06),
                width: isCurrentUser ? 1.5 : 1,
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
              children: [
                // Rank number
                SizedBox(
                  width: 24,
                  child: Text(
                    '$rank',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSoft,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Avatar
                AppImage(
                  url: item.displayAvatar,
                  width: 42,
                  height: 42,
                  borderRadius: BorderRadius.circular(21),
                ),
                const SizedBox(width: 12),

                // User details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.displayName,
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
                          if (item.isVerifiedUser) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 14,
                              color: Color(0xFF2E90FA),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.displayCategory} · ${item.displayVotes}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSoft,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Rating pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F7FC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 13,
                        color: Color(0xFFFFB800),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        item.displayScore,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackRankRow({
    required Map<String, dynamic> user,
    required int rank,
    required bool isCurrentUser,
  }) {
    final votes = user['votes']?.toString() ?? '0';
    final isVerified = user['verified'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isCurrentUser) {
              context.push('/my-profile');
            } else {
              context.push('/public-profile?id=${user['id']}');
            }
          },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: isCurrentUser
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFAF7FF), Color(0xFFFFF9FB)],
                    )
                  : null,
              color: isCurrentUser ? null : Colors.white,
              border: Border.all(
                color: isCurrentUser
                    ? const Color(0xFF8B3DFF).withValues(alpha: 0.35)
                    : const Color(0xFF5E2EAA).withValues(alpha: 0.06),
                width: isCurrentUser ? 1.5 : 1,
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
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '$rank',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSoft,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                AppImage(
                  url: user['avatarUrl'] as String,
                  width: 42,
                  height: 42,
                  borderRadius: BorderRadius.circular(21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user['name'] as String,
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
                          if (isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 14,
                              color: Color(0xFF2E90FA),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${user['category']} · $votes votes',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSoft,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F7FC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 13,
                        color: Color(0xFFFFB800),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        (user['talentScore'] as num).toStringAsFixed(1),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ApiPodiumCard extends StatelessWidget {
  const _ApiPodiumCard({
    required this.item,
    required this.rank,
    required this.badgeGradient,
    this.isFirst = false,
  });

  final LeaderboardRankItem item;
  final int rank;
  final Gradient badgeGradient;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final avatarSize = isFirst ? 64.0 : 54.0;
    final badgeSize = isFirst ? 22.0 : 20.0;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        GestureDetector(
          onTap: () {
            if (item.user?.id != null && item.user!.id.isNotEmpty) {
              context.push('/public-profile?id=${item.user!.id}');
            }
          },
          child: Container(
            padding: EdgeInsets.fromLTRB(
              8,
              isFirst ? 22 : 16,
              8,
              isFirst ? 16 : 14,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isFirst ? 24 : 20),
              gradient: isFirst
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFFF9EC), Color(0xFFFFEFC7)],
                    )
                  : const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white, Color(0xFFFAF7FF)],
                    ),
              border: Border.all(
                color: isFirst
                    ? const Color(0xFFFFD566).withValues(alpha: 0.6)
                    : const Color(0xFF8B3DFF).withValues(alpha: 0.12),
                width: isFirst ? 1.5 : 1.2,
              ),
              boxShadow: [
                if (isFirst)
                  BoxShadow(
                    color: const Color(0xFFFFB800).withValues(alpha: 0.24),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  )
                else
                  BoxShadow(
                    color: const Color(0xFF5E2EAA).withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: avatarSize,
                  height: avatarSize + 6,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: isFirst ? 3 : 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF15083C,
                              ).withValues(alpha: 0.16),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: AppImage(
                          url: item.displayAvatar,
                          width: avatarSize,
                          height: avatarSize,
                          borderRadius: BorderRadius.circular(avatarSize / 2),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        child: Container(
                          width: badgeSize,
                          height: badgeSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: badgeGradient,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF5E2EAA,
                                ).withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$rank',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: isFirst ? 11 : 10.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.displayName,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: isFirst ? 13 : 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: isFirst ? 14 : 13,
                      color: const Color(0xFFFFB800),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      item.displayScore,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isFirst ? 12 : 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (isFirst) const Positioned(top: -12, child: _CrownWidget()),
      ],
    );
  }
}

class _FallbackPodiumCard extends StatelessWidget {
  const _FallbackPodiumCard({
    required this.user,
    required this.rank,
    required this.badgeGradient,
    this.isFirst = false,
  });

  final Map<String, dynamic> user;
  final int rank;
  final Gradient badgeGradient;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final avatarSize = isFirst ? 64.0 : 54.0;
    final badgeSize = isFirst ? 22.0 : 20.0;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        GestureDetector(
          onTap: () => context.push('/public-profile?id=${user['id']}'),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              8,
              isFirst ? 22 : 16,
              8,
              isFirst ? 16 : 14,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isFirst ? 24 : 20),
              gradient: isFirst
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFFF9EC), Color(0xFFFFEFC7)],
                    )
                  : const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white, Color(0xFFFAF7FF)],
                    ),
              border: Border.all(
                color: isFirst
                    ? const Color(0xFFFFD566).withValues(alpha: 0.6)
                    : const Color(0xFF8B3DFF).withValues(alpha: 0.12),
                width: isFirst ? 1.5 : 1.2,
              ),
              boxShadow: [
                if (isFirst)
                  BoxShadow(
                    color: const Color(0xFFFFB800).withValues(alpha: 0.24),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  )
                else
                  BoxShadow(
                    color: const Color(0xFF5E2EAA).withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: avatarSize,
                  height: avatarSize + 6,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: isFirst ? 3 : 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF15083C,
                              ).withValues(alpha: 0.16),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: AppImage(
                          url: user['avatarUrl'] as String,
                          width: avatarSize,
                          height: avatarSize,
                          borderRadius: BorderRadius.circular(avatarSize / 2),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        child: Container(
                          width: badgeSize,
                          height: badgeSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: badgeGradient,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF5E2EAA,
                                ).withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$rank',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: isFirst ? 11 : 10.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user['name'] as String,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: isFirst ? 13 : 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: isFirst ? 14 : 13,
                      color: const Color(0xFFFFB800),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      (user['talentScore'] as num).toStringAsFixed(1),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isFirst ? 12 : 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (isFirst) const Positioned(top: -12, child: _CrownWidget()),
      ],
    );
  }
}

class _CrownWidget extends StatelessWidget {
  const _CrownWidget();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26,
      height: 18,
      child: CustomPaint(painter: _CrownPainter()),
    );
  }
}

class _CrownPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFD65C), Color(0xFFFF9500)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = const Color(0xFFFFB800).withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final path = Path()
      ..moveTo(0, size.height * 0.35)
      ..lineTo(size.width * 0.24, size.height * 0.65)
      ..lineTo(size.width * 0.5, 0)
      ..lineTo(size.width * 0.76, size.height * 0.65)
      ..lineTo(size.width, size.height * 0.35)
      ..lineTo(size.width * 0.88, size.height)
      ..lineTo(size.width * 0.12, size.height)
      ..close();

    canvas.drawPath(path.shift(const Offset(0, 2)), shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LeaderboardSkeleton extends StatelessWidget {
  const _LeaderboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0EDF7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 145,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0EDF7),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 110,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0EDF7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFF0EDF7),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < 4; i++) ...[
            Container(
              height: 60,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EDF7),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
