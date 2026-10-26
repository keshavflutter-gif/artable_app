import 'otp_channel.dart';

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
        // Backend enum accepts only 'EMAIL' | 'PHONE'.
        'channel': OtpChannel.toApi(channel),
      };
}
