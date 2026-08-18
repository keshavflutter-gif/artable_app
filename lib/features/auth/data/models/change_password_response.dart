class ChangePasswordResponse {
  const ChangePasswordResponse({
    required this.success,
    required this.message,
  });

  final bool success;
  final String message;

  factory ChangePasswordResponse.fromJson(Map<String, dynamic> json) {
    return ChangePasswordResponse(
      success: json['success'] == true || json['status'] == 200,
      message: json['message']?.toString() ?? '',
    );
  }
}
