import 'package:flutter/foundation.dart';
import 'package:artable_app/core/network/api_auth_headers.dart';
import 'package:artable_app/core/network/api_client.dart';
import 'package:artable_app/core/network/api_session_callbacks_factory.dart';
import 'package:artable_app/core/storage/auth_storage_service.dart';
import '../models/wallet_response.dart';
import '../models/wallet_transactions_response.dart';

class WalletRepository {
  WalletRepository({
    ApiClient? apiClient,
    AuthStorageService? storageService,
    void Function({
      required String sessionToken,
      String? refreshToken,
    })? onTokensRefreshed,
    Future<void> Function()? onSessionRefreshFailed,
  }) : _storageService = storageService ?? AuthStorageService() {
    _apiClient = apiClient ??
        ApiClient(
          sessionCallbacks: createApiSessionCallbacks(
            storage: _storageService,
            onTokensRefreshed: onTokensRefreshed,
            onSessionRefreshFailed: onSessionRefreshFailed,
          ),
        );
  }

  late final ApiClient _apiClient;
  final AuthStorageService _storageService;

  Future<WalletResponse> getWalletInfo({
    String? sessionToken,
    String? refreshToken,
  }) async {
    final headers = (sessionToken != null &&
            sessionToken.isNotEmpty &&
            refreshToken != null &&
            refreshToken.isNotEmpty)
        ? ApiAuthHeaders.authenticated(
            sessionToken: sessionToken,
            refreshToken: refreshToken,
          )
        : <String, String>{};

    debugPrint('=== GET WALLET === Requesting /app/wallet');

    final response = await _apiClient.get(
      '/app/wallet',
      headers: headers.isNotEmpty ? headers : null,
    );

    debugPrint('=== GET WALLET === Response status: ${response['success']}');

    return WalletResponse.fromJson(response);
  }

  Future<WalletTransactionsResponse> getWalletTransactions({
    String? tab,
    String? type,
    int page = 1,
    int limit = 20,
    String? sessionToken,
    String? refreshToken,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (tab != null && tab.trim().isNotEmpty && tab.trim().toLowerCase() != 'all') {
      queryParams['tab'] = tab.trim();
    }
    if (type != null && type.trim().isNotEmpty) {
      queryParams['type'] = type.trim();
    }

    final headers = (sessionToken != null &&
            sessionToken.isNotEmpty &&
            refreshToken != null &&
            refreshToken.isNotEmpty)
        ? ApiAuthHeaders.authenticated(
            sessionToken: sessionToken,
            refreshToken: refreshToken,
          )
        : <String, String>{};

    final queryString = Uri(queryParameters: queryParams).query;
    final path = queryString.isNotEmpty ? '/app/wallet/transactions?$queryString' : '/app/wallet/transactions';

    debugPrint('=== GET WALLET TRANSACTIONS === Requesting $path');

    final response = await _apiClient.get(
      path,
      headers: headers.isNotEmpty ? headers : null,
    );

    debugPrint('=== GET WALLET TRANSACTIONS === Response status: ${response['success']}');

    return WalletTransactionsResponse.fromJson(response);
  }
}
