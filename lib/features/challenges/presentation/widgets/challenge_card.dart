import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/app/theme/app_typography.dart';
import 'package:artable_app/core/utils/challenge_helpers.dart';
import 'package:artable_app/core/widgets/network_image_widget.dart';

class ChallengeCard extends StatelessWidget {
  const ChallengeCard({super.key, required this.challenge});

  final Map<String, dynamic> challenge;

  @override
  Widget build(BuildContext context) {
    final status = (challenge['status'] as String? ?? 'active').toLowerCase();
    final rawRating = challenge['rating'] ?? challenge['averageRating'] ?? 0;
    final rating = rawRating is num
        ? rawRating.toDouble()
        : (double.tryParse(rawRating.toString()) ?? 0.0);
    final id = challenge['id'] as String? ?? '';
    final imageUrl = challenge['imageUrl'] as String? ??
        challenge['bannerUrl'] as String? ??
        '';
    final category = challenge['category'] as String? ??
        challenge['categoryName'] as String? ??
        'DANCE';
    final title = challenge['title'] as String? ?? '';
    final rawPrize = challenge['prize'] as String? ?? '₹5,000';
    final prizeLabel = rawPrize.contains('Prize') ? rawPrize : '$rawPrize Prize Pool';
    final participantsCount = challenge['participants'] is int
        ? challenge['participants'] as int
        : (challenge['joinedCount'] is int
            ? challenge['joinedCount'] as int
            : 0);
    final joinedLabel = challenge['joinedLabel'] as String? ??
        '${formatParticipants(participantsCount)} joined';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x0D241E38)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x245E2EAA),
            blurRadius: 36,
            offset: Offset(0, 18),
          ),
          BoxShadow(
            color: Color(0x0D5E2EAA),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: () => context.push('/challenge-detail?id=$id'),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NetworkImageWidget(
                    url: imageUrl,
                    alignment: const Alignment(0, -0.4),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0x3D140A28),
                          Colors.transparent,
                          Colors.transparent,
                          const Color(0x4D0F0820),
                        ],
                        stops: const [0, 0.24, 0.74, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _StatusBadge(status: status),
                  ),
                  if (rating > 0)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _RatingBadge(rating: rating),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(9, 5, 11, 5),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppColors.purple,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        category.toUpperCase(),
                        style: AppTypography.body(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.purple,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => context.push('/challenge-detail?id=$id'),
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.display(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                      height: 1.34,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _StatChip(
                        icon: Icons.emoji_events_outlined,
                        label: prizeLabel,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatChip(
                        icon: Icons.calendar_today_outlined,
                        label: challengeDateLabel(challenge),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.people_outline, size: 14, color: AppColors.purple),
                    const SizedBox(width: 6),
                    Text(
                      joinedLabel,
                      style: AppTypography.body(
                        fontSize: 13,
                        color: AppColors.textSoft,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GradientButton(
                  height: 46,
                  fontSize: 13.5,
                  letterSpacing: 0.3,
                  label: challengeCtaLabel(status),
                  onTap: () => context.push('/challenge-detail?id=$id'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  Color get _dotColor {
    switch (status) {
      case 'active':
        return const Color(0xFF21A573);
      case 'upcoming':
        return const Color(0xFFFF8A3D);
      case 'featured':
        return AppColors.purple;
      default:
        return AppColors.textSoft;
    }
  }

  String get _label {
    switch (status) {
      case 'active':
        return 'Active';
      case 'upcoming':
        return 'Upcoming';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.fromLTRB(9, 0, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F140A28),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: _dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            _label,
            style: AppTypography.body(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F140A28),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 12, color: Color(0xFFFFB13C)),
          const SizedBox(width: 5),
          Text(
            rating.toStringAsFixed(1),
            style: AppTypography.body(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.purple),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    this.onTap,
    this.height = 56,
    this.fontSize = 15,
    this.letterSpacing = 0.8,
    this.icon,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onTap;
  final double height;
  final double fontSize;
  final double letterSpacing;
  final Widget? icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(30),
        child: Ink(
          height: height,
          decoration: BoxDecoration(
            gradient: AppGradients.button,
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(
                color: Color(0x47FF3D77),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.28),
                        Colors.transparent,
                      ],
                      stops: const [0, 0.55],
                    ),
                  ),
                ),
              ),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: AppTypography.display(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: letterSpacing,
                      ),
                    ),
                    if (icon != null) ...[
                      const SizedBox(width: 10),
                      icon!,
                    ],
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
