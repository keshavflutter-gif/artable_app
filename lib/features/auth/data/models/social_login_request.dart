class SocialLoginRequest {
  const SocialLoginRequest({
    required this.provider,
    required this.providerId,
    required this.email,
    this.fullName,
    this.firstName,
    this.middleName,
    this.lastName,
    this.profilePhotoUrl,
    this.idToken,
    this.fcmToken,
    this.deviceType,
    this.deviceVersion,
  });

  final String provider;
  final String providerId;
  final String email;
  final String? fullName;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? profilePhotoUrl;
  /// Optional Google/Apple ID token for backend verification.
  final String? idToken;
  final String? fcmToken;
  final String? deviceType;
  final String? deviceVersion;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'provider': provider,
      'providerId': providerId,
      'email': email,
    };

    void putIfPresent(String key, String? value) {
      if (value != null && value.isNotEmpty) {
        map[key] = value;
      }
    }

    putIfPresent('fullName', fullName);
    putIfPresent('firstName', firstName);
    putIfPresent('middleName', middleName);
    putIfPresent('lastName', lastName);
    putIfPresent('profilePhotoUrl', profilePhotoUrl);
    putIfPresent('idToken', idToken);
    map['fcmToken'] = (fcmToken != null && fcmToken!.trim().isNotEmpty)
        ? fcmToken!.trim()
        : 'optional-fcm-token';
    map['deviceType'] = (deviceType != null && deviceType!.trim().isNotEmpty)
        ? deviceType!.trim()
        : 'mobile-app';
    map['deviceVersion'] = (deviceVersion != null && deviceVersion!.trim().isNotEmpty)
        ? deviceVersion!.trim()
        : '1.0.0';

    return map;
  }
}
