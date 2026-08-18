class VerifyOtpResponse {
  const VerifyOtpResponse({
    this.success = false,
    this.message = '',
    this.data,
  });

  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResponse(
      success: json['success'] as bool? ?? false,
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
