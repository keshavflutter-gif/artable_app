import 'wallet_response.dart';

class WalletPagination {
  const WalletPagination({
    this.page = 1,
    this.limit = 20,
    this.total = 0,
  });

  final int page;
  final int limit;
  final int total;

  factory WalletPagination.fromJson(Map<String, dynamic> json) {
    return WalletPagination(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

class WalletTransactionsResponse {
  const WalletTransactionsResponse({
    required this.success,
    required this.message,
    this.transactions = const [],
    this.ads = const [],
    this.tabs = const ['All', 'Credit', 'Debit', 'Withdrawal'],
    this.pagination,
  });

  final bool success;
  final String message;
  final List<WalletTransaction> transactions;
  final List<dynamic> ads;
  final List<String> tabs;
  final WalletPagination? pagination;

  factory WalletTransactionsResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'] as List? ?? [];
    final parsedTx = rawData
        .whereType<Map>()
        .map((e) => WalletTransaction.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final rawTabs = (json['tabs'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        ['All', 'Credit', 'Debit', 'Withdrawal'];

    return WalletTransactionsResponse(
      success: json['success'] == true || json['status'] == 200,
      message: json['message']?.toString() ?? 'Successfully',
      transactions: parsedTx,
      ads: json['ads'] as List? ?? [],
      tabs: rawTabs,
      pagination: json['pagination'] is Map
          ? WalletPagination.fromJson(Map<String, dynamic>.from(json['pagination'] as Map))
          : null,
    );
  }
}
