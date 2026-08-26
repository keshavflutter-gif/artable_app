import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_typography.dart';
import 'package:artable_app/core/utils/challenge_helpers.dart';
import 'package:artable_app/data/datasources/mock_data.dart';
import 'package:artable_app/app/routes/app_routes.dart';
import 'package:artable_app/features/shell/presentation/widgets/app_shell.dart';
import 'package:artable_app/features/challenges/presentation/widgets/challenge_card.dart';
import 'package:artable_app/core/widgets/network_image_widget.dart';
import 'package:artable_app/features/challenges/presentation/bloc/challenges_cubit.dart';
import 'package:artable_app/features/studio/presentation/bloc/studio_cubit.dart';

class SubmitEntryScreen extends StatefulWidget {
  const SubmitEntryScreen({super.key, this.challengeId});

  final String? challengeId;

  @override
  State<SubmitEntryScreen> createState() => _SubmitEntryScreenState();
}

class _SubmitEntryScreenState extends State<SubmitEntryScreen> {
  bool _showDrafts = false;
  int? _selectedDraft;
  bool _rulesConfirmed = false;

  Map<String, dynamic> get _challenge {
    return findChallengeById(
          MockData.CHALLENGES.cast<Map<String, dynamic>>(),
          widget.challengeId,
        ) ??
        MockData.CHALLENGES.first;
  }

  static const _drafts = [
    {
      'name': 'Studio Take — Jul 9',
      'meta': '0:42 · Recorded in-app',
      'imageUrl': 'https://loremflickr.com/100/100/dance,rehearsal?lock=701',
    },
    {
      'name': 'Studio Take — Jul 6',
      'meta': '0:55 · Recorded in-app',
      'imageUrl': 'https://loremflickr.com/100/100/dance,practice?lock=702',
    },
    {
      'name': 'Studio Take — Jul 2',
      'meta': '0:38 · Recorded in-app',
      'imageUrl': 'https://loremflickr.com/100/100/dance,studio?lock=703',
    },
  ];

  bool get _canSubmit => _selectedDraft != null && _rulesConfirmed;

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
                          onTap: () {
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

                            context.push('${AppRoutes.studioStart}?id=$realChallengeId');
                          },
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () => setState(() => _showDrafts = !_showDrafts),
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
                        if (_showDrafts) ...[
                          const SizedBox(height: 12),
                          ..._drafts.asMap().entries.map((entry) {
                            final index = entry.key;
                            final draft = entry.value;
                            final selected = _selectedDraft == index;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedDraft = index),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: selected ? AppColors.purple : AppColors.inputBorder,
                                    width: 1.5,
                                  ),
                                  boxShadow: selected
                                      ? [
                                          BoxShadow(
                                            color: AppColors.purple.withValues(alpha: 0.14),
                                            blurRadius: 0,
                                            spreadRadius: 3,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    NetworkImageWidget(
                                      url: draft['imageUrl'] as String,
                                      width: 46,
                                      height: 46,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            draft['name'] as String,
                                            style: AppTypography.body(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            draft['meta'] as String,
                                            style: AppTypography.body(
                                              fontSize: 11,
                                              color: AppColors.textSoft,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: selected ? AppColors.purple : AppColors.inputBorder,
                                          width: 2,
                                        ),
                                        color: selected ? AppColors.purple : Colors.transparent,
                                      ),
                                      child: selected
                                          ? const Icon(Icons.check, size: 12, color: Colors.white)
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                  _DetailSection(
                    title: 'Before You Submit',
                    child: Column(
                      children: const [
                        _ChecklistItem(
                          text: 'Video must be recorded in the Artable in-app studio.',
                        ),
                        _ChecklistItem(
                          text: 'Gallery upload is not allowed. Please record your video using the in-app studio.',
                        ),
                        _ChecklistItem(
                          text: 'One entry per user for this challenge.',
                        ),
                      ],
                    ),
                  ),
                  _RatingNote(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: Checkbox(
                          value: _rulesConfirmed,
                          onChanged: (v) => setState(() => _rulesConfirmed = v ?? false),
                          activeColor: AppColors.purple,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'I confirm this entry follows the challenge rules and was recorded in the Artable app studio.',
                          style: AppTypography.body(
                            fontSize: 13,
                            color: AppColors.textSoft,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  GradientButton(
                    label: 'Submit Entry',
                    enabled: _canSubmit,
                    icon: const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                    onTap: _canSubmit
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Entry submitted successfully!')),
                            );
                          }
                        : null,
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
          NetworkImageWidget(
            url: challenge['imageUrl'] as String,
            width: 74,
            height: 74,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge['title'] as String,
                  style: AppTypography.display(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Category: ${challenge['category']}',
                  style: AppTypography.body(fontSize: 12, color: AppColors.textSoft),
                ),
                Text(
                  challenge['prize'] as String,
                  style: AppTypography.body(fontSize: 12, color: AppColors.textSoft),
                ),
                Text(
                  'Ends ${formatDate(challenge['endDate'] as String)}',
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

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.inputBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check, size: 18, color: Color(0xFF21B573)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTypography.body(
                fontSize: 13.5,
                color: AppColors.textSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.orange.withValues(alpha: 0.08),
            AppColors.purple.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.star_outline, size: 18, color: AppColors.purple),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Winners are decided by Talent Score. Likes and shares improve visibility.',
              style: AppTypography.body(
                fontSize: 12.5,
                color: AppColors.textSoft,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
