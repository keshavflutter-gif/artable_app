import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/core/widgets/app_back_header.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';
import 'package:artable_app/core/widgets/gradient_button.dart';
import 'package:artable_app/data/datasources/mock_data.dart';

class WithdrawalRequestScreen extends StatefulWidget {
  const WithdrawalRequestScreen({super.key});

  @override
  State<WithdrawalRequestScreen> createState() => _WithdrawalRequestScreenState();
}

class _WithdrawalRequestScreenState extends State<WithdrawalRequestScreen> {
  final _amountController = TextEditingController();
  var _success = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = '0.00';
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _onQuickSelect(String val, String available) {
    if (val == 'Max') {
      final cleanVal = available.replaceAll(RegExp(r'[^0-9.]'), '');
      _amountController.text = double.tryParse(cleanVal)?.toStringAsFixed(2) ?? cleanVal;
    } else {
      _amountController.text = double.tryParse(val)?.toStringAsFixed(2) ?? val;
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = MockData.WALLET_SUMMARY;
    final availableStr = wallet['availableBalance'] ?? '₹1,240';

    if (_success) {
      return AppScreen(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: Color(0xFFE6F8F3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 56,
                  color: Color(0xFF00C897),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Withdrawal Requested',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Color(0xFF241E38),
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '₹${_amountController.text} will be processed shortly.',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF8B849C),
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 2),
              GradientButton(
                label: 'Back to Wallet',
                onPressed: () => context.go('/wallet'),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      );
    }

    return AppScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppBackHeader(title: 'Withdraw Funds'),
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: AppContent(
                noBottomPad: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // Available Balance Gradient Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF1E1343), // Dark Navy
                            Color(0xFF4C1D95), // Deep Violet
                            Color(0xFF7C3AED), // Purple
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4C1D95).withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
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
                                  'AVAILABLE BALANCE',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: Colors.white.withValues(alpha: 0.65),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  availableStr,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 28,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Withdrawal Amount Header Label
                    const Text(
                      'Withdrawal Amount',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Color(0xFF241E38),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Input Box with Rupee sign prefix
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F7FC),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFECE8F5), width: 1.2),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            '₹',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Color(0xFF241E38),
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                color: Color(0xFF241E38),
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                              cursorColor: const Color(0xFF8B3DFF),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                filled: false,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Minimum Warning
                    const Text(
                      'Minimum withdrawal: ₹50',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF8B849C),
                        fontWeight: FontWeight.w500,
                        fontSize: 10.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quick Select Buttons
                    Row(
                      children: ['50', '100', '250', 'Max'].map((val) {
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => _onQuickSelect(val, availableStr),
                            child: Container(
                              margin: EdgeInsets.only(
                                left: val == '50' ? 0 : 4,
                                right: val == 'Max' ? 0 : 4,
                              ),
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFECE8F5), width: 1.2),
                              ),
                              child: Center(
                                child: Text(
                                  val == 'Max' ? 'Max' : '₹$val',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    color: Color(0xFF8B849C),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Verified Bank Account Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
                          Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF3EAFD),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.account_balance_outlined,
                              color: Color(0xFF8B3DFF),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Bank Account (Razorpay)',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Color(0xFF241E38),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  '•••• •••• •••• 4821',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: Color(0xFF8B849C),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Verified Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE6F8F3),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'VERIFIED',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      color: Color(0xFF00C897),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 7.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF8B3DFF),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Payout info box
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
                            Icons.info_outline_rounded,
                            color: Color(0xFF8B3DFF),
                            size: 18,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Payouts via Razorpay',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Color(0xFF241E38),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Withdrawals are processed securely through Razorpay and usually reach your bank within 2-3 business days.',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: Color(0xFF8B849C),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 10,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Request Button
                    Container(
                      height: 54,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: AppGradients.button,
                        borderRadius: BorderRadius.circular(27),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5487).withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            final parsed = double.tryParse(_amountController.text) ?? 0.0;
                            if (parsed >= 50.0) {
                              setState(() => _success = true);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Minimum withdrawal amount is ₹50.'),
                                  backgroundColor: Color(0xFFFF3D77),
                                ),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(27),
                          child: const Center(
                            child: Text(
                              'Request Withdrawal',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Reviewed footer disclaimer
                    const Center(
                      child: Text(
                        'Withdrawal requests are reviewed before processing.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFFB5ADC8),
                          fontWeight: FontWeight.w500,
                          fontSize: 10.5,
                        ),
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
}
