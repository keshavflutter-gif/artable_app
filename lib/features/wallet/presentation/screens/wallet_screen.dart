import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/core/widgets/app_back_header.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';
import 'package:artable_app/features/profile/presentation/widgets/profile_reward_widgets.dart';
import 'package:artable_app/data/datasources/mock_data.dart';
import 'package:artable_app/features/wallet/presentation/bloc/wallet_cubit.dart';
import 'package:artable_app/features/wallet/presentation/bloc/wallet_state.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<WalletCubit>();
      if (!cubit.hasLoaded) {
        cubit.loadWalletInfo();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppBackHeader(title: 'Wallet'),
          Expanded(
            child: BlocBuilder<WalletCubit, WalletState>(
              builder: (context, state) {
                final cubit = context.read<WalletCubit>();
                final walletData = state.walletData;

                final availableBalance = walletData?.displayAvailableBalance ?? MockData.WALLET_SUMMARY['availableBalance'] as String;
                final pendingRewards = walletData != null ? walletData.displayPendingAmount : MockData.WALLET_SUMMARY['pendingRewards'] as String;
                final totalWithdrawn = walletData != null ? walletData.displayWithdrawnAmount : MockData.WALLET_SUMMARY['totalWithdrawn'] as String;
                final minWithdrawal = walletData != null ? '₹${walletData.minimumWithdrawalAmount.toStringAsFixed(0)}' : MockData.WALLET_SUMMARY['minWithdrawal'] as String;

                final transactionsList = (walletData?.recentTransactions != null && walletData!.recentTransactions.isNotEmpty)
                    ? walletData.recentTransactions.map((tx) => tx.toUiMap()).toList()
                    : MockData.TRANSACTIONS;

                return RefreshIndicator(
                  onRefresh: () => cubit.loadWalletInfo(forceRefresh: true),
                  color: const Color(0xFFFF5487),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: AppContent(
                      noBottomPad: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),

                          // Main Dark Blue-Purple Gradient Balance Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF13092A),
                                  Color(0xFF261250),
                                  Color(0xFF5E2EAA),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4B1E90).withValues(alpha: 0.28),
                                  blurRadius: 22,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'AVAILABLE BALANCE',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: Colors.white70,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  availableBalance,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Divider(
                                  color: Colors.white24,
                                  height: 1,
                                  thickness: 1,
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    _MiniStat(
                                      value: pendingRewards,
                                      label: 'PENDING',
                                    ),
                                    _MiniStat(
                                      value: totalWithdrawn,
                                      label: 'WITHDRAWN',
                                    ),
                                    _MiniStat(
                                      value: minWithdrawal,
                                      label: 'MIN. WITHDRAW',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Action Buttons: Withdraw & History
                          Row(
                            children: [
                              // Withdraw Button
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF8B3DFF).withValues(alpha: 0.20),
                                        blurRadius: 14,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => context.push('/withdrawal-request'),
                                      borderRadius: BorderRadius.circular(28),
                                      child: Container(
                                        height: 48,
                                        decoration: BoxDecoration(
                                          gradient: AppGradients.button,
                                          borderRadius: BorderRadius.circular(28),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: const [
                                            Icon(
                                              Icons.outbox_rounded,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Withdraw',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // History Button
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => context.push('/transaction-history'),
                                      borderRadius: BorderRadius.circular(28),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(28),
                                          border: Border.all(
                                            color: const Color(0x145E2EAA),
                                            width: 1.5,
                                          ),
                                          color: Colors.white,
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Color(0x0C15083C),
                                              blurRadius: 10,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: const [
                                            Icon(
                                              Icons.receipt_long_rounded,
                                              size: 16,
                                              color: AppColors.text,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'History',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.text,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Security Note Subtext
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.lock_outline_rounded,
                                size: 13,
                                color: AppColors.textSoft,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Withdrawals processed securely via Razorpay.',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSoft,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 22),

                          // Section Header: Earnings Summary
                          const Text(
                            'Earnings Summary',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Earnings Summary 2x2 Grid
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.35,
                            children: [
                              _EarningStat(
                                value: _findEarnings(walletData, 'CHALLENGE_WIN') ?? (MockData.WALLET_SUMMARY['challengeWins'] as String),
                                label: 'Challenge Wins',
                                icon: Icons.emoji_events_rounded,
                              ),
                              _EarningStat(
                                value: _findEarnings(walletData, 'REFERRAL') ?? (MockData.WALLET_SUMMARY['referralRewards'] as String),
                                label: 'Referral Rewards',
                                icon: Icons.person_add_outlined,
                              ),
                              _EarningStat(
                                value: _findEarnings(walletData, 'BONUS') ?? (MockData.WALLET_SUMMARY['dailyBonus'] as String),
                                label: 'Daily Bonus',
                                icon: Icons.calendar_today_rounded,
                              ),
                              _EarningStat(
                                value: _findEarnings(walletData, 'WITHDRAWAL') ?? (MockData.WALLET_SUMMARY['sponsorRewards'] as String),
                                label: 'Withdrawal Sum',
                                icon: Icons.outbox_rounded,
                              ),
                            ],
                          ),

                          const SizedBox(height: 22),

                          // Section Header: Recent Transactions
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Recent Transactions',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.push('/transaction-history'),
                                child: const Text(
                                  'See All',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.purple,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Transactions List
                          if (state.isLoading && !state.hasLoaded)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: CircularProgressIndicator(color: AppColors.purple),
                              ),
                            )
                          else if (transactionsList.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(
                                  'No recent transactions',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: AppColors.textSoft,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            )
                          else
                            ...transactionsList.take(5).map((tx) {
                              return TransactionRow(
                                tx: tx,
                                onTap: tx['rewardId'] != null
                                    ? () => context.push('/reward-detail?id=${tx['rewardId']}')
                                    : null,
                              );
                            }),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String? _findEarnings(dynamic walletData, String type) {
    if (walletData == null || walletData.earningsSummary == null) return null;
    for (final item in walletData.earningsSummary) {
      if (item.type?.toUpperCase() == type.toUpperCase()) {
        if (item.amount != null) {
          final amt = double.tryParse(item.amount!) ?? 0.0;
          return '₹${amt.toStringAsFixed(0)}';
        }
      }
    }
    return null;
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Colors.white60,
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningStat extends StatelessWidget {
  const _EarningStat({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0x145E2EAA),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A15083C),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFFF5F0FE),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 16,
              color: AppColors.purple,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSoft,
            ),
          ),
        ],
      ),
    );
  }
}
