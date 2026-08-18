import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';
import 'package:artable_app/core/widgets/app_back_header.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';
import 'package:artable_app/features/profile/presentation/bloc/achievements_cubit.dart';
import 'package:artable_app/data/datasources/mock_data.dart';
import 'package:artable_app/features/profile/data/models/achievements_response.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AchievementsCubit>().loadAchievements();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final achievementsVm = context.watch<AchievementsCubit>();
    final data = achievementsVm.data;
    final isLoading = achievementsVm.isLoading && !achievementsVm.hasLoaded;

    // Fallback Mock Creator Level logic if API data not yet loaded
    final earnedCount = data?.earnedCount ??
        MockData.BADGES.where((b) => b['earned'] == true).length;
    final totalCount = data?.totalCount ?? MockData.BADGES.length;

    final levelIndex = (earnedCount / 3)
        .floor()
        .clamp(0, MockData.CREATOR_LEVELS.length - 1);
    final defaultLevel = MockData.CREATOR_LEVELS[levelIndex];
    final defaultNextLevel = levelIndex + 1 < MockData.CREATOR_LEVELS.length
        ? MockData.CREATOR_LEVELS[levelIndex + 1]
        : null;
    final defaultNextMilestoneCount = (levelIndex + 1) * 3;
    final defaultNextMilestoneString = defaultNextLevel != null
        ? '$defaultNextLevel at $defaultNextMilestoneCount badges'
        : null;

    final level = data?.levelCard?.value.isNotEmpty == true
        ? data!.levelCard!.value
        : (data?.currentLevel.isNotEmpty == true
            ? data!.currentLevel
            : defaultLevel);

    final earnedLabel = data?.levelCard?.earnedLabel.isNotEmpty == true
        ? data!.levelCard!.earnedLabel
        : (data?.earnedLabel.isNotEmpty == true
            ? data!.earnedLabel
            : '$earnedCount/$totalCount');

    final earnedText = data?.levelCard?.earnedText.isNotEmpty == true
        ? data!.levelCard!.earnedText
        : 'Badges Earned';

    final nextMilestone = data?.levelCard?.nextMilestone.isNotEmpty == true
        ? data!.levelCard!.nextMilestone
        : (data?.nextMilestone.isNotEmpty == true
            ? data!.nextMilestone
            : defaultNextMilestoneString);

    final nextMilestoneText =
        data?.levelCard?.nextMilestoneText.isNotEmpty == true
            ? data!.levelCard!.nextMilestoneText
            : 'Next Milestone';

    const defaultCategories = [
      ('participation', 'Participation'),
      ('winner', 'Winner'),
      ('referral', 'Referral'),
      ('activity', 'Activity'),
    ];

    final hasApiGroups = data != null && data.groups.isNotEmpty;

    return AppScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppBackHeader(title: 'Achievements'),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.purple),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => context
                        .read<AchievementsCubit>()
                        .loadAchievements(forceRefresh: true),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),

                          // 1. Top Level Summary Banner Card (Deep Royal Purple)
                          _buildSummaryCard(
                            level: level,
                            earnedLabel: earnedLabel,
                            earnedText: earnedText,
                            nextMilestone: nextMilestone,
                            nextMilestoneText: nextMilestoneText,
                          ),

                          const SizedBox(height: 24),

                          // 2. Badge Groups (from API) or Fallback Categories (Mock Data)
                          if (hasApiGroups) ...[
                            for (final group in data.groups) ...[
                              _buildApiGroupSection(group: group),
                              const SizedBox(height: 20),
                            ],
                          ] else ...[
                            for (final cat in defaultCategories) ...[
                              _buildCategorySection(
                                categoryKey: cat.$1,
                                categoryTitle: cat.$2,
                              ),
                              const SizedBox(height: 20),
                            ],
                          ],

                          const SizedBox(height: 36),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // --- Top Level Summary Banner Card ---
  Widget _buildSummaryCard({
    required String level,
    required String earnedLabel,
    required String earnedText,
    required String? nextMilestone,
    required String nextMilestoneText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF261057),
            Color(0xFF3F1B85),
            Color(0xFF6E28E0),
          ],
          stops: [0.0, 0.45, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A1F8F).withValues(alpha: 0.32),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Level Label
          Text(
            'CURRENT LEVEL',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.8),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),

          // Level Title (e.g. Starter / Influencer)
          Text(
            level,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 16),

          // Bottom Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Left: Badges Earned
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    earnedLabel,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    earnedText,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),

              // Right: Next Milestone
              if (nextMilestone != null && nextMilestone.isNotEmpty)
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        nextMilestone,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        nextMilestoneText,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                        textAlign: TextAlign.end,
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

  // --- API Group Section with 3-Column Grid ---
  Widget _buildApiGroupSection({
    required AchievementGroup group,
  }) {
    if (group.items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          group.title,
          style: AppTextStyles.displayBold.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: group.items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 12,
            childAspectRatio: 0.68,
          ),
          itemBuilder: (context, index) {
            final item = group.items[index];
            return _AchievementBadgeCard(item: item);
          },
        ),
      ],
    );
  }

  // --- Mock Data Fallback Category Section with 3-Column Grid ---
  Widget _buildCategorySection({
    required String categoryKey,
    required String categoryTitle,
  }) {
    final badges = MockData.BADGES
        .where((b) => b['category'] == categoryKey)
        .toList();

    if (badges.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          categoryTitle,
          style: AppTextStyles.displayBold.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: badges.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 12,
            childAspectRatio: 0.68,
          ),
          itemBuilder: (context, index) {
            final badge = badges[index];
            return _AchievementBadgeCard(badge: badge);
          },
        ),
      ],
    );
  }
}

// --- Individual Achievement Badge Card ---
class _AchievementBadgeCard extends StatelessWidget {
  const _AchievementBadgeCard({
    this.item,
    this.badge,
  });

  final AchievementBadgeItem? item;
  final Map<String, dynamic>? badge;

  IconData _getBadgeIcon(String icon) {
    switch (icon.toLowerCase()) {
      case 'upload':
        return Icons.upload_rounded;
      case 'flame':
      case 'fire':
        return Icons.local_fire_department_rounded;
      case 'trophy':
        return Icons.emoji_events_rounded;
      case 'medal':
        return Icons.verified_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'chart':
        return Icons.bar_chart_rounded;
      case 'video':
        return Icons.videocam_rounded;
      case 'lock':
        return Icons.lock_outline_rounded;
      default:
        return Icons.workspace_premium_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEarned = item != null ? item!.isEarned : (badge?['earned'] == true);
    final iconName = item?.icon ?? (badge?['icon'] as String?) ?? 'medal';
    final name = item?.title ?? (badge?['name'] as String?) ?? '';
    final description =
        item?.description ?? (badge?['description'] as String?) ?? '';
    final imageUrl = item?.imageUrl ?? (badge?['imageUrl'] as String?);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFECE8F5).withValues(alpha: 0.8),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5E2EAA).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Circular Badge Icon Container (Vibrant Gradient when earned, Soft Neutral when locked)
          Container(
            width: 48,
            height: 48,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isEarned
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFF4860),
                        Color(0xFF8B2BE2),
                      ],
                    )
                  : null,
              color: isEarned ? null : const Color(0xFFF6F3FC),
              border: isEarned
                  ? null
                  : Border.all(
                      color: const Color(0xFFECE8F5),
                      width: 1,
                    ),
              boxShadow: isEarned
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFF3868).withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      isEarned
                          ? _getBadgeIcon(iconName)
                          : Icons.lock_outline_rounded,
                      size: isEarned ? 22 : 19,
                      color:
                          isEarned ? Colors.white : const Color(0xFFB7B1C6),
                    ),
                  )
                : Icon(
                    isEarned
                        ? _getBadgeIcon(iconName)
                        : Icons.lock_outline_rounded,
                    size: isEarned ? 22 : 19,
                    color: isEarned ? Colors.white : const Color(0xFFB7B1C6),
                  ),
          ),
          const SizedBox(height: 10),

          // Badge Name
          Text(
            name,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 4),
            // Badge Description
            Expanded(
              child: Center(
                child: Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSoft,
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ] else
            const Spacer(),
        ],
      ),
    );
  }
}
