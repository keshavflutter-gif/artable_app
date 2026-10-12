class ResendOtpRequest {
  const ResendOtpRequest({
    required this.userId,
    required this.email,
    this.channel = 'SMS',
  });

  final String userId;
  final String email;
  final String channel;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'email': email,
        'channel': channel,
      };
}
