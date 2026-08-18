import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/core/widgets/app_back_header.dart';
import 'package:artable_app/core/widgets/app_image.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';
import 'package:artable_app/features/profile/presentation/widgets/profile_reward_widgets.dart';
import 'package:artable_app/features/rewards/presentation/bloc/rewards_cubit.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<RewardsCubit>().loadRewards();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final rewardsProvider = context.watch<RewardsCubit>();
    final featured = rewardsProvider.featuredRewardAsUiMap;
    final list = rewardsProvider.rewardsAsUiMaps;
    final tabs = rewardsProvider.availableTabs;
    final isLoading =
        rewardsProvider.isLoading && !rewardsProvider.hasLoaded;

    return AppScreen(
      child: Column(
        children: [
          // Top App Back Header
          AppBackHeader(
            title: 'Rewards',
            trailing: AppIconButton(
              icon: Icons.account_balance_wallet_outlined,
              onTap: () => context.push('/wallet'),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.purple,
              onRefresh: () =>
                  rewardsProvider.loadRewards(forceRefresh: true),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: AppContent(
                  noBottomPad: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),

                      // Balance Card
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 18, horizontal: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF2E1C60),
                              Color(0xFF6B28D0),
                              Color(0xFFE2387B),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6B28D0)
                                  .withValues(alpha: 0.22),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _BalanceCol(
                                value: rewardsProvider.availableBalanceFormatted,
                                label: 'AVAILABLE REWARDS',
                              ),
                            ),
                            Container(
                                width: 1, height: 36, color: Colors.white38),
                            Expanded(
                              child: _BalanceCol(
                                value: rewardsProvider.totalEarnedFormatted,
                                label: 'TOTAL EARNED',
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Horizontal Filter Tabs
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: tabs.map((tab) {
                            final selected = tab.toLowerCase() ==
                                rewardsProvider.selectedTab.toLowerCase();
                            return _TabChip(
                              label: tab,
                              selected: selected,
                              onTap: () => rewardsProvider.selectTab(tab),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      if (isLoading)
                        const _RewardsSkeleton()
                      else ...[
                        // Featured Reward Banner
                        if (featured != null &&
                            featured.isNotEmpty &&
                            featured['id'] != null)
                          GestureDetector(
                            onTap: () => context
                                .push('/reward-detail?id=${featured['id']}'),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: SizedBox(
                                height: 155,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    AppImage(
                                      url: featured['imageUrl'] as String? ??
                                          'https://images.unsplash.com/photo-1518834107812-67b0b7c58434?w=800&q=80',
                                      fit: BoxFit.cover,
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.black
                                                .withValues(alpha: 0.15),
                                            Colors.black
                                                .withValues(alpha: 0.75),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 12,
                                      left: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 9, vertical: 3.5),
                                        decoration: BoxDecoration(
                                          color: Colors.black
                                              .withValues(alpha: 0.45),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Icon(
                                              Icons.star_rounded,
                                              size: 11,
                                              color: Color(0xFFFFC93D),
                                            ),
                                            SizedBox(width: 3),
                                            Text(
                                              'FEATURED REWARD',
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                color: Colors.white,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 8.5,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 14,
                                      bottom: 14,
                                      right: 14,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            featured['title'] as String? ??
                                                'Win premium prizes from active challenges',
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                              height: 1.2,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets
                                                .symmetric(
                                                horizontal: 11, vertical: 4.5),
                                            decoration: BoxDecoration(
                                              color: Colors.white
                                                  .withValues(alpha: 0.22),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: Colors.white
                                                    .withValues(alpha: 0.35),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
                                                Text(
                                                  'View Rewards',
                                                  style: TextStyle(
                                                    fontFamily: 'Inter',
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.w800,
                                                    fontSize: 10.5,
                                                  ),
                                                ),
                                                SizedBox(width: 3),
                                                Icon(
                                                  Icons
                                                      .chevron_right_rounded,
                                                  size: 13,
                                                  color: Colors.white,
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
                            ),
                          ),

                        const SizedBox(height: 20),

                        // Section Header: All Rewards
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'All Rewards',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text,
                              ),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  context.push('/transaction-history'),
                              child: const Text(
                                'History',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.purple,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Grid of Rewards
                        if (list.isNotEmpty)
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 0.60,
                            ),
                            itemCount: list.length,
                            itemBuilder: (context, index) =>
                                RewardCard(reward: list[index]),
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: Text(
                                'No rewards available for this category.',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  color: AppColors.textSoft,
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 24),
                      ],
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
}

class _BalanceCol extends StatelessWidget {
  const _BalanceCol({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: Colors.white70,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: selected ? AppGradients.button : null,
            color: selected ? null : Colors.white,
            border: selected
                ? null
                : Border.all(
                    color: const Color(0x145E2EAA),
                    width: 1,
                  ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? const Color(0xFF8B3DFF).withValues(alpha: 0.20)
                    : const Color(0x0A15083C),
                blurRadius: selected ? 10 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: selected ? Colors.white : AppColors.textSoft,
            ),
          ),
        ),
      ),
    );
  }
}

class _RewardsSkeleton extends StatelessWidget {
  const _RewardsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 155,
          decoration: BoxDecoration(
            color: const Color(0xFFF0EDF7),
            borderRadius: BorderRadius.circular(20),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 120,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFFF0EDF7),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            Container(
              width: 60,
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
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.60,
          ),
          itemCount: 4,
          itemBuilder: (context, index) => Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF0EDF7),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ],
    );
  }
}
