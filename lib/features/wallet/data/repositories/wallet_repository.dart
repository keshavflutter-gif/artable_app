import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:artable_app/core/constants/api_constants.dart';
import 'package:artable_app/core/network/api_auth_headers.dart';
import 'package:artable_app/core/network/api_client.dart';
import 'package:artable_app/core/network/api_response_helpers.dart';
import 'package:artable_app/core/network/api_session_callbacks_factory.dart';
import 'package:artable_app/core/storage/auth_storage_service.dart';
import 'package:artable_app/core/storage/local_storage.dart';
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
      ApiConstants.wallet,
      headers: headers.isNotEmpty ? headers : null,
    );

    debugPrint('=== GET WALLET === Response status: ${response['success']}');

    if (response['success'] == true && response['data'] != null) {
      try {
        LocalStorage.rawPrefs?.setString('cached_wallet_info', jsonEncode(response));
      } catch (_) {}
    }

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
    final path = queryString.isNotEmpty
        ? '${ApiConstants.walletTransactions}?$queryString'
        : ApiConstants.walletTransactions;

    debugPrint('=== GET WALLET TRANSACTIONS === Requesting $path');

    final response = await _apiClient.get(
      path,
      headers: headers.isNotEmpty ? headers : null,
    );

    debugPrint('=== GET WALLET TRANSACTIONS === Response status: ${response['success']}');

    return WalletTransactionsResponse.fromJson(response);
  }

  Future<Map<String, dynamic>> requestWithdraw({
    required num amount,
    String currency = 'INR',
    String? sessionToken,
    String? refreshToken,
  }) async {
    final headers = ApiResponseHelpers.authHeaders(
      sessionToken: sessionToken,
      refreshToken: refreshToken,
    );

    debugPrint(
      '=== POST WALLET WITHDRAW === amount=$amount currency=$currency',
    );

    return _apiClient.post(
      ApiConstants.walletWithdraw,
      body: {
        'amount': amount,
        'currency': currency,
      },
      headers: headers,
    );
  }

  Future<List<Map<String, dynamic>>> getWithdrawals({
    int page = 1,
    int limit = 20,
    String? sessionToken,
    String? refreshToken,
  }) async {
    final headers = ApiResponseHelpers.authHeaders(
      sessionToken: sessionToken,
      refreshToken: refreshToken,
    );

    final path = ApiResponseHelpers.pathWithQuery(
      ApiConstants.walletWithdrawals,
      {
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );

    final response = await _apiClient.get(path, headers: headers);
    return ApiResponseHelpers.dataAsList(
      response,
      nestedKeys: const ['withdrawals', 'items', 'list'],
    );
  }
}
