class RegisterResponse {
  const RegisterResponse({
    this.success = false,
    this.message = '',
    this.userId = '',
    this.verifyId = '',
    this.otp,
    this.data,
  });

  final bool success;
  final String message;
  final String userId;
  final String verifyId;
  final dynamic otp;
  final Map<String, dynamic>? data;

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    String extractVerifyId(Map<String, dynamic> map) {
      if (map['verifyId'] != null) return map['verifyId'].toString();
      if (map['data'] is Map && map['data']['verifyId'] != null) {
        return map['data']['verifyId'].toString();
      }
      return '';
    }

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
      otp: json['otp'] ??
          (json['data'] is Map ? (json['data'] as Map)['otp'] : null),
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
        if (otp != null) 'otp': otp,
        if (data != null) 'data': data,
      };
}
