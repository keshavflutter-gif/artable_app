import 'dart:convert';

import 'user_info.dart';

class LoginResponse {
  const LoginResponse({
    required this.sessionToken,
    required this.refreshToken,
    this.userInfo,
  });

  final String sessionToken;
  final String refreshToken;
  final UserInfo? userInfo;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final payload = _resolvePayload(json);

    final sessionToken = payload['sessionToken']?.toString() ??
        payload['token']?.toString() ??
        payload['accessToken']?.toString() ??
        payload['access_token']?.toString() ??
        json['sessionToken']?.toString() ??
        json['token']?.toString() ??
        json['accessToken']?.toString() ??
        '';

    final refreshToken = payload['refreshToken']?.toString() ??
        payload['refresh_token']?.toString() ??
        json['refreshToken']?.toString() ??
        json['refresh_token']?.toString() ??
        sessionToken;

    UserInfo extracted = UserInfo.fromApiResponse(json);

    if (extracted.id.isEmpty) {
      final fallbackId = payload['userId']?.toString() ??
          payload['user_id']?.toString() ??
          payload['id']?.toString() ??
          payload['_id']?.toString() ??
          payload['uid']?.toString() ??
          json['userId']?.toString() ??
          json['user_id']?.toString() ??
          json['id']?.toString() ??
          json['_id']?.toString() ??
          json['uid']?.toString() ??
          _extractUserIdFromJwt(sessionToken) ??
          _extractUserIdFromJwt(refreshToken);

      if (fallbackId != null && fallbackId.isNotEmpty) {
        extracted = UserInfo(
          id: fallbackId,
          email: extracted.email,
          username: extracted.username,
          firstName: extracted.firstName,
          middleName: extracted.middleName,
          lastName: extracted.lastName,
          phoneNumber: extracted.phoneNumber,
          gender: extracted.gender,
          dob: extracted.dob,
          bio: extracted.bio,
          category: extracted.category,
          socialLinks: extracted.socialLinks,
        );
      }
    }

    return LoginResponse(
      sessionToken: sessionToken,
      refreshToken: refreshToken,
      userInfo: extracted.id.isNotEmpty ||
              (extracted.username != null && extracted.username!.isNotEmpty) ||
              (extracted.displayName.isNotEmpty)
          ? extracted
          : null,
    );
  }

  static String? _extractUserIdFromJwt(String token) {
    if (token.isEmpty) return null;
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;
      final normalized = base64Url.normalize(parts[1]);
      final payloadString = utf8.decode(base64Url.decode(normalized));
      final payloadMap = jsonDecode(payloadString);
      if (payloadMap is Map) {
        return payloadMap['id']?.toString() ??
            payloadMap['_id']?.toString() ??
            payloadMap['userId']?.toString() ??
            payloadMap['user_id']?.toString() ??
            payloadMap['sub']?.toString();
      }
    } catch (_) {}
    return null;
  }

  static Map<String, dynamic> _resolvePayload(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return json;
  }
}
