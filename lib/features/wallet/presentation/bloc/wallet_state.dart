import 'package:artable_app/features/wallet/data/models/wallet_response.dart';
import 'package:artable_app/features/wallet/data/models/wallet_transactions_response.dart';

class WalletState {
  const WalletState({
    this.isLoading = false,
    this.hasLoaded = false,
    this.errorMessage,
    this.response,
    this.walletData,
    this.isTransactionsLoading = false,
    this.hasTransactionsLoaded = false,
    this.transactionsResponse,
    this.transactions = const [],
    this.transactionTabs = const ['All', 'Credit', 'Debit', 'Withdrawal'],
    this.selectedTransactionTab = 'All',
  });

  final bool isLoading;
  final bool hasLoaded;
  final String? errorMessage;
  final WalletResponse? response;
  final WalletData? walletData;

  final bool isTransactionsLoading;
  final bool hasTransactionsLoaded;
  final WalletTransactionsResponse? transactionsResponse;
  final List<WalletTransaction> transactions;
  final List<String> transactionTabs;
  final String selectedTransactionTab;

  WalletState copyWith({
    bool? isLoading,
    bool? hasLoaded,
    String? errorMessage,
    bool clearError = false,
    WalletResponse? response,
    WalletData? walletData,
    bool? isTransactionsLoading,
    bool? hasTransactionsLoaded,
    WalletTransactionsResponse? transactionsResponse,
    List<WalletTransaction>? transactions,
    List<String>? transactionTabs,
    String? selectedTransactionTab,
  }) {
    return WalletState(
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      response: response ?? this.response,
      walletData: walletData ?? this.walletData,
      isTransactionsLoading: isTransactionsLoading ?? this.isTransactionsLoading,
      hasTransactionsLoaded: hasTransactionsLoaded ?? this.hasTransactionsLoaded,
      transactionsResponse: transactionsResponse ?? this.transactionsResponse,
      transactions: transactions ?? this.transactions,
      transactionTabs: transactionTabs ?? this.transactionTabs,
      selectedTransactionTab: selectedTransactionTab ?? this.selectedTransactionTab,
    );
  }
}
