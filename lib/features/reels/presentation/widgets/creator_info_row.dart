import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';
import 'package:artable_app/app/routes/app_routes.dart';
import 'package:artable_app/core/utils/mock_helpers.dart';
import 'package:artable_app/core/utils/reel_helpers.dart';
import 'package:artable_app/core/widgets/app_network_image.dart';

class CreatorInfoRow extends StatelessWidget {
  const CreatorInfoRow({
    super.key,
    required this.reel,
    this.subtitle,
    this.showFollow = false,
    this.lightText = false,
    this.onTapProfile,
  });

  final Map<String, dynamic> reel;
  final String? subtitle;
  final bool showFollow;
  final bool lightText;
  final VoidCallback? onTapProfile;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = (reel['avatarUrl'] as String?)?.trim() ??
        (reel['profilePhotoUrl'] as String?)?.trim() ??
        (reel['profile_photo_url'] as String?)?.trim() ??
        (reel['user'] is Map ? (reel['user']['profilePhotoUrl']?.toString() ?? reel['user']['avatarUrl']?.toString()) : null) ??
        '';

    final handle = (reel['handle'] as String?)?.trim() ??
        (reel['username'] as String?)?.trim() ??
        (reel['user'] is Map ? reel['user']['username']?.toString() : null) ??
        '';

    final displayHandle = handle.isNotEmpty
        ? (handle.startsWith('@') ? handle : '@$handle')
        : ((reel['creator'] as String?)?.trim() ?? '@user');

    final isVerified = reel['verified'] == true ||
        reel['isBlueTick'] == true ||
        reel['is_blue_tick'] == true ||
        reel['isVerified'] == true ||
        reel['is_verified'] == true ||
        reel['isBlueTick']?.toString() == 'true' ||
        reel['isVerified']?.toString() == 'true' ||
        (reel['user'] is Map &&
            ((reel['user'] as Map)['isBlueTick'] == true ||
             (reel['user'] as Map)['is_blue_tick'] == true ||
             (reel['user'] as Map)['isVerified'] == true ||
             (reel['user'] as Map)['is_verified'] == true ||
             (reel['user'] as Map)['isBlueTick']?.toString() == 'true' ||
             (reel['user'] as Map)['isVerified']?.toString() == 'true'));

    void navigateToProfile() {
      if (onTapProfile != null) {
        onTapProfile!();
        return;
      }
      String? targetUserId = reel['userId']?.toString() ??
          reel['user_id']?.toString() ??
          reel['creatorId']?.toString() ??
          (reel['creator'] is Map ? (reel['creator'] as Map)['id']?.toString() : null) ??
          (reel['user'] is Map ? (reel['user'] as Map)['id']?.toString() : null);

      if ((targetUserId == null || targetUserId.isEmpty) && displayHandle.isNotEmpty) {
        final mockCreator = MockHelpers.creatorByHandle(displayHandle);
        if (mockCreator != null) {
          targetUserId = mockCreator['id']?.toString();
        }
      }

      if (targetUserId != null && targetUserId.isNotEmpty) {
        context.push('${AppRoutes.publicProfile}?id=$targetUserId');
      }
    }

    final authCubit = context.watch<AuthCubit>();
    final authState = authCubit.state;
    final currentUserId = (authState.userId ?? authCubit.userId ?? authState.currentUser['id']?.toString())?.trim();
    final currentUsername = authCubit.username.isNotEmpty
        ? authCubit.username.trim().replaceAll('@', '')
        : (authState.currentUser['username']?.toString() ?? '').trim().replaceAll('@', '');

    final reelUserId = (reel['userId']?.toString() ??
        reel['user_id']?.toString() ??
        reel['creatorId']?.toString() ??
        (reel['user'] is Map ? (reel['user'] as Map)['id']?.toString() : null))?.trim();

    final reelUsername = ((reel['handle'] as String?)?.trim() ??
        (reel['username'] as String?)?.trim() ??
        (reel['user'] is Map ? (reel['user'] as Map)['username']?.toString() : null))?.trim().replaceAll('@', '');

    final bool isSelf = (currentUserId != null && currentUserId.isNotEmpty && reelUserId != null && reelUserId.isNotEmpty && currentUserId == reelUserId) ||
        (currentUsername.isNotEmpty && reelUsername != null && reelUsername.isNotEmpty && currentUsername.toLowerCase() == reelUsername.toLowerCase());

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: navigateToProfile,
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: lightText
                          ? Colors.white.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white24,
                    backgroundImage: avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl.isEmpty
                        ? const Icon(Icons.person, size: 18, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              displayHandle,
                              style: AppTextStyles.displaySemiBold135.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                                color: lightText ? Colors.white : AppColors.text,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, size: 14, color: Color(0xFF3B9DFF)),
                          ],
                        ],
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 11,
                            color: lightText
                                ? Colors.white.withValues(alpha: 0.75)
                                : AppColors.textSoft,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showFollow && !isSelf)
          _FollowButton(
            light: lightText,
            profileId: reelUserId,
            initialFollowing: reel['isFollowing'] == true ||
                reel['is_following'] == true ||
                reel['following'] == true ||
                (reel['user'] is Map &&
                    ((reel['user'] as Map)['isFollowing'] == true ||
                        (reel['user'] as Map)['is_following'] == true ||
                        (reel['user'] as Map)['following'] == true)),
          ),
      ],
    );
  }
}

class _FollowButton extends StatefulWidget {
  const _FollowButton({
    required this.light,
    this.profileId,
    this.initialFollowing = false,
  });

  final bool light;
  final String? profileId;
  final bool initialFollowing;

  @override
  State<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<_FollowButton> {
  late bool _following;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _following = widget.initialFollowing;
  }

  @override
  void didUpdateWidget(covariant _FollowButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFollowing != widget.initialFollowing) {
      _following = widget.initialFollowing;
    }
  }

  Future<void> _toggleFollow() async {
    final pId = widget.profileId?.trim();
    if (_isLoading) return;
    if (pId == null || pId.isEmpty) {
      setState(() => _following = !_following);
      return;
    }

    final previous = _following;
    setState(() {
      _isLoading = true;
      _following = !_following;
    });

    try {
      final response = await context.read<AuthCubit>().toggleFollow(pId);
      if (mounted) {
        setState(() {
          _following = response.following;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _following = previous;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${e.toString().replaceAll('Exception: ', '')}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleFollow,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          gradient: _following ? null : AppGradients.button,
          color: _following ? Colors.white.withValues(alpha: 0.16) : null,
          borderRadius: BorderRadius.circular(999),
          border: _following
              ? Border.all(color: Colors.white.withValues(alpha: 0.35))
              : null,
          boxShadow: _following
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFFFF3D77).withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: _isLoading
            ? const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                _following ? 'Following' : 'Follow',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

class ReelThumb extends StatelessWidget {
  const ReelThumb({super.key, required this.reel});

  final Map<String, dynamic> reel;

  @override
  Widget build(BuildContext context) {
    final category = reel['category'] as String? ?? '';
    return GestureDetector(
      onTap: () => context.push('${AppRoutes.videoDetail}?id=${reel['id']}'),
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AppNetworkImage(
                    url: reel['imageUrl'] as String,
                    width: 140,
                    height: 200,
                    alt: reel['title'] as String? ?? '',
                  ),
                ),
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ReelHelpers.categoryTint(category),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      category.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundImage: NetworkImage(reel['avatarUrl'] as String),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    reel['handle'] as String? ?? '',
                    style: AppTextStyles.hint12.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (reel['verified'] == true)
                  const Icon(Icons.verified, size: 13, color: Color(0xFF3B9DFF)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
