import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';
import 'package:artable_app/core/widgets/app_back_header.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';
import 'package:artable_app/core/widgets/gradient_button.dart';
import 'package:artable_app/data/datasources/mock_data.dart';

class DailyBonusScreen extends StatefulWidget {
  const DailyBonusScreen({super.key});

  @override
  State<DailyBonusScreen> createState() => _DailyBonusScreenState();
}

class _DailyBonusScreenState extends State<DailyBonusScreen> {
  late Map<String, dynamic> _bonus;
  late bool _claimedToday;
  late int _effectiveStreak;

  @override
  void initState() {
    super.initState();
    _bonus = Map<String, dynamic>.from(MockData.DAILY_BONUS);
    _claimedToday = _bonus['claimedToday'] as bool? ?? false;
    final streak = _bonus['currentStreak'] as int? ?? 5;
    _effectiveStreak = streak + (_claimedToday ? 1 : 0);
  }

  void _claim() {
    if (_claimedToday) return;
    setState(() {
      _claimedToday = true;
      _effectiveStreak++;
      _bonus['claimedToday'] = true;
      _bonus['currentStreak'] = _effectiveStreak;
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = _bonus['todayReward'] is Map<String, dynamic>
        ? _bonus['todayReward'] as Map<String, dynamic>
        : <String, dynamic>{};
    final next = _bonus['nextMilestone'] is Map<String, dynamic>
        ? _bonus['nextMilestone'] as Map<String, dynamic>
        : <String, dynamic>{};
    final weekly = _bonus['weeklyRewards'] is List
        ? _bonus['weeklyRewards'] as List
        : const [];
    final milestones = _bonus['milestones'] is List
        ? _bonus['milestones'] as List
        : const [];

    final todayLabel = (today['label'] ?? today['title'] ?? 'Day $_effectiveStreak Reward').toString();
    final todayAmount = (today['amount'] ?? '').toString();
    final nextDays = (next['day'] ?? next['days'] ?? 7).toString();
    final nextReward = (next['reward'] ?? 'Bonus Coins').toString();

    return AppScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppBackHeader(title: 'Daily Bonus'),
          Expanded(
            child: SingleChildScrollView(
              child: AppContent(
                noBottomPad: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppGradients.button,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.stars, size: 48, color: Colors.white),
                          const SizedBox(height: 12),
                          Text('$_effectiveStreak-Day Streak', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text('$todayLabel${todayAmount.isNotEmpty ? ' · $todayAmount' : ''}', style: TextStyle(color: Colors.white.withValues(alpha: 0.9))),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _claimedToday ? null : _claim,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.purple,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: Text(_claimedToday ? 'Claimed Today' : 'Claim Daily Bonus'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Next Milestone', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.inputBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.emoji_events, color: AppColors.purple),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('$nextDays-Day Milestone', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                                Text(nextReward, style: AppTextStyles.bodySoft.copyWith(fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Weekly Calendar', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 8),
                    Row(
                      children: weekly.map((w) {
                        final map = w as Map<String, dynamic>;
                        final d = map['day'] as int? ?? 1;
                        final done = d <= _effectiveStreak;
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: done ? AppColors.purple : AppColors.inputBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Text('D$d', style: TextStyle(color: done ? Colors.white : AppColors.text, fontWeight: FontWeight.w700, fontSize: 11)),
                                const SizedBox(height: 4),
                                Icon(Icons.star, size: 14, color: done ? Colors.white : AppColors.textFaint),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Text('Streak Milestones', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 8),
                    ...milestones.map((m) {
                      final map = m as Map<String, dynamic>;
                      final days = map['days'] as int? ?? (map['day'] as int? ?? 0);
                      final rewardStr = (map['reward'] ?? '').toString();
                      final achieved = _effectiveStreak >= days;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          achieved ? Icons.check_circle : Icons.lock_outline,
                          color: achieved ? AppColors.success : AppColors.textFaint,
                        ),
                        title: Text('$days-Day Streak', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                        subtitle: Text(rewardStr, style: AppTextStyles.bodySoft.copyWith(fontSize: 12)),
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

class RewardCalendarScreen extends StatelessWidget {
  const RewardCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final d = MockData.DAILY_BONUS;
    final streak = (d['currentStreak'] as int? ?? 5);
    final claimed = (d['claimedToday'] as bool? ?? false);
    final effectiveStreak = streak + (claimed ? 1 : 0);
    final totalDays = (d['totalDays'] as int? ?? 30);
    final pct = (effectiveStreak / totalDays * 100).clamp(0, 100).round();

    return AppScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppBackHeader(title: 'Reward Calendar'),
          Expanded(
            child: SingleChildScrollView(
              child: AppContent(
                noBottomPad: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$effectiveStreak / $totalDays days ($pct%)', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: pct / 100, color: AppColors.purple, backgroundColor: AppColors.inputBg),
                    const SizedBox(height: 20),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                      ),
                      itemCount: totalDays,
                      itemBuilder: (_, i) {
                        final day = i + 1;
                        final isClaimed = day < effectiveStreak;
                        final isToday = day == effectiveStreak;
                        return Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isToday ? AppColors.purple : isClaimed ? AppColors.success.withValues(alpha: 0.15) : AppColors.inputBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              color: isToday ? Colors.white : AppColors.text,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    GradientButton(
                      label: claimed ? 'View Bonus' : 'Claim Today',
                      onPressed: () => context.push('/daily-bonus'),
                    ),
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
