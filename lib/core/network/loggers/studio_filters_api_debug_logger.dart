import 'dart:convert';
import 'package:flutter/foundation.dart';

class StudioFiltersApiDebugLogger {
  StudioFiltersApiDebugLogger._();

  static void logRequest({
    required String method,
    required String url,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) {
    debugPrint('=== STUDIO API REQUEST ===');
    debugPrint('Method: $method');
    debugPrint('URL: $url');
    if (headers != null && headers.isNotEmpty) {
      final maskedHeaders = Map<String, String>.from(headers);
      if (maskedHeaders.containsKey('Authorization')) {
        maskedHeaders['Authorization'] = '***MASKED***';
      }
      debugPrint('Headers: $maskedHeaders');
    }
    if (body != null && body.isNotEmpty) {
      debugPrint('Body:');
      try {
        debugPrint(const JsonEncoder.withIndent('  ').convert(body));
      } catch (_) {
        debugPrint(body.toString());
      }
    }
  }

  static void logResponse({
    required int statusCode,
    required String responseBody,
    String? url,
  }) {
    debugPrint('=== STUDIO FILTERS CONFIG API RESPONSE ===');
    if (url != null && url.isNotEmpty) {
      debugPrint('URL: $url');
    }
    debugPrint('Status Code: $statusCode');
    debugPrint('Response:');
    try {
      final decoded = jsonDecode(responseBody);
      debugPrint(const JsonEncoder.withIndent('  ').convert(decoded));
    } catch (_) {
      debugPrint(responseBody.isNotEmpty ? responseBody : '{}');
    }
  }
}
