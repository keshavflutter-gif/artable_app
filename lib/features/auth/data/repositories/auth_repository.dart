import 'package:artable_app/core/network/api_auth_headers.dart';
import 'package:artable_app/core/network/api_client.dart';
import 'package:artable_app/core/network/api_exception.dart';
import 'package:artable_app/core/network/api_session_callbacks_factory.dart';
import 'package:artable_app/core/storage/auth_storage_service.dart';
import '../models/change_password_request.dart';
import '../models/change_password_response.dart';
import '../models/forgot_password_request.dart';
import '../models/forgot_password_response.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/register_request.dart';
import '../models/register_response.dart';
import '../models/resend_otp_request.dart';
import '../models/resend_otp_response.dart';
import '../models/reset_password_request.dart';
import '../models/reset_password_response.dart';
import '../models/token_verify_request.dart';
import '../models/token_verify_response.dart';
import '../models/update_profile_request.dart';
import '../models/user_info.dart';
import '../models/verify_otp_request.dart';
import '../models/verify_otp_response.dart';

class AuthRepository {
  AuthRepository({
    ApiClient? apiClient,
    AuthStorageService? storageService,
    void Function({
      required String sessionToken,
      String? refreshToken,
    })? onTokensRefreshed,
    Future<void> Function()? onSessionRefreshFailed,
  }) : _storageService = storageService ?? AuthStorageService() {
    _apiClient = apiClient ??
        ApiClient(
          sessionCallbacks: createApiSessionCallbacks(
            storage: _storageService,
            onTokensRefreshed: onTokensRefreshed,
            onSessionRefreshFailed: onSessionRefreshFailed,
          ),
        );
  }

  late final ApiClient _apiClient;
  final AuthStorageService _storageService;

  Future<LoginResponse> login(LoginRequest request) async {
    final data = await _apiClient.post('/auth/login', body: request.toJson());
    final response = LoginResponse.fromJson(data);

    if (response.sessionToken.isEmpty || response.refreshToken.isEmpty) {
      throw ApiException('Login response did not include session tokens.');
    }

    await _storageService.saveSession(
      sessionToken: response.sessionToken,
      refreshToken: response.refreshToken,
      userId: response.userInfo?.id,
      displayName: response.userInfo?.displayName,
    );
    await _persistUserProfile(response.userInfo);

    return response;
  }

  Future<UserInfo> getUserDetails({
    required String userId,
    required String sessionToken,
    required String refreshToken,
  }) async {
    final data = await _apiClient.get(
      '/user/$userId',
      headers: ApiAuthHeaders.authenticated(
        sessionToken: sessionToken,
        refreshToken: refreshToken,
      ),
    );

    final userInfo = UserInfo.fromApiResponse(data);
    await _persistUserProfile(userInfo);
    return userInfo;
  }

  Future<UserInfo> updateProfile({
    required UpdateProfileRequest request,
    required String sessionToken,
    required String refreshToken,
  }) async {
    final data = await _apiClient.put(
      '/user',
      body: request.toJson(),
      headers: ApiAuthHeaders.authenticated(
        sessionToken: sessionToken,
        refreshToken: refreshToken,
      ),
    );

    final updatedUser = UserInfo.fromApiResponse(data);
    await _persistUserProfile(updatedUser);
    return updatedUser;
  }

  Future<void> _persistUserProfile(UserInfo? userInfo) async {
    if (userInfo == null) return;

    await _storageService.saveProfileDetails(
      displayName: userInfo.displayName,
      firstName: userInfo.firstName,
      middleName: userInfo.middleName,
      lastName: userInfo.lastName,
      phoneNumber: userInfo.phoneNumber,
      gender: userInfo.gender,
      dob: userInfo.dob,
      username: userInfo.username,
      bio: userInfo.bio,
      category: userInfo.category,
      socialLinks: userInfo.socialLinks,
    );
  }

  Future<void> persistLocalProfileDetails({
    String? displayName,
    String? firstName,
    String? middleName,
    String? lastName,
    String? bio,
    String? username,
    String? category,
    List<Map<String, dynamic>>? socialLinks,
  }) {
    return _storageService.saveProfileDetails(
      displayName: displayName,
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      bio: bio,
      username: username,
      category: category,
      socialLinks: socialLinks,
    );
  }

  Future<RegisterResponse> register(RegisterRequest request) async {
    final data = await _apiClient.post('/auth/register', body: request.toJson());
    return RegisterResponse.fromJson(data);
  }

  Future<VerifyOtpResponse> verifyOtp(VerifyOtpRequest request) async {
    final data = await _apiClient.post('/auth/verify-otp', body: request.toJson());
    return VerifyOtpResponse.fromJson(data);
  }

  Future<ResendOtpResponse> resendOtp(ResendOtpRequest request) async {
    final data = await _apiClient.post('/auth/resend-otp', body: request.toJson());
    return ResendOtpResponse.fromJson(data);
  }

  Future<ForgotPasswordResponse> forgotPassword(ForgotPasswordRequest request) async {
    final data = await _apiClient.post('/auth/forgot-password', body: request.toJson());
    return ForgotPasswordResponse.fromJson(data);
  }

  Future<TokenVerifyResponse> verifyResetToken(TokenVerifyRequest request) async {
    final data = await _apiClient.post(
      '/auth/reset-password/token-verify',
      body: request.toJson(),
    );
    return TokenVerifyResponse.fromJson(data);
  }

  Future<ResetPasswordResponse> resetPassword(ResetPasswordRequest request) async {
    final data = await _apiClient.post(
      '/auth/reset-password',
      body: request.toJson(),
    );
    return ResetPasswordResponse.fromJson(data);
  }

  Future<ChangePasswordResponse> changePassword({
    required ChangePasswordRequest request,
    required String sessionToken,
    required String refreshToken,
  }) async {
    final data = await _apiClient.post(
      '/user/change-password',
      body: request.toJson(),
      headers: ApiAuthHeaders.authenticated(
        sessionToken: sessionToken,
        refreshToken: refreshToken,
      ),
    );
    return ChangePasswordResponse.fromJson(data);
  }

  Future<void> clearStoredSession() => _storageService.clearSession();

  Future<StoredAuthSession?> loadStoredSession() async {
    final sessionToken = await _storageService.getSessionToken();
    final refreshToken = await _storageService.getRefreshToken();
    final userId = await _storageService.getUserId();
    final profileDetails = await _storageService.getProfileDetails();

    if (sessionToken == null ||
        sessionToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      return null;
    }

    return StoredAuthSession(
      sessionToken: sessionToken,
      refreshToken: refreshToken,
      userId: userId,
      displayName: profileDetails?.displayName,
      profileDetails: profileDetails,
    );
  }
}

class StoredAuthSession {
  const StoredAuthSession({
    required this.sessionToken,
    required this.refreshToken,
    this.userId,
    this.displayName,
    this.profileDetails,
  });

  final String sessionToken;
  final String refreshToken;
  final String? userId;
  final String? displayName;
  final StoredProfileDetails? profileDetails;
}
