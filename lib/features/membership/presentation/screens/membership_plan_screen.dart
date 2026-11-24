import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/core/network/api_response_helpers.dart';
import 'package:artable_app/core/widgets/app_back_header.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:artable_app/features/home/presentation/bloc/home_cubit.dart';
import 'package:artable_app/features/membership/data/repositories/membership_repository.dart';
import 'package:artable_app/features/payment/data/models/payment_options_model.dart';
import 'package:artable_app/features/payment/data/models/payment_result_model.dart';
import 'package:artable_app/features/payment/data/services/razorpay_service.dart';
import 'package:artable_app/features/trending/presentation/bloc/trending_videos_cubit.dart';

const _kPlanComparisonRows = [
  {'feature': 'Ads', 'basic': 'Shown', 'prime': 'None'},
  {'feature': 'Profile Badge', 'basic': 'Standard', 'prime': 'Diamond'},
  {'feature': 'Challenge Access', 'basic': 'Standard', 'prime': 'Standard'},
  {'feature': 'Support', 'basic': 'Standard', 'prime': 'Priority'},
];

class MembershipPlanScreen extends StatefulWidget {
  const MembershipPlanScreen({super.key});

  @override
  State<MembershipPlanScreen> createState() => _MembershipPlanScreenState();
}

class _MembershipPlanScreenState extends State<MembershipPlanScreen> {
  MembershipRepository? _repo;
  var _loading = true;
  String _currentPlan = 'basic';
  String _primePrice = '₹299';
  String? _primePlanId;

  MembershipRepository _repository() {
    final auth = context.read<AuthCubit>();
    return _repo ??= MembershipRepository(
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
      final me = await _repository().getMyMembership(
        sessionToken: auth.sessionToken,
        refreshToken: auth.refreshToken,
      );
      final plans = await _repository().getPlans(
        sessionToken: auth.sessionToken,
        refreshToken: auth.refreshToken,
      );

      final planName = (me['plan'] ??
              me['currentPlan'] ??
              me['tier'] ??
              'basic')
          .toString()
          .toLowerCase();
      Map<String, dynamic>? primePlan;
      for (final p in plans) {
        final slug = (p['slug'] ?? p['code'] ?? p['name'] ?? '')
            .toString()
            .toLowerCase();
        if (slug.contains('prime')) {
          primePlan = p;
          break;
        }
      }
      primePlan ??= plans.isNotEmpty ? plans.last : null;

      final price = primePlan?['price'] ??
          primePlan?['amount'] ??
          primePlan?['priceLabel'];
      final priceLabel = price != null ? '₹$price' : '₹299';

      if (!mounted) return;
      setState(() {
        _currentPlan = planName.contains('prime') ? 'prime' : 'basic';
        _primePrice = priceLabel.toString();
        _primePlanId = primePlan?['id']?.toString();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPrime = _currentPlan == 'prime';
    final currentPlanLabel = isPrime ? 'Prime' : 'Basic';

    return AppScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppBackHeader(title: 'Membership'),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
              child: AppContent(
                noBottomPad: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  const SizedBox(height: 8),

                  // Basic Plan Card
                  _BasicPlanCard(currentPlanLabel: currentPlanLabel),

                  const SizedBox(height: 14),

                  // Prime Plan Card
                  _PrimePlanCard(
                    price: '$_primePrice INR',
                    onUpgrade: _primePlanId == null
                        ? null
                        : () => context.push(
                              '/prime-payment?planId=${Uri.encodeComponent(_primePlanId!)}',
                            ),
                  ),

                  const SizedBox(height: 22),

                  // Compare Plans Section Header
                  const Text(
                    'Compare Plans',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Plan Comparison Table Card
                  const _PlanComparisonCard(),

                  const SizedBox(height: 24),
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

class _BasicPlanCard extends StatelessWidget {
  const _BasicPlanCard({required this.currentPlanLabel});

  final String currentPlanLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0x088B3DFF),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0x175E2EAA),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0D15083C),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Basic & Free
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Basic',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                ),
              ),
              Text(
                'Free',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Tag Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.inputBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Free Plan',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSoft,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0x1F1FAE6A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: Color(0xFF1FAE6A),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Current Plan: $currentPlanLabel',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1FAE6A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Features List
          const _FeatureItem(
            icon: Icons.person_outline_rounded,
            iconColor: AppColors.purple,
            textColor: AppColors.textSoft,
            text: 'Standard profile identity',
          ),
          const SizedBox(height: 10),
          const _FeatureItem(
            icon: Icons.block_rounded,
            iconColor: AppColors.purple,
            textColor: AppColors.textSoft,
            text: 'Ads shown between videos',
          ),
          const SizedBox(height: 10),
          const _FeatureItem(
            icon: Icons.emoji_events_outlined,
            iconColor: AppColors.purple,
            textColor: AppColors.textSoft,
            text: 'Core challenge access',
          ),
          const SizedBox(height: 10),
          const _FeatureItem(
            icon: Icons.credit_card_outlined,
            iconColor: AppColors.purple,
            textColor: AppColors.textSoft,
            text: 'Standard wallet & rewards',
          ),
        ],
      ),
    );
  }
}

class _PrimePlanCard extends StatelessWidget {
  const _PrimePlanCard({
    required this.price,
    required this.onUpgrade,
  });

  final String price;
  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2B1F4A),
            Color(0xFF4C307B),
            Color(0xFF7032CD),
          ],
          stops: [0.0, 0.45, 1.0],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7032CD).withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Diamond Mark + Prime & Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4C6CF7), Color(0xFF8B3DFF)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.1),
                          blurRadius: 0,
                          spreadRadius: 3,
                        ),
                        const BoxShadow(
                          color: Color(0x664C6CF7),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.diamond_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Prime',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Text(
                price,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Most Popular Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.diamond_rounded,
                  size: 11,
                  color: Colors.white,
                ),
                SizedBox(width: 4),
                Text(
                  'Most Popular',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Features List
          const _FeatureItem(
            icon: Icons.check_circle_outline_rounded,
            iconColor: Color(0xFFFFC93D),
            textColor: Colors.white,
            text: 'Ad-free experience',
          ),
          const SizedBox(height: 10),
          const _FeatureItem(
            icon: Icons.diamond_rounded,
            iconColor: Color(0xFFFFC93D),
            textColor: Colors.white,
            text: 'Diamond profile badge',
          ),
          const SizedBox(height: 10),
          const _FeatureItem(
            icon: Icons.person_outline_rounded,
            iconColor: Color(0xFFFFC93D),
            textColor: Colors.white,
            text: 'Premium identity across app',
          ),
          const SizedBox(height: 10),
          const _FeatureItem(
            icon: Icons.notifications_none_rounded,
            iconColor: Color(0xFFFFC93D),
            textColor: Colors.white,
            text: 'Priority customer support',
          ),

          const SizedBox(height: 18),

          // Upgrade Button inside Card
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onUpgrade,
              borderRadius: BorderRadius.circular(28),
              // onUpgrade null when plan id unavailable
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: AppGradients.button,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B3DFF).withValues(alpha: 0.20),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Upgrade to Prime',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Helper Subtext
          Center(
            child: Text(
              'Upgrade to remove ads and unlock your diamond profile badge.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.72),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.iconColor,
    required this.textColor,
    required this.text,
  });

  final IconData icon;
  final Color iconColor;
  final Color textColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanComparisonCard extends StatelessWidget {
  const _PlanComparisonCard();

  @override
  Widget build(BuildContext context) {
    final rows = _kPlanComparisonRows;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0x145E2EAA),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0D15083C),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.inputBg,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: const [
                Expanded(
                  flex: 14,
                  child: Text(
                    'FEATURE',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSoft,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                Expanded(
                  flex: 10,
                  child: Text(
                    'BASIC',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSoft,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                Expanded(
                  flex: 10,
                  child: Text(
                    'PRIME',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSoft,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Table Rows
          ...List.generate(rows.length, (index) {
            final row = rows[index];
            final feature = row['feature'] as String;
            final basic = row['basic'] as String;
            final prime = row['prime'] as String;
            final isPill = prime != basic;
            final isEven = index.isEven;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isEven ? Colors.white : const Color(0x058B3DFF),
                border: Border(
                  top: BorderSide(
                    color: AppColors.divider,
                    width: 0.8,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 14,
                    child: Text(
                      feature,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 10,
                    child: Text(
                      basic,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSoft,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 10,
                    child: Center(
                      child: isPill
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                gradient: AppGradients.button,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                prime,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              prime,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.purple,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class PrimePaymentScreen extends StatefulWidget {
  const PrimePaymentScreen({super.key, this.planId});

  final String? planId;

  @override
  State<PrimePaymentScreen> createState() => _PrimePaymentScreenState();
}

class _PrimePaymentScreenState extends State<PrimePaymentScreen> {
  MembershipRepository? _repo;
  final _razorpay = RazorpayService();
  var _loading = true;
  var _paying = false;
  String _priceStr = '₹299';
  String? _planId;
  double _amount = 299;

  MembershipRepository _repository() {
    final auth = context.read<AuthCubit>();
    return _repo ??= MembershipRepository(
      onTokensRefreshed: auth.applyRefreshedTokens,
      onSessionRefreshFailed: auth.handleSessionRefreshFailed,
    );
  }

  @override
  void initState() {
    super.initState();
    _razorpay.init();
    _planId = widget.planId?.trim();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_loadPlan());
    });
  }

  @override
  void dispose() {
    _razorpay.dispose();
    super.dispose();
  }

  Future<void> _loadPlan() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthCubit>();
      final plans = await _repository().getPlans(
        sessionToken: auth.sessionToken,
        refreshToken: auth.refreshToken,
      );
      Map<String, dynamic>? selected;
      final id = _planId;
      if (id != null && id.isNotEmpty) {
        for (final p in plans) {
          if (p['id']?.toString() == id) {
            selected = p;
            break;
          }
        }
      }
      if (selected == null) {
        for (final p in plans) {
          final slug =
              (p['slug'] ?? p['name'] ?? '').toString().toLowerCase();
          if (slug.contains('prime')) {
            selected = p;
            break;
          }
        }
        selected ??= plans.isNotEmpty ? plans.first : null;
      }

      final price = selected?['price'] ?? selected?['amount'] ?? 299;
      final amount = price is num
          ? price.toDouble()
          : (double.tryParse(price.toString()) ?? 299);

      if (!mounted) return;
      setState(() {
        _planId = selected?['id']?.toString() ?? _planId;
        _amount = amount;
        _priceStr = '₹${amount % 1 == 0 ? amount.toInt() : amount}';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _pay() async {
    final planId = _planId?.trim();
    if (planId == null || planId.isEmpty || _paying) return;
    setState(() => _paying = true);

    try {
      final auth = context.read<AuthCubit>();
      final subscribeRes = await _repository().subscribe(
        planId: planId,
        sessionToken: auth.sessionToken,
        refreshToken: auth.refreshToken,
      );

      if (subscribeRes['success'] != true) {
        throw Exception(
          subscribeRes['message']?.toString() ?? 'Unable to start payment.',
        );
      }

      final data = ApiResponseHelpers.dataAsMap(subscribeRes) ?? subscribeRes;
      final orderId = data['razorpayOrderId']?.toString() ??
          data['orderId']?.toString();
      final amountRaw = data['amount'] ?? _amount;
      final amount = amountRaw is num
          ? amountRaw.toDouble()
          : (double.tryParse(amountRaw.toString()) ?? _amount);

      final user = auth.currentUser;
      final email = user['email']?.toString();
      final phone = user['phoneNumber']?.toString() ?? user['phone']?.toString();

      _razorpay.openCheckout(
        options: PaymentOptionsModel(
          amount: amount,
          orderId: orderId,
          description: 'Artable Prime Membership',
          userEmail: email,
          userContact: phone,
          notes: {'planId': planId},
        ),
        onResult: (PaymentResult result) async {
          if (!mounted) return;
          if (result.isSuccess &&
              result.paymentId != null &&
              result.orderId != null &&
              result.signature != null) {
            try {
              final verify = await _repository().verifyPayment(
                planId: planId,
                razorpayOrderId: result.orderId!,
                razorpayPaymentId: result.paymentId!,
                razorpaySignature: result.signature!,
                sessionToken: auth.sessionToken,
                refreshToken: auth.refreshToken,
              );
              if (!mounted) return;
              setState(() => _paying = false);
              if (verify['success'] == true) {
                context.go('/subscription-success');
              } else {
                _showError(verify['message']?.toString() ??
                    'Payment verification failed.');
              }
            } catch (e) {
              if (mounted) {
                setState(() => _paying = false);
                _showError(e.toString());
              }
            }
          } else if (result.isFailed) {
            setState(() => _paying = false);
            _showError(result.errorMessage ?? 'Payment was not completed.');
          } else {
            setState(() => _paying = false);
          }
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _paying = false);
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF3D77),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final priceStr = _priceStr;

    return AppScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppBackHeader(title: 'Prime Subscription'),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
              child: AppContent(
                noBottomPad: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  const SizedBox(height: 8),

                  // Payment Summary Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFAF7FF),
                          Color(0x0F8B3DFF),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0x175E2EAA),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x0F15083C),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Plan Row
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF5A75F0), Color(0xFF9248FF)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF5A75F0).withValues(alpha: 0.20),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.diamond_rounded,
                                size: 19,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Artable Prime',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.text,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Premium Membership',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.purple,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Benefits Box
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0x0A8B3DFF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: const [
                              _PaymentBenefitRow(
                                icon: Icons.block_rounded,
                                text: 'Ad-free experience',
                              ),
                              SizedBox(height: 9),
                              _PaymentBenefitRow(
                                icon: Icons.diamond_rounded,
                                text: 'Diamond profile badge',
                              ),
                              SizedBox(height: 9),
                              _PaymentBenefitRow(
                                icon: Icons.person_outline_rounded,
                                text: 'Premium identity',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Divider Line
                        Container(
                          height: 1,
                          color: AppColors.divider,
                        ),

                        const SizedBox(height: 12),

                        // Total Due Today Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Due Today',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSoft,
                              ),
                            ),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '$priceStr ',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.text,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: 'INR',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.purple,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Payment Method Section Title
                  const Text(
                    'Payment Method',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Payment Method Preview Card
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0x145E2EAA),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x0D15083C),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.inputBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.credit_card_rounded,
                            size: 19,
                            color: AppColors.purple,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Visa •••• 4242',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.text,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Dummy card for preview',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textFaint,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.inputBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'PREVIEW ONLY',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textSoft,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Secure Checkout Card
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0x0D1FAE6A),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0x291FAE6A),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0x1F1FAE6A),
                          ),
                          child: const Icon(
                            Icons.shield_outlined,
                            size: 18,
                            color: Color(0xFF1FAE6A),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Secure Checkout',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.text,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Payments are processed securely via Razorpay.',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSoft,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Bottom Button: Pay $3.99
                  Container(
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
                        onTap: _paying ? null : _pay,
                        borderRadius: BorderRadius.circular(28),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: AppGradients.button,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Center(
                            child: _paying
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.2,
                                    ),
                                  )
                                : Text(
                                    'Pay $priceStr',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Terms subtext
                  const Center(
                    child: Text(
                      'By continuing, you agree to Prime membership terms.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textFaint,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
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

class _PaymentBenefitRow extends StatelessWidget {
  const _PaymentBenefitRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: AppColors.purple,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSoft,
            ),
          ),
        ),
      ],
    );
  }
}

class SubscriptionSuccessScreen extends StatelessWidget {
  const SubscriptionSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top Blue-Purple Gradient Circle Icon with Glow Shadow
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5A75F0), Color(0xFF9248FF)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF9248FF).withValues(alpha: 0.20),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 20),

                // Heading Title: Welcome to Prime
                const Text(
                  'Welcome to Prime',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),

                const SizedBox(height: 8),

                // Description Subtext
                const SizedBox(
                  width: 250,
                  child: Text(
                    'You now have an ad-free experience with a premium diamond badge on your profile.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSoft,
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Prime Member Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5A75F0), Color(0xFF9248FF)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF9248FF).withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.diamond_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Prime Member',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Action Buttons Column
                Column(
                  children: [
                    // Button 1: View My Profile (Gradient Button)
                    Container(
                      width: double.infinity,
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
                          onTap: () => context.go('/my-profile'),
                          borderRadius: BorderRadius.circular(28),
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: AppGradients.button,
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: const Center(
                              child: Text(
                                'View My Profile',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Button 2: Back to Home (Outlined Tinted Button - Flat, No Shadow)
                    SizedBox(
                      width: double.infinity,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            try {
                              context.read<HomeCubit>().loadHomeDashboard(forceRefresh: true);
                            } catch (_) {}
                            try {
                              context.read<TrendingVideosCubit>().loadTrendingVideos(forceRefresh: true);
                            } catch (_) {}
                            context.go('/home');
                          },
                          borderRadius: BorderRadius.circular(28),
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0x0D8B3DFF),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: const Color(0x388B3DFF),
                                width: 1.5,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'Back to Home',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.purple,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

