import 'package:artable_app/core/network/api_auth_headers.dart';
import 'package:artable_app/core/network/api_client.dart';
import 'package:artable_app/core/network/api_session_callbacks_factory.dart';
import 'package:artable_app/core/storage/auth_storage_service.dart';
import '../models/achievements_response.dart';

class AchievementsRepository {
  AchievementsRepository({
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

  Future<AchievementsResponse> getAchievements({
    required String sessionToken,
    required String refreshToken,
  }) async {
    final data = await _apiClient.get(
      '/app/profile/achievements',
      headers: ApiAuthHeaders.authenticated(
        sessionToken: sessionToken,
        refreshToken: refreshToken,
      ),
    );

    return AchievementsResponse.fromJson(data);
  }
}
