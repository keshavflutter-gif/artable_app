import 'package:flutter/foundation.dart';
import 'package:artable_app/core/network/api_auth_headers.dart';
import 'package:artable_app/core/network/api_client.dart';
import 'package:artable_app/core/network/api_session_callbacks_factory.dart';
import 'package:artable_app/core/storage/auth_storage_service.dart';
import '../models/winners_response.dart';

class WinnersRepository {
  WinnersRepository({
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

  Future<WinnersResponse> getWinners({
    String? tab,
    String? sessionToken,
    String? refreshToken,
  }) async {
    final queryParams = <String, String>{};
    if (tab != null && tab.trim().isNotEmpty) {
      queryParams['tab'] = tab.trim();
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

    debugPrint('=== GET WINNERS === Requesting /app/winners queryParams: $queryParams');

    final queryString = Uri(queryParameters: queryParams).query;
    final path = queryString.isNotEmpty ? '/app/winners?$queryString' : '/app/winners';

    final response = await _apiClient.get(
      path,
      headers: headers.isNotEmpty ? headers : null,
    );

    debugPrint('=== GET WINNERS === Response received: ${response['success']}');

    return WinnersResponse.fromJson(response);
  }
}
