import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:artable_app/features/payment/data/models/payment_options_model.dart';
import 'package:artable_app/features/payment/data/models/payment_result_model.dart';

/// Service managing the Razorpay payment flow.
///
/// Usage:
/// ```dart
/// final paymentService = RazorpayService();
/// paymentService.init();
///
/// paymentService.openCheckout(
///   options: PaymentOptionsModel(
///     amount: 99.0,
///     description: 'Prime Membership',
///     userEmail: 'user@example.com',
///     userContact: '9876543210',
///   ),
///   onResult: (result) {
///     if (result.isSuccess) {
///       // Verify on your backend using result.paymentId, result.orderId, result.signature
///     } else if (result.isFailed) {
///       // Handle error: result.errorMessage
///     }
///   },
/// );
///
/// // Clean up when widget is disposed:
/// paymentService.dispose();
/// ```
class RazorpayService {
  Razorpay? _razorpay;
  void Function(PaymentResult result)? _currentCallback;
  bool _isInitialized = false;

  /// Initializes the Razorpay instance and attaches event listeners.
  void init() {
    if (_isInitialized && _razorpay != null) return;

    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _isInitialized = true;
    debugPrint('RazorpayService: Initialized successfully');
  }

  /// Opens the Razorpay checkout interface.
  void openCheckout({
    required PaymentOptionsModel options,
    required void Function(PaymentResult result) onResult,
  }) {
    if (!_isInitialized || _razorpay == null) {
      init();
    }

    _currentCallback = onResult;

    try {
      debugPrint(
          'RazorpayService: Opening checkout for amount ₹${options.amount}');
      _razorpay!.open(options.toMap());
    } catch (e, stackTrace) {
      debugPrint('RazorpayService: Error opening checkout: $e\n$stackTrace');
      _currentCallback?.call(
        PaymentResult.failure(
          code: -1,
          message: e.toString(),
        ),
      );
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('RazorpayService: Payment Success! ID: ${response.paymentId}');
    final result = PaymentResult.success(
      paymentId: response.paymentId,
      orderId: response.orderId,
      signature: response.signature,
    );
    _currentCallback?.call(result);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('RazorpayService: Payment Error! Code: ${response
        .code}, Message: ${response.message}');
    final result = PaymentResult.failure(
      code: response.code,
      message: response.message,
    );
    _currentCallback?.call(result);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint(
        'RazorpayService: External Wallet Selected: ${response.walletName}');
    final result = PaymentResult.externalWallet(
      walletName: response.walletName,
    );
    _currentCallback?.call(result);
  }

  /// Clears the Razorpay instance and listeners to prevent memory leaks.
  void dispose() {
    try {
      _razorpay?.clear();
      _razorpay = null;
      _currentCallback = null;
      _isInitialized = false;
      debugPrint('RazorpayService: Disposed');
    } catch (e) {
      debugPrint('RazorpayService: Error during dispose: $e');
    }
  }
}

