import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';
import 'package:artable_app/app/routes/app_routes.dart';
import 'package:artable_app/core/utils/reel_helpers.dart';
import 'package:artable_app/core/widgets/app_network_image.dart';

class CreatorInfoRow extends StatelessWidget {
  const CreatorInfoRow({
    super.key,
    required this.reel,
    this.subtitle,
    this.showFollow = false,
    this.lightText = false,
  });

  final Map<String, dynamic> reel;
  final String? subtitle;
  final bool showFollow;
  final bool lightText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
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
                  backgroundImage: NetworkImage(reel['avatarUrl'] as String),
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
                            reel['handle'] as String? ?? '',
                            style: AppTextStyles.displaySemiBold135.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                              color: lightText ? Colors.white : AppColors.text,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (reel['verified'] == true || reel['isBlueTick'] == true) ...[
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
        if (showFollow) _FollowButton(light: lightText),
      ],
    );
  }
}

class _FollowButton extends StatefulWidget {
  const _FollowButton({required this.light});

  final bool light;

  @override
  State<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<_FollowButton> {
  bool _following = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _following = !_following),
      child: Container(
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
        child: Text(
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
