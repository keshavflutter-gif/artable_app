class TokenVerifyRequest {
  const TokenVerifyRequest({
    required this.token,
  });

  final String token;

  Map<String, dynamic> toJson() => {
        'token': token,
      };
}
