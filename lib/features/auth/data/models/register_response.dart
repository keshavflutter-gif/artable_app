class RegisterResponse {
  const RegisterResponse({
    this.success = false,
    this.message = '',
    this.userId = '',
    this.verifyId = '',
    this.emailVerifyId = '',
    this.phoneVerifyId = '',
    this.otp,
    this.phoneOtp,
    this.data,
  });

  final bool success;
  final String message;
  final String userId;

  /// Generic verify id (backend currently returns the email one here).
  final String verifyId;

  /// Verify id for the EMAIL OTP.
  final String emailVerifyId;

  /// Verify id for the PHONE OTP — use this when verifying via mobile number.
  final String phoneVerifyId;

  final dynamic otp;
  final dynamic phoneOtp;
  final Map<String, dynamic>? data;

  /// Verify id to use for the mobile-number OTP screen.
  /// Falls back to [verifyId] when the backend didn't send `phoneVerifyId`.
  String get phoneOrDefaultVerifyId =>
      phoneVerifyId.isNotEmpty ? phoneVerifyId : verifyId;

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    String extractKey(Map<String, dynamic> map, String key) {
      if (map[key] != null) return map[key].toString();
      if (map['data'] is Map && map['data'][key] != null) {
        return map['data'][key].toString();
      }
      return '';
    }

    String extractVerifyId(Map<String, dynamic> map) =>
        extractKey(map, 'verifyId');

    String extractUserId(Map<String, dynamic> map) {
      if (map['userId'] != null) return map['userId'].toString();
      if (map['id'] != null) return map['id'].toString();
      if (map['_id'] != null) return map['_id'].toString();
      if (map['data'] is Map) {
        final d = map['data'] as Map;
        if (d['userId'] != null) return d['userId'].toString();
        if (d['id'] != null) return d['id'].toString();
        if (d['_id'] != null) return d['_id'].toString();
      }
      return '';
    }

    return RegisterResponse(
      success: json['success'] as bool? ?? true,
      message: json['message'] as String? ?? '',
      userId: extractUserId(json),
      verifyId: extractVerifyId(json),
      emailVerifyId: extractKey(json, 'emailVerifyId'),
      phoneVerifyId: extractKey(json, 'phoneVerifyId'),
      otp: json['otp'] ??
          (json['data'] is Map ? (json['data'] as Map)['otp'] : null),
      phoneOtp: json['phoneOtp'] ??
          (json['data'] is Map ? (json['data'] as Map)['phoneOtp'] : null),
      data: json['data'] is Map<String, dynamic>
          ? json['data'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'userId': userId,
        'verifyId': verifyId,
        if (emailVerifyId.isNotEmpty) 'emailVerifyId': emailVerifyId,
        if (phoneVerifyId.isNotEmpty) 'phoneVerifyId': phoneVerifyId,
        if (otp != null) 'otp': otp,
        if (phoneOtp != null) 'phoneOtp': phoneOtp,
        if (data != null) 'data': data,
      };
}
