class RegisterRequest {
  const RegisterRequest({
    required this.fullName,
    required this.email,
    required this.password,
    required this.confirmPassword,
    this.phoneNumber,
  });

  final String fullName;
  final String email;
  final String password;
  final String confirmPassword;
  final String? phoneNumber;

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
      };
}
