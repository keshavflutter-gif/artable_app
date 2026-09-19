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
    putIfPresent('fcmToken', fcmToken);
    putIfPresent('deviceType', deviceType);
    putIfPresent('deviceVersion', deviceVersion);

    return map;
  }
}
