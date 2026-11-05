import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:artable_app/core/constants/api_constants.dart';
import 'package:artable_app/core/network/api_auth_headers.dart';
import 'package:artable_app/core/network/api_client.dart';
import 'package:artable_app/core/network/api_exception.dart';
import 'package:artable_app/core/network/api_session_callbacks_factory.dart';
import 'package:artable_app/core/storage/auth_storage_service.dart';
import '../models/referral_models.dart';

class ReferralRepository {
  ReferralRepository({
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
    var sToken = sessionToken;
    var rToken = refreshToken;
    if (sToken == null || sToken.isEmpty || sToken == 'design_preview') {
      sToken = await _storageService.getSessionToken();
    }
    if (rToken == null || rToken.isEmpty || rToken == 'design_preview') {
      rToken = await _storageService.getRefreshToken();
    }
    // Session token alone is enough — Refresh-Token is optional.
    if (sToken == null || sToken.isEmpty) {
      return <String, String>{};
    }
    return ApiAuthHeaders.authenticated(
      sessionToken: sToken,
      refreshToken: (rToken != null && rToken.isNotEmpty) ? rToken : null,
    );
  }

  Future<ReferralInviteResponse> getInvite({
    String? sessionToken,
    String? refreshToken,
  }) async {
    final headers = await _authHeaders(
      sessionToken: sessionToken,
      refreshToken: refreshToken,
    );
    if (headers.isEmpty) {
      throw ApiException(
        'Please sign in to get your invite code.',
        statusCode: 401,
      );
    }
    debugPrint('=== REFERRAL INVITE REQUEST === GET ${ApiConstants.referralsInvite}');
    final data = await _apiClient.get(
      ApiConstants.referralsInvite,
      headers: headers,
    );
    debugPrint('=== REFERRAL INVITE RESPONSE ===');
    debugPrint(const JsonEncoder.withIndent('  ').convert(data));
    final parsed = ReferralInviteResponse.fromJson(data);
    final normalized = parsed.data?.withFallbackLink();
    return ReferralInviteResponse(
      success: parsed.success && (normalized?.code.isNotEmpty ?? false),
      message: parsed.message,
      data: normalized,
    );
  }

  Future<ReferralTrackingResponse> getTracking({
    String? sessionToken,
    String? refreshToken,
  }) async {
    final headers = await _authHeaders(
      sessionToken: sessionToken,
      refreshToken: refreshToken,
    );
    if (headers.isEmpty) {
      throw ApiException(
        'Please sign in to view referral tracking.',
        statusCode: 401,
      );
    }
    debugPrint('=== REFERRAL TRACKING REQUEST === GET ${ApiConstants.referralsTracking}');
    final data = await _apiClient.get(
      ApiConstants.referralsTracking,
      headers: headers,
    );
    debugPrint('=== REFERRAL TRACKING RESPONSE ===');
    debugPrint(const JsonEncoder.withIndent('  ').convert(data));
    return ReferralTrackingResponse.fromJson(data);
  }

  Future<ApplyReferralResponse> applyReferral({
    required String referralCode,
    String? sessionToken,
    String? refreshToken,
  }) async {
    final headers = await _authHeaders(
      sessionToken: sessionToken,
      refreshToken: refreshToken,
    );
    if (headers.isEmpty) {
      return const ApplyReferralResponse(
        success: false,
        message: 'Please sign in to apply a referral code.',
      );
    }
    final body = {'referralCode': referralCode.trim()};
    debugPrint('=== REFERRAL APPLY REQUEST === POST ${ApiConstants.referralsApply}');
    debugPrint(const JsonEncoder.withIndent('  ').convert(body));
    try {
      final data = await _apiClient.post(
        ApiConstants.referralsApply,
        body: body,
        headers: headers,
      );
      debugPrint('=== REFERRAL APPLY RESPONSE ===');
      debugPrint(const JsonEncoder.withIndent('  ').convert(data));
      return ApplyReferralResponse.fromJson(data);
    } on ApiException catch (e) {
      debugPrint('=== REFERRAL APPLY RESPONSE (ERROR) === ${e.statusCode} ${e.message}');
      if (e.data != null) {
        debugPrint(const JsonEncoder.withIndent('  ').convert(e.data));
        return ApplyReferralResponse.fromJson(e.data!);
      }
      return ApplyReferralResponse(success: false, message: e.message);
    }
  }
}
