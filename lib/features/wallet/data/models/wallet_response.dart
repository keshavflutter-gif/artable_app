class WalletInfo {
  const WalletInfo({
    this.id,
    this.userId,
    this.balance,
    this.coins,
    this.points,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String? userId;
  final String? balance;
  final int? coins;
  final int? points;
  final String? createdAt;
  final String? updatedAt;

  double get balanceNum {
    if (balance == null) return 0.0;
    return double.tryParse(balance!) ?? 0.0;
  }

  String get displayBalance {
    if (balance == null || balance!.isEmpty) return '₹0';
    final val = balanceNum;
    if (val < 0) {
      return '-₹${val.abs().toStringAsFixed(0)}';
    }
    return '₹${val.toStringAsFixed(0)}';
  }

  factory WalletInfo.fromJson(Map<String, dynamic> json) {
    return WalletInfo(
      id: json['id']?.toString(),
      userId: json['userId']?.toString(),
      balance: json['balance']?.toString(),
      coins: (json['coins'] as num?)?.toInt(),
      points: (json['points'] as num?)?.toInt(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'balance': balance,
      'coins': coins,
      'points': points,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class EarningsSummaryItem {
  const EarningsSummaryItem({
    this.type,
    this.amount,
  });

  final String? type;
  final String? amount;

  factory EarningsSummaryItem.fromJson(Map<String, dynamic> json) {
    String? amt;
    if (json['_sum'] is Map) {
      amt = (json['_sum'] as Map)['amount']?.toString();
    } else {
      amt = json['amount']?.toString();
    }
    return EarningsSummaryItem(
      type: json['type']?.toString(),
      amount: amt,
    );
  }
}

class WalletTransaction {
  const WalletTransaction({
    required this.id,
    this.userId,
    this.type,
    this.status,
    this.amount,
    this.coins,
    this.points,
    this.reference,
    this.paymentProvider,
    this.providerOrderId,
    this.providerPaymentId,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.label,
    this.signedAmount,
  });

  final String id;
  final String? userId;
  final String? type;
  final String? status;
  final String? amount;
  final int? coins;
  final int? points;
  final String? reference;
  final String? paymentProvider;
  final String? providerOrderId;
  final String? providerPaymentId;
  final String? description;
  final String? createdAt;
  final String? updatedAt;
  final String? label;
  final String? signedAmount;

  double get amountNum {
    if (amount == null) return 0.0;
    return double.tryParse(amount!) ?? 0.0;
  }

  bool get isWithdrawal =>
      type?.toUpperCase() == 'WITHDRAWAL' || type?.toUpperCase() == 'DEBIT';

  bool get isCredit =>
      type?.toUpperCase() == 'BONUS' ||
      type?.toUpperCase() == 'CREDIT' ||
      type?.toUpperCase() == 'REWARD' ||
      type?.toUpperCase() == 'CHALLENGE_WIN';

  String get displayTitle {
    if (label != null && label!.trim().isNotEmpty) return label!.trim();
    if (description != null && description!.trim().isNotEmpty) {
      return description!.trim();
    }
    if (type != null && type!.isNotEmpty) return type!;
    return 'Transaction';
  }

  String get displayAmount {
    if (signedAmount != null && signedAmount!.trim().isNotEmpty) {
      final s = signedAmount!.trim();
      if (s.startsWith('-')) {
        return '-₹${s.substring(1)}';
      }
      if (s.startsWith('+')) {
        return '+₹${s.substring(1)}';
      }
      return s;
    }
    final amt = amountNum;
    if (isWithdrawal) {
      return '-₹${amt.toStringAsFixed(0)}';
    }
    if (amt > 0) {
      return '+₹${amt.toStringAsFixed(0)}';
    }
    if (coins != null && coins! > 0) {
      return '+${coins!} Coins';
    }
    if (points != null && points! > 0) {
      return '+${points!} Pts';
    }
    return '₹${amt.toStringAsFixed(0)}';
  }

  String get categoryKey {
    final t = (type ?? '').toLowerCase();
    if (t.contains('withdraw')) return 'withdrawal';
    if (t.contains('bonus') || t.contains('daily')) return 'daily_bonus';
    if (t.contains('win') || t.contains('challenge')) return 'challenge_win';
    if (t.contains('referral')) return 'referral';
    if (t.contains('voucher')) return 'voucher';
    return 'other';
  }

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString(),
      type: json['type']?.toString(),
      status: json['status']?.toString(),
      amount: json['amount']?.toString(),
      coins: (json['coins'] as num?)?.toInt(),
      points: (json['points'] as num?)?.toInt(),
      reference: json['reference']?.toString(),
      paymentProvider: json['paymentProvider']?.toString(),
      providerOrderId: json['providerOrderId']?.toString(),
      providerPaymentId: json['providerPaymentId']?.toString(),
      description: json['description']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      label: json['label']?.toString(),
      signedAmount: json['signedAmount']?.toString(),
    );
  }

  Map<String, dynamic> toUiMap() {
    return {
      'id': id,
      'title': displayTitle,
      'amount': displayAmount,
      'date': createdAt ?? '',
      'type': isWithdrawal ? 'debit' : 'credit',
      'category': categoryKey,
      'status': status ?? 'Completed',
    };
  }
}

class WalletData {
  const WalletData({
    this.wallet,
    this.minimumWithdrawalAmount = 50.0,
    this.withdrawalEnabled = true,
    this.pendingAmount = 0.0,
    this.withdrawnAmount,
    this.earningsSummary = const [],
    this.recentTransactions = const [],
  });

  final WalletInfo? wallet;
  final double minimumWithdrawalAmount;
  final bool withdrawalEnabled;
  final double pendingAmount;
  final String? withdrawnAmount;
  final List<EarningsSummaryItem> earningsSummary;
  final List<WalletTransaction> recentTransactions;

  String get displayAvailableBalance => wallet?.displayBalance ?? '₹0';
  String get displayWithdrawnAmount {
    if (withdrawnAmount == null || withdrawnAmount!.isEmpty) return '₹0';
    final amt = double.tryParse(withdrawnAmount!) ?? 0.0;
    return '₹${amt.toStringAsFixed(0)}';
  }

  String get displayPendingAmount {
    return '₹${pendingAmount.toStringAsFixed(0)}';
  }

  factory WalletData.fromJson(Map<String, dynamic> json) {
    final rawSummary = json['earningsSummary'] as List? ?? [];
    final parsedSummary = rawSummary
        .whereType<Map>()
        .map((e) => EarningsSummaryItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final rawTx = json['recentTransactions'] as List? ?? [];
    final parsedTx = rawTx
        .whereType<Map>()
        .map((e) => WalletTransaction.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return WalletData(
      wallet: json['wallet'] is Map
          ? WalletInfo.fromJson(Map<String, dynamic>.from(json['wallet'] as Map))
          : null,
      minimumWithdrawalAmount:
          (json['minimumWithdrawalAmount'] as num?)?.toDouble() ?? 50.0,
      withdrawalEnabled: json['withdrawalEnabled'] == true,
      pendingAmount: (json['pendingAmount'] as num?)?.toDouble() ?? 0.0,
      withdrawnAmount: json['withdrawnAmount']?.toString(),
      earningsSummary: parsedSummary,
      recentTransactions: parsedTx,
    );
  }
}

class WalletResponse {
  const WalletResponse({
    required this.success,
    required this.message,
    this.data,
  });

  final bool success;
  final String message;
  final WalletData? data;

  factory WalletResponse.fromJson(Map<String, dynamic> json) {
    return WalletResponse(
      success: json['success'] == true || json['status'] == 200,
      message: json['message']?.toString() ?? 'Successfully',
      data: json['data'] is Map
          ? WalletData.fromJson(Map<String, dynamic>.from(json['data'] as Map))
          : null,
    );
  }
}
