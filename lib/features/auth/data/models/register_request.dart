/// Body for `POST /auth/register`.
///
/// Expected payload:
/// ```json
/// {
///   "fullName": "Demo User",
///   "email": "nak.kalvani@gmail.com",
///   "password": "Password@123",
///   "confirmPassword": "Password@123",
///   "phoneNumber": "+916353041683"
/// }
/// ```
class RegisterRequest {
  const RegisterRequest({
    required this.fullName,
    required this.email,
    required this.password,
    required this.confirmPassword,
    this.phoneNumber,
  });

  /// Country calling code applied when the user enters a bare 10-digit number.
  static const String defaultCountryCode = '+91';

  final String fullName;
  final String email;
  final String password;
  final String confirmPassword;
  final String? phoneNumber;

  /// Normalises a phone number to the `+<country><number>` form the API expects.
  ///
  /// - `6353041683`      -> `+916353041683`
  /// - `916353041683`    -> `+916353041683`
  /// - `+91 63530 41683` -> `+916353041683`
  /// Returns null for an empty input.
  static String? normalizePhoneNumber(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final hasPlus = trimmed.startsWith('+');
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;

    if (hasPlus) return '+$digits';

    final cc = defaultCountryCode.substring(1); // "91"
    if (digits.length == 10) return '$defaultCountryCode$digits';
    if (digits.length == 10 + cc.length && digits.startsWith(cc)) {
      return '+$digits';
    }
    // Unknown shape: send with a leading '+' so the format is still E.164-like.
    return '+$digits';
  }

  Map<String, dynamic> toJson() {
    final phone = normalizePhoneNumber(phoneNumber);
    return {
      'fullName': fullName,
      'email': email,
      'password': password,
      'confirmPassword': confirmPassword,
      if (phone != null) 'phoneNumber': phone,
    };
  }
}
