/// Payment-related constants and configuration.
class PaymentConstants {
  PaymentConstants._();

  /// Replace with your Razorpay Key ID (Test key: rzp_test_..., Live key: rzp_live_...)
  /// Keep your Key Secret only on your backend server, never in the Flutter app.
  static const String razorpayKeyId = 'rzp_test_YOUR_KEY_ID';

  /// Default currency code
  static const String currencyINR = 'INR';

  /// Default company/merchant name displayed in Razorpay modal
  static const String merchantName = 'Artable';
}

