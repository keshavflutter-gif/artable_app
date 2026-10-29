import 'login_response.dart';
import 'user_info.dart';

class VerifyOtpResponse {
  const VerifyOtpResponse({
    this.success = false,
    this.message = '',
    this.data,
    this.sessionToken = '',
    this.refreshToken = '',
    this.userInfo,
  });

  final bool success;
  final String message;
  final Map<String, dynamic>? data;
  final String sessionToken;
  final String refreshToken;
  final UserInfo? userInfo;

  bool get hasSession => sessionToken.trim().isNotEmpty;

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? data;
    if (json['data'] is Map<String, dynamic>) {
      data = json['data'] as Map<String, dynamic>;
    } else if (json['data'] is Map) {
      data = Map<String, dynamic>.from(json['data'] as Map);
    }

    final login = LoginResponse.fromJson(json);
    return VerifyOtpResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: data,
      sessionToken: login.sessionToken,
      refreshToken: login.refreshToken,
      userInfo: login.userInfo,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        if (data != null) 'data': data,
      };
}
