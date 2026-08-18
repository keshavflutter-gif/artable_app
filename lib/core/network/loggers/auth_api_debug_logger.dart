import 'dart:convert';

import 'package:flutter/foundation.dart';

class AuthApiDebugLogger {
  AuthApiDebugLogger._();

  static const _sensitiveKeys = {
    'password',
    'sessiontoken',
    'refreshtoken',
    'token',
    'accesstoken',
    'authorization',
  };

  static void logRequest({
    required String method,
    required String url,
    required Map<String, String> headers,
    Map<String, dynamic>? body,
    required String apiLabel,
  }) {
    final maskedHeaders = _maskMap(headers);
    final maskedBody = body != null ? _maskMap(body) : null;

    debugPrint('=== $apiLabel API REQUEST ===');
    debugPrint('Method: $method');
    debugPrint('URL: $url');
    debugPrint('Headers: $maskedHeaders');
    if (maskedBody != null) {
      debugPrint('Body: ${const JsonEncoder.withIndent('  ').convert(maskedBody)}');
    }
  }

  static void logResponse({
    required String apiLabel,
    required int statusCode,
    required String responseBody,
    String? url,
    Map<String, dynamic>? responseData,
  }) {
    final maskedBody = _maskJsonString(responseBody);
    final maskedData = responseData == null
        ? null
        : const JsonEncoder.withIndent('  ').convert(_maskMap(responseData));

    debugPrint('=== $apiLabel API RESPONSE ===');
    if (url != null && url.isNotEmpty) {
      debugPrint('URL: $url');
    }
    debugPrint('Status Code: $statusCode');
    debugPrint('Response: ${maskedBody.isNotEmpty ? maskedBody : (maskedData ?? '{}')}');
  }

  static String _maskJsonString(String body) {
    if (body.isEmpty) return body;
    try {
      final decoded = jsonDecode(body);
      return const JsonEncoder.withIndent('  ').convert(_maskValue(decoded));
    } catch (_) {
      return body;
    }
  }

  static Map<String, dynamic> _maskMap(Map<String, dynamic> map) {
    return Map<String, dynamic>.from(
      map.map((key, value) => MapEntry(key, _maskEntry(key, value))),
    );
  }

  static dynamic _maskEntry(String key, dynamic value) {
    if (_isSensitiveKey(key)) {
      return '***MASKED***';
    }
    return _maskValue(value);
  }

  static dynamic _maskValue(dynamic value) {
    if (value is Map) {
      return _maskMap(Map<String, dynamic>.from(value));
    }
    if (value is List) {
      return value.map(_maskValue).toList();
    }
    return value;
  }

  static bool _isSensitiveKey(String key) {
    return _sensitiveKeys.contains(key.toLowerCase());
  }
}
