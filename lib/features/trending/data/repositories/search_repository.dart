import 'package:artable_app/core/constants/api_constants.dart';
import 'package:artable_app/core/network/api_client.dart';
import 'package:artable_app/core/network/api_response_helpers.dart';
import 'package:artable_app/core/network/api_session_callbacks_factory.dart';
import 'package:artable_app/core/storage/auth_storage_service.dart';

class SearchRepository {
  SearchRepository({
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

  Future<Map<String, dynamic>> search({
    required String query,
    String? tab,
    int page = 1,
    int limit = 20,
    String? sessionToken,
    String? refreshToken,
  }) async {
    final params = <String, String>{
      'q': query.trim(),
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (tab != null && tab.trim().isNotEmpty) {
      params['tab'] = tab.trim().toLowerCase();
    }

    final path = ApiResponseHelpers.pathWithQuery(ApiConstants.search, params);
    final response = await _apiClient.get(
      path,
      headers: ApiResponseHelpers.authHeaders(
        sessionToken: sessionToken,
        refreshToken: refreshToken,
      ),
    );

    final data = ApiResponseHelpers.dataAsMap(response) ?? response;
    return {
      'success': response['success'] == true,
      'message': response['message'],
      'videos': _extractList(data, const ['videos', 'videoResults']),
      'creators': _extractList(data, const ['creators', 'users', 'profiles']),
      'challenges':
          _extractList(data, const ['challenges', 'challengeResults']),
    };
  }

  List<Map<String, dynamic>> _extractList(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final raw = data[key];
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }
    return const [];
  }
}