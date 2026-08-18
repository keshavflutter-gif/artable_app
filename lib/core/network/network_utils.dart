class NetworkUtils {
  NetworkUtils._();

  static bool isSuccessStatusCode(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }
}
