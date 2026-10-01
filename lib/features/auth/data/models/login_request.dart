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
    final map = <String, dynamic>{
      'email': email,
      'password': password,
    };

    if (deviceType != null && deviceType!.isNotEmpty) {
      map['deviceType'] = deviceType;
    }
    if (deviceVersion != null && deviceVersion!.isNotEmpty) {
      map['deviceVersion'] = deviceVersion;
    }
    if (fcmToken != null && fcmToken!.isNotEmpty) {
      map['fcmToken'] = fcmToken;
    }

    return map;
  }
}

