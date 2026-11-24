import 'package:artable_app/core/constants/api_constants.dart';
import 'package:artable_app/core/network/api_client.dart';
import 'package:artable_app/core/network/api_response_helpers.dart';
import 'package:artable_app/core/network/api_session_callbacks_factory.dart';
import 'package:artable_app/core/storage/auth_storage_service.dart';

class MembershipRepository {
  MembershipRepository({
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

  Future<List<Map<String, dynamic>>> getPlans({
    String? sessionToken,
    String? refreshToken,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.membershipPlans,
      headers: ApiResponseHelpers.authHeaders(
        sessionToken: sessionToken,
        refreshToken: refreshToken,
      ),
    );
    return ApiResponseHelpers.dataAsList(
      response,
      nestedKeys: const ['plans', 'items', 'list'],
    );
  }

  Future<Map<String, dynamic>> getMyMembership({
    String? sessionToken,
    String? refreshToken,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.membershipMe,
      headers: ApiResponseHelpers.authHeaders(
        sessionToken: sessionToken,
        refreshToken: refreshToken,
      ),
    );
    return ApiResponseHelpers.dataAsMap(response) ?? response;
  }

  Future<Map<String, dynamic>> subscribe({
    required String planId,
    String? sessionToken,
    String? refreshToken,
  }) async {
    return _apiClient.post(
      ApiConstants.membershipSubscribe,
      body: {'planId': planId.trim()},
      headers: ApiResponseHelpers.authHeaders(
        sessionToken: sessionToken,
        refreshToken: refreshToken,
      ),
    );
  }

  Future<Map<String, dynamic>> verifyPayment({
    required String planId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    String? sessionToken,
    String? refreshToken,
  }) async {
    return _apiClient.post(
      ApiConstants.membershipVerifyPayment,
      body: {
        'planId': planId.trim(),
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySignature': razorpaySignature,
      },
      headers: ApiResponseHelpers.authHeaders(
        sessionToken: sessionToken,
        refreshToken: refreshToken,
      ),
    );
  }
}