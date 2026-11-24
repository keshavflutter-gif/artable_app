import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';
import 'package:artable_app/core/widgets/app_back_header.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';
import 'package:artable_app/core/widgets/filter_pills.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:artable_app/features/rewards/data/repositories/rewards_repository.dart';

class CashRewardsScreen extends StatelessWidget {
  const CashRewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _TypedRewardsScreen(
      title: 'Cash Rewards',
      type: 'cash',
      icon: Icons.account_balance_wallet_outlined,
      color: AppColors.purple,
    );
  }
}

class VoucherRewardsScreen extends StatelessWidget {
  const VoucherRewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _TypedRewardsScreen(
      title: 'Voucher Rewards',
      type: 'voucher',
      icon: Icons.confirmation_number_outlined,
      color: AppColors.blue,
    );
  }
}

class ProductRewardsScreen extends StatelessWidget {
  const ProductRewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _TypedRewardsScreen(
      title: 'Product Rewards',
      type: 'product',
      icon: Icons.inventory_2_outlined,
      color: AppColors.orange,
    );
  }
}

class SponsorRewardsScreen extends StatelessWidget {
  const SponsorRewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _TypedRewardsScreen(
      title: 'Sponsor Rewards',
      type: 'sponsor',
      icon: Icons.handshake_outlined,
      color: AppColors.pink,
    );
  }
}

class _TypedRewardsScreen extends StatefulWidget {
  const _TypedRewardsScreen({
    required this.title,
    required this.type,
    required this.icon,
    required this.color,
  });

  final String title;
  final String type;
  final IconData icon;
  final Color color;

  @override
  State<_TypedRewardsScreen> createState() => _TypedRewardsScreenState();
}

class _TypedRewardsScreenState extends State<_TypedRewardsScreen> {
  RewardsRepository? _repo;
  var _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rewards = const [];

  RewardsRepository _repository() {
    final auth = context.read<AuthCubit>();
    return _repo ??= RewardsRepository(
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthCubit>();
      final res = await _repository().getRewards(
        type: widget.type,
        sessionToken: auth.sessionToken,
        refreshToken: auth.refreshToken,
      );
      if (!mounted) return;
      setState(() {
        _rewards = res.data?.rewards.map((r) => r.toUiMap()).toList() ??
            const [];
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load ${widget.title.toLowerCase()}.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      child: Column(
        children: [
          AppBackHeader(title: widget.title),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _rewards.isEmpty
                        ? Center(
                            child: EmptyNote(
                              message:
                                  '${widget.title} will appear here once available.',
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                            children: _rewards.map((r) {
                              return GestureDetector(
                                onTap: () => context.push(
                                  '/reward-detail?id=${r['id']}',
                                ),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border:
                                        Border.all(color: AppColors.inputBorder),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: widget.color
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          widget.icon,
                                          color: widget.color,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              r['title'] as String? ?? '',
                                              style: AppTextStyles.body.copyWith(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                              ),
                                            ),
                                            Text(
                                              r['value'] as String? ?? '',
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