import 'package:flutter/material.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';
import 'package:artable_app/core/widgets/app_back_header.dart';
import 'package:artable_app/core/widgets/app_image.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';
import 'package:artable_app/core/widgets/filter_pills.dart';
import 'package:artable_app/data/datasources/mock_data.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const _filters = ['All', 'Challenges', 'Rewards', 'Winners', 'Social', 'Referrals'];
  var _filter = 'All';
  late List<Map<String, dynamic>> _items;

  @override
  void initState() {
    super.initState();
    _items = MockData.NOTIFICATIONS.map((n) => Map<String, dynamic>.from(n)).toList();
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'All') return _items;
    return _items.where((n) {
      final cat = (n['category'] as String);
      return _filter.toLowerCase() == cat ||
          (_filter == 'Challenges' && cat == 'challenges');
    }).toList();
  }

  void _markAllRead() {
    setState(() {
      for (final n in _items) {
        n['read'] = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return AppScreen(
      child: Column(
        children: [
          AppBackHeader(
            title: 'Notifications',
            trailing: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _markAllRead,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Mark all',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.purple,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
          FilterPills(items: _filters, selected: _filter, onSelected: (f) => setState(() => _filter = f)),
          Expanded(
            child: list.isEmpty
                ? const EmptyNote(message: 'No notifications here yet.')
                : ListView.builder(
                    padding: const EdgeInsets.all(22),
                    itemCount: list.length,
                    itemBuilder: (_, i) => _NotificationTile(n: list[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.n});

  final Map<String, dynamic> n;

  IconData _getIcon(String? iconKey, String? category) {
    switch (iconKey) {
      case 'trophy':
        return Icons.emoji_events_outlined;
      case 'cash':
      case 'wallet':
        return Icons.account_balance_wallet_outlined;
      case 'gift':
        return Icons.card_giftcard_outlined;
      case 'heartFilled':
        return Icons.favorite_border;
      case 'comment':
        return Icons.chat_bubble_outline;
      case 'follow':
        return Icons.person_add_outlined;
      default:
        if (category == 'challenges' || category == 'winners') {
          return Icons.emoji_events_outlined;
        } else if (category == 'rewards') {
          return Icons.account_balance_wallet_outlined;
        }
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final read = n['read'] as bool? ?? true;
    final avatarId = n['avatarId'] as String?;
    Map<String, dynamic>? user;
    if (avatarId != null) {
      user = MockData.CREATORS.cast<Map<String, dynamic>?>().firstWhere(
        (u) => u!['id'] == avatarId,
        orElse: () => null,
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: read ? Colors.white : AppColors.inputBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (user != null)
            AppImage(url: user['avatarUrl'] as String, width: 40, height: 40, borderRadius: BorderRadius.circular(20))
          else
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: AppColors.purple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(_getIcon(n['icon'] as String?, n['category'] as String?), color: AppColors.purple, size: 20),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n['title'] as String, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700, fontSize: 13)),
                Text(n['description'] as String, style: AppTextStyles.bodySoft.copyWith(fontSize: 12)),
                Text(n['time'] as String, style: AppTextStyles.bodySoft.copyWith(fontSize: 10)),
              ],
            ),
          ),
          if (!read)
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.pink, shape: BoxShape.circle)),
        ],
      ),
    );
  }
}

class ActivityCenterScreen extends StatelessWidget {
  const ActivityCenterScreen({super.key, this.showBackButton = true});

  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final s = MockData.ACTIVITY_SUMMARY;

    return AppScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showBackButton)
            const AppBackHeader(title: 'Activity Center')
          else
            Padding(
              padding: EdgeInsets.fromLTRB(
                22,
                MediaQuery.paddingOf(context).top + 20,
                22,
                6,
              ),
              child: Text(
                'Activity Center',
                style: AppTextStyles.displayBold.copyWith(fontSize: 17.5),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: showBackButton ? 22 : 86),
              child: AppContent(
                noBottomPad: true,
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _ActivityStat(value: '${s['likes']}', label: 'Likes'),
                      _ActivityStat(value: '${s['comments']}', label: 'Comments'),
                      _ActivityStat(value: '${s['ratings']}', label: 'Ratings'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _ActivityStat(value: '${s['entries']}', label: 'Entries'),
                      _ActivityStat(value: s['rewardsEarned'] as String, label: 'Earned'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Recent Activity', style: AppTextStyles.sectionTitle),
                  ...MockData.ACTIVITY_LOG.map((a) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(a['text'] as String, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700, fontSize: 13)),
                      subtitle: Text('${a['related']} · ${a['time']}', style: AppTextStyles.bodySoft.copyWith(fontSize: 11)),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
}

class _ActivityStat extends StatelessWidget {
  const _ActivityStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.inputBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(value, style: AppTextStyles.displayBold.copyWith(fontSize: 16)),
            Text(label, style: AppTextStyles.bodySoft.copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
