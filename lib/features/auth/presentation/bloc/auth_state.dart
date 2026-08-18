import 'package:artable_app/features/auth/data/models/user_info.dart';

class AuthState {
  const AuthState({
    this.currentUser = const {
      'name': '',
      'initials': 'U',
      'handle': '',
      'avatarUrl': '',
      'bio': '',
      'stats': {
        'rank': '#--',
        'level': 'Creator',
        'entries': 0,
        'wins': 0,
        'points': 0,
        'followers': '0',
        'following': 0,
      },
      'isLoggedIn': false,
    },
    this.sessionToken,
    this.refreshToken,
    this.userId,
    this.isLoading = false,
    this.isVerifyingOtp = false,
    this.isResendingOtp = false,
    this.isSendingForgotPassword = false,
    this.isVerifyingResetToken = false,
    this.isResettingPassword = false,
    this.isUpdatingProfile = false,
    this.isChangingPassword = false,
    this.errorMessage,
    this.isResetTokenValid,
    this.resetTokenMessage,
    this.activeResetToken,
    this.pendingEmail,
    this.pendingPassword,
    this.pendingVerifyId,
    this.pendingUserId,
    this.lastRegisteredFullName,
  });

  final Map<String, dynamic> currentUser;
  final String? sessionToken;
  final String? refreshToken;
  final String? userId;
  final bool isLoading;
  final bool isVerifyingOtp;
  final bool isResendingOtp;
  final bool isSendingForgotPassword;
  final bool isVerifyingResetToken;
  final bool isResettingPassword;
  final bool isUpdatingProfile;
  final bool isChangingPassword;
  final String? errorMessage;
  final bool? isResetTokenValid;
  final String? resetTokenMessage;
  final String? activeResetToken;
  final String? pendingEmail;
  final String? pendingPassword;
  final String? pendingVerifyId;
  final String? pendingUserId;
  final String? lastRegisteredFullName;

  bool get isLoggedIn => currentUser['isLoggedIn'] as bool? ?? false;

  String get fullName {
    final storedFullName = currentUser['fullName'] as String?;
    if (storedFullName != null &&
        storedFullName.trim().isNotEmpty &&
        storedFullName.trim() != username &&
        !UserInfo.isPlaceholderName(storedFullName.trim())) {
      return storedFullName.trim();
    }

    final name = currentUser['name'] as String? ?? '';
    if (name.isNotEmpty && name != username && !UserInfo.isPlaceholderName(name)) {
      return name;
    }

    if (lastRegisteredFullName != null &&
        lastRegisteredFullName!.trim().isNotEmpty &&
        lastRegisteredFullName!.trim() != username &&
        !UserInfo.isPlaceholderName(lastRegisteredFullName!.trim())) {
      return lastRegisteredFullName!.trim();
    }

    final first = currentUser['firstName'] as String? ?? '';
    final middle = currentUser['middleName'] as String? ?? '';
    final last = currentUser['lastName'] as String? ?? '';
    final parts = [first, middle, last]
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty && !UserInfo.isPlaceholderName(p))
        .toList();
    if (parts.isNotEmpty) return parts.join(' ');

    return '';
  }

  String get username {
    final u = currentUser['username'] as String?;
    if (u != null && u.trim().isNotEmpty) return u.trim().replaceAll('@', '');
    final handle = currentUser['handle'] as String?;
    if (handle != null && handle.trim().isNotEmpty) return handle.trim().replaceAll('@', '');
    return '';
  }

  String get userName => fullName.isNotEmpty ? fullName : (currentUser['name'] as String? ?? username);
  String get userInitials => currentUser['initials'] as String? ?? 'U';
  String get bio => (currentUser['bio'] as String?)?.trim() ?? '';
  String get category => (currentUser['category'] as String?)?.trim() ?? '';
  String get coverUrl => (currentUser['coverUrl'] as String?)?.trim() ?? '';
  String get avatarUrl => (currentUser['avatarUrl'] as String?)?.trim() ?? '';
  dynamic get socialLinks => currentUser['socialLinks'];

  AuthState copyWith({
    Map<String, dynamic>? currentUser,
    String? sessionToken,
    String? refreshToken,
    String? userId,
    bool? isLoading,
    bool? isVerifyingOtp,
    bool? isResendingOtp,
    bool? isSendingForgotPassword,
    bool? isVerifyingResetToken,
    bool? isResettingPassword,
    bool? isUpdatingProfile,
    bool? isChangingPassword,
    String? errorMessage,
    bool? isResetTokenValid,
    String? resetTokenMessage,
    String? activeResetToken,
    String? pendingEmail,
    String? pendingPassword,
    String? pendingVerifyId,
    String? pendingUserId,
    String? lastRegisteredFullName,
    bool clearError = false,
    bool clearSession = false,
  }) {
    return AuthState(
      currentUser: currentUser ?? this.currentUser,
      sessionToken: clearSession ? null : (sessionToken ?? this.sessionToken),
      refreshToken: clearSession ? null : (refreshToken ?? this.refreshToken),
      userId: clearSession ? null : (userId ?? this.userId),
      isLoading: isLoading ?? this.isLoading,
      isVerifyingOtp: isVerifyingOtp ?? this.isVerifyingOtp,
      isResendingOtp: isResendingOtp ?? this.isResendingOtp,
      isSendingForgotPassword: isSendingForgotPassword ?? this.isSendingForgotPassword,
      isVerifyingResetToken: isVerifyingResetToken ?? this.isVerifyingResetToken,
      isResettingPassword: isResettingPassword ?? this.isResettingPassword,
      isUpdatingProfile: isUpdatingProfile ?? this.isUpdatingProfile,
      isChangingPassword: isChangingPassword ?? this.isChangingPassword,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isResetTokenValid: isResetTokenValid ?? this.isResetTokenValid,
      resetTokenMessage: resetTokenMessage ?? this.resetTokenMessage,
      activeResetToken: activeResetToken ?? this.activeResetToken,
      pendingEmail: pendingEmail ?? this.pendingEmail,
      pendingPassword: pendingPassword ?? this.pendingPassword,
      pendingVerifyId: pendingVerifyId ?? this.pendingVerifyId,
      pendingUserId: pendingUserId ?? this.pendingUserId,
      lastRegisteredFullName: lastRegisteredFullName ?? this.lastRegisteredFullName,
    );
  }
}
