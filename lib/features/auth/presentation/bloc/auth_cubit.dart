import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:artable_app/core/network/api_exception.dart';
import 'package:artable_app/features/auth/data/models/change_password_request.dart';
import 'package:artable_app/features/auth/data/models/forgot_password_request.dart';
import 'package:artable_app/features/auth/data/models/forgot_password_response.dart';
import 'package:artable_app/features/auth/data/models/login_request.dart';
import 'package:artable_app/features/auth/data/models/logout_response.dart';
import 'package:artable_app/features/auth/data/models/register_request.dart';
import 'package:artable_app/features/auth/data/models/register_response.dart';
import 'package:artable_app/features/auth/data/models/resend_otp_request.dart';
import 'package:artable_app/features/auth/data/models/resend_otp_response.dart';
import 'package:artable_app/features/auth/data/models/reset_password_request.dart';
import 'package:artable_app/features/auth/data/models/reset_password_response.dart';
import 'package:artable_app/features/auth/data/models/token_verify_request.dart';
import 'package:artable_app/features/auth/data/models/token_verify_response.dart';
import 'package:artable_app/features/auth/data/models/update_profile_request.dart';
import 'package:artable_app/features/auth/data/models/user_info.dart';
import 'package:artable_app/features/auth/data/models/verify_otp_request.dart';
import 'package:artable_app/features/auth/data/models/verify_otp_response.dart';
import 'package:artable_app/features/auth/data/repositories/auth_repository.dart';
import 'package:artable_app/app/routes/app_router.dart';
import 'package:artable_app/app/routes/app_routes.dart';
import 'package:artable_app/core/storage/auth_storage_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({AuthRepository? authRepository})
      : super(const AuthState()) {
    _authRepository = authRepository ??
        AuthRepository(
          onTokensRefreshed: applyRefreshedTokens,
          onSessionRefreshFailed: handleSessionRefreshFailed,
        );
  }

  late final AuthRepository _authRepository;
  Future<void>? _initializationFuture;

  // Convenient property getters delegating to state
  Map<String, dynamic> get currentUser => state.currentUser;
  bool get isLoggedIn => state.isLoggedIn;
  String get fullName => state.fullName;
  String get username => state.username;
  String get userName => state.userName;
  String get userInitials => state.userInitials;
  String get bio => state.bio;
  String get category => state.category;
  String get coverUrl => state.coverUrl;
  String get avatarUrl => state.avatarUrl;
  dynamic get socialLinks => state.socialLinks;
  String? get sessionToken => state.sessionToken;
  String? get refreshToken => state.refreshToken;
  String? get userId => state.userId;
  String? get pendingEmail => state.pendingEmail;
  String? get pendingPassword => state.pendingPassword;
  String? get pendingVerifyId => state.pendingVerifyId;
  String? get pendingUserId => state.pendingUserId;
  String? get lastRegisteredFullName => state.lastRegisteredFullName;
  bool get isLoading => state.isLoading;
  bool get isVerifyingOtp => state.isVerifyingOtp;
  bool get isResendingOtp => state.isResendingOtp;
  bool get isSendingForgotPassword => state.isSendingForgotPassword;
  bool get isVerifyingResetToken => state.isVerifyingResetToken;
  bool get isResettingPassword => state.isResettingPassword;
  bool? get isResetTokenValid => state.isResetTokenValid;
  String? get resetTokenMessage => state.resetTokenMessage;
  String? get activeResetToken => state.activeResetToken;
  bool get isUpdatingProfile => state.isUpdatingProfile;
  bool get isChangingPassword => state.isChangingPassword;
  String? get errorMessage => state.errorMessage;

  void applyRefreshedTokens({
    required String sessionToken,
    String? refreshToken,
  }) {
    emit(state.copyWith(
      sessionToken: sessionToken,
      refreshToken: (refreshToken != null && refreshToken.isNotEmpty)
          ? refreshToken
          : state.refreshToken,
    ));
  }

  Future<void> handleSessionRefreshFailed() async {
    await logout();
    try {
      if (appRouter.canPop()) {
        appRouter.pop();
      }
    } catch (_) {}
    appRouter.go(AppRoutes.login);
  }

  Future<void> initialize() {
    return _initializationFuture ??= _restoreSessionFromStorage();
  }

  Future<void> ensureInitialized() => initialize();

  /// Design-only preview session (no API, no validation).
  void signInForDesignPreview() {
    final updatedUser = Map<String, dynamic>.from(state.currentUser);
    updatedUser['name'] = 'Demo User';
    updatedUser['initials'] = 'DU';
    updatedUser['handle'] = '@demo_user';
    updatedUser['isLoggedIn'] = true;

    emit(state.copyWith(
      sessionToken: 'design_preview',
      refreshToken: 'design_preview',
      userId: 'design_user',
      currentUser: updatedUser,
      clearError: true,
    ));
  }

  /// Design-only local profile update (no API, no validation).
  void applyDesignProfilePreview({
    required String fullName,
    required String username,
    required String bio,
    required String category,
    required String socialLinkUrl,
  }) {
    final updatedUser = Map<String, dynamic>.from(state.currentUser);
    updatedUser['name'] = fullName;
    updatedUser['initials'] = _initialsFromName(fullName);
    final handle = username.startsWith('@') ? username : '@$username';
    updatedUser['handle'] = handle;
    updatedUser['bio'] = bio;
    updatedUser['category'] = category;
    if (socialLinkUrl.isNotEmpty && socialLinkUrl != 'https://') {
      updatedUser['socialLinks'] = [
        {'url': socialLinkUrl},
      ];
    }
    emit(state.copyWith(currentUser: updatedUser));
  }

  Future<void> _restoreSessionFromStorage() async {
    final storedSession = await _authRepository.loadStoredSession();
    if (storedSession == null) return;

    final updatedUser = Map<String, dynamic>.from(state.currentUser);
    if (storedSession.displayName != null &&
        storedSession.displayName!.isNotEmpty) {
      updatedUser['name'] = storedSession.displayName;
      updatedUser['initials'] = _initialsFromName(storedSession.displayName!);
    }
    _applyStoredProfileDetailsToMap(updatedUser, storedSession.profileDetails);
    updatedUser['isLoggedIn'] = true;

    emit(state.copyWith(
      sessionToken: storedSession.sessionToken,
      refreshToken: storedSession.refreshToken,
      userId: storedSession.userId,
      currentUser: updatedUser,
    ));

    if (storedSession.userId != null && storedSession.userId!.isNotEmpty) {
      fetchUserDetails();
    }
  }

  Future<bool> login(String email, String password) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final response = await _authRepository.login(
        LoginRequest(email: email.trim(), password: password),
      );

      final updatedUser = Map<String, dynamic>.from(state.currentUser);
      String? newUserId = response.userInfo?.id ?? state.userId;
      String? lastRegisteredName = state.lastRegisteredFullName;

      final (userMap, newRegisteredName, updatedUid) = _applyUserInfoToState(
        updatedUser,
        response.userInfo,
        lastRegisteredName,
        newUserId,
      );

      userMap['isLoggedIn'] = true;

      emit(state.copyWith(
        isLoading: false,
        sessionToken: response.sessionToken,
        refreshToken: response.refreshToken,
        userId: updatedUid,
        currentUser: userMap,
        lastRegisteredFullName: newRegisteredName,
      ));

      if (updatedUid != null && updatedUid.isNotEmpty) {
        fetchUserDetails();
      }

      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
      return false;
    } catch (_) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to log in. Please try again.',
      ));
      return false;
    }
  }

  Future<RegisterResponse?> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
    String? phoneNumber,
  }) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final request = RegisterRequest(
        fullName: fullName.trim(),
        email: email.trim(),
        password: password,
        confirmPassword: confirmPassword,
        phoneNumber: phoneNumber?.trim(),
      );

      final response = await _authRepository.register(request);

      debugPrint('=== REGISTER API SUCCESS ===');
      debugPrint('Success: ${response.success}');
      debugPrint('Message: ${response.message}');
      debugPrint('User ID: ${response.userId}');
      debugPrint('Verify ID: ${response.verifyId}');
      if (response.otp != null) {
        debugPrint('OTP: ${response.otp}');
      }

      emit(state.copyWith(
        isLoading: false,
        pendingEmail: email.trim(),
        pendingPassword: password,
        pendingVerifyId: response.verifyId,
        pendingUserId: response.userId,
        lastRegisteredFullName: fullName.trim(),
      ));

      return response;
    } on ApiException catch (e) {
      debugPrint('=== REGISTER API EXCEPTION ===');
      debugPrint('Status Code: ${e.statusCode}');
      debugPrint('Message: ${e.message}');
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
      return null;
    } catch (e) {
      debugPrint('=== REGISTER API ERROR ===: $e');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to create account. Please try again.',
      ));
      return null;
    }
  }

  Future<VerifyOtpResponse?> verifyOtp({
    required String verifyId,
    required String otp,
    String channel = 'EMAIL',
    String? email,
    String? password,
  }) async {
    emit(state.copyWith(isVerifyingOtp: true, clearError: true));

    try {
      final effectiveVerifyId = verifyId.isNotEmpty
          ? verifyId
          : (state.pendingVerifyId ?? '');

      final request = VerifyOtpRequest(
        verifyId: effectiveVerifyId,
        otp: otp,
        channel: channel,
      );

      final response = await _authRepository.verifyOtp(request);
      debugPrint('=== VERIFY OTP RESPONSE SUCCESS ===');
      debugPrint('Success: ${response.success}');
      debugPrint('Message: ${response.message}');
      if (response.data != null) {
        debugPrint('Data: ${response.data}');
      }

      if (response.success) {
        final token = response.data?['sessionToken']?.toString() ??
            response.data?['token']?.toString() ??
            response.data?['accessToken']?.toString();
        final refresh = response.data?['refreshToken']?.toString();

        if (token != null && token.isNotEmpty) {
          final updatedUser = Map<String, dynamic>.from(state.currentUser);
          String? updatedUid = state.userId;
          String? registeredName = state.lastRegisteredFullName;

          final userMap = response.data?['user'] ?? response.data?['userInfo'];
          if (userMap is Map<String, dynamic>) {
            final userInfo = UserInfo.fromJson(userMap);
            final res = _applyUserInfoToState(
              updatedUser,
              userInfo,
              registeredName,
              updatedUid,
            );
            updatedUid = res.$3;
            registeredName = res.$2;
          } else if (registeredName != null && registeredName.isNotEmpty) {
            updatedUser['name'] = registeredName;
            updatedUser['initials'] = _initialsFromName(registeredName);
          }
          updatedUser['isLoggedIn'] = true;

          await _authRepository.persistLocalProfileDetails(
            displayName: updatedUser['name'] as String?,
            firstName: updatedUser['firstName'] as String?,
            lastName: updatedUser['lastName'] as String?,
          );

          emit(state.copyWith(
            isVerifyingOtp: false,
            sessionToken: token,
            refreshToken: refresh ?? token,
            userId: updatedUid,
            currentUser: updatedUser,
            lastRegisteredFullName: registeredName,
          ));
        } else {
          emit(state.copyWith(isVerifyingOtp: false));
          final loginEmail = (email != null && email.isNotEmpty)
              ? email
              : state.pendingEmail;
          final loginPass = (password != null && password.isNotEmpty)
              ? password
              : state.pendingPassword;

          if (loginEmail != null &&
              loginEmail.isNotEmpty &&
              loginPass != null &&
              loginPass.isNotEmpty) {
            debugPrint('=== AUTO LOGGING IN POST-VERIFY OTP ===');
            await login(loginEmail, loginPass);
          }
        }
      } else {
        emit(state.copyWith(isVerifyingOtp: false));
      }

      return response;
    } on ApiException catch (e) {
      debugPrint('=== VERIFY OTP API EXCEPTION ===');
      debugPrint('Status Code: ${e.statusCode}');
      debugPrint('Message: ${e.message}');
      emit(state.copyWith(isVerifyingOtp: false, errorMessage: e.message));
      return null;
    } catch (e) {
      debugPrint('=== VERIFY OTP ERROR ===: $e');
      emit(state.copyWith(
        isVerifyingOtp: false,
        errorMessage: 'Unable to verify OTP. Please try again.',
      ));
      return null;
    }
  }

  Future<ResendOtpResponse?> resendOtp({
    String? userId,
    String? email,
    String channel = 'EMAIL',
  }) async {
    emit(state.copyWith(isResendingOtp: true, clearError: true));

    try {
      final effectiveUserId = (userId != null && userId.isNotEmpty)
          ? userId
          : (state.pendingUserId ?? state.userId ?? '');
      final effectiveEmail = (email != null && email.isNotEmpty)
          ? email
          : (state.pendingEmail ?? '');

      final request = ResendOtpRequest(
        userId: effectiveUserId,
        email: effectiveEmail,
        channel: channel,
      );

      final response = await _authRepository.resendOtp(request);

      debugPrint('=== RESEND OTP RESPONSE SUCCESS ===');
      debugPrint('Success: ${response.success}');
      debugPrint('Message: ${response.message}');
      debugPrint('New Verify ID: ${response.verifyId}');
      if (response.otp != null) {
        debugPrint('New OTP: ${response.otp}');
      }

      emit(state.copyWith(
        isResendingOtp: false,
        pendingVerifyId: response.verifyId.isNotEmpty
            ? response.verifyId
            : state.pendingVerifyId,
      ));

      return response;
    } on ApiException catch (e) {
      debugPrint('=== RESEND OTP API EXCEPTION ===');
      debugPrint('Status Code: ${e.statusCode}');
      debugPrint('Message: ${e.message}');
      emit(state.copyWith(isResendingOtp: false, errorMessage: e.message));
      return null;
    } catch (e) {
      debugPrint('=== RESEND OTP ERROR ===: $e');
      emit(state.copyWith(
        isResendingOtp: false,
        errorMessage: 'Unable to resend OTP. Please try again.',
      ));
      return null;
    }
  }

  Future<ForgotPasswordResponse?> forgotPassword({
    required String email,
  }) async {
    emit(state.copyWith(isSendingForgotPassword: true, clearError: true));

    try {
      final request = ForgotPasswordRequest(email: email.trim());
      final response = await _authRepository.forgotPassword(request);

      debugPrint('=== FORGOT PASSWORD RESPONSE SUCCESS ===');
      debugPrint('Success: ${response.success}');
      debugPrint('Message: ${response.message}');

      emit(state.copyWith(isSendingForgotPassword: false));
      return response;
    } on ApiException catch (e) {
      debugPrint('=== FORGOT PASSWORD API EXCEPTION ===');
      debugPrint('Status Code: ${e.statusCode}');
      debugPrint('Message: ${e.message}');
      emit(state.copyWith(
        isSendingForgotPassword: false,
        errorMessage: e.message,
      ));
      return null;
    } catch (e) {
      debugPrint('=== FORGOT PASSWORD ERROR ===: $e');
      emit(state.copyWith(
        isSendingForgotPassword: false,
        errorMessage: 'Unable to send reset instructions. Please try again.',
      ));
      return null;
    }
  }

  Future<TokenVerifyResponse?> verifyResetToken({
    required String token,
  }) async {
    final activeToken = token.trim();
    emit(state.copyWith(
      isVerifyingResetToken: true,
      activeResetToken: activeToken,
      isResetTokenValid: null,
      resetTokenMessage: null,
    ));

    try {
      debugPrint('=== RESET TOKEN: $activeToken ===');

      final request = TokenVerifyRequest(token: activeToken);
      final response = await _authRepository.verifyResetToken(request);

      debugPrint('=== TOKEN VERIFY RESPONSE SUCCESS ===');
      debugPrint('Success: ${response.success}');
      debugPrint('Message: ${response.message}');
      debugPrint('Reset Token: $activeToken');

      emit(state.copyWith(
        isVerifyingResetToken: false,
        isResetTokenValid: response.success,
        resetTokenMessage: response.message,
      ));

      return response;
    } on ApiException catch (e) {
      debugPrint('=== TOKEN VERIFY API EXCEPTION ===');
      debugPrint('Status Code: ${e.statusCode}');
      debugPrint('Message: ${e.message}');
      debugPrint('Reset Token: $activeToken');

      emit(state.copyWith(
        isVerifyingResetToken: false,
        isResetTokenValid: false,
        resetTokenMessage: e.message,
      ));
      return null;
    } catch (e) {
      debugPrint('=== TOKEN VERIFY ERROR ===: $e');
      debugPrint('Reset Token: $activeToken');

      emit(state.copyWith(
        isVerifyingResetToken: false,
        isResetTokenValid: false,
        resetTokenMessage: 'Unable to verify reset token.',
      ));
      return null;
    }
  }

  Future<ResetPasswordResponse?> resetPassword({
    required String token,
    required String password,
  }) async {
    emit(state.copyWith(isResettingPassword: true, clearError: true));

    try {
      final effectiveToken = token.trim().isNotEmpty
          ? token.trim()
          : (state.activeResetToken ?? '');

      debugPrint('=== RESET PASSWORD API REQUEST ===');
      debugPrint('Reset Token: $effectiveToken');

      final request = ResetPasswordRequest(
        token: effectiveToken,
        password: password,
      );

      final response = await _authRepository.resetPassword(request);

      debugPrint('=== RESET PASSWORD API SUCCESS ===');
      debugPrint('Success: ${response.success}');
      debugPrint('Message: ${response.message}');
      debugPrint('Reset Token: $effectiveToken');

      emit(state.copyWith(isResettingPassword: false));
      return response;
    } on ApiException catch (e) {
      debugPrint('=== RESET PASSWORD API EXCEPTION ===');
      debugPrint('Status Code: ${e.statusCode}');
      debugPrint('Message: ${e.message}');
      emit(state.copyWith(isResettingPassword: false, errorMessage: e.message));
      return null;
    } catch (e) {
      debugPrint('=== RESET PASSWORD ERROR ===: $e');
      emit(state.copyWith(
        isResettingPassword: false,
        errorMessage: 'Unable to reset password. Please try again.',
      ));
      return null;
    }
  }

  Future<LogoutResponse?> logout() async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final response = await _authRepository.logout(
        sessionToken: state.sessionToken,
        refreshToken: state.refreshToken,
      );

      final clearedUser = Map<String, dynamic>.from(state.currentUser);
      clearedUser['isLoggedIn'] = false;
      clearedUser['name'] = '';
      clearedUser['fullName'] = '';
      clearedUser['handle'] = '';
      clearedUser['username'] = '';
      clearedUser['avatarUrl'] = '';
      clearedUser['bio'] = '';

      emit(state.copyWith(
        isLoading: false,
        clearSession: true,
        currentUser: clearedUser,
        clearError: true,
      ));

      return response;
    } on ApiException catch (e) {
      debugPrint('=== LOGOUT API EXCEPTION ===: ${e.message}');
      final clearedUser = Map<String, dynamic>.from(state.currentUser);
      clearedUser['isLoggedIn'] = false;
      clearedUser['name'] = '';
      clearedUser['fullName'] = '';
      clearedUser['handle'] = '';
      clearedUser['username'] = '';
      clearedUser['avatarUrl'] = '';
      clearedUser['bio'] = '';

      emit(state.copyWith(
        isLoading: false,
        clearSession: true,
        currentUser: clearedUser,
        errorMessage: e.message,
      ));
      return null;
    } catch (e) {
      debugPrint('=== LOGOUT ERROR ===: $e');
      final clearedUser = Map<String, dynamic>.from(state.currentUser);
      clearedUser['isLoggedIn'] = false;
      clearedUser['name'] = '';
      clearedUser['fullName'] = '';
      clearedUser['handle'] = '';
      clearedUser['username'] = '';
      clearedUser['avatarUrl'] = '';
      clearedUser['bio'] = '';

      emit(state.copyWith(
        isLoading: false,
        clearSession: true,
        currentUser: clearedUser,
        clearError: true,
      ));
      return null;
    }
  }

  Future<bool> saveProfile({
    required String fullName,
    required String username,
    required String bio,
    required String category,
    required String socialLinkUrl,
  }) async {
    if (state.isUpdatingProfile) return false;

    emit(state.copyWith(isUpdatingProfile: true, clearError: true));

    try {
      final trimmedFullName = fullName.trim();
      final nameParts = _splitFullNameParts(trimmedFullName);
      final socialLinks = _buildSocialLinks(socialLinkUrl);
      final trimmedBio = bio.trim();
      final trimmedCategory = category.trim();

      final updatedUser = Map<String, dynamic>.from(state.currentUser);
      updatedUser['bio'] = trimmedBio;
      updatedUser['category'] = trimmedCategory;
      if (socialLinks.isNotEmpty) {
        updatedUser['socialLinks'] = socialLinks;
      }
      updatedUser['fullName'] = trimmedFullName;
      updatedUser['name'] = trimmedFullName;
      updatedUser['initials'] = _initialsFromName(trimmedFullName);
      updatedUser['username'] = username.trim();
      updatedUser['handle'] = '@${username.trim()}';

      final request = UpdateProfileRequest(
        fullName: trimmedFullName,
        firstName: nameParts.$1.isNotEmpty ? nameParts.$1 : trimmedFullName,
        middleName: nameParts.$2,
        lastName: _resolveLastNameForApi(
          splitLast: nameParts.$3,
          storedLast: updatedUser['lastName'] as String?,
        ),
        username: username.trim(),
        bio: trimmedBio,
        category: trimmedCategory,
        socialLinks: socialLinks,
      );

      final updatedUserFromApi = await _authRepository.updateProfile(
        request: request,
        sessionToken: state.sessionToken ?? '',
        refreshToken: state.refreshToken ?? '',
      );

      final (finalUserMap, finalRegisteredName, _) = _applyUserInfoToState(
        updatedUser,
        updatedUserFromApi,
        trimmedFullName,
        state.userId,
      );

      finalUserMap['fullName'] = trimmedFullName;
      finalUserMap['name'] = trimmedFullName;
      finalUserMap['initials'] = _initialsFromName(trimmedFullName);

      fetchUserDetails();

      List<Map<String, dynamic>>? socialListToPersist;
      final currentSocial = finalUserMap['socialLinks'];
      if (currentSocial is List) {
        socialListToPersist = currentSocial
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      } else if (currentSocial is Map) {
        socialListToPersist = [Map<String, dynamic>.from(currentSocial)];
      }

      await _authRepository.persistLocalProfileDetails(
        displayName: finalUserMap['name'] as String?,
        firstName: finalUserMap['firstName'] as String?,
        middleName: finalUserMap['middleName'] as String?,
        lastName: finalUserMap['lastName'] as String?,
        bio: trimmedBio,
        username: _usernameFromHandle(finalUserMap['handle'] as String?),
        category: trimmedCategory,
        socialLinks: socialListToPersist,
      );

      emit(state.copyWith(
        isUpdatingProfile: false,
        currentUser: finalUserMap,
        lastRegisteredFullName: finalRegisteredName,
      ));

      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(isUpdatingProfile: false, errorMessage: e.message));
      return false;
    } catch (_) {
      emit(state.copyWith(
        isUpdatingProfile: false,
        errorMessage: 'Unable to update profile. Please try again.',
      ));
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (state.isChangingPassword) return false;

    emit(state.copyWith(isChangingPassword: true, clearError: true));

    try {
      final response = await _authRepository.changePassword(
        request: ChangePasswordRequest(
          currentPassword: currentPassword,
          newPassword: newPassword,
        ),
        sessionToken: state.sessionToken ?? '',
        refreshToken: state.refreshToken ?? '',
      );

      emit(state.copyWith(isChangingPassword: false));
      return response.success;
    } on ApiException catch (e) {
      emit(state.copyWith(isChangingPassword: false, errorMessage: e.message));
      return false;
    } catch (_) {
      emit(state.copyWith(
        isChangingPassword: false,
        errorMessage: 'Unable to change password. Please try again.',
      ));
      return false;
    }
  }

  Future<UserInfo?> fetchUserDetails({String? targetUserId}) async {
    String? uid = targetUserId ?? state.userId;
    if (uid == null || uid.isEmpty) {
      uid = _extractUserIdFromTokens(state.sessionToken, state.refreshToken);
      if (uid != null && uid.isNotEmpty) {
        emit(state.copyWith(userId: uid));
      }
    }
    if (uid == null || uid.isEmpty) return null;
    if ((state.sessionToken == null || state.sessionToken!.isEmpty) &&
        (state.refreshToken == null || state.refreshToken!.isEmpty)) {
      return null;
    }

    try {
      final userInfo = await _authRepository.getUserDetails(
        userId: uid,
        sessionToken: state.sessionToken ?? '',
        refreshToken: state.refreshToken ?? '',
      );

      if (targetUserId == null || targetUserId == state.userId) {
        final updatedUser = Map<String, dynamic>.from(state.currentUser);
        final (userMap, newRegName, newUid) = _applyUserInfoToState(
          updatedUser,
          userInfo,
          state.lastRegisteredFullName,
          state.userId,
        );

        emit(state.copyWith(
          currentUser: userMap,
          lastRegisteredFullName: newRegName,
          userId: newUid,
        ));
      }

      return userInfo;
    } on ApiException catch (e) {
      debugPrint('fetchUserDetails API error: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('fetchUserDetails error: $e');
      return null;
    }
  }

  static (Map<String, dynamic>, String?, String?) _applyUserInfoToState(
    Map<String, dynamic> currentUser,
    UserInfo? userInfo,
    String? lastRegisteredFullName,
    String? currentUserId,
  ) {
    if (userInfo == null) {
      return (currentUser, lastRegisteredFullName, currentUserId);
    }

    String? uid = currentUserId;
    if (userInfo.id.isNotEmpty) {
      uid = userInfo.id;
    }
    if (userInfo.username != null && userInfo.username!.isNotEmpty) {
      currentUser['handle'] = '@${userInfo.username}';
      currentUser['username'] = userInfo.username;
    }
    if (userInfo.firstName != null) {
      currentUser['firstName'] = userInfo.firstName;
    }
    if (userInfo.middleName != null) {
      currentUser['middleName'] = userInfo.middleName;
    }
    if (userInfo.lastName != null) {
      currentUser['lastName'] = userInfo.lastName;
    }

    String? regName = lastRegisteredFullName;
    final rawFullName = userInfo.rawFullName?.trim();
    if (rawFullName != null &&
        rawFullName.isNotEmpty &&
        !UserInfo.isPlaceholderName(rawFullName)) {
      regName = rawFullName;
      currentUser['fullName'] = rawFullName;
      currentUser['name'] = rawFullName;
      currentUser['initials'] = _initialsFromName(rawFullName);
    } else if (currentUser['fullName'] != null &&
        (currentUser['fullName'] as String).trim().isNotEmpty) {
      final existing = (currentUser['fullName'] as String).trim();
      currentUser['name'] = existing;
      currentUser['initials'] = _initialsFromName(existing);
    } else if (regName != null && regName.isNotEmpty) {
      currentUser['fullName'] = regName;
      currentUser['name'] = regName;
      currentUser['initials'] = _initialsFromName(regName);
    } else {
      final fallback = userInfo.fullName;
      if (fallback.isNotEmpty && !UserInfo.isPlaceholderName(fallback)) {
        currentUser['fullName'] = fallback;
        currentUser['name'] = fallback;
        currentUser['initials'] = _initialsFromName(fallback);
      } else {
        final displayName = userInfo.displayName;
        if (displayName.isNotEmpty) {
          currentUser['name'] = displayName;
          currentUser['initials'] = _initialsFromName(displayName);
        }
      }
    }

    if (userInfo.phoneNumber != null) {
      currentUser['phoneNumber'] = userInfo.phoneNumber;
    }
    if (userInfo.gender != null) currentUser['gender'] = userInfo.gender;
    if (userInfo.dob != null) currentUser['dob'] = userInfo.dob;
    if (userInfo.bio != null) {
      currentUser['bio'] = userInfo.bio!.trim();
    }
    if (userInfo.category != null) {
      currentUser['category'] = userInfo.category!.trim();
    }
    if (userInfo.profilePhotoUrl != null &&
        userInfo.profilePhotoUrl!.isNotEmpty) {
      currentUser['avatarUrl'] = userInfo.profilePhotoUrl;
    }
    if (userInfo.coverImageUrl != null && userInfo.coverImageUrl!.isNotEmpty) {
      currentUser['coverUrl'] = userInfo.coverImageUrl;
    }
    if (userInfo.socialLinks != null) {
      currentUser['socialLinks'] = userInfo.socialLinks;
    }

    return (currentUser, regName, uid);
  }

  static void _applyStoredProfileDetailsToMap(
    Map<String, dynamic> currentUser,
    StoredProfileDetails? details,
  ) {
    if (details == null) return;

    if (details.displayName != null && details.displayName!.trim().isNotEmpty) {
      final name = details.displayName!.trim();
      currentUser['fullName'] = name;
      currentUser['name'] = name;
      currentUser['initials'] = _initialsFromName(name);
    }
    if (details.firstName != null) currentUser['firstName'] = details.firstName;
    if (details.middleName != null) {
      currentUser['middleName'] = details.middleName;
    }
    if (details.lastName != null) currentUser['lastName'] = details.lastName;
    if (details.phoneNumber != null) {
      currentUser['phoneNumber'] = details.phoneNumber;
    }
    if (details.gender != null) currentUser['gender'] = details.gender;
    if (details.dob != null) currentUser['dob'] = details.dob;
    if (details.bio != null && details.bio!.trim().isNotEmpty) {
      currentUser['bio'] = details.bio!.trim();
    }
    if (details.username != null && details.username!.isNotEmpty) {
      currentUser['handle'] = '@${details.username}';
    }
    if (details.category != null) currentUser['category'] = details.category;
    if (details.socialLinks != null) {
      currentUser['socialLinks'] = details.socialLinks;
    }
  }

  Map<String, dynamic> _buildSocialLinks(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty || trimmed == 'https://') {
      return const {};
    }
    if (trimmed.contains('instagram.com')) {
      return {'instagramUrl': trimmed};
    } else if (trimmed.contains('youtube.com') ||
        trimmed.contains('youtu.be')) {
      return {'youtubeUrl': trimmed};
    } else {
      return {'websiteUrl': trimmed};
    }
  }

  (String, String, String) _splitFullNameParts(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return ('', '', '');
    }
    if (parts.length == 1) {
      return (parts.first, '', '');
    }
    if (parts.length == 2) {
      return (parts.first, '', parts.last);
    }
    return (
      parts.first,
      parts.sublist(1, parts.length - 1).join(' '),
      parts.last,
    );
  }

  String _resolveLastNameForApi({
    required String splitLast,
    String? storedLast,
  }) {
    if (splitLast.isNotEmpty && !UserInfo.isPlaceholderName(splitLast)) {
      return splitLast;
    }
    return '';
  }

  String? _usernameFromHandle(String? handle) {
    if (handle == null || handle.isEmpty) return null;
    return handle.replaceAll('@', '');
  }

  static String? _extractUserIdFromTokens(String? token, String? refreshToken) {
    if (token != null && token.isNotEmpty) {
      final id = _extractUserIdFromJwt(token);
      if (id != null && id.isNotEmpty) return id;
    }
    if (refreshToken != null && refreshToken.isNotEmpty) {
      final id = _extractUserIdFromJwt(refreshToken);
      if (id != null && id.isNotEmpty) return id;
    }
    return null;
  }

  static String? _extractUserIdFromJwt(String token) {
    if (token.isEmpty) return null;
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;
      final normalized = base64Url.normalize(parts[1]);
      final payloadString = utf8.decode(base64Url.decode(normalized));
      final payloadMap = jsonDecode(payloadString);
      if (payloadMap is Map) {
        return payloadMap['id']?.toString() ??
            payloadMap['_id']?.toString() ??
            payloadMap['userId']?.toString() ??
            payloadMap['user_id']?.toString() ??
            payloadMap['sub']?.toString();
      }
    } catch (_) {}
    return null;
  }

  static String _initialsFromName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    if (parts.isNotEmpty && parts.first.isNotEmpty) {
      return parts.first[0].toUpperCase();
    }
    return 'U';
  }
}
