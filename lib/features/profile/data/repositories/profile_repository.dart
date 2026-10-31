import 'package:artable_app/core/network/api_auth_headers.dart';
import 'package:artable_app/core/network/api_client.dart';
import 'package:artable_app/core/network/api_session_callbacks_factory.dart';
import 'package:artable_app/core/storage/auth_storage_service.dart';
import '../models/follow_response.dart';
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

    // Fire both endpoints together — sequential calls were doubling profile wait.
    final results = await Future.wait<Object?>([
      _apiClient
          .get('/app/profile', headers: headers)
          .then<Object?>((data) => ProfileResponse.fromJson(data))
          .catchError((_) => null),
      _apiClient
          .get('/user', headers: headers)
          .then<Object?>((data) => data)
          .catchError((_) => null),
    ]);

    final profile = results[0] is ProfileResponse ? results[0] as ProfileResponse : null;
    final userJson = results[1] is Map
        ? Map<String, dynamic>.from(results[1] as Map)
        : null;

    if (profile != null) {
      if (userJson == null) return profile;
      try {
        final userProfile = ProfileResponse.fromJson(userJson);
        if (userProfile.data.recentVideos.isEmpty) return profile;
        final existingIds = profile.data.recentVideos.map((v) => v.id).toSet();
        final mergedVideos = [
          ...profile.data.recentVideos,
          ...userProfile.data.recentVideos
              .where((v) => v.id.isNotEmpty && existingIds.add(v.id)),
        ];
        return ProfileResponse(
          success: profile.success,
          message: profile.message,
          data: profile.data.copyWith(recentVideos: mergedVideos),
        );
      } catch (_) {
        return profile;
      }
    }

    if (userJson != null) {
      return ProfileResponse.fromJson(userJson);
    }

    throw Exception('Failed to load profile');
  }

  Future<FollowResponse> toggleFollow({
    required String profileId,
    String? sessionToken,
    String? refreshToken,
  }) async {
    final cleanId = profileId.trim();
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

    final data = await _apiClient.post(
      '/app/profiles/$cleanId/follow',
      headers: headers,
    );

    return FollowResponse.fromJson(data);
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

