/// Maps between the app's internal OTP channel name (`SMS` / `EMAIL`) and the
/// values the backend enum accepts (`PHONE` / `EMAIL`).
class OtpChannel {
  OtpChannel._();

  /// Internal value used across screens/routes for a mobile-number OTP.
  static const String sms = 'SMS';

  /// Internal + backend value for an email OTP.
  static const String email = 'EMAIL';

  /// Backend enum value for a mobile-number OTP.
  static const String apiPhone = 'PHONE';

  /// App value -> backend enum (`SMS`/`PHONE`/`MOBILE` => `PHONE`, else `EMAIL`).
  static String toApi(String channel) {
    switch (channel.trim().toUpperCase()) {
      case sms:
      case apiPhone:
      case 'MOBILE':
        return apiPhone;
      default:
        return email;
    }
  }

  /// Backend value -> app value (`PHONE`/`MOBILE` => `SMS`, else `EMAIL`).
  static String fromApi(String channel) {
    switch (channel.trim().toUpperCase()) {
      case sms:
      case apiPhone:
      case 'MOBILE':
        return sms;
      default:
        return email;
    }
  }
}
