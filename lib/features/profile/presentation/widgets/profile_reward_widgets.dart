import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';
import 'package:artable_app/core/utils/format_utils.dart';
import 'package:artable_app/core/widgets/app_image.dart';

class ProfileCoverHeader extends StatelessWidget {
  const ProfileCoverHeader({
    super.key,
    required this.coverUrl,
    required this.avatarUrl,
    this.showBackButton = false,
  });

  final String coverUrl;
  final String avatarUrl;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150 + 46,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            height: 150,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppImage(url: coverUrl, fit: BoxFit.cover),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0x0D0A0514),
                        const Color(0x590A0514),
                      ],
                    ),
                  ),
                ),
                if (showBackButton)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: SafeArea(
                      bottom: false,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _CoverBackButton(onTap: () => context.pop()),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 150 - 46,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x3315083C),
                      blurRadius: 26,
                      offset: const Offset(0, 12),
                    ),
                  ],
                  border: Border.all(color: Colors.white, width: 5),
                ),
                child: AppImage(
                  url: avatarUrl,
                  width: 92,
                  height: 92,
                  borderRadius: BorderRadius.circular(46),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverBackButton extends StatelessWidget {
  const _CoverBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.inputBorder, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D5E2EAA),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.chevron_left, size: 18),
      ),
    );
  }
}

class ProfileStatsGrid extends StatelessWidget {
  const ProfileStatsGrid({
    super.key,
    required this.videos,
    required this.likes,
    required this.talentScore,
    required this.challengesWon,
  });

  final dynamic videos;
  final dynamic likes;
  final dynamic talentScore;
  final dynamic challengesWon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(value: '$videos', label: 'VIDEOS'),
        const SizedBox(width: 6),
        _StatCard(value: '$likes', label: 'LIKES'),
        const SizedBox(width: 6),
        _StatCard(value: '$talentScore', label: 'TALENT SCORE'),
        const SizedBox(width: 6),
        _StatCard(value: '$challengesWon', label: 'WON'),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.inputBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0x145E2EAA),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textSoft,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoGridCard extends StatelessWidget {
  const VideoGridCard({super.key, required this.video});

  final Map<String, dynamic> video;

  @override
  Widget build(BuildContext context) {
    final status = video['status'] as String?;
    return GestureDetector(
      onTap: () {
        if (video['draftId'] != null) {
          context.push('/studio-drafts');
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 0.75,
              child: AppImage(
                url: video['thumbnailUrl'] as String,
                fit: BoxFit.cover,
              ),
            ),
            if (status != null && status != 'live')
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.replaceAll('_', ' '),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video['challengeTitle'] as String? ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  if (video['views'] != '—')
                    Text(
                      '${video['views']} views',
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
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

class BadgeCard extends StatelessWidget {
  const BadgeCard({super.key, required this.badge});

  final Map<String, dynamic> badge;

  IconData _getIcon(String icon) {
    switch (icon) {
      case 'upload':
        return Icons.upload_rounded;
      case 'flame':
        return Icons.local_fire_department_rounded;
      case 'trophy':
        return Icons.emoji_events_rounded;
      case 'medal':
        return Icons.verified_rounded;
      case 'crown':
        return Icons.workspace_premium_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'chart':
        return Icons.bar_chart_rounded;
      case 'video':
        return Icons.videocam_rounded;
      default:
        return Icons.workspace_premium_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEarned = badge['earned'] == true;
    final iconName = badge['icon'] as String? ?? 'medal';

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFECE8F5),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C15083C),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isEarned
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFF4860),
                        Color(0xFF8B2BE2),
                      ],
                    )
                  : null,
              color: isEarned ? null : const Color(0xFFF6F3FC),
              border: isEarned
                  ? null
                  : Border.all(
                      color: const Color(0xFFECE8F5),
                      width: 1,
                    ),
              boxShadow: isEarned
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFF3868).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              isEarned ? _getIcon(iconName) : Icons.lock_outline_rounded,
              size: isEarned ? 20 : 17,
              color: isEarned ? Colors.white : const Color(0xFFB7B1C6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            badge['name'] as String,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class RewardCard extends StatelessWidget {
  const RewardCard({super.key, required this.reward});

  final Map<String, dynamic> reward;

  Color get _typeColor {
    final t = (reward['type'] as String? ?? 'cash').toLowerCase();
    switch (t) {
      case 'voucher':
      case 'vouchers':
        return AppColors.blue;
      case 'product':
      case 'products':
        return AppColors.orange;
      case 'sponsor':
        return AppColors.pink;
      default:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = (reward['status'] as String? ?? 'available').toLowerCase();
    final isClaimed = status == 'claimed' || reward['isClaimed'] == true;
    final isAvailable = (status == 'available' || reward['isAvailable'] == true) && !isClaimed;
    final locked = status == 'locked' || (!isClaimed && !isAvailable);
    final typeStr = reward['type'] as String? ?? 'cash';
    final actionLabel = isClaimed
        ? 'View ›'
        : isAvailable
            ? 'Claim ›'
            : 'Locked ›';

    return GestureDetector(
      onTap: () => context.push('/reward-detail?id=${reward['id']}'),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0x145E2EAA),
            width: 1,
          ),
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C15083C),
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AppImage(
                  url: reward['imageUrl'] as String? ?? '',
                  height: 105,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _StatusBadge(status: status),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: _typeColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      typeStr.toUpperCase(),
                      style: TextStyle(
                        color: _typeColor,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    height: 32,
                    child: Text(
                      reward['title'] as String? ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: AppColors.text,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          reward['value'] as String? ?? '₹0',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: locked
                              ? null
                              : const LinearGradient(
                                  colors: [Color(0xFFFF5487), Color(0xFF9652FF)],
                                ),
                          color: locked ? AppColors.inputBg : null,
                        ),
                        child: Text(
                          actionLabel,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: locked ? AppColors.textSoft : Colors.white,
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
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    if (s == 'claimed') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: const Color(0xFF00C897),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'CLAIMED',
          style: TextStyle(
            fontFamily: 'Inter',
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.3,
          ),
        ),
      );
    }
    if (s == 'locked') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: const Color(0xCC4A4B57),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'LOCKED',
          style: TextStyle(
            fontFamily: 'Inter',
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.3,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF3D77), Color(0xFF8B3DFF)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'AVAILABLE',
        style: TextStyle(
          fontFamily: 'Inter',
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class TransactionRow extends StatelessWidget {
  const TransactionRow({
    super.key,
    required this.tx,
    this.onTap,
  });

  final Map<String, dynamic> tx;
  final VoidCallback? onTap;

  IconData _iconForCategory(String cat) {
    switch (cat) {
      case 'challenge_win':
        return Icons.emoji_events_rounded;
      case 'referral':
        return Icons.person_add_outlined;
      case 'daily_bonus':
        return Icons.calendar_today_rounded;
      case 'withdrawal':
        return Icons.account_balance_rounded;
      case 'voucher':
        return Icons.confirmation_number_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = tx['type'] as String? ?? 'credit';
    final isCredit = type == 'credit';
    final statusStr = (tx['status'] as String? ?? 'completed').toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0x145E2EAA),
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A15083C),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F0FE),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconForCategory(tx['category'] as String? ?? ''),
                  size: 17,
                  color: AppColors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx['title'] as String? ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      FormatUtils.formatDateTime(tx['date'] as String? ?? ''),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSoft,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    tx['amount'] as String? ?? '',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: isCredit ? const Color(0xFF00C897) : AppColors.pink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: isCredit
                          ? const Color(0xFFE6F8F3)
                          : const Color(0xFFFFF0F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      statusStr,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                        color: isCredit
                            ? const Color(0xFF00C897)
                            : AppColors.pink,
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

class WinnerCard extends StatelessWidget {
  const WinnerCard({super.key, required this.winner});

  final Map<String, dynamic> winner;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/winner-detail?id=${winner['id']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: winner['rank'] == 1 ? AppGradients.button : null,
                color: winner['rank'] == 1 ? null : AppColors.inputBg,
                shape: BoxShape.circle,
              ),
              child: Text(
                '#${winner['rank']}',
                style: AppTextStyles.displayBold.copyWith(
                  fontSize: 12,
                  color: winner['rank'] == 1 ? Colors.white : AppColors.text,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Challenge ${winner['challengeId']}',
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  Text(
                    winner['prize'] as String,
                    style: AppTextStyles.bodySoft.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: AppColors.orange),
                    Text(
                      (winner['talentScore'] as num).toStringAsFixed(1),
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                Text(
                  FormatUtils.formatDate(winner['winDate'] as String),
                  style: AppTextStyles.bodySoft.copyWith(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
