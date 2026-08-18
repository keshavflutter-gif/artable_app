import 'package:artable_app/core/network/api_auth_headers.dart';
import 'package:artable_app/core/network/api_client.dart';
import 'package:artable_app/core/network/api_session_callbacks_factory.dart';
import 'package:artable_app/core/storage/auth_storage_service.dart';
import '../models/challenge_detail_response.dart';

class ChallengesRepository {
  ChallengesRepository({
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

  Future<ChallengeDetailResponse> getChallengeDetail({
    required String challengeId,
    String? sessionToken,
    String? refreshToken,
  }) async {
    final path = '/app/challenges/$challengeId';

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

    return ChallengeDetailResponse.fromJson(data);
  }

  Future<ChallengesListResponse> getChallenges({
    String? tab,
    String? categoryId,
    int page = 1,
    int limit = 20,
    String? query,
    String? sessionToken,
    String? refreshToken,
  }) async {
    final queryParams = <String, String>{
      if (tab != null && tab.isNotEmpty) 'tab': tab.toUpperCase(),
      if (categoryId != null && categoryId.trim().isNotEmpty)
        'categoryId': categoryId.trim(),
      if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final queryString = Uri(queryParameters: queryParams).query;
    final path = '/app/challenges?$queryString';

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

    return ChallengesListResponse.fromJson(data);
  }

  Future<JoinChallengeResponse> joinChallenge({
    required String challengeId,
    String? sessionToken,
    String? refreshToken,
  }) async {
    final path = '/app/challenges/$challengeId/join';

    final headers = (sessionToken != null &&
            sessionToken.isNotEmpty &&
            refreshToken != null &&
            refreshToken.isNotEmpty)
        ? ApiAuthHeaders.authenticated(
            sessionToken: sessionToken,
            refreshToken: refreshToken,
          )
        : <String, String>{};

    final data = await _apiClient.post(
      path,
      headers: headers.isNotEmpty ? headers : null,
    );

    return JoinChallengeResponse.fromJson(data);
  }
}

