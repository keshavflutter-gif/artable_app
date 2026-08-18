import 'package:flutter/material.dart';

import 'package:artable_app/core/widgets/app_back_header.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';
import 'package:artable_app/core/widgets/gradient_switch.dart';
import 'package:artable_app/data/datasources/mock_data.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  late List<Map<String, dynamic>> _settings;
  var _masterOn = true;

  @override
  void initState() {
    super.initState();
    _settings = MockData.NOTIFICATION_SETTINGS
        .map((s) => Map<String, dynamic>.from(s))
        .toList();
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
            child: SingleChildScrollView(
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
                              setState(() {
                                _masterOn = val;
                              });
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
                                          setState(() {
                                            item['enabled'] = val;
                                          });
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
