import 'dart:async';

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
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _selectedTab = _indexForTab(widget.initialTab);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.isActive) {
        _bootstrapLoad();
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  int _indexForTab(String tab) {
    final idx = _tabKeys.indexWhere(
      (k) => k.toLowerCase() == tab.trim().toLowerCase(),
    );
    return idx < 0 ? 0 : idx;
  }

  bool get _hasCategory =>
      widget.categoryFilter != null && widget.categoryFilter!.trim().isNotEmpty;

  @override
  void didUpdateWidget(covariant ChallengesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    final tabChanged =
        oldWidget.initialTab.trim().toLowerCase() !=
        widget.initialTab.trim().toLowerCase();
    final categoryChanged =
        (oldWidget.categoryFilter ?? '').trim() !=
        (widget.categoryFilter ?? '').trim();
    final becameActive = widget.isActive && !oldWidget.isActive;

    if (tabChanged && !_hasCategory) {
      final next = _indexForTab(widget.initialTab);
      if (next != _selectedTab) {
        setState(() => _selectedTab = next);
      }
      if (widget.isActive) {
        _loadCurrentTab(forceRefresh: true);
      }
    }

    if (categoryChanged && widget.isActive) {
      if (_hasCategory) {
        context
            .read<ChallengesCubit>()
            .loadChallengesByCategory(widget.categoryFilter!.trim());
      } else {
        // Category cleared (e.g. /challenges?categoryId=x → /challenges).
        _loadCurrentTab(forceRefresh: true);
      }
    }

    if (becameActive) {
      final cubit = context.read<ChallengesCubit>();
      final tabKey = _tabKeys[_selectedTab];
      final hadError = _hasCategory
          ? cubit.getCategoryChallengesError(widget.categoryFilter!) != null
          : cubit.getTabChallengesError(tabKey) != null;
      // First open or failed load — don't spam API on every tab switch.
      // Join state is patched in ChallengesCubit; pull-to-refresh for full reload.
      if (!_hasLoadedOnce || hadError) {
        _bootstrapLoad();
      }
    }
  }

  void _bootstrapLoad({bool forceRefresh = false}) {
    _hasLoadedOnce = true;
    if (_hasCategory) {
      context.read<ChallengesCubit>().loadChallengesByCategory(
            widget.categoryFilter!.trim(),
            forceRefresh: forceRefresh,
          );
    } else {
      _loadCurrentTab(forceRefresh: forceRefresh);
    }
  }

  Future<void> _loadCurrentTab({bool forceRefresh = false}) {
    final tabKey = _tabKeys[_selectedTab];
    return context.read<ChallengesCubit>().loadTabChallenges(
          tabKey,
          forceRefresh: forceRefresh,
        );
  }

  void _onTabSelected(int index) {
    setState(() => _selectedTab = index);
    context.read<ChallengesCubit>().loadTabChallenges(_tabKeys[index]);
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      context.read<ChallengesCubit>().setChallengeQuery(
            value,
            tab: _tabKeys[_selectedTab],
            categoryId: widget.categoryFilter,
          );
    });
  }

  String _emptyCopy({required bool hasError, required String? err}) {
    if (hasError) return err ?? 'Something went wrong.';
    if (_hasCategory) {
      return 'No challenges in this category yet — check back soon.';
    }
    switch (_tabKeys[_selectedTab]) {
      case 'UPCOMING':
        return 'No upcoming challenges yet — check back soon.';
      case 'COMPLETED':
        return 'No completed challenges to show.';
      case 'FEATURED':
        return 'No featured challenges right now.';
      default:
        return 'No active challenges right now — check back soon.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChallengesCubit>();
    final currentTab = _tabKeys[_selectedTab];
    final hasCategory = _hasCategory;
    final challenges = hasCategory
        ? provider.getChallengesForCategory(
            widget.categoryFilter!,
            query: provider.challengeQuery,
          )
        : provider.getChallengesForTab(
            currentTab,
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
            onChanged: _onSearchChanged,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                if (hasCategory) {
                  await context.read<ChallengesCubit>().loadChallengesByCategory(
                        widget.categoryFilter!,
                        forceRefresh: true,
                      );
                } else {
                  await _loadCurrentTab(forceRefresh: true);
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
                                  _emptyCopy(hasError: hasError, err: err),
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
                                        unawaited(
                                          _loadCurrentTab(forceRefresh: true),
                                        );
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
                            bottom: index < challenges.length - 1 ? 14 : 0,
                          ),
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
