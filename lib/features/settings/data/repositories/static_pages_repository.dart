import 'package:artable_app/core/network/api_client.dart';
import 'package:artable_app/core/network/api_auth_headers.dart';
import 'package:artable_app/core/network/api_session_callbacks_factory.dart';
import 'package:artable_app/core/storage/auth_storage_service.dart';
import '../models/privacy_policy_model.dart';
import '../models/faq_model.dart';

class StaticPagesRepository {
  StaticPagesRepository({
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

  Future<StaticPageData> getStaticPage(
    String slug, {
    String? sessionToken,
    String? refreshToken,
  }) async {
    final headers = (sessionToken != null &&
            sessionToken.isNotEmpty &&
            refreshToken != null &&
            refreshToken.isNotEmpty)
        ? ApiAuthHeaders.authenticated(
            sessionToken: sessionToken,
            refreshToken: refreshToken,
          )
        : <String, String>{};

    final cleanSlug = slug.trim().replaceAll(RegExp(r'^/+'), '');
    final res = await _apiClient.get(
      '/app/static-pages/$cleanSlug',
      headers: headers.isNotEmpty ? headers : null,
    );

    if (res['success'] == true && res['data'] is Map) {
      return StaticPageData.fromJson(
        Map<String, dynamic>.from(res['data'] as Map),
      );
    }
    throw Exception(res['message']?.toString() ?? 'Failed to load $slug');
  }

  Future<StaticPageData> getPrivacyPolicy({
    String? sessionToken,
    String? refreshToken,
  }) =>
      getStaticPage(
        'privacy-policy',
        sessionToken: sessionToken,
        refreshToken: refreshToken,
      );

  Future<StaticPageData> getTermsConditions({
    String? sessionToken,
    String? refreshToken,
  }) =>
      getStaticPage(
        'terms-conditions',
        sessionToken: sessionToken,
        refreshToken: refreshToken,
      );

  Future<List<FaqItem>> getFaqs({
    String? sessionToken,
    String? refreshToken,
  }) async {
    final headers = (sessionToken != null &&
            sessionToken.isNotEmpty &&
            refreshToken != null &&
            refreshToken.isNotEmpty)
        ? ApiAuthHeaders.authenticated(
            sessionToken: sessionToken,
            refreshToken: refreshToken,
          )
        : <String, String>{};

    final res = await _apiClient.get(
      '/app/faqs',
      headers: headers.isNotEmpty ? headers : null,
    );

    if (res['success'] == true && res['data'] is List) {
      return (res['data'] as List)
          .whereType<Map>()
          .map((item) => FaqItem.fromJson(Map<String, dynamic>.from(item)))
          .where((faq) => faq.isActive)
          .toList();
    }
    throw Exception(res['message']?.toString() ?? 'Failed to load FAQs');
  }
}
