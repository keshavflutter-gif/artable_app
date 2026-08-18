import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';
import 'package:artable_app/core/widgets/app_back_header.dart';
import 'package:artable_app/core/widgets/app_image.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';
import 'package:artable_app/core/widgets/filter_pills.dart';
import 'package:artable_app/data/datasources/mock_data.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();

  void _goResults([String? q]) {
    final query = (q ?? _controller.text).trim();
    context.push('/search-results?q=${Uri.encodeComponent(query)}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final creators = MockData.CREATORS
        .where((c) => c['isCurrentUser'] != true)
        .take(5)
        .toList();
    final challenges = MockData.CHALLENGES
        .where((c) => c['status'] == 'active')
        .take(3)
        .toList();

    return AppScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppBackHeader(title: 'Search'),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSearchBar(
                    controller: _controller,
                    onSubmitted: _goResults,
                  ),
                  AppContent(
                    noBottomPad: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  DetailSection(
                    title: 'Recent Searches',
                    child: Column(
                      children: MockData.RECENT_SEARCHES.map((q) {
                        return _RecentChip(query: q, onTap: () => _goResults(q));
                      }).toList(),
                    ),
                  ),
                  DetailSection(
                    title: 'Popular',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: MockData.POPULAR_SEARCHES.map((label) {
                        return GestureDetector(
                          onTap: () => _goResults(label),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.inputBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.inputBorder),
                            ),
                            child: Text(label, style: AppTextStyles.body.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  DetailSection(
                    title: 'Suggested Creators',
                    child: SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: creators.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (_, i) {
                          final c = creators[i];
                          return GestureDetector(
                            onTap: () => context.push('/public-profile?id=${c['id']}'),
                            child: SizedBox(
                              width: 88,
                              child: Column(
                                children: [
                                  AppImage(
                                    url: c['avatarUrl'] as String,
                                    width: 64,
                                    height: 64,
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    c['name'] as String,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.body.copyWith(fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  DetailSection(
                    title: 'Suggested Challenges',
                    child: SizedBox(
                      height: 130,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: challenges.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (_, i) {
                          final c = challenges[i];
                          return GestureDetector(
                            onTap: () => context.push('/challenge-detail?id=${c['id']}'),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: SizedBox(
                                width: 180,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    AppImage(url: c['imageUrl'] as String, fit: BoxFit.cover),
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 10,
                                      right: 10,
                                      bottom: 10,
                                      child: Text(
                                        c['title'] as String,
                                        maxLines: 2,
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  DetailSection(
                    title: 'Trending Categories',
                    child: SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: MockData.CATEGORIES.take(6).length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (_, i) {
                          final cat = MockData.CATEGORIES[i];
                          return GestureDetector(
                            onTap: () => _goResults(cat['name'] as String),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: SizedBox(
                                width: 100,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    AppImage(url: cat['imageUrl'] as String, fit: BoxFit.cover),
                                    Container(color: Colors.black38),
                                    Center(
                                      child: Text(
                                        cat['name'] as String,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ],
),
);
}
}

class _RecentChip extends StatelessWidget {
  const _RecentChip({required this.query, required this.onTap});

  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.inputBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.history, size: 16, color: AppColors.textSoft),
            const SizedBox(width: 10),
            Expanded(child: Text(query, style: AppTextStyles.body.copyWith(fontSize: 13))),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textFaint),
          ],
        ),
      ),
    );
  }
}
