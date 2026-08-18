class VerifyOtpRequest {
  const VerifyOtpRequest({
    required this.verifyId,
    required this.otp,
    this.channel = 'EMAIL',
  });

  final String verifyId;
  final String otp;
  final String channel;

  Map<String, dynamic> toJson() => {
        'verifyId': verifyId,
        'otp': otp,
        'channel': channel,
      };
}
