/// Apple Sign-In config.
/// Fill [clientId] and [redirectUri] when the client provides Apple Developer details.
///
/// Required from Apple Developer / Firebase later:
/// 1. Enable "Sign In with Apple" capability for App ID `com.artable`
/// 2. Create a Services ID (used as [clientId] on Android)
/// 3. Configure return URL / redirect URI (used as [redirectUri] on Android)
/// 4. Enable Apple provider in Firebase Authentication
/// 5. Add Team ID, Key ID, and .p8 private key in Firebase (Apple provider settings)
class AppleAuthConfig {
  AppleAuthConfig._();

  /// Apple Services ID (e.g. `com.artable.signin`). Leave empty until provided.
  static const String clientId = '';

  /// OAuth redirect URI registered with Apple / Firebase handler URL.
  /// Example: `https://coffee-spark-ai-barista-5e2cd.firebaseapp.com/__/auth/handler`
  static const String redirectUri = '';

  static bool get isAndroidConfigured =>
      clientId.isNotEmpty && redirectUri.isNotEmpty;
}
