class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.data});

  final String message;
  final int? statusCode;

  /// Decoded error response body, when the server returned JSON.
  final Map<String, dynamic>? data;

  /// Non-empty field errors from `{ "error": { "email": "", "phoneNumber": "..." } }`.
  Map<String, String> get fieldErrors => extractFieldErrors(data);

  static Map<String, String> extractFieldErrors(Map<String, dynamic>? data) {
    if (data == null) return const {};
    final error = data['error'];
    if (error is! Map) return const {};
    final out = <String, String>{};
    error.forEach((key, value) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) out[key.toString()] = text;
    });
    return out;
  }

  @override
  String toString() => message;
}
