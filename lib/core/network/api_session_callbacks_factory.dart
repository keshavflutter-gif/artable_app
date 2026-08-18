import '../storage/auth_storage_service.dart';
import 'api_session_callbacks.dart';

ApiSessionCallbacks createApiSessionCallbacks({
  required AuthStorageService storage,
  void Function({
    required String sessionToken,
    String? refreshToken,
  })? onTokensRefreshed,
  Future<void> Function()? onSessionRefreshFailed,
}) {
  return ApiSessionCallbacks(
    getRefreshToken: storage.getRefreshToken,
    updateSessionTokens: ({
      required String sessionToken,
      String? refreshToken,
    }) async {
      await storage.updateSessionTokens(
        sessionToken: sessionToken,
        refreshToken: refreshToken,
      );
      onTokensRefreshed?.call(
        sessionToken: sessionToken,
        refreshToken: refreshToken,
      );
    },
    onRefreshFailed: () async {
      await onSessionRefreshFailed?.call();
    },
  );
}
