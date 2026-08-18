class ApiAuthHeaders {
  ApiAuthHeaders._();

  static Map<String, String> authenticated({
    required String sessionToken,
    required String refreshToken,
  }) {
    return {
      'Authorization': 'Bearer $sessionToken',
      'Refresh-Token': refreshToken,
    };
  }
}
