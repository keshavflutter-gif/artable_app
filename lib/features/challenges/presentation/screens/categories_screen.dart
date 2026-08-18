import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_typography.dart';
import 'package:artable_app/features/challenges/presentation/bloc/challenges_cubit.dart';
import 'package:artable_app/features/shell/presentation/widgets/app_shell.dart';
import 'package:artable_app/features/challenges/presentation/widgets/category_card.dart';
import 'package:artable_app/core/widgets/search_bar_widget.dart';
import 'package:artable_app/core/widgets/section_header.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ChallengesCubit>().loadCategories();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChallengesCubit>();
    final categories = provider.filteredCategories;
    final summary = provider.categorySummary;
    final isLoading =
        provider.isLoadingCategories && !provider.hasLoadedCategories;

    return AppShell(
      currentPath: '/categories',
      body: Column(
        children: [
          AppPageHeader(
            title: 'Challenge Categories',
            onBack: () => context.go('/home'),
          ),
          SearchBarWidget(
            placeholder: 'Search categories...',
            onChanged: (value) =>
                context.read<ChallengesCubit>().setCategoryQuery(value),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => context
                  .read<ChallengesCubit>()
                  .loadCategories(forceRefresh: true),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _CategoryHero(
                      count: summary?.totalCategories ?? categories.length,
                      activeChallenges: summary != null
                          ? '${summary.activeChallenges}'
                          : '${categories.fold<int>(0, (sum, c) => sum + ((c['count'] as int?) ?? 0))}',
                      updatedFrequency: summary?.updatedFrequency ?? 'Daily',
                    ),
                    SectionHeader(title: 'All Categories', marginTop: 0),
                    Text(
                      'Browse by Talent Type',
                      style: AppTypography.body(
                        fontSize: 12.5,
                        color: AppColors.textSoft,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (categories.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.category_outlined,
                              size: 48,
                              color: AppColors.textSoft.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No categories found',
                              style: AppTypography.body(
                                fontSize: 14,
                                color: AppColors.textSoft,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 1.05,
                        ),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          return CategoryCard(
                            category: categories[index],
                            gridMode: true,
                          );
                        },
                      ),
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

class _CategoryHero extends StatelessWidget {
  const _CategoryHero({
    required this.count,
    required this.activeChallenges,
    required this.updatedFrequency,
  });

  final int count;
  final String activeChallenges;
  final String updatedFrequency;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 16, 0, 20),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.orange.withValues(alpha: 0.11),
            AppColors.pink.withValues(alpha: 0.08),
            AppColors.purple.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.14)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x245E2EAA),
            blurRadius: 40,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -50,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.pink.withValues(alpha: 0.20),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.72],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Explore Talent Challenges',
                style: AppTypography.display(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Find competitions by category and discover trending talent spaces.',
                style: AppTypography.body(
                  fontSize: 12.5,
                  color: AppColors.textSoft,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatChip(
                      icon: Icons.grid_view_rounded,
                      value: '$count',
                      label: 'Categories',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatChip(
                      icon: Icons.local_fire_department_outlined,
                      value: activeChallenges,
                      label: 'Active',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatChip(
                      icon: Icons.calendar_today_outlined,
                      value: updatedFrequency,
                      label: 'Updated',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x125E2EAA),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 15, color: AppColors.purple),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.display(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: AppColors.purple,
              height: 1.15,
            ),
          ),
          Text(
            label,
            style: AppTypography.body(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSoft,
            ),
          ),
        ],
      ),
    );
  }
}
