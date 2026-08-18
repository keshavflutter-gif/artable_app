import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/app/theme/app_typography.dart';
import 'package:artable_app/core/utils/challenge_helpers.dart';
import 'package:artable_app/core/widgets/gradient_button.dart';
import 'package:artable_app/features/challenges/presentation/bloc/challenges_cubit.dart';
import 'package:artable_app/data/datasources/mock_data.dart';
import 'package:artable_app/features/challenges/data/models/challenge_detail_response.dart';
import 'package:artable_app/core/widgets/network_image_widget.dart';

class ChallengeDetailScreen extends StatefulWidget {
  const ChallengeDetailScreen({super.key, required this.challengeId});

  final String challengeId;

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.challengeId.isNotEmpty) {
        context.read<ChallengesCubit>().loadChallengeDetail(widget.challengeId);
      }
    });
  }

  Map<String, dynamic> _fallbackChallenge(String id) {
    return findChallengeById(
          MockData.CHALLENGES.cast<Map<String, dynamic>>(),
          id,
        ) ??
        MockData.CHALLENGES.first;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChallengesCubit>();
    final ChallengeDetailData? liveDetail = provider.getChallengeDetail(widget.challengeId);
    final fallback = _fallbackChallenge(widget.challengeId);

    final title = liveDetail?.title.isNotEmpty == true
        ? liveDetail!.title
        : (fallback['title'] as String? ?? '');

    final bannerUrl = liveDetail?.bannerUrl.isNotEmpty == true
        ? liveDetail!.bannerUrl
        : (fallback['imageUrl'] as String? ?? '');

    final status = (liveDetail?.status ?? fallback['status'] as String? ?? 'ACTIVE')
        .toLowerCase();

    final prize = liveDetail?.formattedPrizePool.isNotEmpty == true
        ? liveDetail!.formattedPrizePool
        : (fallback['prize'] as String? ?? '₹5,000');

    final joinedText = liveDetail?.joinedLabel.isNotEmpty == true
        ? liveDetail!.joinedLabel
        : '${formatParticipants(liveDetail?.joinedCount ?? fallback['participants'] as int? ?? 1)} joined';

    final remaining = daysRemaining(liveDetail?.endDate.isNotEmpty == true
        ? liveDetail!.endDate
        : (fallback['endDate'] as String? ?? ''));

    String countdownMain;
    String countdownSub;
    if (liveDetail != null && liveDetail.daysLeftLabel.isNotEmpty) {
      countdownMain = liveDetail.daysLeftLabel;
      countdownSub = liveDetail.endDateLabel.isNotEmpty
          ? 'Ends ${liveDetail.endDateLabel}'
          : 'Active';
    } else if (status == 'completed') {
      countdownMain = 'Ended';
      countdownSub = formatDate(fallback['endDate'] as String);
    } else if (status == 'upcoming') {
      countdownMain = 'Starts soon';
      countdownSub = formatDate(fallback['endDate'] as String);
    } else {
      countdownMain = remaining > 0 ? '$remaining days left' : 'Ending today';
      countdownSub = 'Ends ${formatDate(fallback['endDate'] as String)}';
    }

    final categoryName = liveDetail?.categoryName.isNotEmpty == true
        ? liveDetail!.categoryName
        : (liveDetail?.category?.name ?? fallback['category'] as String? ?? 'Dance');

    final description = liveDetail?.description.isNotEmpty == true
        ? liveDetail!.description
        : (fallback['description'] as String? ?? '');

    final rules = (liveDetail != null && liveDetail.rules.isNotEmpty)
        ? liveDetail.rules
        : (fallback['rules'] as List? ?? const []).cast<String>();

    final prizeBreakdown = (liveDetail != null && liveDetail.prizeBreakdown.isNotEmpty)
        ? liveDetail.prizeBreakdown.map((p) => p.toUiMap()).toList()
        : (fallback['prizeBreakdown'] as List? ?? const []).cast<Map<String, dynamic>>();

    final topParticipants =
        (fallback['topParticipants'] as List? ?? const []).cast<Map<String, dynamic>>();

    final isLoading = provider.isLoadingChallengeDetail(widget.challengeId) &&
        liveDetail == null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () => context
            .read<ChallengesCubit>()
            .loadChallengeDetail(widget.challengeId, forceRefresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 290,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    NetworkImageWidget(
                      url: bannerUrl,
                      alignment: const Alignment(0, -0.56),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.3),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                            Colors.black.withValues(alpha: 0.9),
                          ],
                          stops: const [0.0, 0.3, 0.75, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16 + MediaQuery.paddingOf(context).top,
                      left: 20,
                      child: _BackButton(
                        onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/challenges');
                          }
                        },
                      ),
                    ),
                    Positioned(
                      left: 22,
                      right: 22,
                      bottom: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _StatusBadge(status: status),
                          const SizedBox(height: 10),
                          Text(
                            title,
                            style: AppTypography.display(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _DetailStat(
                              icon: Icons.star_outline,
                              value: prize,
                              label: 'Prize',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _DetailStat(
                              icon: Icons.people_outline,
                              value: joinedText,
                              label: 'Joined',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _DetailStat(
                              icon: Icons.calendar_today_outlined,
                              value: countdownMain,
                              label: countdownSub,
                              subBold: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      RichText(
                        text: TextSpan(
                          style: AppTypography.body(
                            fontSize: 12.5,
                            color: AppColors.textSoft,
                          ),
                          children: [
                            const TextSpan(text: 'Category: '),
                            TextSpan(
                              text: categoryName,
                              style: const TextStyle(
                                color: AppColors.purple,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _DetailSection(
                        title: 'About this Challenge',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              description,
                              style: AppTypography.body(
                                fontSize: 13,
                                color: AppColors.textSoft,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const _RatingNote(),
                          ],
                        ),
                      ),
                      if (rules.isNotEmpty)
                        _DetailSection(
                          title: 'Rules',
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F7FD),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.inputBorder),
                            ),
                            child: Column(
                              children: rules.asMap().entries.map((entry) {
                                final isLast = entry.key == rules.length - 1;
                                return Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    border: isLast
                                        ? null
                                        : const Border(
                                            bottom: BorderSide(
                                                color: AppColors.inputBorder),
                                          ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.check_circle_outline,
                                          size: 17, color: AppColors.purple),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          entry.value,
                                          style: AppTypography.body(
                                            fontSize: 12.5,
                                            color: AppColors.textSoft,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      if (prizeBreakdown.isNotEmpty)
                        _DetailSection(
                          title: 'Prize Breakdown',
                          child: Column(
                            children: prizeBreakdown.asMap().entries.map((entry) {
                              final rank = entry.key + 1;
                              final item = entry.value;
                              final rawReward = item['reward'] as String? ??
                                  item['amount'] as String? ??
                                  '';

                              String amount = item['amount'] as String? ?? rawReward;
                              String? badge = item['badge'] as String?;
                              if (badge == null && rawReward.contains('+')) {
                                final parts = rawReward.split('+');
                                amount = parts[0].trim();
                                badge = parts[1].trim();
                              }

                              return Container(
                                margin: EdgeInsets.only(
                                    bottom: entry.key < prizeBreakdown.length - 1
                                        ? 10
                                        : 0),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: rank == 1
                                      ? const Color(0xFFFFF0F5)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: rank == 1
                                        ? AppColors.pink.withValues(alpha: 0.25)
                                        : AppColors.inputBorder,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: rank == 1
                                          ? AppColors.pink.withValues(alpha: 0.1)
                                          : const Color(0xFF5E2EAA)
                                              .withValues(alpha: 0.05),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        gradient: rank == 1
                                            ? AppGradients.button
                                            : rank == 2
                                                ? const LinearGradient(
                                                    colors: [
                                                      AppColors.purple,
                                                      AppColors.blue
                                                    ],
                                                  )
                                                : const LinearGradient(
                                                    colors: [
                                                      Color(0xFFB7B1C6),
                                                      Color(0xFF8B849C)
                                                    ],
                                                  ),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Text(
                                        '$rank',
                                        style: AppTypography.display(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            (item['place'] as String? ?? 'PLACE')
                                                .toUpperCase(),
                                            style: AppTypography.body(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: rank == 1
                                                  ? AppColors.pink
                                                  : AppColors.textSoft,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            amount,
                                            style: AppTypography.display(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.text,
                                            ),
                                          ),
                                          if (badge != null &&
                                              badge.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: rank == 1
                                                    ? AppColors.pink
                                                        .withValues(alpha: 0.12)
                                                    : AppColors.purple
                                                        .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    rank == 1
                                                        ? Icons.workspace_premium
                                                        : Icons
                                                            .military_tech_outlined,
                                                    size: 11,
                                                    color: rank == 1
                                                        ? AppColors.pink
                                                        : AppColors.purple,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    badge,
                                                    style: AppTypography.body(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w600,
                                                      color: rank == 1
                                                          ? AppColors.pink
                                                          : AppColors.purple,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      if (topParticipants.isNotEmpty)
                        _DetailSection(
                          title: 'Top Participants',
                          child: Column(
                            children: topParticipants.map((p) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    NetworkImageWidget(
                                      url: p['avatarUrl'] as String,
                                      width: 40,
                                      height: 40,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        p['name'] as String,
                                        style: AppTypography.body(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.text,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                            color: AppColors.inputBorder),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF5E2EAA)
                                                .withValues(alpha: 0.06),
                                            blurRadius: 10,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star,
                                              size: 12,
                                              color: Color(0xFFFFB800)),
                                          const SizedBox(width: 4),
                                          Text(
                                            (p['score'] as num).toStringAsFixed(1),
                                            style: AppTypography.display(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.text,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(
                                    color: AppColors.inputBorder, width: 1.5),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x145E2EAA),
                                    blurRadius: 14,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.share_outlined,
                                  size: 20, color: AppColors.text),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GradientButton(
                              label: provider
                                      .isJoiningChallenge(widget.challengeId)
                                  ? 'Joining...'
                                  : 'Join Challenge',
                              icon: provider
                                      .isJoiningChallenge(widget.challengeId)
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.arrow_forward,
                                      size: 18, color: Colors.white),
                              enabled: !provider
                                  .isJoiningChallenge(widget.challengeId),
                              onPressed: () async {
                                final targetId =
                                    liveDetail?.id.isNotEmpty == true
                                        ? liveDetail!.id
                                        : widget.challengeId;
                                final response = await context
                                    .read<ChallengesCubit>()
                                    .joinChallenge(targetId);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      response.message ??
                                          (response.success
                                              ? 'Challenge joined successfully'
                                              : 'Failed to join challenge'),
                                    ),
                                    backgroundColor: response.success
                                        ? AppColors.purple
                                        : Colors.redAccent,
                                  ),
                                );
                                if (response.success) {
                                  context.go('/submit-entry?id=$targetId');
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'active':
        bg = const Color(0xFF21B573);
        fg = Colors.white;
        label = 'Active';
        icon = Icons.local_fire_department;
      case 'upcoming':
        bg = const Color(0xFFFF9F1C);
        fg = Colors.white;
        label = 'Upcoming';
        icon = Icons.alarm;
      case 'completed':
        bg = AppColors.textSoft;
        fg = Colors.white;
        label = 'Ended';
        icon = Icons.check;
      default:
        bg = AppColors.purple;
        fg = Colors.white;
        label = status.toUpperCase();
        icon = Icons.circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.body(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  const _DetailStat({
    required this.icon,
    required this.value,
    required this.label,
    this.subBold = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool subBold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C5E2EAA),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.purple),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.display(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body(
              fontSize: 9.5,
              fontWeight: subBold ? FontWeight.w700 : FontWeight.w600,
              color: AppColors.textSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 22),
        Text(
          title,
          style: AppTypography.display(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _RatingNote extends StatelessWidget {
  const _RatingNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.purple.withValues(alpha: 0.08),
            AppColors.pink.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.star, size: 16, color: Color(0xFFFFB800)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Winners are decided by Talent Score. Likes and shares improve visibility.',
              style: AppTypography.body(
                fontSize: 11.5,
                color: AppColors.textSoft,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.35),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: const Icon(Icons.arrow_back, size: 18, color: Colors.white),
      ),
    );
  }
}
