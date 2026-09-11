import 'dart:async';
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
import 'package:artable_app/features/studio/data/services/studio_music_playback_service.dart';
import 'package:artable_app/core/utils/reel_helpers.dart';

class StudioDraftsScreen extends StatefulWidget {
  const StudioDraftsScreen({super.key, this.challengeId});

  final String? challengeId;

  @override
  State<StudioDraftsScreen> createState() => _StudioDraftsScreenState();
}

class _StudioDraftsScreenState extends State<StudioDraftsScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(StudioMusicPlaybackService.stop());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<StudioCubit>().fetchDraftsList(
              challengeId: widget.challengeId,
              forceRefresh: true,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final studio = context.watch<StudioCubit>();
    final drafts = studio.state.drafts;
    final isLoading = studio.state.isLoadingDrafts;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            const AppScreenHeader(title: 'Drafts'),
            if (drafts.length >= StudioCubit.maxDraftsLimit)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFB74D), width: 1),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Draft gallery full (20/20). Delete a draft to save a new video.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE65100),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (drafts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Saved Drafts',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${drafts.length} / ${StudioCubit.maxDraftsLimit}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.purple,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.purple),
                    )
                  : drafts.isEmpty
                      ? const _EmptyState()
                      : RefreshIndicator(
                          color: AppColors.purple,
                          onRefresh: () => context.read<StudioCubit>().fetchDraftsList(
                                challengeId: widget.challengeId,
                                forceRefresh: true,
                              ),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                            itemCount: drafts.length,
                            itemBuilder: (context, i) {
                              final draft = drafts[i];
                              return Padding(
                                padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
                                child: _DraftCard(
                                  draft: draft,
                                  onDelete: () async {
                                    final confirm = await _showDeleteConfirmDialog(context);
                                    if (confirm != true) return;

                                    if (!context.mounted) return;
                                    final draftId = draft['id'] as String;
                                    final success = await context.read<StudioCubit>().deleteDraft(draftId);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            success ? 'Draft deleted successfully' : 'Failed to delete draft',
                                          ),
                                          backgroundColor: success ? AppColors.purple : Colors.redAccent,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                  onContinue: () => context.push(
                                    '${AppRoutes.studioPreview}?draft=${draft['id']}&id=${draft['challengeId']}',
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
    );
  }

  Future<bool?> _showDeleteConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFECE8F5), width: 1.2),
        ),
        backgroundColor: Colors.white,
        elevation: 16,
        shadowColor: const Color(0xFF5E2EAA).withValues(alpha: 0.15),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFFCEDEE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  color: Color(0xFFE0405A),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Delete Draft?',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Are you sure you want to delete this draft? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  color: AppColors.textSoft,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFFECE8F5), width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSoft,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: const Color(0xFFE0405A),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
    String thumbnailUrl = (draft['thumbnailUrl'] as String?) ?? (draft['imageUrl'] as String?) ?? '';
    final challengeId = (draft['challengeId'] as String?) ?? '';
    if (thumbnailUrl.isEmpty || thumbnailUrl.contains('storage.example')) {
      if (challengeId.isNotEmpty) {
        final challenge = ReelHelpers.challengeById(challengeId);
        if (challenge != null) {
          thumbnailUrl = (challenge['bannerUrl'] as String?) ?? (challenge['imageUrl'] as String?) ?? '';
        }
      }
    }

    final title = (draft['challengeTitle'] as String?) ?? (draft['title'] as String?) ?? 'Draft Entry';
    final dateStr = (draft['recordedAt'] as String?) ?? (draft['createdAt'] as String?) ?? '';
    final formattedDate = dateStr.isNotEmpty ? AppFormatters.formatDateTime(dateStr) : '';
    final duration = (draft['duration'] as String?) ?? '0:42';

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
              url: thumbnailUrl,
              width: 58,
              height: 78,
              alt: title,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.displaySemiBold135.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  formattedDate.isNotEmpty ? '$formattedDate · $duration' : duration,
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
  const _EmptyState();

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
          ],
        ),
      ),
    );
  }
}
