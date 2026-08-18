import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_typography.dart';
import 'package:artable_app/features/challenges/presentation/bloc/challenges_cubit.dart';
import 'package:artable_app/app/routes/app_routes.dart';
import 'package:artable_app/features/shell/presentation/widgets/app_shell.dart';
import 'package:artable_app/features/shell/presentation/widgets/bottom_nav.dart';
import 'package:artable_app/features/challenges/presentation/widgets/challenge_card.dart';
import 'package:artable_app/core/widgets/search_bar_widget.dart';
import 'package:artable_app/core/widgets/tab_row.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({
    super.key,
    this.initialTab = 'active',
    this.categoryFilter,
  });

  final String initialTab;
  final String? categoryFilter;

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  static const _tabKeys = ['ACTIVE', 'UPCOMING', 'COMPLETED', 'FEATURED'];
  static const _tabLabels = ['Active', 'Upcoming', 'Completed', 'Featured'];

  late int _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = _tabKeys.indexWhere(
      (k) => k.toLowerCase() == widget.initialTab.toLowerCase(),
    );
    if (_selectedTab < 0) _selectedTab = 0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (widget.categoryFilter != null &&
            widget.categoryFilter!.isNotEmpty) {
          context
              .read<ChallengesCubit>()
              .loadChallengesByCategory(widget.categoryFilter!);
        } else {
          _loadCurrentTab();
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant ChallengesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryFilter != widget.categoryFilter &&
        widget.categoryFilter != null &&
        widget.categoryFilter!.isNotEmpty) {
      context
          .read<ChallengesCubit>()
          .loadChallengesByCategory(widget.categoryFilter!);
    }
  }

  void _loadCurrentTab({bool forceRefresh = false}) {
    final tabKey = _tabKeys[_selectedTab];
    context.read<ChallengesCubit>().loadTabChallenges(
          tabKey,
          forceRefresh: forceRefresh,
        );
  }

  void _onTabSelected(int index) {
    setState(() => _selectedTab = index);
    final tabKey = _tabKeys[index];
    context.read<ChallengesCubit>().loadTabChallenges(tabKey);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChallengesCubit>();
    final currentTab = _tabKeys[_selectedTab];
    final hasCategory =
        widget.categoryFilter != null && widget.categoryFilter!.isNotEmpty;
    final challenges = hasCategory
        ? provider.getChallengesForCategory(
            widget.categoryFilter!,
            query: provider.challengeQuery,
          )
        : provider.getChallengesForTab(
            currentTab,
            categoryId: widget.categoryFilter,
            query: provider.challengeQuery,
          );
    final isLoading = hasCategory
        ? (provider.isLoadingCategoryChallenges(widget.categoryFilter!) &&
            !provider.hasLoadedCategoryChallenges(widget.categoryFilter!))
        : (provider.isLoadingTabChallenges(currentTab) &&
            !provider.hasLoadedTabChallenges(currentTab));

    return AppShell(
      currentPath: AppRoutes.challenges,
      bottomNavVariant: BottomNavVariant.home,
      body: Column(
        children: [
          AppPageHeader(
            title: 'Challenges',
            onBack: () => context.go(AppRoutes.home),
          ),
          SearchBarWidget(
            placeholder: 'Search challenges...',
            showFilter: true,
            onChanged: (value) => context
                .read<ChallengesCubit>()
                .setChallengeQuery(
                  value,
                  tab: _tabKeys[_selectedTab],
                  categoryId: widget.categoryFilter,
                ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                if (hasCategory) {
                  await context
                      .read<ChallengesCubit>()
                      .loadChallengesByCategory(
                        widget.categoryFilter!,
                        forceRefresh: true,
                      );
                } else {
                  _loadCurrentTab(forceRefresh: true);
                }
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    if (!hasCategory) ...[
                      TabRow(
                        tabs: _tabLabels,
                        selectedIndex: _selectedTab,
                        onTabSelected: _onTabSelected,
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (challenges.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 40, horizontal: 20),
                        child: Text(
                          'No challenges in this category yet — check back soon.',
                          textAlign: TextAlign.center,
                          style: AppTypography.body(
                            fontSize: 13.5,
                            color: AppColors.textSoft,
                          ),
                        ),
                      )
                    else
                      ...challenges.asMap().entries.map((entry) {
                        final index = entry.key;
                        final challenge = entry.value;
                        return Padding(
                          padding: EdgeInsets.only(
                              bottom: index < challenges.length - 1 ? 14 : 0),
                          child: ChallengeCard(challenge: challenge),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
