import 'dart:convert';
import 'package:flutter/foundation.dart';

class TrendingVideosApiDebugLogger {
  TrendingVideosApiDebugLogger._();

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
  }) {
    debugPrint('=== TRENDING VIDEOS API REQUEST ===');
    debugPrint('Method: $method');
    debugPrint('URL: $url');
    debugPrint('Headers: ${_maskHeaders(headers)}');
  }

  static void logResponse({
    required int statusCode,
    required String responseBody,
    String? url,
    Map<String, dynamic>? responseData,
  }) {
    final maskedBody = _maskJsonString(responseBody);

    debugPrint('=== TRENDING VIDEOS API RESPONSE ===');
    debugPrint('TRENDING VIDEOS API RESPONSE');
    if (url != null && url.isNotEmpty) {
      debugPrint('URL: $url');
    }
    debugPrint('Status Code: $statusCode');
    debugPrint('Response:');
    debugPrint(maskedBody.isNotEmpty
        ? maskedBody
        : (responseData != null
            ? _maskJsonString(jsonEncode(responseData))
            : '{}'));
  }

  static Map<String, String> _maskHeaders(Map<String, String> headers) {
    return headers.map((key, value) {
      if (_isSensitiveKey(key)) {
        return MapEntry(key, '***MASKED***');
      }
      return MapEntry(key, value);
    });
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
