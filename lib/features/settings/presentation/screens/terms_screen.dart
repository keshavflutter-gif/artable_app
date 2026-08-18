import 'package:flutter/material.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_typography.dart';
import 'package:artable_app/core/widgets/app_back_header.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _sectionKeys = {};

  static const _pills = [
    'Introduction',
    'Accounts',
    'Challenges',
    'Studio',
    'Ratings',
    'Rewards',
    'Prime',
    'Prohibited Content',
    'Suspension',
    'Changes',
  ];

  static const _sections = [
    {
      'title': '1. Introduction',
      'body':
          'Welcome to ARTABLE. These Terms & Conditions ("Terms") govern your access to and use of the ARTABLE app, including talent challenges, the recording studio, rewards, and membership features. By creating an account or using the app, you agree to these placeholder Terms.',
    },
    {
      'title': '2. User Accounts',
      'body':
          'You are responsible for maintaining the confidentiality of your account credentials and for all activity under your account. You must provide accurate information when creating your profile.',
    },
    {
      'title': '3. Challenge Participation',
      'body':
          'Entries submitted to challenges must be your own original work, recorded through the in-app Studio. Participation is subject to each challenge\'s individual rules, deadlines, and eligibility criteria.',
    },
    {
      'title': '4. In-App Studio Recording',
      'body':
          'To help keep challenges fair, entries must be captured live using ARTABLE\'s built-in recording tools rather than uploaded from an external gallery.',
    },
    {
      'title': '5. Talent Ratings',
      'body':
          'Talent scores and ratings are generated from community voting and platform criteria. Ratings are intended to reflect audience engagement and are not a guarantee of any outcome.',
    },
    {
      'title': '6. Rewards & Wallet',
      'body':
          'Rewards earned through challenges, referrals, and daily engagement are credited to your in-app wallet. Withdrawal requests are reviewed before processing.',
    },
    {
      'title': '7. Prime Membership',
      'body':
          'Prime is an optional paid membership that removes ads and unlocks a diamond profile badge. Membership pricing and features may be updated from time to time.',
    },
    {
      'title': '8. Prohibited Content',
      'body':
          'Content that is abusive, infringing, or otherwise violates community guidelines is not permitted and may be removed at ARTABLE\'s discretion.',
    },
    {
      'title': '9. Account Suspension',
      'body':
          'Accounts found in violation of these Terms may be suspended or terminated, including forfeiture of pending rewards where applicable.',
    },
    {
      'title': '10. Changes to Terms',
      'body':
          'ARTABLE may update these Terms periodically. Continued use of the app after changes take effect constitutes acceptance of the revised Terms.',
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
          const AppBackHeader(title: 'Terms & Conditions'),
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
