import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:artable_app/core/widgets/app_back_header.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';
import 'package:artable_app/core/widgets/gradient_switch.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:artable_app/features/settings/data/repositories/settings_repository.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  var _settings = <Map<String, dynamic>>[];
  var _masterOn = true;
  var _loading = true;
  SettingsRepository? _repo;

  SettingsRepository _repository() {
    final auth = context.read<AuthCubit>();
    return _repo ??= SettingsRepository(
      onTokensRefreshed: auth.applyRefreshedTokens,
      onSessionRefreshFailed: auth.handleSessionRefreshFailed,
    );
  }

  static List<Map<String, dynamic>> _defaultCategories() => [
        {
          'id': 'challenges',
          'title': 'Challenge Updates',
          'desc': 'New challenges, deadlines, and results.',
          'enabled': true,
        },
        {
          'id': 'rewards',
          'title': 'New Rewards',
          'desc': 'When new rewards become available.',
          'enabled': true,
        },
        {
          'id': 'winners',
          'title': 'Winner Announcements',
          'desc': 'When challenge winners are announced.',
          'enabled': true,
        },
        {
          'id': 'social',
          'title': 'Likes & Comments',
          'desc': 'Activity on your videos and profile.',
          'enabled': true,
        },
        {
          'id': 'referrals',
          'title': 'Referral Rewards',
          'desc': 'Updates on friends you’ve invited.',
          'enabled': false,
        },
        {
          'id': 'dailyBonus',
          'title': 'Daily Bonus Reminder',
          'desc': 'A nudge to claim your daily streak bonus.',
          'enabled': true,
        },
        {
          'id': 'membership',
          'title': 'Membership Updates',
          'desc': 'Prime membership news and billing updates.',
          'enabled': false,
        },
      ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_load());
    });
  }

  /// Backend returns flat booleans; UI uses category cards.
  static const _flatKeyAliases = <String, List<String>>{
    'challenges': ['challenges', 'challengeUpdates'],
    'rewards': ['rewards', 'newRewards'],
    'winners': ['winners', 'winnerAnnouncements'],
    'social': ['social', 'likesAndComments'],
    'referrals': ['referrals', 'referralRewards'],
    'dailyBonus': ['dailyBonus', 'dailyBonusReminder'],
    'membership': ['membership', 'membershipUpdates'],
  };

  static bool _readFlag(
    Map<String, dynamic> data,
    List<String> keys, {
    bool fallback = true,
  }) {
    for (final key in keys) {
      if (data.containsKey(key)) return data[key] == true;
    }
    return fallback;
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthCubit>();
      final data = await _repository().getNotificationSettings(
        sessionToken: auth.sessionToken,
        refreshToken: auth.refreshToken,
      );
      if (!mounted) return;

      final masterOn = _readFlag(
        data,
        const [
          'pushNotifications',
          'master',
          'pushEnabled',
          'masterEnabled',
          'enabled',
        ],
        fallback: true,
      );

      final cats = data['categories'];
      final parsed = <Map<String, dynamic>>[];
      if (cats is List) {
        for (final item in cats) {
          if (item is! Map) continue;
          final m = Map<String, dynamic>.from(item);
          parsed.add({
            'id': m['id']?.toString() ?? '',
            'title': m['title']?.toString() ?? '',
            'desc': m['desc']?.toString() ?? m['description']?.toString() ?? '',
            'enabled': m['enabled'] == true,
          });
        }
      }

      // Flat API shape → merge into default category cards.
      final merged = _defaultCategories().map((cat) {
        final id = cat['id'] as String;
        final aliases = _flatKeyAliases[id] ?? [id];
        final enabled = _readFlag(
          data,
          aliases,
          fallback: cat['enabled'] == true,
        );
        return {...cat, 'enabled': enabled};
      }).toList();

      setState(() {
        _masterOn = masterOn;
        _settings = parsed.isNotEmpty ? parsed : merged;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _settings = _defaultCategories();
        _loading = false;
      });
    }
  }

  Future<void> _persist() async {
    try {
      final auth = context.read<AuthCubit>();
      final body = <String, dynamic>{
        'pushNotifications': _masterOn,
        'master': _masterOn,
        'pushEnabled': _masterOn,
        'categories': _settings,
      };
      for (final item in _settings) {
        final id = item['id']?.toString() ?? '';
        final enabled = item['enabled'] == true;
        final aliases = _flatKeyAliases[id] ?? [id];
        for (final key in aliases) {
          body[key] = enabled;
        }
      }
      await _repository().updateNotificationSettings(
        body: body,
        sessionToken: auth.sessionToken,
        refreshToken: auth.refreshToken,
      );
    } catch (_) {}
  }

  // Map settings ID to icon background color and icon shape
  Map<String, dynamic> _getCategoryIconData(String id) {
    switch (id) {
      case 'challenges':
        return {
          'icon': Icons.emoji_events_outlined,
          'color': const Color(0xFF4C6CF7), // Blue
        };
      case 'rewards':
        return {
          'icon': Icons.card_giftcard_outlined,
          'color': const Color(0xFF8B3DFF), // Purple
        };
      case 'winners':
        return {
          'icon': Icons.workspace_premium_outlined, // Fixed Crown icon
          'color': const Color(0xFFFF3D77), // Pink/Magenta
        };
      case 'social':
        return {
          'icon': Icons.favorite_border_rounded,
          'color': const Color(0xFF4C6CF7), // Light Blue
        };
      case 'referrals':
        return {
          'icon': Icons.person_add_alt_1_outlined,
          'color': const Color(0xFF8B3DFF), // Purple
        };
      case 'dailyBonus':
        return {
          'icon': Icons.local_fire_department_outlined,
          'color': const Color(0xFFFF7A45), // Orange
        };
      case 'membership':
        return {
          'icon': Icons.diamond_outlined,
          'color': const Color(0xFF8B3DFF), // Purple
        };
      default:
        return {
          'icon': Icons.notifications_none_rounded,
          'color': const Color(0xFF8B849C),
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppBackHeader(title: 'Notification Settings'),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
              child: AppContent(
                noBottomPad: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    
                    // Master Switch Card (Push Notifications)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBF9FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFECE8F5), width: 1.2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFE8EE),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_active_outlined,
                              color: Color(0xFFFF3D77),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Push Notifications',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Color(0xFF241E38),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Master switch for all notification categories',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: const Color(0xFF8B849C),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 10.5,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GradientSwitch(
                            value: _masterOn,
                            onChanged: (val) {
                              setState(() => _masterOn = val);
                              unawaited(_persist());
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // "Categories" Title
                    const Text(
                      'Categories',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Color(0xFF241E38),
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Switch Categories List
                    Opacity(
                      opacity: _masterOn ? 1.0 : 0.5,
                      child: Column(
                        children: _settings.map((item) {
                          final id = item['id'] as String;
                          final iconData = _getCategoryIconData(id);
                          final enabled = item['enabled'] as bool;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFECE8F5), width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF5E2EAA).withValues(alpha: 0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Colored circular background container for icon
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: (iconData['color'] as Color).withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    iconData['icon'] as IconData,
                                    color: iconData['color'] as Color,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                // Title & Description
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['title'] as String,
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          color: Color(0xFF241E38),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item['desc'] as String,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          color: Color(0xFF8B849C),
                                          fontWeight: FontWeight.w500,
                                          fontSize: 10,
                                          height: 1.35,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                // Switch
                                GradientSwitch(
                                  value: enabled,
                                  enabled: _masterOn,
                                  onChanged: _masterOn
                                      ? (val) {
                                          setState(() => item['enabled'] = val);
                                          unawaited(_persist());
                                        }
                                      : null,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Info footer pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBF9FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFECE8F5), width: 1.2),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFF8B3DFF),
                            size: 18,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You can change these preferences anytime.',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: Color(0xFF8B3DFF),
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
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
