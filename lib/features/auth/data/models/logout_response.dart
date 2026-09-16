class LogoutResponse {
  const LogoutResponse({
    required this.success,
    required this.message,
  });

  final bool success;
  final String message;

  factory LogoutResponse.fromJson(Map<String, dynamic> json) {
    return LogoutResponse(
      success: json['success'] == true || json['status'] == 200,
      message: json['message']?.toString() ?? '',
    );
  }
}
