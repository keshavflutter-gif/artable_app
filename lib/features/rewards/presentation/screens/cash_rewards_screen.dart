import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';
import 'package:artable_app/core/widgets/app_back_header.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';
import 'package:artable_app/core/widgets/filter_pills.dart';

class CashRewardsScreen extends StatelessWidget {
  const CashRewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppBackHeader(title: 'Cash Rewards'),
          Expanded(
            child: Center(
              child: EmptyNote(
                message: 'Cash rewards will appear here once available.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VoucherRewardsScreen extends StatelessWidget {
  const VoucherRewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CategoryListScreen(
      title: 'Voucher Rewards',
      rewards: [],
      icon: Icons.confirmation_number_outlined,
      color: AppColors.blue,
    );
  }
}

class ProductRewardsScreen extends StatelessWidget {
  const ProductRewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CategoryListScreen(
      title: 'Product Rewards',
      rewards: [],
      icon: Icons.inventory_2_outlined,
      color: AppColors.orange,
    );
  }
}

class SponsorRewardsScreen extends StatelessWidget {
  const SponsorRewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CategoryListScreen(
      title: 'Sponsor Rewards',
      rewards: [],
      icon: Icons.handshake_outlined,
      color: AppColors.pink,
    );
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
      child: Column(
        children: [
          AppBackHeader(title: title),
          Expanded(
            child: rewards.isEmpty
                ? Center(
                    child: EmptyNote(
                      message: '$title will appear here once available.',
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                    children: rewards.map((r) {
                      return GestureDetector(
                        onTap: () =>
                            context.push('/reward-detail?id=${r['id']}'),
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
                                    Text(
                                      r['title'] as String,
                                      style: AppTextStyles.body.copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      r['value'] as String,
                                      style: AppTextStyles.bodySoft
                                          .copyWith(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: AppColors.textFaint,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
