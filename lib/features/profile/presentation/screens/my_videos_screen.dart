import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/core/widgets/app_back_header.dart';
import 'package:artable_app/core/widgets/app_image.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';
import 'package:artable_app/core/widgets/filter_pills.dart';
import 'package:artable_app/features/profile/data/models/my_videos_response.dart';
import 'package:artable_app/features/profile/presentation/bloc/my_videos_cubit.dart';
import 'package:artable_app/features/profile/presentation/bloc/my_videos_state.dart';

class MyVideosScreen extends StatefulWidget {
  const MyVideosScreen({super.key});

  @override
  State<MyVideosScreen> createState() => _MyVideosScreenState();
}

class _MyVideosScreenState extends State<MyVideosScreen> {
  static const _defaultFilterTabs = [
    ('ALL', 'All'),
    ('LIVE', 'Live'),
    ('UNDER_REVIEW', 'Under Review'),
    ('DRAFTS', 'Drafts'),
    ('REJECTED', 'Rejected'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<MyVideosCubit>();
      if (!cubit.hasLoaded && !cubit.isLoading) {
        cubit.loadMyVideos();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyVideosCubit, MyVideosState>(
      builder: (context, state) {
        final cubit = context.read<MyVideosCubit>();

        // Extract tab pills dynamically from API tabs if available, else fallback
        final dynamicTabs = state.tabs.isNotEmpty
            ? state.tabs.map((t) => (t.key, t.label)).toList()
            : _defaultFilterTabs;

        final activeTabKey = state.activeTab;
        final selectedTabLabel = dynamicTabs
            .firstWhere(
              (t) => t.$1 == activeTabKey,
              orElse: () => dynamicTabs.first,
            )
            .$2;

        final list = state.videos;
        final emptyState = state.emptyState;
        final emptyMsg = emptyState?.message.isNotEmpty == true
            ? emptyState!.message
            : 'No videos found in this section.';

        return AppScreen(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppBackHeader(title: 'My Videos'),
              const SizedBox(height: 6),
              FilterPills(
                items: dynamicTabs.map((f) => f.$2).toList(),
                selected: selectedTabLabel,
                onSelected: (label) {
                  final target = dynamicTabs.firstWhere((f) => f.$2 == label);
                  cubit.selectTab(target.$1);
                },
              ),
              const SizedBox(height: 14),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.purple,
                  onRefresh: () => cubit.loadMyVideos(forceRefresh: true),
                  child: state.isLoading && list.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(color: AppColors.purple),
                        )
                      : list.isEmpty
                          ? ListView(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9F8FC),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: const Color(0xFFECE8F5), width: 1.2),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.video_library_outlined, size: 40, color: AppColors.textSoft),
                                      const SizedBox(height: 10),
                                      Text(
                                        emptyState?.title.isNotEmpty == true
                                            ? emptyState!.title
                                            : 'No Videos Available',
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.text,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        emptyMsg,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12.5,
                                          color: AppColors.textSoft,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.54,
                              ),
                              itemCount: list.length,
                              itemBuilder: (context, i) => _FigmaMyVideoCard(item: list[i]),
                            ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FigmaMyVideoCard extends StatelessWidget {
  const _FigmaMyVideoCard({required this.item});

  final MyVideoItem item;

  @override
  Widget build(BuildContext context) {
    final statusRaw = item.status.toLowerCase();
    final title = item.title.isNotEmpty ? item.title : 'Challenge Video';
    final thumbnailUrl = item.thumbnailUrl;
    final views = item.viewsLabel;
    final likes = item.likesLabel;
    final date = item.dateLabel;
    final rejectionReason = item.rejectionReason;
    final talentScore = item.talentScoreLabel;

    Color badgeColor;
    String badgeLabel;

    if (statusRaw == 'approved' || statusRaw == 'live' || item.isLive) {
      badgeColor = const Color(0xFF00C853);
      badgeLabel = 'LIVE';
    } else if (statusRaw == 'pending_review' || statusRaw == 'under_review') {
      badgeColor = const Color(0xFFFF9800);
      badgeLabel = 'UNDER REVIEW';
    } else if (statusRaw == 'draft') {
      badgeColor = const Color(0xFF5E2EAA);
      badgeLabel = 'DRAFT';
    } else {
      badgeColor = const Color(0xFFFF3B30);
      badgeLabel = 'REJECTED';
    }

    if (item.statusBadge?.label.isNotEmpty == true) {
      badgeLabel = item.statusBadge!.label.toUpperCase();
    } else if (item.statusLabel?.isNotEmpty == true) {
      badgeLabel = item.statusLabel!.toUpperCase();
    }

    final hasScore = talentScore.isNotEmpty && talentScore != '0' && talentScore != '0.0';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECE8F5), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D15083C),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail with top rounded corners and Status Badge / Rating Pill
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14.8)),
            child: SizedBox(
              height: 140,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppImage(url: thumbnailUrl, fit: BoxFit.cover),
                  // Status Badge (Top-Left)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        badgeLabel,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  // Score Pill (Top-Right)
                  if (hasScore)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xCC000000),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 9.5, color: Color(0xFFFFC107)),
                            const SizedBox(width: 2.5),
                            Text(
                              talentScore,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Content Area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Stats Row (Views, Likes, Date)
                  Row(
                    children: [
                      const Icon(Icons.remove_red_eye_outlined, size: 10.5, color: AppColors.textSoft),
                      const SizedBox(width: 2.5),
                      Text(
                        views,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSoft,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.favorite_border_rounded, size: 10.5, color: AppColors.textSoft),
                      const SizedBox(width: 2.5),
                      Text(
                        likes,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSoft,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        date,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 8.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textFaint,
                        ),
                      ),
                    ],
                  ),

                  // Rejection Notice
                  if (statusRaw == 'rejected' && rejectionReason != null && rejectionReason.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      rejectionReason,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF3B30),
                        height: 1.15,
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Action Buttons
                  if (statusRaw == 'draft' || item.canContinueDraft)
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildSmallActionButton(
                            icon: Icons.edit_outlined,
                            label: 'Continue Draft',
                            onTap: () => context.push('/studio-drafts'),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          flex: 2,
                          child: _buildSmallActionButton(
                            icon: Icons.share_outlined,
                            label: 'Share',
                            onTap: () {},
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _buildSmallActionButton(
                            icon: Icons.remove_red_eye_outlined,
                            label: 'View',
                            onTap: () {
                              final challengeObj = item.challenge;
                              final challengeId = challengeObj?['id']?.toString() ?? '';
                              final routeId = challengeId.isNotEmpty ? challengeId : item.id;
                              context.push('/video-detail?id=$routeId');
                            },
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: _buildSmallActionButton(
                            icon: Icons.share_outlined,
                            label: 'Share',
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 26,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F5FC),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0xFFECE8F5), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 11, color: AppColors.text),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
