class TokenVerifyResponse {
  const TokenVerifyResponse({
    this.success = false,
    this.message = '',
    this.data,
  });

  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  factory TokenVerifyResponse.fromJson(Map<String, dynamic> json) {
    return TokenVerifyResponse(
      success: json['success'] as bool? ??
          (json['status'] == 200 || json['status'] == 201),
      message: json['message'] as String? ?? '',
      data: json['data'] is Map<String, dynamic>
          ? json['data'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        if (data != null) 'data': data,
      };
}
