class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://server.keshavinfotechdemo2.com:3055';
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resendOtp = '/auth/resend-otp';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String tokenVerify = '/auth/token-verify';
  static const String user = '/user';
  static const String changePassword = '/user/change-password';
  static const String home = '/app/home';
  static const String categories = '/app/categories';
  static const String challenges = '/app/challenges';
  static const String leaderboard = '/app/leaderboard';
  static const String trendingVideos = '/app/videos/trending';
  static const String profileStats = '/app/profile/stats';
  static const String achievements = '/app/profile/achievements';
  static const String rewards = '/app/rewards';
}
