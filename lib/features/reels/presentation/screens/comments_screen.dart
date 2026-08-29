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
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reelId = widget.reelId ?? 'r1';
      context.read<ReelsCubit>().fetchComments(reelId);
    });
  }

  Future<void> _postComment() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSubmitting) return;

    final reelId = widget.reelId ?? 'r1';

    setState(() {
      _isSubmitting = true;
    });

    FocusScope.of(context).unfocus();

    try {
      final success = await context.read<ReelsCubit>().addComment(reelId, text);
      if (success) {
        _inputController.clear();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to post comment. Please try again.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _confirmDeleteComment(String commentId) async {
    final cleanId = commentId.trim();
    if (cleanId.isEmpty) return;
    final reelId = widget.reelId ?? 'r1';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: Color(0xFFECE8F5), width: 1.5),
        ),
        backgroundColor: Colors.white,
        elevation: 20,
        shadowColor: const Color(0xFF5E2EAA).withValues(alpha: 0.15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3EAFD),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFF8B3DFF),
                  size: 34,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Delete Comment?',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF241E38),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Are you sure you want to delete this comment? This action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12.5,
                    color: Color(0xFF7A7090),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 26),
              Container(
                height: 50,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: AppGradients.button,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5487).withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.of(ctx).pop(true),
                    borderRadius: BorderRadius.circular(25),
                    child: const Center(
                      child: Text(
                        'Delete Comment',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 50,
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFECE8F5), width: 1.5),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Color(0xFF7A7090),
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true && mounted) {
      final success = await context.read<ReelsCubit>().deleteComment(
            videoId: reelId,
            commentId: cleanId,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Comment deleted successfully' : 'Failed to delete comment'),
            backgroundColor: success ? const Color(0xFF8B3DFF) : Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reelId = widget.reelId ?? 'r1';
    final reelsProvider = context.watch<ReelsCubit>();
    final comments = reelsProvider.getComments(reelId);
    final countLabel =
        '${comments.length} comment${comments.length == 1 ? '' : 's'}';

    final List<Map<String, dynamic>> displayedComments = List.from(comments);
    if (_sortMode == 'recent') {
      displayedComments.sort((a, b) {
        final aDate = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime(1970);
        final bDate = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });
    } else if (_sortMode == 'top') {
      displayedComments.sort((a, b) {
        final aLikes = a['likes'] is int ? a['likes'] as int : (int.tryParse(a['likes']?.toString() ?? '') ?? 0);
        final bLikes = b['likes'] is int ? b['likes'] as int : (int.tryParse(b['likes']?.toString() ?? '') ?? 0);
        return bLikes.compareTo(aLikes);
      });
    }

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
              child: displayedComments.isEmpty
                  ? Center(
                      child: Text(
                        'No comments yet. Be the first to comment.',
                        style: AppTextStyles.hint12,
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(22, 6, 22, 12),
                      itemCount: displayedComments.length,
                      itemBuilder: (context, i) {
                        final item = displayedComments[i];
                        final cId = item['id']?.toString() ?? item['_id']?.toString() ?? '';
                        return _CommentItem(
                          comment: item,
                          liked: false,
                          onLike: () {},
                          onDelete: cId.isNotEmpty ? () => _confirmDeleteComment(cId) : null,
                        );
                      },
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
                        enabled: !_isSubmitting,
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
                    onTap: _isSubmitting ? null : _postComment,
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
                      child: _isSubmitting
                          ? const Padding(
                              padding: EdgeInsets.all(11.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send, size: 17, color: Colors.white),
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
    this.onDelete,
  });

  final Map<String, dynamic> comment;
  final bool liked;
  final VoidCallback onLike;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final avatar = comment['avatarUrl']?.toString() ??
        comment['userAvatar']?.toString() ??
        (comment['user'] is Map ? comment['user']['avatarUrl']?.toString() : null) ??
        '';

    final username = comment['username']?.toString() ??
        comment['userName']?.toString() ??
        (comment['user'] is Map
            ? (comment['user']['fullName']?.toString() ??
                comment['user']['username']?.toString())
            : null) ??
        'User';

    final time = comment['time']?.toString() ??
        comment['timeAgo']?.toString() ??
        comment['createdAt']?.toString() ??
        'Just now';

    final text = comment['text']?.toString() ??
        comment['content']?.toString() ??
        '';

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
              url: avatar,
              width: 40,
              height: 40,
              alt: username,
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
                      username,
                      style: AppTextStyles.displaySemiBold135.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppColors.text,
                      ),
                    ),
                    if (comment['isBlueTick'] == true || (comment['user'] is Map && comment['user']['isBlueTick'] == true)) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified,
                        size: 13,
                        color: Color(0xFF2E90FA),
                      ),
                    ],
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
                      time,
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
                  text,
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
                    if (onDelete != null) ...[
                      const Spacer(),
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                          color: Color(0xFFB7B1C6),
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Delete comment',
                      ),
                    ],
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
