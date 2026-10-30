import 'dart:async';
import 'dart:io';

class NetworkUtils {
  NetworkUtils._();

  static const noInternetMessage =
      'Please check your internet connection and try again.';

  static bool isSuccessStatusCode(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }

  static bool isNetworkError(Object? error) {
    if (error == null) return false;
    final lower = error.toString().toLowerCase();
    return lower.contains('socketexception') ||
        lower.contains('clientexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('no internet') ||
        lower.contains('network_error') ||
        lower.contains('network is unreachable') ||
        lower.contains('connection refused') ||
        lower.contains('connection timed out') ||
        lower.contains('connection reset') ||
        lower.contains('network unreachable') ||
        lower.contains('timeoutexception') ||
        lower.contains('unable to connect') ||
        lower.contains('check internet');
  }

  static Future<bool> hasInternet() async {
    try {
      final result = await InternetAddress.lookup('one.one.one.one')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    } catch (_) {
      return false;
    }
  }
}
