class GenerateSessionRequest {
  const GenerateSessionRequest({required this.refreshToken});

  final String refreshToken;

  Map<String, dynamic> toJson() => {
        'refreshToken': refreshToken,
      };
}
