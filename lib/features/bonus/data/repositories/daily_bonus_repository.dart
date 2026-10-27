import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:artable_app/core/constants/api_constants.dart';
import 'package:artable_app/core/network/api_auth_headers.dart';
import 'package:artable_app/core/network/api_client.dart';
import 'package:artable_app/core/network/api_exception.dart';
import 'package:artable_app/core/network/api_session_callbacks_factory.dart';
import 'package:artable_app/core/storage/auth_storage_service.dart';
import 'package:artable_app/features/bonus/data/models/claim_daily_bonus_request.dart';
import 'package:artable_app/features/bonus/data/models/claim_daily_bonus_response.dart';
import 'package:artable_app/features/bonus/data/models/daily_bonus_calendar_response.dart';

class DailyBonusRepository {
  DailyBonusRepository({
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

  Future<Map<String, String>> _authHeaders({
    String? sessionToken,
    String? refreshToken,
  }) async {
    String? sToken = sessionToken;
    String? rToken = refreshToken;
    if (sToken == null || sToken.isEmpty || sToken == 'design_preview') {
      sToken = await _storageService.getSessionToken();
    }
    if (rToken == null || rToken.isEmpty || rToken == 'design_preview') {
      rToken = await _storageService.getRefreshToken();
    }
    if (sToken == null || sToken.isEmpty || rToken == null || rToken.isEmpty) {
      return <String, String>{};
    }
    return ApiAuthHeaders.authenticated(
      sessionToken: sToken,
      refreshToken: rToken,
    );
  }

  Future<DailyBonusCalendarResponse> getCalendar({
    String? sessionToken,
    String? refreshToken,
  }) async {
    final headers = await _authHeaders(
      sessionToken: sessionToken,
      refreshToken: refreshToken,
    );
    debugPrint('=== DAILY BONUS CALENDAR REQUEST ===');
    debugPrint('Method: GET');
    debugPrint('URL: ${ApiConstants.dailyBonusCalendar}');

    final data = await _apiClient.get(
      ApiConstants.dailyBonusCalendar,
      headers: headers.isNotEmpty ? headers : null,
    );
    debugPrint('=== DAILY BONUS CALENDAR RESPONSE ===');
    debugPrint(const JsonEncoder.withIndent('  ').convert(data));
    return DailyBonusCalendarResponse.fromJson(data);
  }

  Future<ClaimDailyBonusResponse> claim({
    required int coins,
    required int points,
    required int streakDay,
    String? sessionToken,
    String? refreshToken,
  }) async {
    final request = ClaimDailyBonusRequest(
      coins: coins,
      points: points,
      streakDay: streakDay,
    );

    final headers = await _authHeaders(
      sessionToken: sessionToken,
      refreshToken: refreshToken,
    );

    debugPrint('=== CLAIM DAILY BONUS REQUEST ===');
    debugPrint('URL: ${ApiConstants.dailyBonusClaim}');
    debugPrint(const JsonEncoder.withIndent('  ').convert(request.toJson()));

    try {
      final data = await _apiClient.post(
        ApiConstants.dailyBonusClaim,
        body: request.toJson(),
        headers: headers.isNotEmpty ? headers : null,
      );
      debugPrint('=== CLAIM DAILY BONUS RESPONSE ===');
      debugPrint(const JsonEncoder.withIndent('  ').convert(data));
      return ClaimDailyBonusResponse.fromJson(data);
    } on ApiException catch (e) {
      debugPrint('=== CLAIM DAILY BONUS RESPONSE (ERROR) ===');
      debugPrint('Status: ${e.statusCode}');
      debugPrint('Message: ${e.message}');
      if (e.data != null) {
        debugPrint(const JsonEncoder.withIndent('  ').convert(e.data));
        return ClaimDailyBonusResponse.fromJson(e.data!);
      }
      debugPrint('{}');
      rethrow;
    }
  }
}
