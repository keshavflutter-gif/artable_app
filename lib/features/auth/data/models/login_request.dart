class LoginRequest {
  const LoginRequest({
    required this.email,
    required this.password,
    this.deviceType = 'mobile-app',
    this.deviceVersion = '1.0.0',
    this.fcmToken,
  });

  final String email;
  final String password;
  final String? deviceType;
  final String? deviceVersion;
  final String? fcmToken;

  Map<String, dynamic> toJson() {
    final effectiveDeviceType = (deviceType != null && deviceType!.trim().isNotEmpty)
        ? deviceType!.trim()
        : 'mobile-app';

    final effectiveDeviceVersion = (deviceVersion != null && deviceVersion!.trim().isNotEmpty)
        ? deviceVersion!.trim()
        : '1.0.0';

    final effectiveFcmToken = (fcmToken != null && fcmToken!.trim().isNotEmpty)
        ? fcmToken!.trim()
        : 'optional-fcm-token';

    return <String, dynamic>{
      'email': email,
      'password': password,
      'deviceType': effectiveDeviceType,
      'deviceVersion': effectiveDeviceVersion,
      'fcmToken': effectiveFcmToken,
    };
  }
}

