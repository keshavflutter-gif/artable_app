import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';
import 'package:artable_app/core/network/api_exception.dart';
import 'package:artable_app/core/widgets/app_back_header.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';
import 'package:artable_app/core/widgets/gradient_button.dart';
import 'package:artable_app/data/datasources/mock_data.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:artable_app/features/bonus/data/daily_bonus_rewarded_ad.dart';
import 'package:artable_app/features/bonus/data/models/daily_bonus_calendar_response.dart';
import 'package:artable_app/features/bonus/data/repositories/daily_bonus_repository.dart';
import 'package:artable_app/features/rewards/presentation/bloc/rewards_cubit.dart';

class DailyBonusScreen extends StatefulWidget {
  const DailyBonusScreen({super.key});

  @override
  State<DailyBonusScreen> createState() => _DailyBonusScreenState();
}

class _DailyBonusScreenState extends State<DailyBonusScreen> {
  DailyBonusRepository? _repo;
  DailyBonusCalendarResponse? _bonus;
  bool _loading = true;
  String? _error;
  bool _isClaiming = false;

  bool get _claimedToday => _bonus?.claimedToday ?? false;

  int get _streak => _bonus?.currentStreak ?? 0;

  int get _coins => _bonus?.todayCoins ?? 0;

  DailyBonusRepository _repository() {
    final auth = context.read<AuthCubit>();
    return _repo ??= DailyBonusRepository(
      onTokensRefreshed: auth.applyRefreshedTokens,
      onSessionRefreshFailed: auth.handleSessionRefreshFailed,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_loadCalendar());
    });
  }

  @override
  void dispose() {
    DailyBonusRewardedAd.instance.dispose();
    super.dispose();
  }

  Future<void> _loadCalendar({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final auth = context.read<AuthCubit>();
      final res = await _repository().getCalendar(
        sessionToken: auth.sessionToken,
        refreshToken: auth.refreshToken,
      );
      if (!mounted) return;
      setState(() {
        _bonus = res;
        _loading = false;
        _error = null;
      });
      if (!res.claimedToday) {
        unawaited(DailyBonusRewardedAd.instance.load());
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load daily bonus.';
      });
    }
  }

  Future<void> _onClaimTap() async {
    if (_claimedToday || _isClaiming) return;
    setState(() => _isClaiming = true);

    final earned = await DailyBonusRewardedAd.instance.show();
    if (!mounted) return;

    if (!earned) {
      setState(() => _isClaiming = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Watch the ad to claim your daily bonus.'),
        ),
      );
      return;
    }

    try {
      final auth = context.read<AuthCubit>();
      final streakDay = _streak > 0 ? _streak + (_claimedToday ? 0 : 1) : 1;
      final coins = _coins > 0 ? _coins : 10;
      final claim = await _repository().claim(
        coins: coins,
        points: coins,
        streakDay: streakDay,
        sessionToken: auth.sessionToken,
        refreshToken: auth.refreshToken,
      );
      if (!mounted) return;

      if (claim.success) {
        try {
          context.read<RewardsCubit>().claimDailyBonus(
            claim.coins > 0 ? claim.coins : coins,
          );
        } catch (_) {}
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            claim.message.isNotEmpty
                ? claim.message
                : (claim.success
                      ? 'Daily bonus claimed successfully'
                      : 'Unable to claim daily bonus.'),
          ),
        ),
      );
      await _loadCalendar(showLoader: false);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to claim daily bonus.')),
      );
    } finally {
      if (mounted) setState(() => _isClaiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayLabel = _bonus?.todayLabel ?? '';
    final coinsLabel = _coins > 0 ? '$_coins Coins' : '';
    final subtitle = [
      if (todayLabel.isNotEmpty) todayLabel,
      if (coinsLabel.isNotEmpty) coinsLabel,
    ].join(' · ');
    final next = _bonus?.nextMilestone;
    final week = _bonus?.weekDays ?? const [];
    final milestones = _bonus?.milestones ?? const [];

    return AppScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppBackHeader(title: 'Daily Bonus'),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _bonus == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _loadCalendar,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadCalendar,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
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
                                  const Icon(
                                    Icons.stars,
                                    size: 48,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '$_streak-Day Streak',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (subtitle.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      subtitle,
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: (_claimedToday || _isClaiming)
                                        ? null
                                        : _onClaimTap,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: AppColors.purple,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                    ),
                                    child: Text(
                                      _claimedToday
                                          ? 'Claimed Today'
                                          : (_isClaiming
                                                ? 'Loading Ad…'
                                                : 'Claim Daily Bonus'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (next != null) ...[
                              const SizedBox(height: 24),
                              Text(
                                'Next Milestone',
                                style: AppTextStyles.sectionTitle,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.inputBg,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.emoji_events,
                                      color: AppColors.purple,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            next.title.isNotEmpty
                                                ? next.title
                                                : '${next.day}-Day Milestone',
                                            style: AppTextStyles.body.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          if (next.reward.isNotEmpty)
                                            Text(
                                              next.reward,
                                              style: AppTextStyles.bodySoft
                                                  .copyWith(fontSize: 12),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (week.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              Text(
                                'Weekly Calendar',
                                style: AppTextStyles.sectionTitle,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: week.map((day) {
                                  final done =
                                      day.claimed ||
                                      (_streak > 0 && day.day <= _streak);
                                  return Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: done
                                            ? AppColors.purple
                                            : AppColors.inputBg,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            'D${day.day}',
                                            style: TextStyle(
                                              color: done
                                                  ? Colors.white
                                                  : AppColors.text,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 11,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Icon(
                                            Icons.star,
                                            size: 14,
                                            color: done
                                                ? Colors.white
                                                : AppColors.textFaint,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                            if (milestones.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              Text(
                                'Streak Milestones',
                                style: AppTextStyles.sectionTitle,
                              ),
                              const SizedBox(height: 8),
                              ...milestones.map((m) {
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(
                                    m.unlocked
                                        ? Icons.check_circle
                                        : Icons.lock_outline,
                                    color: m.unlocked
                                        ? AppColors.success
                                        : AppColors.textFaint,
                                  ),
                                  title: Text(
                                    m.title.isNotEmpty
                                        ? m.title
                                        : '${m.day}-Day Streak',
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: m.reward.isNotEmpty
                                      ? Text(
                                          m.reward,
                                          style: AppTextStyles.bodySoft
                                              .copyWith(fontSize: 12),
                                        )
                                      : null,
                                );
                              }),
                            ],
                          ],
                        ),
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
                    Text(
                      '$effectiveStreak / $totalDays days ($pct%)',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: pct / 100,
                      color: AppColors.purple,
                      backgroundColor: AppColors.inputBg,
                    ),
                    const SizedBox(height: 20),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
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
                            color: isToday
                                ? AppColors.purple
                                : isClaimed
                                ? AppColors.success.withValues(alpha: 0.15)
                                : AppColors.inputBg,
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
