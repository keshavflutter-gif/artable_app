import 'package:artable_app/core/constants/payment_constants.dart';

/// Configuration options passed to Razorpay checkout dialog.
class PaymentOptionsModel {
  /// The amount in rupees (e.g., 99.0 for ₹99).
  /// Will be automatically multiplied by 100 to convert to paise for Razorpay.
  final double amount;

  /// Razorpay Order ID generated from your backend server.
  /// Mandatory for authentic backend-verified payments.
  final String? orderId;

  /// Business/Merchant name shown in the payment window.
  final String name;

  /// Short description of the purchase (e.g. "Prime Membership", "Cooking Challenge Entry").
  final String description;

  /// Customer's phone number for prefilling.
  final String? userContact;

  /// Customer's email for prefilling.
  final String? userEmail;

  /// Custom Razorpay Key ID (optional, defaults to PaymentConstants.razorpayKeyId).
  final String? keyId;

  /// Currency code (defaults to 'INR').
  final String currency;

  /// Additional metadata or key-value pairs.
  final Map<String, dynamic>? notes;

  const PaymentOptionsModel({
    required this.amount,
    this.orderId,
    this.name = PaymentConstants.merchantName,
    required this.description,
    this.userContact,
    this.userEmail,
    this.keyId,
    this.currency = PaymentConstants.currencyINR,
    this.notes,
  });

  /// Converts this model to the Map structure required by `Razorpay.open()`.
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
      'key': keyId ?? PaymentConstants.razorpayKeyId,
      // Razorpay expects amount in smallest currency unit (paise for INR)
      'amount': (amount * 100).toInt(),
      'name': name,
      'description': description,
      'currency': currency,
      'timeout': 180, // timeout in seconds
    };

    if (orderId != null && orderId!.isNotEmpty) {
      map['order_id'] = orderId;
    }

    // Prefill customer details
    final Map<String, dynamic> prefill = {};
    if (userContact != null && userContact!.isNotEmpty) {
      prefill['contact'] = userContact;
    }
    if (userEmail != null && userEmail!.isNotEmpty) {
      prefill['email'] = userEmail;
    }
    if (prefill.isNotEmpty) {
      map['prefill'] = prefill;
    }

    // External wallets support (Paytm, etc.)
    map['external'] = {
      'wallets': ['paytm']
    };

    if (notes != null && notes!.isNotEmpty) {
      map['notes'] = notes;
    }

    return map;
  }
}

