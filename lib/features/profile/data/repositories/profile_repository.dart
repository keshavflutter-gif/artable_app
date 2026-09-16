import 'package:artable_app/core/network/api_auth_headers.dart';
import 'package:artable_app/core/network/api_client.dart';
import 'package:artable_app/core/network/api_session_callbacks_factory.dart';
import 'package:artable_app/core/storage/auth_storage_service.dart';
import '../models/profile_response.dart';

class ProfileRepository {
  ProfileRepository({
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

  Future<ProfileResponse> getProfile({
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
        : null;

    final data = await _apiClient.get(
      '/app/profile',
      headers: headers,
    );

    return ProfileResponse.fromJson(data);
  }

  Future<Map<String, dynamic>> deleteVideo({
    required String videoId,
    String? sessionToken,
    String? refreshToken,
  }) async {
    final cleanId = videoId.trim();
    final headers = (sessionToken != null &&
            sessionToken.isNotEmpty &&
            refreshToken != null &&
            refreshToken.isNotEmpty)
        ? ApiAuthHeaders.authenticated(
            sessionToken: sessionToken,
            refreshToken: refreshToken,
          )
        : null;

    try {
      return await _apiClient.delete(
        '/app/videos/$cleanId',
        headers: headers,
      );
    } catch (_) {
      try {
        return await _apiClient.delete(
          '/app/video/$cleanId',
          headers: headers,
        );
      } catch (_) {
        return await _apiClient.delete(
          '/app/profile/videos/$cleanId',
          headers: headers,
        );
      }
    }
  }
}

