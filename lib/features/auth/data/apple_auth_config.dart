/// Apple Sign-In config.
///
/// For iOS:
/// - Sign in with Apple uses native authorization (capabilities enabled in `Runner.entitlements`).
///
/// For Android (Web-based OAuth redirect flow):
/// 1. Create a Services ID in Apple Developer Portal (e.g. `com.artable.signin`).
/// 2. Configure return URL / redirect URI in Apple Developer Portal.
/// 3. Set [clientId] and [redirectUri] below.
class AppleAuthConfig {
  AppleAuthConfig._();

  /// Apple Services ID (e.g. `com.artable.signin`).
  static const String clientId = 'com.artable.signin';

  /// OAuth redirect URI registered with Apple / Firebase auth handler.
  /// Example: `https://<firebase-project>.firebaseapp.com/__/auth/handler`
  static const String redirectUri =
      'https://artable.app/auth/apple/callback';

  static bool get isAndroidConfigured =>
      clientId.isNotEmpty && redirectUri.isNotEmpty;
}
