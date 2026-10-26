import 'otp_channel.dart';

class VerifyOtpRequest {
  const VerifyOtpRequest({
    required this.verifyId,
    required this.otp,
    this.channel = 'SMS',
  });

  final String verifyId;
  final String otp;
  final String channel;

  Map<String, dynamic> toJson() => {
        'verifyId': verifyId,
        'otp': otp,
        // Backend enum accepts only 'EMAIL' | 'PHONE'.
        'channel': OtpChannel.toApi(channel),
      };
}
