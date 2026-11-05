import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';
import 'dart:async';

import 'package:artable_app/core/utils/comment_permissions.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:artable_app/features/reels/presentation/bloc/reels_cubit.dart';
import 'package:artable_app/core/widgets/app_network_image.dart';
import 'package:artable_app/core/widgets/app_screen_header.dart';
import 'package:artable_app/features/reels/data/services/reel_bgm_playback_service.dart';
import 'package:artable_app/features/studio/data/services/studio_music_playback_service.dart';

class CommentsScreen extends StatefulWidget {
  const CommentsScreen({super.key, this.reelId});

  final String? reelId;

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final _inputController = TextEditingController();
  final _inputFocus = FocusNode();
  final _scrollController = ScrollController();
  String _sortMode = 'top';
  bool _isSubmitting = false;
  String? _replyParentId;
  String? _replyUsername;
  final Set<String> _expandedReplyParents = <String>{};
  final Set<String> _loadedReplyParents = <String>{};
  final Set<String> _loadingReplyParents = <String>{};

  @override
  void initState() {
    super.initState();
    ReelBgmPlaybackService.silenceForNavigation();
    StudioMusicPlaybackService.directPause();
    unawaited(StudioMusicPlaybackService.stop());
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ReelBgmPlaybackService.silenceForNavigation();
      final reelId = widget.reelId ?? 'r1';
      context.read<ReelsCubit>().fetchComments(reelId);
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels < pos.maxScrollExtent - 240) return;
    final reelId = widget.reelId ?? 'r1';
    final cubit = context.read<ReelsCubit>();
    if (cubit.hasMoreComments(reelId) && !cubit.isLoadingComments(reelId)) {
      unawaited(cubit.loadMoreComments(reelId));
    }
  }

  Future<void> _postComment() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSubmitting) return;

    final reelId = widget.reelId ?? 'r1';
    final parentId = _replyParentId;

    setState(() {
      _isSubmitting = true;
    });

    FocusScope.of(context).unfocus();

    try {
      final success = await context.read<ReelsCubit>().addComment(
            reelId,
            text,
            parentCommentId: parentId,
          );
      if (success) {
        _inputController.clear();
        if (mounted) {
          setState(() {
            if (parentId != null && parentId.trim().isNotEmpty) {
              _expandedReplyParents.add(parentId.trim());
              _loadedReplyParents.add(parentId.trim());
            }
            _replyParentId = null;
            _replyUsername = null;
          });
        }
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

  void _startReply(Map<String, dynamic> comment) {
    final id =
        (comment['id']?.toString() ?? comment['_id']?.toString() ?? '').trim();
    if (id.isEmpty) return;
    final username = comment['username']?.toString() ??
        comment['userName']?.toString() ??
        'User';
    setState(() {
      _replyParentId = id;
      _replyUsername = username;
      final mention = '@$username ';
      if (!_inputController.text.startsWith(mention)) {
        _inputController.text = mention;
        _inputController.selection = TextSelection.collapsed(
          offset: _inputController.text.length,
        );
      }
    });
    _inputFocus.requestFocus();
  }

  Future<void> _toggleLike(Map<String, dynamic> comment) async {
    final id =
        (comment['id']?.toString() ?? comment['_id']?.toString() ?? '').trim();
    if (id.isEmpty) return;
    final reelId = widget.reelId ?? 'r1';
    final ok = await context.read<ReelsCubit>().toggleCommentLike(
          videoId: reelId,
          commentId: id,
        );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update like. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  int _replyCountOf(Map<String, dynamic> c) {
    if (c['replyCount'] is int) return c['replyCount'] as int;
    return int.tryParse(c['replyCount']?.toString() ?? '') ?? 0;
  }

  Future<void> _toggleReplies(Map<String, dynamic> comment) async {
    final parentId = _commentId(comment);
    if (parentId.isEmpty) return;

    if (_expandedReplyParents.contains(parentId)) {
      setState(() => _expandedReplyParents.remove(parentId));
      return;
    }

    if (_loadedReplyParents.contains(parentId)) {
      setState(() => _expandedReplyParents.add(parentId));
      return;
    }

    if (_loadingReplyParents.contains(parentId)) return;

    setState(() => _loadingReplyParents.add(parentId));
    final reelId = widget.reelId ?? 'r1';
    final ok = await context.read<ReelsCubit>().fetchCommentReplies(
          videoId: reelId,
          parentCommentId: parentId,
        );
    if (!mounted) return;
    setState(() {
      _loadingReplyParents.remove(parentId);
      if (ok) {
        _loadedReplyParents.add(parentId);
        _expandedReplyParents.add(parentId);
      }
    });
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not load replies. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  void dispose() {
    // Don't re-lock BGM on pop — feed uncover must be able to resume video.
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _inputController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _loadMoreReplies(String parentId) async {
    if (parentId.isEmpty || _loadingReplyParents.contains(parentId)) return;
    setState(() => _loadingReplyParents.add(parentId));
    final reelId = widget.reelId ?? 'r1';
    final ok = await context.read<ReelsCubit>().loadMoreCommentReplies(
          videoId: reelId,
          parentCommentId: parentId,
        );
    if (!mounted) return;
    setState(() => _loadingReplyParents.remove(parentId));
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not load more replies. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _confirmDeleteComment(Map<String, dynamic> comment) async {
    final cleanId =
        (comment['id']?.toString() ?? comment['_id']?.toString() ?? '').trim();
    if (cleanId.isEmpty) return;
    final reelId = widget.reelId ?? 'r1';
    final reels = context.read<ReelsCubit>();
    if (!reels.canDeleteComment(reelId, comment)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You can only delete your own comments, or comments on your videos.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

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

  String _commentId(Map<String, dynamic> c) =>
      (c['id']?.toString() ?? c['_id']?.toString() ?? '').trim();

  String _parentIdOf(Map<String, dynamic> c) =>
      (c['parentCommentId']?.toString() ??
              c['parent_comment_id']?.toString() ??
              '')
          .trim();

  /// Roots first (sorted), then expanded replies indented underneath.
  List<({Map<String, dynamic> comment, bool isReply, String? loadMoreParentId})>
      _threadedComments(
    List<Map<String, dynamic>> comments, {
    required bool Function(String parentId) hasMoreReplies,
  }) {
    int likesOf(Map<String, dynamic> c) => c['likes'] is int
        ? c['likes'] as int
        : (int.tryParse(c['likes']?.toString() ?? '') ?? 0);
    DateTime dateOf(Map<String, dynamic> c) =>
        DateTime.tryParse(c['createdAt']?.toString() ?? '') ?? DateTime(1970);

    int compare(Map<String, dynamic> a, Map<String, dynamic> b) {
      if (_sortMode == 'recent') return dateOf(b).compareTo(dateOf(a));
      return likesOf(b).compareTo(likesOf(a));
    }

    final roots = <Map<String, dynamic>>[];
    final repliesByParent = <String, List<Map<String, dynamic>>>{};
    for (final c in comments) {
      final parent = _parentIdOf(c);
      if (parent.isEmpty) {
        roots.add(c);
      } else {
        repliesByParent.putIfAbsent(parent, () => []).add(c);
      }
    }
    roots.sort(compare);
    for (final list in repliesByParent.values) {
      list.sort(compare);
    }

    final out =
        <({Map<String, dynamic> comment, bool isReply, String? loadMoreParentId})>[];
    for (final root in roots) {
      out.add((comment: root, isReply: false, loadMoreParentId: null));
      final id = _commentId(root);
      if (!_expandedReplyParents.contains(id)) continue;
      final replies = repliesByParent[id] ?? const [];
      for (final reply in replies) {
        out.add((comment: reply, isReply: true, loadMoreParentId: null));
      }
      if (hasMoreReplies(id)) {
        out.add((
          comment: root,
          isReply: true,
          loadMoreParentId: id,
        ));
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final reelId = widget.reelId ?? 'r1';
    final reelsProvider = context.watch<ReelsCubit>();
    final comments = reelsProvider.getComments(reelId);
    final threaded = _threadedComments(
      comments,
      hasMoreReplies: reelsProvider.hasMoreReplies,
    );
    final totalCount = reelsProvider.getCommentsCount(reelId);
    final countLabel =
        '$totalCount comment${totalCount == 1 ? '' : 's'}';
    final hasMore = reelsProvider.hasMoreComments(reelId);
    final loadingMore = reelsProvider.isLoadingComments(reelId);

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
              child: threaded.isEmpty
                  ? Center(
                      child: Text(
                        'No comments yet. Be the first to comment.',
                        style: AppTextStyles.hint12,
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(22, 6, 22, 12),
                      itemCount: threaded.length + ((hasMore || loadingMore) ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i >= threaded.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: loadingMore
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : TextButton(
                                      onPressed: () => context
                                          .read<ReelsCubit>()
                                          .loadMoreComments(reelId),
                                      child: Text(
                                        'Load more comments',
                                        style: AppTextStyles.hint12.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.purple,
                                        ),
                                      ),
                                    ),
                            ),
                          );
                        }
                        final entry = threaded[i];
                        final loadMoreParentId = entry.loadMoreParentId;
                        if (loadMoreParentId != null) {
                          final loading =
                              _loadingReplyParents.contains(loadMoreParentId) ||
                                  reelsProvider
                                      .isLoadingReplies(loadMoreParentId);
                          return Padding(
                            padding: const EdgeInsets.only(left: 28, bottom: 10),
                            child: GestureDetector(
                              onTap: loading
                                  ? null
                                  : () => unawaited(
                                        _loadMoreReplies(loadMoreParentId),
                                      ),
                              child: Row(
                                children: [
                                  if (loading)
                                    const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.6,
                                      ),
                                    )
                                  else
                                    Icon(
                                      Icons.expand_more_rounded,
                                      size: 16,
                                      color: AppColors.purple
                                          .withValues(alpha: 0.85),
                                    ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Load more replies',
                                    style: AppTextStyles.hint12.copyWith(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.purple,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        final item = entry.comment;
                        final cId = _commentId(item);
                        final auth = context.read<AuthCubit>();
                        final currentUserId = (auth.userId ??
                                auth.state.userId ??
                                auth.state.currentUser['id']?.toString())
                            ?.trim();
                        final canDelete = cId.isNotEmpty &&
                            CommentPermissions.canDeleteComment(
                              currentUserId: currentUserId,
                              comment: item,
                              video: reelsProvider.getVideo(reelId),
                            );
                        final replyCount = _replyCountOf(item);
                        final hasLoadedReplies =
                            _loadedReplyParents.contains(cId);
                        final isExpanded =
                            _expandedReplyParents.contains(cId);
                        final isLoadingReplies =
                            _loadingReplyParents.contains(cId);
                        // Probe once when replyCount is unknown; hide after empty load.
                        final showViewReplies = !entry.isReply &&
                            cId.isNotEmpty &&
                            (isLoadingReplies ||
                                isExpanded ||
                                replyCount > 0 ||
                                !hasLoadedReplies);
                        final repliesLabel = !showViewReplies
                            ? null
                            : (isExpanded
                                ? 'Hide replies'
                                : (replyCount > 0
                                    ? 'View $replyCount ${replyCount == 1 ? 'reply' : 'replies'}'
                                    : 'View replies'));
                        return Padding(
                          padding: EdgeInsets.only(left: entry.isReply ? 28 : 0),
                          child: _CommentItem(
                            comment: item,
                            liked: item['liked'] == true,
                            onLike: () => _toggleLike(item),
                            onReply: () => _startReply(
                              entry.isReply
                                  ? comments.firstWhere(
                                      (c) =>
                                          _commentId(c) == _parentIdOf(item),
                                      orElse: () => item,
                                    )
                                  : item,
                            ),
                            onDelete: canDelete
                                ? () => _confirmDeleteComment(item)
                                : null,
                            repliesLabel: repliesLabel,
                            repliesLoading: isLoadingReplies,
                            onToggleReplies: showViewReplies
                                ? () => _toggleReplies(item)
                                : null,
                          ),
                        );
                      },
                    ),
            ),
            if (_replyUsername != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Replying to @$_replyUsername',
                        style: AppTextStyles.hint12.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.purple,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _replyParentId = null;
                        _replyUsername = null;
                      }),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Cancel',
                        style: AppTextStyles.hint12.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
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
                        focusNode: _inputFocus,
                        enabled: !_isSubmitting,
                        decoration: InputDecoration(
                          filled: false,
                          hintText: _replyUsername != null
                              ? 'Write a reply...'
                              : 'Add a comment...',
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
    required this.onReply,
    this.onDelete,
    this.repliesLabel,
    this.repliesLoading = false,
    this.onToggleReplies,
  });

  final Map<String, dynamic> comment;
  final bool liked;
  final VoidCallback onLike;
  final VoidCallback onReply;
  final VoidCallback? onDelete;
  final String? repliesLabel;
  final bool repliesLoading;
  final VoidCallback? onToggleReplies;

  String _likesLabel(Map<String, dynamic> c) {
    final raw = c['likes'] ?? c['likeCount'] ?? c['likesCount'];
    if (raw is int) return raw.toString();
    final asText = raw?.toString().trim().toLowerCase();
    if (asText == null ||
        asText.isEmpty ||
        asText == 'null' ||
        asText == 'undefined') {
      return '0';
    }
    return (int.tryParse(asText) ?? 0).toString();
  }

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
                    if (comment['isBlueTick'] == true ||
                        comment['is_blue_tick'] == true ||
                        comment['isVerified'] == true ||
                        comment['is_verified'] == true ||
                        (comment['user'] is Map &&
                            ((comment['user'] as Map)['isBlueTick'] == true ||
                             (comment['user'] as Map)['is_blue_tick'] == true ||
                             (comment['user'] as Map)['isVerified'] == true ||
                             (comment['user'] as Map)['is_verified'] == true))) ...[
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
                              _likesLabel(comment),
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
                      onPressed: onReply,
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
                if (repliesLabel != null) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: repliesLoading ? null : onToggleReplies,
                    child: Row(
                      children: [
                        if (repliesLoading)
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 1.6),
                          )
                        else
                          Icon(
                            Icons.subdirectory_arrow_right_rounded,
                            size: 14,
                            color: AppColors.purple.withValues(alpha: 0.85),
                          ),
                        const SizedBox(width: 6),
                        Text(
                          repliesLabel!,
                          style: AppTextStyles.hint12.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.purple,
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
  }
}
