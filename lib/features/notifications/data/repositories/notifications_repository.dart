import 'package:artable_app/core/constants/api_constants.dart';
import 'package:artable_app/core/network/api_client.dart';
import 'package:artable_app/core/network/api_response_helpers.dart';
import 'package:artable_app/core/network/api_session_callbacks_factory.dart';
import 'package:artable_app/core/storage/auth_storage_service.dart';

class NotificationsRepository {
  NotificationsRepository({
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

  Future<List<Map<String, dynamic>>> getNotifications({
    int page = 1,
    int limit = 30,
    String? category,
    String? sessionToken,
    String? refreshToken,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (category != null &&
        category.trim().isNotEmpty &&
        category.toLowerCase() != 'all') {
      params['category'] = category.trim().toLowerCase();
    }

    final path = ApiResponseHelpers.pathWithQuery(
      ApiConstants.notifications,
      params,
    );

    final response = await _apiClient.get(
      path,
      headers: ApiResponseHelpers.authHeaders(
        sessionToken: sessionToken,
        refreshToken: refreshToken,
      ),
    );

    return ApiResponseHelpers.dataAsList(
      response,
      nestedKeys: const ['notifications', 'items', 'list'],
    );
  }

  Future<Map<String, dynamic>> markRead({
    List<String>? ids,
    bool markAll = false,
    String? sessionToken,
    String? refreshToken,
  }) async {
    final body = <String, dynamic>{};
    if (markAll) {
      body['markAll'] = true;
    } else if (ids != null && ids.isNotEmpty) {
      body['ids'] = ids;
    }

    return _apiClient.post(
      ApiConstants.notificationsRead,
      body: body,
      headers: ApiResponseHelpers.authHeaders(
        sessionToken: sessionToken,
        refreshToken: refreshToken,
      ),
    );
  }
}