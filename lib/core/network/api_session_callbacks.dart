class ApiSessionCallbacks {
  const ApiSessionCallbacks({
    required this.getSessionToken,
    required this.getRefreshToken,
    required this.updateSessionTokens,
    required this.onRefreshFailed,
  });

  final Future<String?> Function() getSessionToken;
  final Future<String?> Function() getRefreshToken;
  final Future<void> Function({
    required String sessionToken,
    String? refreshToken,
  }) updateSessionTokens;
  final Future<void> Function() onRefreshFailed;
}
