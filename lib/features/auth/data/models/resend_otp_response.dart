class ResendOtpResponse {
  const ResendOtpResponse({
    this.success = false,
    this.message = '',
    this.verifyId = '',
    this.otp,
    this.data,
  });

  final bool success;
  final String message;
  final String verifyId;
  final dynamic otp;
  final Map<String, dynamic>? data;

  factory ResendOtpResponse.fromJson(Map<String, dynamic> json) {
    String extractVerifyId(Map<String, dynamic> map) {
      if (map['verifyId'] != null) return map['verifyId'].toString();
      if (map['data'] is Map && map['data']['verifyId'] != null) {
        return map['data']['verifyId'].toString();
      }
      return '';
    }

    return ResendOtpResponse(
      success: json['success'] as bool? ?? true,
      message: json['message'] as String? ?? '',
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
        'verifyId': verifyId,
        if (otp != null) 'otp': otp,
        if (data != null) 'data': data,
      };
}
