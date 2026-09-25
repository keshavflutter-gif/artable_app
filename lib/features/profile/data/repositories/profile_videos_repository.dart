import 'package:artable_app/core/network/api_auth_headers.dart';
import 'package:artable_app/core/network/api_client.dart';
import 'package:artable_app/core/network/api_session_callbacks_factory.dart';
import 'package:artable_app/core/storage/auth_storage_service.dart';
import '../models/my_videos_response.dart';

class ProfileVideosRepository {
  ProfileVideosRepository({
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

  Future<MyVideosResponse> getMyVideos({
    String tab = 'ALL',
    int page = 1,
    int limit = 20,
    String? sessionToken,
    String? refreshToken,
  }) async {
    final queryParams = <String, String>{
      'tab': tab.trim().isEmpty ? 'ALL' : tab.trim(),
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final queryString = Uri(queryParameters: queryParams).query;
    final path = '/app/profile/videos?$queryString';

    final headers = (sessionToken != null &&
            sessionToken.isNotEmpty &&
            refreshToken != null &&
            refreshToken.isNotEmpty)
        ? ApiAuthHeaders.authenticated(
            sessionToken: sessionToken,
            refreshToken: refreshToken,
          )
        : null;

    final data = await _apiClient.get(path, headers: headers);
    return MyVideosResponse.fromJson(data);
  }

  Future<Map<String, dynamic>> deleteVideo({
    required String videoId,
    String? sessionToken,
    String? refreshToken,
  }) async {
    final cleanId = videoId.trim();
    String? sToken = sessionToken;
    String? rToken = refreshToken;

    if (sToken == null || sToken.isEmpty || rToken == null || rToken.isEmpty) {
      sToken = await _storageService.getSessionToken();
      rToken = await _storageService.getRefreshToken();
    }

    final headers = (sToken != null && sToken.isNotEmpty && rToken != null && rToken.isNotEmpty)
        ? ApiAuthHeaders.authenticated(
            sessionToken: sToken,
            refreshToken: rToken,
          )
        : null;

    return await _apiClient.delete(
      '/app/videos/$cleanId',
      headers: headers,
    );
  }
}

