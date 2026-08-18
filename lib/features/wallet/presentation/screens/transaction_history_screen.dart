import 'package:flutter/material.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/core/utils/format_utils.dart';
import 'package:artable_app/core/widgets/app_back_header.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';
import 'package:artable_app/core/widgets/filter_pills.dart';
import 'package:artable_app/data/datasources/mock_data.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  static const _filters = ['All', 'Credit', 'Debit', 'Withdrawn'];
  var _filter = 'All';

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'challenge_win':
        return Icons.emoji_events_outlined;
      case 'referral':
        return Icons.person_add_alt_1_outlined;
      case 'daily_bonus':
        return Icons.local_fire_department_outlined;
      case 'withdrawal':
        return Icons.account_balance_wallet_outlined;
      case 'voucher':
        return Icons.confirmation_number_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawTransactions = MockData.TRANSACTIONS;
    final List<Map<String, dynamic>> filteredList;

    if (_filter == 'All') {
      filteredList = rawTransactions;
    } else {
      final filterType = _filter.toLowerCase();
      filteredList = rawTransactions.where((tx) => tx['type'] == filterType).toList();
    }

    return AppScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppBackHeader(title: 'Transaction History'),
          const SizedBox(height: 8),
          
          // Custom Filter Pills
          FilterPills(
            items: _filters,
            selected: _filter,
            onSelected: (f) => setState(() => _filter = f),
          ),
          const SizedBox(height: 16),

          // Scrollable List
          Expanded(
            child: filteredList.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 22, vertical: 32),
                    child: Center(
                      child: Text(
                        'No transactions found.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textSoft,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    itemCount: filteredList.length + 1, // Add +1 for the Ad Banner
                    itemBuilder: (context, index) {
                      if (index == filteredList.length) {
                        return _buildAdBanner();
                      }

                      final tx = filteredList[index];
                      return _buildTransactionCard(tx);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> tx) {
    final type = tx['type'] as String? ?? 'credit';
    final isCredit = type == 'credit' || (tx['amount'] as String? ?? '').startsWith('+');
    final status = tx['status'] as String? ?? 'completed';
    
    // Status Badge Details
    final String statusStr;
    final Color badgeBg;
    final Color badgeText;

    if (status == 'pending') {
      statusStr = 'PENDING';
      badgeBg = const Color(0xFFFFF2E6);
      badgeText = const Color(0xFFE68A00);
    } else if (type == 'withdrawn') {
      statusStr = 'WITHDRAWN';
      badgeBg = const Color(0xFFE8F0FE);
      badgeText = const Color(0xFF1A73E8);
    } else {
      statusStr = 'COMPLETED';
      badgeBg = const Color(0xFFE6F8F3);
      badgeText = const Color(0xFF00C897);
    }

    final formattedDate = FormatUtils.formatDateTime(tx['date'] as String? ?? '')
        .replaceAll('·', '-');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
          // Icon Circular Backdrop
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFFF3EAFD),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _iconForCategory(tx['category'] as String? ?? ''),
              color: const Color(0xFF8B3DFF),
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          
          // Transaction Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx['title'] as String? ?? '',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Color(0xFF241E38),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF8B849C),
                    fontWeight: FontWeight.w500,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Amount & Status Badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                tx['amount'] as String? ?? '',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: isCredit ? const Color(0xFF00C897) : const Color(0xFFFF3D77),
                  fontWeight: FontWeight.w900,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusStr,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: badgeText,
                    fontWeight: FontWeight.w900,
                    fontSize: 7.5,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EC), // Soft cream/yellow tint
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFBEFD7), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9F1C).withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Sneaker Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=160&h=160&q=80&auto=format&fit=crop',
              width: 72,
              height: 72,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),

          // Tagline & Button
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'SPORTIFY',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFFB5ADC8),
                        fontWeight: FontWeight.w800,
                        fontSize: 9.5,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    // Ad tag badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB703),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Ad',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 7.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Run Faster.\nBe Stronger.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Color(0xFF241E38),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                // Shop Now Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB703),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFB703).withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Shop Now',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Color(0xFF241E38),
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
