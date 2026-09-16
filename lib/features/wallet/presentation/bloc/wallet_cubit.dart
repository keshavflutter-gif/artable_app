import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:artable_app/features/wallet/data/models/wallet_response.dart';
import 'package:artable_app/features/wallet/data/repositories/wallet_repository.dart';
import 'wallet_state.dart';

class WalletCubit extends Cubit<WalletState> {
  WalletCubit({
    AuthCubit? authCubit,
    WalletRepository? walletRepository,
  })  : _authCubit = authCubit,
        _walletRepository = walletRepository ??
            WalletRepository(
              onTokensRefreshed: authCubit?.applyRefreshedTokens,
              onSessionRefreshFailed: authCubit?.handleSessionRefreshFailed,
            ),
        super(const WalletState());

  final AuthCubit? _authCubit;
  final WalletRepository _walletRepository;

  bool get hasLoaded => state.hasLoaded;
  WalletData? get walletData => state.walletData;

  Future<void> loadWalletInfo({bool forceRefresh = false}) async {
    if (state.hasLoaded && !forceRefresh && !state.isLoading) return;

    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final res = await _walletRepository.getWalletInfo(
        sessionToken: _authCubit?.sessionToken,
        refreshToken: _authCubit?.refreshToken,
      );

      emit(state.copyWith(
        isLoading: false,
        hasLoaded: true,
        response: res,
        walletData: res.data,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load wallet data: $e',
      ));
    }
  }

  Future<void> loadWalletTransactions({
    bool forceRefresh = false,
    String? tab,
    int page = 1,
  }) async {
    final targetTab = tab ?? state.selectedTransactionTab;
    if (state.hasTransactionsLoaded && !forceRefresh && !state.isTransactionsLoading && targetTab == state.selectedTransactionTab) {
      return;
    }

    emit(state.copyWith(
      isTransactionsLoading: true,
      selectedTransactionTab: targetTab,
      clearError: true,
    ));

    try {
      final res = await _walletRepository.getWalletTransactions(
        tab: targetTab,
        page: page,
        sessionToken: _authCubit?.sessionToken,
        refreshToken: _authCubit?.refreshToken,
      );

      final tabsList = res.tabs.isNotEmpty ? res.tabs : state.transactionTabs;

      emit(state.copyWith(
        isTransactionsLoading: false,
        hasTransactionsLoaded: true,
        transactionsResponse: res,
        transactionTabs: tabsList,
        transactions: res.transactions,
      ));
    } catch (e) {
      emit(state.copyWith(
        isTransactionsLoading: false,
        errorMessage: 'Failed to load transactions: $e',
      ));
    }
  }

  void selectTransactionTab(String tab) {
    loadWalletTransactions(forceRefresh: true, tab: tab);
  }
}
