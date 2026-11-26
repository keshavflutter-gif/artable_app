/// Apple Sign-In config.
///
/// iOS: native Sign in with Apple (`Runner.entitlements`).
///
/// Android (web OAuth):
/// 1. Apple Developer → Services ID = [clientId]
/// 2. Return URL must exactly match [redirectUri]
/// 3. Host `hosting/artable.app/auth/apple/callback/index.html` at that URL
///    (bridges HTTPS → `signinwithapple://callback` for the app)
/// 4. Enable Apple provider in Firebase Auth for the same Services ID
class AppleAuthConfig {
  AppleAuthConfig._();

  /// Apple Services ID (must match Apple Developer Portal).
  static const String clientId = 'com.artable.signin';

  /// Must match the Return URL registered for [clientId].
  static const String redirectUri =
      'https://artable.app/auth/apple/callback';

  static bool get isAndroidConfigured =>
      clientId.trim().isNotEmpty && redirectUri.trim().isNotEmpty;
}
