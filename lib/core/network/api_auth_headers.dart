class ApiAuthHeaders {
  ApiAuthHeaders._();

  static Map<String, String> authenticated({
    String? sessionToken,
    String? refreshToken,
  }) {
    final headers = <String, String>{};
    if (sessionToken != null && sessionToken.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${sessionToken.trim()}';
    }
    if (refreshToken != null && refreshToken.trim().isNotEmpty) {
      headers['Refresh-Token'] = refreshToken.trim();
    }
    return headers;
  }
}
