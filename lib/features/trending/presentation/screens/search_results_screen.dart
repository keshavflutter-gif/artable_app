import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';
import 'package:artable_app/core/widgets/app_back_header.dart';
import 'package:artable_app/core/widgets/app_image.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';
import 'package:artable_app/data/datasources/mock_data.dart';

class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({
    super.key,
    required this.query,
  });

  final String query;

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _controller.text.toLowerCase().trim();

    final matchingVideos = MockData.REELS.where((v) {
      final title = (v['title'] as String? ?? '').toLowerCase();
      final creator = (v['creatorName'] as String? ?? '').toLowerCase();
      final tag = (v['tag'] as String? ?? '').toLowerCase();
      return q.isEmpty ||
          title.contains(q) ||
          creator.contains(q) ||
          tag.contains(q);
    }).toList();

    final matchingCreators = MockData.CREATORS.where((c) {
      final name = (c['name'] as String? ?? '').toLowerCase();
      final handle = (c['handle'] as String? ?? '').toLowerCase();
      final bio = (c['bio'] as String? ?? '').toLowerCase();
      return q.isEmpty ||
          name.contains(q) ||
          handle.contains(q) ||
          bio.contains(q);
    }).toList();

    final matchingChallenges = MockData.CHALLENGES.where((c) {
      final title = (c['title'] as String? ?? '').toLowerCase();
      final cat = (c['category'] as String? ?? '').toLowerCase();
      return q.isEmpty || title.contains(q) || cat.contains(q);
    }).toList();

    return AppScreen(
      child: Column(
        children: [
          AppBackHeader(
            title: widget.query.isNotEmpty ? widget.query : 'Search Results',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.inputBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: TextField(
                controller: _controller,
                onSubmitted: (val) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search artworks, creators, challenges...',
                  hintStyle: AppTextStyles.body.copyWith(
                    color: AppColors.textFaint,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textSoft,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          TabBar(
            controller: _tabController,
            isScrollable: false,
            indicatorColor: AppColors.purple,
            labelColor: AppColors.purple,
            unselectedLabelColor: AppColors.textSoft,
            labelStyle: AppTextStyles.displaySemiBold14,
            tabs: const [
              Tab(text: 'Top'),
              Tab(text: 'Videos'),
              Tab(text: 'Creators'),
              Tab(text: 'Challenges'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTopTab(
                  matchingVideos,
                  matchingCreators,
                  matchingChallenges,
                ),
                _buildVideosTab(matchingVideos),
                _buildCreatorsTab(matchingCreators),
                _buildChallengesTab(matchingChallenges),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopTab(
    List<Map<String, dynamic>> videos,
    List<Map<String, dynamic>> creators,
    List<Map<String, dynamic>> challenges,
  ) {
    if (videos.isEmpty && creators.isEmpty && challenges.isEmpty) {
      return _buildEmptyState();
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (creators.isNotEmpty) ...[
            Text('Creators', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: creators.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final c = creators[i];
                  return GestureDetector(
                    onTap: () => context.push('/public-profile?id=${c['id']}'),
                    child: Column(
                      children: [
                        AppImage(
                          url: c['avatarUrl'] as String? ?? '',
                          width: 56,
                          height: 56,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          c['name'] as String? ?? '',
                          style: AppTextStyles.body.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (videos.isNotEmpty) ...[
            Text('Videos', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: videos.length > 4 ? 4 : videos.length,
              itemBuilder: (_, i) => _buildVideoCard(videos[i]),
            ),
            const SizedBox(height: 20),
          ],
          if (challenges.isNotEmpty) ...[
            Text('Challenges', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: challenges.length > 3 ? 3 : challenges.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _buildChallengeCard(challenges[i]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVideosTab(List<Map<String, dynamic>> videos) {
    if (videos.isEmpty) return _buildEmptyState();
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: videos.length,
      itemBuilder: (_, i) => _buildVideoCard(videos[i]),
    );
  }

  Widget _buildCreatorsTab(List<Map<String, dynamic>> creators) {
    if (creators.isEmpty) return _buildEmptyState();
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: creators.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final c = creators[i];
        return ListTile(
          onTap: () => context.push('/public-profile?id=${c['id']}'),
          leading: AppImage(
            url: c['avatarUrl'] as String? ?? '',
            width: 48,
            height: 48,
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            c['name'] as String? ?? '',
            style: AppTextStyles.displaySemiBold14,
          ),
          subtitle: Text(
            '@${c['handle'] ?? ''}',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSoft,
              fontSize: 12,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: AppColors.textFaint,
          ),
        );
      },
    );
  }

  Widget _buildChallengesTab(List<Map<String, dynamic>> challenges) {
    if (challenges.isEmpty) return _buildEmptyState();
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: challenges.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _buildChallengeCard(challenges[i]),
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> v) {
    return GestureDetector(
      onTap: () => context.push('/reels-feed?id=${v['id']}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AppImage(
              url: v['thumbnailUrl'] as String? ?? '',
              fit: BoxFit.cover,
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                  stops: [0.5, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    v['title'] as String? ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    v['creatorName'] as String? ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 10,
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

  Widget _buildChallengeCard(Map<String, dynamic> c) {
    return GestureDetector(
      onTap: () => context.push('/challenge-detail?id=${c['id']}'),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(11),
              ),
              child: AppImage(
                url: c['imageUrl'] as String? ?? '',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c['title'] as String? ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.displaySemiBold14,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${c['category'] ?? ''} • ${c['entryFee'] ?? 'Free'}',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSoft,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textFaint,
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            size: 48,
            color: AppColors.textFaint,
          ),
          const SizedBox(height: 12),
          Text(
            'No results found',
            style: AppTextStyles.displaySemiBold14.copyWith(
              color: AppColors.textSoft,
            ),
          ),
        ],
      ),
    );
  }
}
