import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:artable_app/features/auth/data/models/generate_session_request.dart';
import 'package:artable_app/features/auth/data/models/login_response.dart';
import 'api_config.dart';
import 'api_exception.dart';
import 'api_session_callbacks.dart';
import 'loggers/achievements_api_debug_logger.dart';
import 'loggers/auth_api_debug_logger.dart';
import 'loggers/categories_api_debug_logger.dart';
import 'loggers/challenge_detail_api_debug_logger.dart';
import 'loggers/change_password_api_debug_logger.dart';
import 'loggers/edit_profile_api_debug_logger.dart';
import 'loggers/forgot_password_api_debug_logger.dart';
import 'loggers/home_api_debug_logger.dart';
import 'loggers/leaderboard_api_debug_logger.dart';
import 'loggers/login_api_debug_logger.dart';
import 'loggers/logout_api_debug_logger.dart';
import 'loggers/register_api_debug_logger.dart';
import 'loggers/resend_otp_api_debug_logger.dart';
import 'loggers/reset_password_api_debug_logger.dart';
import 'loggers/rewards_api_debug_logger.dart';
import 'loggers/stats_api_debug_logger.dart';
import 'loggers/token_verify_api_debug_logger.dart';
import 'loggers/trending_videos_api_debug_logger.dart';
import 'loggers/create_video_api_debug_logger.dart';
import 'loggers/user_detail_api_debug_logger.dart';
import 'loggers/verify_otp_api_debug_logger.dart';
import 'loggers/winners_api_debug_logger.dart';

class ApiClient {
  ApiClient({
    http.Client? client,
    String? baseUrl,
    this.sessionCallbacks,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _client;
  final String _baseUrl;
  final ApiSessionCallbacks? sessionCallbacks;

  Future<String?>? _refreshInProgress;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? headers,
  }) {
    return _executeWithAuthRetry(
      path: path,
      headers: headers,
      send: (requestHeaders) {
        final uri = Uri.parse('$_baseUrl$path');
        return _client.get(uri, headers: requestHeaders);
      },
    );
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) {
    return _executeWithAuthRetry(
      path: path,
      body: body,
      headers: headers,
      send: (requestHeaders) {
        final uri = Uri.parse('$_baseUrl$path');
        return _client.post(
          uri,
          headers: requestHeaders,
          body: jsonEncode(body ?? {}),
        );
      },
    );
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) {
    return _executeWithAuthRetry(
      path: path,
      body: body,
      headers: headers,
      send: (requestHeaders) {
        final uri = Uri.parse('$_baseUrl$path');
        return _client.put(
          uri,
          headers: requestHeaders,
          body: jsonEncode(body ?? {}),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _executeWithAuthRetry({
    required String path,
    required Future<http.Response> Function(Map<String, String> headers) send,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool hasRetried = false,
  }) async {
    final requestHeaders = {
      'Content-Type': 'application/json',
      ...?headers,
    };

    _logRequest(
      method: _methodForPath(path, body),
      path: path,
      headers: requestHeaders,
      body: body,
    );

    final response = await send(requestHeaders);
    _logResponse(path, response);

    if (_shouldRefreshSession(
      path: path,
      statusCode: response.statusCode,
      headers: requestHeaders,
      hasRetried: hasRetried,
    )) {
      final newSessionToken = await _refreshSessionToken();
      if (newSessionToken == null || newSessionToken.isEmpty) {
        await sessionCallbacks!.onRefreshFailed();
        return _decodeResponse(response);
      }

      final refreshedRefreshToken = await sessionCallbacks!.getRefreshToken();
      final retryHeaders = {
        ...requestHeaders,
        'Authorization': 'Bearer $newSessionToken',
        if (refreshedRefreshToken != null && refreshedRefreshToken.isNotEmpty)
          'Refresh-Token': refreshedRefreshToken,
      };

      final retryResponse = await send(retryHeaders);
      _logResponse(path, retryResponse);
      return _decodeResponse(retryResponse);
    }

    return _decodeResponse(response);
  }

  bool _shouldRefreshSession({
    required String path,
    required int statusCode,
    required Map<String, String> headers,
    required bool hasRetried,
  }) {
    if (statusCode != 401 || hasRetried || sessionCallbacks == null) {
      return false;
    }
    if (path == '/auth/generate-session') return false;
    return headers.containsKey('Authorization');
  }

  Future<String?> _refreshSessionToken() {
    return _refreshInProgress ??= _performSessionRefresh().whenComplete(() {
      _refreshInProgress = null;
    });
  }

  Future<String?> _performSessionRefresh() async {
    final callbacks = sessionCallbacks;
    if (callbacks == null) return null;

    final refreshToken = await callbacks.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    final uri = Uri.parse('$_baseUrl/auth/generate-session');
    final response = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(
        GenerateSessionRequest(refreshToken: refreshToken).toJson(),
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    Map<String, dynamic>? decoded;
    if (response.body.isNotEmpty) {
      final raw = jsonDecode(response.body);
      if (raw is Map<String, dynamic>) {
        decoded = raw;
      } else if (raw is Map) {
        decoded = Map<String, dynamic>.from(raw);
      }
    }

    if (decoded == null) return null;

    final sessionResponse = LoginResponse.fromJson(decoded);
    if (sessionResponse.sessionToken.isEmpty) return null;

    await callbacks.updateSessionTokens(
      sessionToken: sessionResponse.sessionToken,
      refreshToken: sessionResponse.refreshToken.isNotEmpty
          ? sessionResponse.refreshToken
          : null,
    );

    return sessionResponse.sessionToken;
  }

  void _logRequest({
    required String method,
    required String path,
    required Map<String, String> headers,
    Map<String, dynamic>? body,
  }) {
    final fullUrl = '$_baseUrl$path';

    if (path == '/auth/login') {
      AuthApiDebugLogger.logRequest(
        method: method,
        url: fullUrl,
        headers: headers,
        body: body,
        apiLabel: 'LOGIN',
      );
      return;
    }
    if (path == '/auth/register') {
      AuthApiDebugLogger.logRequest(
        method: method,
        url: fullUrl,
        headers: headers,
        body: body,
        apiLabel: 'REGISTER',
      );
      return;
    }
    if (path == '/auth/verify-otp') {
      AuthApiDebugLogger.logRequest(
        method: method,
        url: fullUrl,
        headers: headers,
        body: body,
        apiLabel: 'VERIFY OTP',
      );
      return;
    }
    if (path == '/auth/resend-otp') {
      AuthApiDebugLogger.logRequest(
        method: method,
        url: fullUrl,
        headers: headers,
        body: body,
        apiLabel: 'RESEND OTP',
      );
      return;
    }
    if (path == '/auth/forgot-password') {
      AuthApiDebugLogger.logRequest(
        method: method,
        url: fullUrl,
        headers: headers,
        body: body,
        apiLabel: 'FORGOT PASSWORD',
      );
      return;
    }
    if (path == '/auth/reset-password/token-verify') {
      AuthApiDebugLogger.logRequest(
        method: method,
        url: fullUrl,
        headers: headers,
        body: body,
        apiLabel: 'TOKEN VERIFY',
      );
      return;
    }
    if (path == '/auth/reset-password') {
      AuthApiDebugLogger.logRequest(
        method: method,
        url: fullUrl,
        headers: headers,
        body: body,
        apiLabel: 'RESET PASSWORD',
      );
      return;
    }
    if (path == '/auth/logout') {
      AuthApiDebugLogger.logRequest(
        method: method,
        url: fullUrl,
        headers: headers,
        body: body,
        apiLabel: 'LOGOUT',
      );
      return;
    }
    if (path.startsWith('/user/')) {
      AuthApiDebugLogger.logRequest(
        method: method,
        url: fullUrl,
        headers: headers,
        body: body,
        apiLabel: 'GET USER DETAIL',
      );
      return;
    }
    if (path == '/user') {
      AuthApiDebugLogger.logRequest(
        method: method,
        url: fullUrl,
        headers: headers,
        body: body,
        apiLabel: 'UPDATE PROFILE',
      );
      return;
    }
    if (path.startsWith('/app/categories')) {
      CategoriesApiDebugLogger.logRequest(
        method: method,
        url: fullUrl,
        headers: headers,
      );
      return;
    }
    if (path.startsWith('/app/challenges')) {
      ChallengeDetailApiDebugLogger.logRequest(
        method: method,
        url: fullUrl,
        headers: headers,
      );
      return;
    }
    if (path.startsWith('/app/videos/trending')) {
      TrendingVideosApiDebugLogger.logRequest(
        method: method,
        url: fullUrl,
        headers: headers,
      );
      return;
    }
    if (path.startsWith('/app/videos')) {
      CreateVideoApiDebugLogger.logRequest(
        method: method,
        url: fullUrl,
        headers: headers,
        body: body,
      );
      return;
    }
    if (path.startsWith('/app/leaderboard')) {
      LeaderboardApiDebugLogger.logRequest(
        method: method,
        url: fullUrl,
        headers: headers,
      );
      return;
    }
    if (path.startsWith('/app/rewards')) {
      RewardsApiDebugLogger.logRequest(
        method: method,
        url: fullUrl,
        headers: headers,
      );
      return;
    }
    if (path.startsWith('/app/winners')) {
      WinnersApiDebugLogger.logRequest(
        method: method,
        url: fullUrl,
        headers: headers,
      );
      return;
    }

    AuthApiDebugLogger.logRequest(
      method: method,
      url: fullUrl,
      headers: headers,
      body: body,
      apiLabel: path.replaceAll('/', ' ').trim().toUpperCase(),
    );
  }

  String _methodForPath(String path, Map<String, dynamic>? body) {
    if (path == '/auth/login' ||
        path == '/auth/register' ||
        path == '/auth/verify-otp' ||
        path == '/auth/resend-otp' ||
        path == '/auth/forgot-password' ||
        path == '/auth/reset-password/token-verify' ||
        path == '/auth/reset-password' ||
        path == '/auth/logout') {
      return 'POST';
    }
    if (path == '/user' && body != null) {
      return 'PUT';
    }
    if (body != null) {
      return 'POST';
    }
    return 'GET';
  }

  void _logResponse(String path, http.Response response) {
    final fullUrl = '$_baseUrl$path';

    if (path == '/auth/login') {
      Map<String, dynamic>? responseData;
      if (response.body.isNotEmpty) {
        try {
          final raw = jsonDecode(response.body);
          if (raw is Map<String, dynamic>) {
            responseData = raw;
          } else if (raw is Map) {
            responseData = Map<String, dynamic>.from(raw);
          }
        } catch (_) {}
      }
      AuthApiDebugLogger.logResponse(
        apiLabel: 'LOGIN',
        statusCode: response.statusCode,
        responseBody: response.body,
        url: fullUrl,
        responseData: responseData,
      );
      LoginApiDebugLogger.logResponse(
        statusCode: response.statusCode,
        responseBody: response.body,
        url: fullUrl,
        responseData: responseData,
      );
    } else if (path == '/auth/register') {
      Map<String, dynamic>? responseData;
      if (response.body.isNotEmpty) {
        try {
          final raw = jsonDecode(response.body);
          if (raw is Map<String, dynamic>) {
            responseData = raw;
          } else if (raw is Map) {
            responseData = Map<String, dynamic>.from(raw);
          }
        } catch (_) {}
      }
      AuthApiDebugLogger.logResponse(
        apiLabel: 'REGISTER',
        statusCode: response.statusCode,
        responseBody: response.body,
        url: fullUrl,
        responseData: responseData,
      );
      RegisterApiDebugLogger.logResponse(
        statusCode: response.statusCode,
        responseBody: response.body,
        url: fullUrl,
        responseData: responseData,
      );
    } else if (path == '/auth/verify-otp') {
      Map<String, dynamic>? responseData;
      if (response.body.isNotEmpty) {
        try {
          final raw = jsonDecode(response.body);
          if (raw is Map<String, dynamic>) {
            responseData = raw;
          } else if (raw is Map) {
            responseData = Map<String, dynamic>.from(raw);
          }
        } catch (_) {}
      }
      AuthApiDebugLogger.logResponse(
        apiLabel: 'VERIFY OTP',
        statusCode: response.statusCode,
        responseBody: response.body,
        url: fullUrl,
        responseData: responseData,
      );
      VerifyOtpApiDebugLogger.logResponse(
        statusCode: response.statusCode,
        responseBody: response.body,
        url: fullUrl,
        responseData: responseData,
      );
    } else if (path == '/auth/resend-otp') {
      Map<String, dynamic>? responseData;
      if (response.body.isNotEmpty) {
        try {
          final raw = jsonDecode(response.body);
          if (raw is Map<String, dynamic>) {
            responseData = raw;
          } else if (raw is Map) {
            responseData = Map<String, dynamic>.from(raw);
          }
        } catch (_) {}
      }
      AuthApiDebugLogger.logResponse(
        apiLabel: 'RESEND OTP',
        statusCode: response.statusCode,
        responseBody: response.body,
        url: fullUrl,
        responseData: responseData,
      );
      ResendOtpApiDebugLogger.logResponse(
        statusCode: response.statusCode,
        responseBody: response.body,
        url: fullUrl,
        responseData: responseData,
      );
    } else if (path == '/auth/forgot-password') {
      Map<String, dynamic>? responseData;
      if (response.body.isNotEmpty) {
        try {
          final raw = jsonDecode(response.body);
          if (raw is Map<String, dynamic>) {
            responseData = raw;
          } else if (raw is Map) {
            responseData = Map<String, dynamic>.from(raw);
          }
        } catch (_) {}
      }
      AuthApiDebugLogger.logResponse(
        apiLabel: 'FORGOT PASSWORD',
        statusCode: response.statusCode,
        responseBody: response.body,
        url: fullUrl,
        responseData: responseData,
      );
      ForgotPasswordApiDebugLogger.logResponse(
        statusCode: response.statusCode,
        responseBody: response.body,
        url: fullUrl,
        responseData: responseData,
      );
    } else if (path == '/auth/reset-password/token-verify') {
      Map<String, dynamic>? responseData;
      if (response.body.isNotEmpty) {
        try {
          final raw = jsonDecode(response.body);
          if (raw is Map<String, dynamic>) {
            responseData = raw;
          } else if (raw is Map) {
            responseData = Map<String, dynamic>.from(raw);
          }
        } catch (_) {}
      }
      AuthApiDebugLogger.logResponse(
        apiLabel: 'TOKEN VERIFY',
        statusCode: response.statusCode,
        responseBody: response.body,
        url: fullUrl,
        responseData: responseData,
      );
      TokenVerifyApiDebugLogger.logResponse(
        statusCode: response.statusCode,
        responseBody: response.body,
        url: fullUrl,
        responseData: responseData,
      );
    } else if (path == '/auth/reset-password') {
      Map<String, dynamic>? responseData;
      if (response.body.isNotEmpty) {
        try {
          final raw = jsonDecode(response.body);
          if (raw is Map<String, dynamic>) {
            responseData = raw;
          } else if (raw is Map) {
            responseData = Map<String, dynamic>.from(raw);
          }
        } catch (_) {}
      }
      AuthApiDebugLogger.logResponse(
        apiLabel: 'RESET PASSWORD',
        statusCode: response.statusCode,
        responseBody: response.body,
        url: fullUrl,
        responseData: responseData,
      );
      ResetPasswordApiDebugLogger.logResponse(
        statusCode: response.statusCode,
        responseBody: response.body,
        url: fullUrl,
        responseData: responseData,
      );
    } else if (path == '/auth/logout') {
      Map<String, dynamic>? responseData;
      if (response.body.isNotEmpty) {
        try {
          final raw = jsonDecode(response.body);
          if (raw is Map<String, dynamic>) {
            responseData = raw;
          } else if (raw is Map) {
            responseData = Map<String, dynamic>.from(raw);
          }
        } catch (_) {}
      }
      AuthApiDebugLogger.logResponse(
        apiLabel: 'LOGOUT',
        statusCode: response.statusCode,
        responseBody: response.body,
        url: fullUrl,
        responseData: responseData,
      );
      LogoutApiDebugLogger.logResponse(
        statusCode: response.statusCode,
        responseBody: response.body,
        url: fullUrl,
        responseData: responseData,
      );
    } else if (path == '/user/change-password') {
      Map<String, dynamic>? responseData;
      if (response.body.isNotEmpty) {
        try {
          final raw = jsonDecode(response.body);
          if (raw is Map<String, dynamic>) {
            responseData = raw;
          } else if (raw is Map) {
            responseData = Map<String, dynamic>.from(raw);
          }
        } catch (_) {}
      }
      AuthApiDebugLogger.logResponse(
        apiLabel: 'CHANGE PASSWORD',
        statusCode: response.statusCode,
        responseBody: response.body,
        url: fullUrl,
        responseData: responseData,
      );
      ChangePasswordApiDebugLogger.logResponse(
        statusCode: response.statusCode,
        responseBody: response.body,
        url: fullUrl,
        responseData: responseData,
      );
    } else if (path.startsWith('/user/')) {
      Map<String, dynamic>? responseData;
      if (response.body.isNotEmpty) {
        try {
          final raw = jsonDecode(response.body);
          if (raw is Map<String, dynamic>) {
            responseData = raw;
          } else if (raw is Map) {
            responseData = Map<String, dynamic>.from(raw);
          }
        } catch (_) {}
      }
      AuthApiDebugLogger.logResponse(
        apiLabel: 'GET USER DETAIL',
        statusCode: response.statusCode,
        responseBody: response.body,
        url: fullUrl,
        responseData: responseData,
      );
      UserDetailApiDebugLogger.logResponse(
        statusCode: response.statusCode,
        responseBody: response.body,
        url: fullUrl,
        responseData: responseData,
      );
    } else if (path == '/user') {
      AuthApiDebugLogger.logResponse(
        apiLabel: 'UPDATE PROFILE',
        statusCode: response.statusCode,
        responseBody: response.body,
        url: fullUrl,
      );
      EditProfileApiDebugLogger.logResponse(
        statusCode: response.statusCode,
        responseBody: response.body,
        url: fullUrl,
      );
    } else if (path == '/app/home') {
      HomeApiDebugLogger.logResponse(
        statusCode: response.statusCode,
        responseBody: response.body,
        url: fullUrl,
      );
    } else if (path == '/app/profile/achievements') {
      AchievementsApiDebugLogger.logResponse(
        statusCode: response.statusCode,
        responseBody: response.body,
        url: fullUrl,
      );
    } else if (path == '/app/profile/stats') {
      StatsApiDebugLogger.logResponse(
        statusCode: response.statusCode,
        responseBody: response.body,
        url: fullUrl,
      );
    } else if (path.startsWith('/app/categories')) {
      CategoriesApiDebugLogger.logResponse(
        statusCode: response.statusCode,
        responseBody: response.body,
        url: fullUrl,
      );
    } else if (path.startsWith('/app/challenges')) {
      ChallengeDetailApiDebugLogger.logResponse(
        statusCode: response.statusCode,
        responseBody: response.body,
        url: fullUrl,
      );
    } else if (path.startsWith('/app/videos/trending')) {
      TrendingVideosApiDebugLogger.logResponse(
        statusCode: response.statusCode,
        responseBody: response.body,
        url: fullUrl,
      );
    } else if (path.startsWith('/app/videos')) {
      CreateVideoApiDebugLogger.logResponse(
        statusCode: response.statusCode,
        responseBody: response.body,
        url: fullUrl,
      );
    } else if (path.startsWith('/app/leaderboard')) {
      LeaderboardApiDebugLogger.logResponse(
        statusCode: response.statusCode,
        responseBody: response.body,
        url: fullUrl,
      );
    } else if (path.startsWith('/app/rewards')) {
      RewardsApiDebugLogger.logResponse(
        statusCode: response.statusCode,
        responseBody: response.body,
        url: fullUrl,
      );
    } else if (path.startsWith('/app/winners')) {
      WinnersApiDebugLogger.logResponse(
        statusCode: response.statusCode,
        responseBody: response.body,
        url: fullUrl,
      );
    } else {
      AuthApiDebugLogger.logResponse(
        apiLabel: path.replaceAll('/', ' ').trim().toUpperCase(),
        statusCode: response.statusCode,
        responseBody: response.body,
        url: fullUrl,
      );
    }
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    Map<String, dynamic>? decoded;
    if (response.body.isNotEmpty) {
      final raw = jsonDecode(response.body);
      if (raw is Map<String, dynamic>) {
        decoded = raw;
      } else if (raw is Map) {
        decoded = Map<String, dynamic>.from(raw);
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded ?? {};
    }

    final message = _extractErrorMessage(decoded) ??
        'Request failed with status ${response.statusCode}';
    throw ApiException(message, statusCode: response.statusCode);
  }

  String? _extractErrorMessage(Map<String, dynamic>? decoded) {
    if (decoded == null) return null;

    final message = decoded['message'];
    if (message is String && message.isNotEmpty) return message;

    final error = decoded['error'];
    if (error is String && error.isNotEmpty) return error;

    final errors = decoded['errors'];
    if (errors is List && errors.isNotEmpty) {
      final first = errors.first;
      if (first is String) return first;
      if (first is Map) {
        final nested = first['message'] ?? first['msg'];
        if (nested is String && nested.isNotEmpty) return nested;
      }
    }

    final details = decoded['details'];
    if (details is List && details.isNotEmpty) {
      final first = details.first;
      if (first is Map) {
        final nested = first['message'] ?? first['msg'];
        if (nested is String && nested.isNotEmpty) return nested;
      }
    }

    return null;
  }
}