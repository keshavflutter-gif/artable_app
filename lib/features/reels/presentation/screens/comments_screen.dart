import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';
import 'package:artable_app/features/reels/presentation/bloc/reels_cubit.dart';
import 'package:artable_app/core/widgets/app_network_image.dart';
import 'package:artable_app/core/widgets/app_screen_header.dart';

class CommentsScreen extends StatefulWidget {
  const CommentsScreen({super.key, this.reelId});

  final String? reelId;

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final _inputController = TextEditingController();
  String _sortMode = 'top';

  void _postComment() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    context.read<ReelsCubit>().addComment(widget.reelId ?? 'r1', text);
    _inputController.clear();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reelId = widget.reelId ?? 'r1';
    final reelsProvider = context.watch<ReelsCubit>();
    final comments = reelsProvider.getComments(reelId);
    final countLabel =
        '${comments.length} comment${comments.length == 1 ? '' : 's'}';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            AppScreenHeader(
              title: 'Comments',
              subtitle: countLabel,
              bottomBorder: true,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
              child: Row(
                children: [
                  _SortChip(
                    label: 'Top comments',
                    active: _sortMode == 'top',
                    onTap: () => setState(() => _sortMode = 'top'),
                  ),
                  const SizedBox(width: 8),
                  _SortChip(
                    label: 'Recent',
                    active: _sortMode == 'recent',
                    onTap: () => setState(() => _sortMode = 'recent'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: comments.isEmpty
                  ? Center(
                      child: Text(
                        'No comments yet. Be the first to comment.',
                        style: AppTextStyles.hint12,
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(22, 6, 22, 12),
                      itemCount: comments.length,
                      itemBuilder: (context, i) => _CommentItem(
                        comment: comments[i],
                        liked: false,
                        onLike: () {},
                      ),
                    ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                14 + MediaQuery.paddingOf(context).bottom,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.98),
                border: Border(
                  top: BorderSide(color: const Color(0xFF5E2EAA).withValues(alpha: 0.1), width: 1.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF15083C).withValues(alpha: 0.09),
                    blurRadius: 30,
                    offset: const Offset(0, -14),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F3FC),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: TextField(
                        controller: _inputController,
                        decoration: InputDecoration(
                          filled: false,
                          hintText: 'Add a comment...',
                          hintStyle: AppTextStyles.hint12.copyWith(fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 11,
                          ),
                        ),
                        onSubmitted: (_) => _postComment(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _postComment,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: AppGradients.button,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF3D77).withValues(alpha: 0.32),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.send, size: 17, color: Colors.white),
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
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          gradient: active ? AppGradients.button : null,
          color: active ? null : const Color(0xFFF6F3FC),
          borderRadius: BorderRadius.circular(999),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF3D77).withValues(alpha: 0.22),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : AppColors.textSoft,
          ),
        ),
      ),
    );
  }
}

class _CommentItem extends StatelessWidget {
  const _CommentItem({
    required this.comment,
    required this.liked,
    required this.onLike,
  });

  final Map<String, dynamic> comment;
  final bool liked;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFAFE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF5E2EAA).withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipOval(
            child: AppNetworkImage(
              url: comment['avatarUrl'] as String,
              width: 40,
              height: 40,
              alt: comment['username'] as String? ?? '',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment['username'] as String? ?? '',
                      style: AppTextStyles.displaySemiBold135.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppColors.text,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          color: AppColors.textFaint,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Text(
                      comment['time'] as String? ?? '',
                      style: AppTextStyles.hint12.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textFaint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  comment['text'] as String? ?? '',
                  style: AppTextStyles.bodyRegular145.copyWith(fontSize: 13, height: 1.55),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    GestureDetector(
                      onTap: onLike,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                        decoration: BoxDecoration(
                          color: liked
                              ? AppColors.pink.withValues(alpha: 0.1)
                              : const Color(0xFF5E2EAA).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              liked ? Icons.favorite : Icons.favorite_border,
                              size: 13,
                              color: liked ? AppColors.pink : AppColors.textSoft,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${comment['likes']}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: liked ? AppColors.pink : AppColors.textSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Reply',
                        style: AppTextStyles.hint12.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
