import 'package:artable_app/core/constants/api_constants.dart';
import 'package:artable_app/core/network/api_client.dart';
import 'package:artable_app/core/network/api_response_helpers.dart';
import 'package:artable_app/core/network/api_session_callbacks_factory.dart';
import 'package:artable_app/core/storage/auth_storage_service.dart';

class ActivityRepository {
  ActivityRepository({
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

  Future<Map<String, dynamic>> getActivity({
    int page = 1,
    int limit = 30,
    String? type,
    String? sessionToken,
    String? refreshToken,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (type != null &&
        type.trim().isNotEmpty &&
        type.trim().toLowerCase() != 'all') {
      params['type'] = type.trim().toLowerCase();
    }

    final path = ApiResponseHelpers.pathWithQuery(
      ApiConstants.activity,
      params,
    );

    final response = await _apiClient.get(
      path,
      headers: ApiResponseHelpers.authHeaders(
        sessionToken: sessionToken,
        refreshToken: refreshToken,
      ),
    );

    final data = ApiResponseHelpers.dataAsMap(response) ?? response;
    final items = ApiResponseHelpers.dataAsList(
      response,
      nestedKeys: const ['activities', 'items', 'list'],
    );

    return {
      'success': response['success'] == true,
      'message': response['message'],
      'summary': _parseSummary(data),
      'items': items,
    };
  }

  static Map<String, dynamic> _parseSummary(Map<String, dynamic> data) {
    final stats = data['stats'] ?? data['summary'] ?? data['totals'];
    final map = stats is Map
        ? Map<String, dynamic>.from(stats)
        : <String, dynamic>{
            'likes': data['likes'] ?? 0,
            'comments': data['comments'] ?? 0,
            'ratings': data['ratings'] ?? 0,
            'entries': data['entries'] ?? 0,
            'rewardsEarned': data['rewardsEarned'] ??
                data['earned'] ??
                data['totalEarned'] ??
                0,
          };

    return {
      'likes': _asInt(map['likes']),
      'comments': _asInt(map['comments']),
      'ratings': _asInt(map['ratings']),
      'entries': _asInt(map['entries'] ?? map['challengeEntries']),
      'rewardsEarned': _formatEarned(
        map['rewardsEarned'] ?? map['earned'] ?? map['totalEarned'],
      ),
    };
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  /// API may send int (0) or string ("₹50") — always return display string.
  static String _formatEarned(dynamic value) {
    if (value == null) return '₹0';
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return '₹0';
      if (trimmed.startsWith('₹')) return trimmed;
      if (trimmed.startsWith(r'$')) {
        return '₹${trimmed.substring(1).trim()}';
      }
      return '₹$trimmed';
    }
    if (value is num) {
      if (value % 1 == 0) return '₹${value.toInt()}';
      return '₹$value';
    }
    return '₹${value.toString()}';
  }
}