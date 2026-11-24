import 'package:artable_app/core/constants/api_constants.dart';
import 'package:artable_app/core/network/api_client.dart';
import 'package:artable_app/core/network/api_response_helpers.dart';
import 'package:artable_app/core/network/api_session_callbacks_factory.dart';
import 'package:artable_app/core/storage/auth_storage_service.dart';

class SettingsRepository {
  SettingsRepository({
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

  Future<Map<String, dynamic>> getPrivacySettings({
    String? sessionToken,
    String? refreshToken,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.settingsPrivacy,
      headers: ApiResponseHelpers.authHeaders(
        sessionToken: sessionToken,
        refreshToken: refreshToken,
      ),
    );
    return ApiResponseHelpers.dataAsMap(response) ?? response;
  }

  Future<Map<String, dynamic>> updatePrivacySettings({
    required Map<String, dynamic> body,
    String? sessionToken,
    String? refreshToken,
  }) async {
    return _apiClient.put(
      ApiConstants.settingsPrivacy,
      body: body,
      headers: ApiResponseHelpers.authHeaders(
        sessionToken: sessionToken,
        refreshToken: refreshToken,
      ),
    );
  }

  Future<Map<String, dynamic>> getNotificationSettings({
    String? sessionToken,
    String? refreshToken,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.settingsNotifications,
      headers: ApiResponseHelpers.authHeaders(
        sessionToken: sessionToken,
        refreshToken: refreshToken,
      ),
    );
    return ApiResponseHelpers.dataAsMap(response) ?? response;
  }

  Future<Map<String, dynamic>> updateNotificationSettings({
    required Map<String, dynamic> body,
    String? sessionToken,
    String? refreshToken,
  }) async {
    return _apiClient.put(
      ApiConstants.settingsNotifications,
      body: body,
      headers: ApiResponseHelpers.authHeaders(
        sessionToken: sessionToken,
        refreshToken: refreshToken,
      ),
    );
  }
}