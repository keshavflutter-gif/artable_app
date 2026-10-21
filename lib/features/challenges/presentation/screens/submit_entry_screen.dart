import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_typography.dart';
import 'package:artable_app/core/utils/challenge_helpers.dart';
import 'package:artable_app/data/datasources/mock_data.dart';
import 'package:artable_app/app/routes/app_routes.dart';
import 'package:artable_app/features/shell/presentation/widgets/app_shell.dart';
import 'package:artable_app/core/widgets/gradient_button.dart';
import 'package:artable_app/core/widgets/app_image.dart';
import 'package:artable_app/features/challenges/presentation/bloc/challenges_cubit.dart';
import 'package:artable_app/features/studio/presentation/bloc/studio_cubit.dart';

class SubmitEntryScreen extends StatefulWidget {
  const SubmitEntryScreen({super.key, this.challengeId});

  final String? challengeId;

  @override
  State<SubmitEntryScreen> createState() => _SubmitEntryScreenState();
}

class _SubmitEntryScreenState extends State<SubmitEntryScreen> {
  @override
  void initState() {
    super.initState();
    final cId = widget.challengeId;
    if (cId != null && cId.isNotEmpty) {
      final challengesCubit = context.read<ChallengesCubit>();
      if (challengesCubit.getChallengeDetail(cId) == null) {
        challengesCubit.loadChallengeDetail(cId).then((_) {
          if (mounted) setState(() {});
        });
      }
    }
  }

  Map<String, dynamic> get _challenge {
    final live = context.read<ChallengesCubit>().getChallengeDetail(widget.challengeId ?? '');
    if (live != null) {
      return {
        'id': live.id,
        'title': live.title,
        'category': live.category?.name ?? 'Dance',
        'categoryId': live.category?.id,
        'prize': live.prizePoolLabel.isNotEmpty
            ? live.prizePoolLabel
            : (live.rewardPool.isNotEmpty
                ? '₹${live.rewardPool} Prize Pool'
                : '₹5,000 Prize Pool'),
        'endDate': live.endDate,
        'imageUrl': live.bannerUrl.isNotEmpty ? live.bannerUrl : (live.category?.imageUrl ?? ''),
      };
    }
    return findChallengeById(
          MockData.CHALLENGES.cast<Map<String, dynamic>>(),
          widget.challengeId,
        ) ??
        MockData.CHALLENGES.first;
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    final id = widget.challengeId;
    if (id != null && id.isNotEmpty) {
      context.go('${AppRoutes.challengeDetail}?id=$id');
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final challenge = _challenge;

    return AppShell(
      currentPath: AppRoutes.submitEntry,
      showBottomNav: false,
      body: Column(
        children: [
          AppPageHeader(
            title: 'Submit Entry',
            onBack: _goBack,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SummaryCard(challenge: challenge),
                  _DetailSection(
                    title: 'Record Your Entry',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GradientButton(
                          label: 'Record Video in App Studio',
                          icon: const Icon(Icons.videocam_outlined, size: 18, color: Colors.white),
                          onPressed: () {
                            final cId = widget.challengeId ?? challenge['id']?.toString() ?? '';
                            final challengesCubit = context.read<ChallengesCubit>();
                            final detail = challengesCubit.getChallengeDetail(cId);

                            final realChallengeId = (detail?.id != null && detail!.id.isNotEmpty)
                                ? detail.id
                                : cId;
                            String? realCategoryId;
                            if (detail?.category?.id != null && detail!.category!.id.isNotEmpty) {
                              realCategoryId = detail.category!.id;
                            } else if (challenge['categoryId'] != null &&
                                challenge['categoryId'].toString() != realChallengeId) {
                              realCategoryId = challenge['categoryId'].toString();
                            }
                            if (realCategoryId == realChallengeId) {
                              realCategoryId = null;
                            }

                            final studioCubit = context.read<StudioCubit>();
                            studioCubit.setVideoSubmissionDetails(
                              title: '',
                              challengeId: realChallengeId,
                              categoryId: realCategoryId,
                            );

                            context.push('${AppRoutes.studioCamera}?id=$realChallengeId');
                          },
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () {
                            final cId = widget.challengeId ?? challenge['id']?.toString() ?? 'c1';
                            context.push('${AppRoutes.studioDrafts}?id=$cId');
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            side: const BorderSide(color: AppColors.inputBorder, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          icon: const Icon(Icons.video_library_outlined, size: 17),
                          label: Text(
                            'Choose from My Drafts',
                            style: AppTypography.display(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.challenge});

  final Map<String, dynamic> challenge;

  @override
  Widget build(BuildContext context) {
    final rawDate = challenge['endDate']?.toString() ?? '';
    final formattedDate = rawDate.isNotEmpty ? formatDate(rawDate) : '';

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F5E2EAA),
            blurRadius: 40,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AppImage(
              url: challenge['imageUrl']?.toString() ?? '',
              width: 74,
              height: 74,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge['title']?.toString() ?? 'Challenge',
                  style: AppTypography.display(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (challenge['category'] != null &&
                    challenge['category'].toString().isNotEmpty)
                  Text(
                    challenge['category'].toString(),
                    style: AppTypography.body(fontSize: 12, color: AppColors.textSoft),
                  ),
                Text(
                  challenge['prize']?.toString() ?? '',
                  style: AppTypography.body(fontSize: 12, color: AppColors.textSoft),
                ),
                if (formattedDate.isNotEmpty)
                  Text(
                    'Ends $formattedDate',
                    style: AppTypography.body(fontSize: 12, color: AppColors.textSoft),
                  ),
              ],
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
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.display(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
