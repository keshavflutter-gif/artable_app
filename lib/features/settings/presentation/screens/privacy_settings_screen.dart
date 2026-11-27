import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/core/widgets/app_back_header.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';
import 'package:artable_app/core/widgets/gradient_switch.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:artable_app/features/settings/data/repositories/settings_repository.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  var _privacy = <String, dynamic>{
    'profileVisibility': 'public',
    'showTalentScore': true,
    'showRewardEarnings': false,
    'allowComments': true,
    'allowShares': true,
    'allowProfileSearch': true,
    'blockedUsersCount': 0,
  };
  var _loading = true;
  SettingsRepository? _repo;

  SettingsRepository _repository() {
    final auth = context.read<AuthCubit>();
    return _repo ??= SettingsRepository(
      onTokensRefreshed: auth.applyRefreshedTokens,
      onSessionRefreshFailed: auth.handleSessionRefreshFailed,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_load());
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthCubit>();
      final data = await _repository().getPrivacySettings(
        sessionToken: auth.sessionToken,
        refreshToken: auth.refreshToken,
      );
      if (!mounted) return;
      setState(() {
        _privacy = _normalizePrivacy({..._privacy, ...data});
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  /// API may send PUBLIC/PRIVATE — UI uses lowercase. Coerce bools safely.
  Map<String, dynamic> _normalizePrivacy(Map<String, dynamic> raw) {
    final out = Map<String, dynamic>.from(raw);
    final vis = out['profileVisibility']?.toString().trim().toLowerCase();
    if (vis == 'public' || vis == 'private') {
      out['profileVisibility'] = vis;
    }
    for (final key in const [
      'showTalentScore',
      'showRewardEarnings',
      'allowComments',
      'allowShares',
      'allowProfileSearch',
      'showActivity',
      'allowRating',
      'privateAccount',
      'showInSearch',
    ]) {
      if (out.containsKey(key)) {
        out[key] = out[key] == true;
      }
    }
    return out;
  }

  Future<void> _persist() async {
    try {
      final auth = context.read<AuthCubit>();
      final body = Map<String, dynamic>.from(_privacy);
      final vis = body['profileVisibility']?.toString().trim().toLowerCase();
      if (vis == 'public' || vis == 'private') {
        // Backend stores uppercase enum.
        body['profileVisibility'] = vis!.toUpperCase();
      }
      await _repository().updatePrivacySettings(
        body: body,
        sessionToken: auth.sessionToken,
        refreshToken: auth.refreshToken,
      );
    } catch (_) {}
  }

  void _updatePrivacy(void Function() mutate) {
    setState(mutate);
    unawaited(_persist());
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppBackHeader(title: 'Privacy Settings'),
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
                            onTap: () =>
                                _updatePrivacy(() => _privacy['profileVisibility'] = v),
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
    final value = _privacy[keyName] == true;

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
              _updatePrivacy(() => _privacy[keyName] = val);
            },
          ),
        ],
      ),
    );
  }
}
