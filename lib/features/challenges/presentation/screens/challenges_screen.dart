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
    this.showBackButton = false,
    this.isActive = true,
  });

  final String initialTab;
  final String? categoryFilter;
  final bool showBackButton;

  /// When hosted in [MainTabShell], only true while the Challenges tab is selected.
  final bool isActive;

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  static const _tabKeys = ['ACTIVE', 'UPCOMING', 'COMPLETED', 'FEATURED'];
  static const _tabLabels = ['Active', 'Upcoming', 'Completed', 'Featured'];

  late int _selectedTab;
  var _hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    _selectedTab = _tabKeys.indexWhere(
      (k) => k.toLowerCase() == widget.initialTab.toLowerCase(),
    );
    if (_selectedTab < 0) _selectedTab = 0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.isActive) {
        _bootstrapLoad();
      }
    });
  }

  @override
  void didUpdateWidget(covariant ChallengesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      // Reload if never loaded, or last load failed (empty + error).
      final cubit = context.read<ChallengesCubit>();
      final tabKey = _tabKeys[_selectedTab];
      final hadError = cubit.getTabChallengesError(tabKey) != null;
      if (!_hasLoadedOnce || hadError) {
        _bootstrapLoad();
      }
    }
    if (oldWidget.categoryFilter != widget.categoryFilter &&
        widget.categoryFilter != null &&
        widget.categoryFilter!.isNotEmpty &&
        widget.isActive) {
      context
          .read<ChallengesCubit>()
          .loadChallengesByCategory(widget.categoryFilter!);
    }
  }

  void _bootstrapLoad() {
    _hasLoadedOnce = true;
    if (widget.categoryFilter != null && widget.categoryFilter!.isNotEmpty) {
      context
          .read<ChallengesCubit>()
          .loadChallengesByCategory(widget.categoryFilter!);
    } else {
      _loadCurrentTab();
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
            showBackButton: widget.showBackButton,
            onBack: () => context.go(AppRoutes.home),
          ),
          SearchBarWidget(
            placeholder: 'Search challenges...',
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
                    else if (challenges.isEmpty) ...[
                      Builder(
                        builder: (context) {
                          final tabError =
                              provider.getTabChallengesError(currentTab);
                          final catError = hasCategory
                              ? provider.getCategoryChallengesError(
                                  widget.categoryFilter!,
                                )
                              : null;
                          final err = (tabError ?? catError)?.trim();
                          final hasError = err != null && err.isNotEmpty;
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 40,
                              horizontal: 20,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  hasError
                                      ? err
                                      : 'No challenges in this category yet — check back soon.',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.body(
                                    fontSize: 13.5,
                                    color: AppColors.textSoft,
                                  ),
                                ),
                                if (hasError) ...[
                                  const SizedBox(height: 12),
                                  TextButton(
                                    onPressed: () {
                                      if (hasCategory) {
                                        context
                                            .read<ChallengesCubit>()
                                            .loadChallengesByCategory(
                                              widget.categoryFilter!,
                                            );
                                      } else {
                                        _loadCurrentTab(forceRefresh: true);
                                      }
                                    },
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ] else
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
