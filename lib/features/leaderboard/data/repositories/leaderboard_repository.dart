import 'package:artable_app/core/network/api_auth_headers.dart';
import 'package:artable_app/core/network/api_client.dart';
import 'package:artable_app/core/network/api_session_callbacks_factory.dart';
import 'package:artable_app/core/storage/auth_storage_service.dart';
import '../models/leaderboard_response.dart';

class LeaderboardRepository {
  LeaderboardRepository({
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

  Future<LeaderboardResponse> getLeaderboard({
    String? scope,
    String? category,
    String? categoryId,
    String? challengeId,
    int page = 1,
    int limit = 20,
    String? sessionToken,
    String? refreshToken,
  }) async {
    final queryParams = <String, String>{
      if (scope != null && scope.trim().isNotEmpty)
        'scope': scope.trim().toUpperCase(),
      if (category != null &&
          category.trim().isNotEmpty &&
          category.trim().toLowerCase() != 'all categories')
        'category': category.trim(),
      if (categoryId != null && categoryId.trim().isNotEmpty)
        'categoryId': categoryId.trim(),
      if (challengeId != null && challengeId.trim().isNotEmpty)
        'challengeId': challengeId.trim(),
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final queryString = Uri(queryParameters: queryParams).query;
    final path = queryParams.isNotEmpty
        ? '/app/leaderboard?$queryString'
        : '/app/leaderboard';

    final headers = (sessionToken != null &&
            sessionToken.isNotEmpty &&
            refreshToken != null &&
            refreshToken.isNotEmpty)
        ? ApiAuthHeaders.authenticated(
            sessionToken: sessionToken,
            refreshToken: refreshToken,
          )
        : <String, String>{};

    final data = await _apiClient.get(
      path,
      headers: headers.isNotEmpty ? headers : null,
    );

    return LeaderboardResponse.fromJson(data);
  }
}
