import 'package:flutter/material.dart';

import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/core/widgets/app_back_header.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';
import 'package:artable_app/core/widgets/gradient_switch.dart';
import 'package:artable_app/data/datasources/mock_data.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  late Map<String, dynamic> _privacy;

  @override
  void initState() {
    super.initState();
    _privacy = Map<String, dynamic>.from(MockData.PRIVACY_SETTINGS);
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppBackHeader(title: 'Privacy Settings'),
          Expanded(
            child: SingleChildScrollView(
              child: AppContent(
                noBottomPad: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    
                    // Stay in Control Banner
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
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF3EAFD),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.security_rounded,
                              color: Color(0xFF8B3DFF),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Stay in control',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Color(0xFF241E38),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Control who can view and interact with your profile.',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: Color(0xFF8B849C),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 11,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // "Profile Visibility" Section
                    const Text(
                      'Profile Visibility',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Color(0xFF241E38),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: ['public', 'private'].map((v) {
                        final selected = _privacy['profileVisibility'] == v;
                        final label = v == 'public' ? 'Public' : 'Private';

                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _privacy['profileVisibility'] = v),
                            child: Container(
                              margin: EdgeInsets.only(
                                left: v == 'public' ? 0 : 6,
                                right: v == 'public' ? 6 : 0,
                              ),
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: selected ? AppGradients.button : null,
                                color: selected ? null : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: selected ? null : Border.all(color: const Color(0xFFECE8F5), width: 1.2),
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFFFF5487).withValues(alpha: 0.2),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: selected ? Colors.white : const Color(0xFF8B849C),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // "Profile Controls" Section
                    const Text(
                      'Profile Controls',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Color(0xFF241E38),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Show Talent Score
                    _buildSwitchRow(
                      title: 'Show Talent Score',
                      desc: 'Display your talent score on your public profile.',
                      keyName: 'showTalentScore',
                    ),
                    const SizedBox(height: 12),

                    // Show Reward Earnings
                    _buildSwitchRow(
                      title: 'Show Reward Earnings',
                      desc: 'Display your total earnings on your public profile.',
                      keyName: 'showRewardEarnings',
                    ),
                    const SizedBox(height: 12),

                    // Allow Comments
                    _buildSwitchRow(
                      title: 'Allow Comments',
                      desc: 'Let other users comment on your videos.',
                      keyName: 'allowComments',
                    ),
                    const SizedBox(height: 12),

                    // Allow Shares
                    _buildSwitchRow(
                      title: 'Allow Shares',
                      desc: 'Let other users share your videos.',
                      keyName: 'allowShares',
                    ),
                    const SizedBox(height: 12),

                    // Allow Profile Search
                    _buildSwitchRow(
                      title: 'Allow Profile Search',
                      desc: 'Let others find your profile via search.',
                      keyName: 'allowProfileSearch',
                    ),
                    const SizedBox(height: 12),

                    // Blocked Users ListTile Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFECE8F5), width: 1.2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF8F7FC),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.block_flipped,
                              color: Color(0xFF8B849C),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Blocked Users',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Color(0xFF241E38),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_privacy['blockedUsersCount'] ?? 0} blocked',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    color: Color(0xFF8B849C),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFFB7B1C6),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Footer Info Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBF9FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFECE8F5), width: 1.2),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            color: Color(0xFF8B3DFF),
                            size: 16,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Some information may remain visible for challenge participation and winner announcements.',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: Color(0xFF8B3DFF),
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                                height: 1.35,
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

  Widget _buildSwitchRow({
    required String title,
    required String desc,
    required String keyName,
  }) {
    final value = _privacy[keyName] as bool? ?? false;

    return Container(
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Color(0xFF241E38),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
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
          GradientSwitch(
            value: value,
            onChanged: (val) {
              setState(() {
                _privacy[keyName] = val;
              });
            },
          ),
        ],
      ),
    );
  }
}
