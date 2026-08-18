import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';
import 'package:artable_app/core/widgets/app_back_header.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';
import 'package:artable_app/data/datasources/mock_data.dart';

class CashRewardsScreen extends StatelessWidget {
  const CashRewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final list = MockData.REWARDS.where((r) => r['type'] == 'cash').toList();
    final total = list.fold<double>(0, (s, r) {
      return s + (double.tryParse((r['value'] as String).replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0);
    });

    return AppScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppBackHeader(title: 'Cash Rewards'),
          Expanded(
            child: SingleChildScrollView(
              child: AppContent(
                noBottomPad: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('₹${total.toStringAsFixed(0)} total', style: AppTextStyles.displayBold.copyWith(fontSize: 22)),
                    const SizedBox(height: 16),
                    ...list.map((r) => _CashRow(reward: r)),
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

class _CashRow extends StatelessWidget {
  const _CashRow({required this.reward});

  final Map<String, dynamic> reward;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/reward-detail?id=${reward['id']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.currency_rupee, color: AppColors.orange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reward['title'] as String, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(reward['value'] as String, style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSoft),
          ],
        ),
      ),
    );
  }
}

class VoucherRewardsScreen extends StatelessWidget {
  const VoucherRewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final list = MockData.REWARDS.where((r) => r['type'] == 'voucher').toList();
    return _CategoryListScreen(title: 'Voucher Rewards', rewards: list, icon: Icons.confirmation_number_outlined, color: AppColors.blue);
  }
}

class ProductRewardsScreen extends StatelessWidget {
  const ProductRewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final list = MockData.REWARDS.where((r) => r['type'] == 'product').toList();
    return _CategoryListScreen(title: 'Product Rewards', rewards: list, icon: Icons.inventory_2_outlined, color: AppColors.orange);
  }
}

class SponsorRewardsScreen extends StatelessWidget {
  const SponsorRewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final list = MockData.REWARDS.where((r) => r['type'] == 'sponsor').toList();
    return _CategoryListScreen(title: 'Sponsor Rewards', rewards: list, icon: Icons.handshake_outlined, color: AppColors.pink);
  }
}

class _CategoryListScreen extends StatelessWidget {
  const _CategoryListScreen({
    required this.title,
    required this.rewards,
    required this.icon,
    required this.color,
  });

  final String title;
  final List<Map<String, dynamic>> rewards;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      child: SingleChildScrollView(
        child: Column(
          children: [
            AppBackHeader(title: title),
            AppContent(
              noBottomPad: true,
              child: Column(
                children: rewards.map((r) {
                  return GestureDetector(
                    onTap: () => context.push('/reward-detail?id=${r['id']}'),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(icon, color: color, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r['title'] as String, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700, fontSize: 13)),
                                Text(r['value'] as String, style: AppTextStyles.bodySoft.copyWith(fontSize: 12)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: AppColors.textFaint),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
