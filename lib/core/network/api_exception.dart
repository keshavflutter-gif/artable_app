class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.data});

  final String message;
  final int? statusCode;

  /// Decoded error response body, when the server returned JSON.
  final Map<String, dynamic>? data;

  @override
  String toString() => message;
}
