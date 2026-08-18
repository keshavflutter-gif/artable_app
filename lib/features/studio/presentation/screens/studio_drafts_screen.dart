import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';
import 'package:artable_app/features/studio/presentation/bloc/studio_cubit.dart';
import 'package:artable_app/app/routes/app_routes.dart';
import 'package:artable_app/core/utils/formatters.dart';
import 'package:artable_app/core/widgets/app_network_image.dart';
import 'package:artable_app/core/widgets/app_screen_header.dart';
import 'package:artable_app/core/widgets/gradient_button.dart';

class StudioDraftsScreen extends StatelessWidget {
  const StudioDraftsScreen({super.key, this.challengeId});

  final String? challengeId;

  @override
  Widget build(BuildContext context) {
    final studio = context.watch<StudioCubit>();
    final drafts = studio.drafts;
    final cid = challengeId ?? 'c1';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            const AppScreenHeader(title: 'Drafts'),
            Expanded(
              child: drafts.isEmpty
                  ? _EmptyState(
                      onStart: () => context.push('${AppRoutes.studioStart}?id=$cid'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                      itemCount: drafts.length,
                      itemBuilder: (context, i) {
                        final draft = drafts[i];
                        return Padding(
                          padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
                          child: _DraftCard(
                            draft: draft,
                            onDelete: () => context.read<StudioCubit>().deleteDraft(draft['id'] as String),
                            onContinue: () => context.push(
                              '${AppRoutes.studioPreview}?draft=${draft['id']}&id=${draft['challengeId']}',
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({
    required this.draft,
    required this.onDelete,
    required this.onContinue,
  });

  final Map<String, dynamic> draft;
  final VoidCallback onDelete;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFFBF6FF)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5E2EAA).withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AppNetworkImage(
              url: draft['thumbnailUrl'] as String,
              width: 58,
              height: 78,
              alt: draft['challengeTitle'] as String? ?? '',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  draft['challengeTitle'] as String? ?? '',
                  style: AppTextStyles.displaySemiBold135.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${AppFormatters.formatDateTime(draft['recordedAt'] as String? ?? '')} · ${draft['duration']}',
                  style: AppTextStyles.hint12.copyWith(fontSize: 11),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F2FC),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'DRAFT',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.purple,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              GestureDetector(
                onTap: onContinue,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: AppGradients.button,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFCEDEE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline, size: 13, color: Color(0xFFE0405A)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0x24FF8A3D),
                    AppColors.purple.withValues(alpha: 0.14),
                  ],
                ),
              ),
              child: const Icon(Icons.description_outlined, size: 26, color: AppColors.purple),
            ),
            const SizedBox(height: 12),
            Text(
              'No drafts yet',
              style: AppTextStyles.displaySemiBold14.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            GradientButton(
              label: 'Start Recording',
              icon: const Icon(Icons.videocam_outlined, color: Colors.white, size: 18),
              onPressed: onStart,
            ),
          ],
        ),
      ),
    );
  }
}
