import 'package:flutter/material.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_typography.dart';
import 'package:artable_app/core/widgets/app_back_header.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _sectionKeys = {};

  static const _pills = [
    'Information We Collect',
    'How We Use It',
    'Video & Challenges',
    'Ratings & Engagement',
    'Rewards & Wallet',
    'Notifications',
    'Data Security',
    'Your Controls',
    'Contact',
  ];

  static const _sections = [
    {
      'title': '1. Information We Collect',
      'body':
          'We collect information you provide directly, such as your profile details, challenge entries, and payment method details for Prime subscriptions, along with usage data generated as you use the app.',
    },
    {
      'title': '2. How We Use Information',
      'body':
          'Your information helps us operate challenges, calculate talent scores, process rewards, personalize your feed, and improve the ARTABLE experience.',
    },
    {
      'title': '3. Video & Challenge Content',
      'body':
          'Videos recorded through the in-app Studio and submitted to challenges may be visible to other users, judges, and the public depending on the challenge and your privacy settings.',
    },
    {
      'title': '4. Ratings and Engagement Data',
      'body':
          'Likes, comments, shares, and talent ratings are collected to calculate your talent score and surface relevant content to the community.',
    },
    {
      'title': '5. Rewards & Wallet Data',
      'body':
          'Wallet balances, transaction history, and withdrawal requests are stored securely and used solely to process your rewards.',
    },
    {
      'title': '6. Notifications',
      'body':
          'We use your notification preferences to determine which updates — challenges, rewards, winners, and more — are sent to your device.',
    },
    {
      'title': '7. Data Security',
      'body':
          'We use industry-standard safeguards to protect your data. No method of transmission or storage is ever 100% secure, but we work to keep your information safe.',
    },
    {
      'title': '8. User Controls',
      'body':
          'You can manage profile visibility, comment and share permissions, and notification preferences at any time from Settings.',
    },
    {
      'title': '9. Contact',
      'body':
          'Questions about this Privacy Policy can be directed to our support team from the Help & Support screen.',
    },
  ];

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < _sections.length; i++) {
      _sectionKeys[i] = GlobalKey();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(int index) {
    final key = _sectionKeys[index];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      child: Column(
        children: [
          const AppBackHeader(title: 'Privacy Policy'),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last updated: July 1, 2026',
                    style: AppTypography.body(
                      fontSize: 11.5,
                      color: AppColors.textFaint,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: List.generate(_pills.length, (index) {
                      return GestureDetector(
                        onTap: () => _scrollToSection(index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _pills[index],
                            style: AppTypography.body(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.purple,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  ...List.generate(_sections.length, (index) {
                    final item = _sections[index];
                    return Padding(
                      key: _sectionKeys[index],
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title']!,
                            style: AppTypography.display(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item['body']!,
                            style: AppTypography.body(
                              fontSize: 12.5,
                              height: 1.5,
                              color: AppColors.textSoft,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
