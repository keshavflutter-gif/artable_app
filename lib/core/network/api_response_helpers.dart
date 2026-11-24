import 'package:artable_app/core/network/api_auth_headers.dart';

/// Shared helpers for typical `{ success, message, data }` API envelopes.
class ApiResponseHelpers {
  ApiResponseHelpers._();

  static Map<String, String>? authHeaders({
    String? sessionToken,
    String? refreshToken,
  }) {
    if (sessionToken != null &&
        sessionToken.isNotEmpty &&
        refreshToken != null &&
        refreshToken.isNotEmpty) {
      return ApiAuthHeaders.authenticated(
        sessionToken: sessionToken,
        refreshToken: refreshToken,
      );
    }
    return null;
  }

  static Map<String, dynamic>? dataAsMap(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  static List<Map<String, dynamic>> dataAsList(
    Map<String, dynamic> response, {
    List<String> nestedKeys = const [
      'items',
      'notifications',
      'activities',
      'results',
      'tracks',
      'plans',
      'rewards',
      'withdrawals',
      'videos',
      'creators',
      'challenges',
      'list',
      'rows',
    ],
  }) {
    final data = response['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      for (final key in nestedKeys) {
        final raw = map[key];
        if (raw is List) {
          return raw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
      // Single-object payloads (e.g. settings).
      return [map];
    }
    final top = response['results'];
    if (top is List) {
      return top
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  static String pathWithQuery(String path, Map<String, String> queryParams) {
    if (queryParams.isEmpty) return path;
    final qs = Uri(queryParameters: queryParams).query;
    return qs.isNotEmpty ? '$path?$qs' : path;
  }

  static bool isSuccess(Map<String, dynamic> response) =>
      response['success'] == true;

  static String? message(Map<String, dynamic> response) =>
      response['message']?.toString();
}