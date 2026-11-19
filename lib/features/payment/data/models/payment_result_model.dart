/// Status outcome of a payment attempt.
enum PaymentStatus {
  success,
  failed,
  externalWallet,
}

/// Unified result model returned by [RazorpayService].
class PaymentResult {
  final PaymentStatus status;

  /// Razorpay Payment ID (present on success).
  final String? paymentId;

  /// Razorpay Order ID (present on success).
  final String? orderId;

  /// Razorpay Signature for server verification (present on success).
  final String? signature;

  /// Error code (present on failure).
  final int? errorCode;

  /// Human-readable error message (present on failure).
  final String? errorMessage;

  /// Selected external wallet name (present on external wallet selection).
  final String? walletName;

  const PaymentResult._({
    required this.status,
    this.paymentId,
    this.orderId,
    this.signature,
    this.errorCode,
    this.errorMessage,
    this.walletName,
  });

  /// Factory for successful payment.
  factory PaymentResult.success({
    required String? paymentId,
    required String? orderId,
    required String? signature,
  }) {
    return PaymentResult._(
      status: PaymentStatus.success,
      paymentId: paymentId,
      orderId: orderId,
      signature: signature,
    );
  }

  /// Factory for failed payment.
  factory PaymentResult.failure({
    required int? code,
    required String? message,
  }) {
    return PaymentResult._(
      status: PaymentStatus.failed,
      errorCode: code,
      errorMessage: message,
    );
  }

  /// Factory for external wallet redirection.
  factory PaymentResult.externalWallet({
    required String? walletName,
  }) {
    return PaymentResult._(
      status: PaymentStatus.externalWallet,
      walletName: walletName,
    );
  }

  bool get isSuccess => status == PaymentStatus.success;
  bool get isFailed => status == PaymentStatus.failed;
  bool get isExternalWallet => status == PaymentStatus.externalWallet;

  @override
  String toString() {
    return 'PaymentResult(status: $status, paymentId: $paymentId, orderId: $orderId, error: $errorMessage)';
  }
}

