import 'dart:async';
import 'dart:io';

class NetworkUtils {
  NetworkUtils._();

  static const offlineMessage =
      'No internet connection. Please check your network and try again.';

  static const serverUnreachableMessage =
      'Unable to reach server. Please try again later.';

  static const timeoutMessage =
      'Server is taking too long to respond. Please try again.';

  /// Legacy alias used in a few screens.
  static const noInternetMessage = offlineMessage;

  static bool isSuccessStatusCode(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }

  /// True only for real device-offline / DNS failure cases.
  /// Do NOT treat server down / timeout as offline (Wi‑Fi can still be on).
  static bool isOfflineError(Object? error) {
    if (error == null) return false;
    final lower = error.toString().toLowerCase();
    return lower.contains('no internet connection') ||
        lower.contains('failed host lookup') ||
        lower.contains('network is unreachable') ||
        lower.contains('network_unreachable') ||
        lower.contains('nodename nor servname') ||
        lower.contains('name or service not known') ||
        lower.contains('errno = 7') || // no address associated with hostname
        lower.contains('errno = 8');
  }

  /// Transport failures including server unreachable / timeout.
  static bool isNetworkError(Object? error) {
    if (error == null) return false;
    if (isOfflineError(error)) return true;
    final lower = error.toString().toLowerCase();
    return lower.contains('socketexception') ||
        lower.contains('clientexception') ||
        lower.contains('connection refused') ||
        lower.contains('connection timed out') ||
        lower.contains('connection reset') ||
        lower.contains('timeoutexception') ||
        lower.contains('unable to reach server') ||
        lower.contains('taking too long to respond') ||
        lower.contains('unable to connect');
  }

  /// Probe public DNS hosts. Returns true if any lookup succeeds.
  static Future<bool> hasInternet() async {
    const hosts = ['one.one.one.one', 'dns.google', 'google.com'];
    for (final host in hosts) {
      try {
        final result = await InternetAddress.lookup(host)
            .timeout(const Duration(seconds: 2));
        if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
          return true;
        }
      } on SocketException {
        continue;
      } on TimeoutException {
        continue;
      } catch (_) {
        continue;
      }
    }
    return false;
  }

  /// Map a low-level HTTP/client error to a user-facing [ApiException] message.
  static String messageForTransportError(Object error) {
    final lower = error.toString().toLowerCase();
    if (lower.contains('failed host lookup') ||
        lower.contains('network is unreachable') ||
        lower.contains('network_unreachable') ||
        lower.contains('nodename nor servname') ||
        lower.contains('name or service not known')) {
      return offlineMessage;
    }
    if (lower.contains('timed out') || lower.contains('timeout')) {
      return timeoutMessage;
    }
    if (lower.contains('connection refused') ||
        lower.contains('connection reset') ||
        lower.contains('failed to fetch') ||
        lower.contains('socketexception') ||
        lower.contains('clientexception')) {
      return serverUnreachableMessage;
    }
    return serverUnreachableMessage;
  }
}
