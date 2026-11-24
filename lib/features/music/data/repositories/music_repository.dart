import 'package:artable_app/core/constants/api_constants.dart';
import 'package:artable_app/core/network/api_client.dart';
import 'package:artable_app/core/network/api_response_helpers.dart';
import 'package:artable_app/core/network/api_session_callbacks_factory.dart';
import 'package:artable_app/core/storage/auth_storage_service.dart';
import 'package:artable_app/features/music/data/models/music_track.dart';

class MusicRepository {
  MusicRepository({
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

  Future<List<MusicTrack>> getMusic({
    String? category,
    int page = 1,
    int limit = 40,
    String? sessionToken,
    String? refreshToken,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (category != null &&
        category.trim().isNotEmpty &&
        category.toLowerCase() != 'all') {
      params['category'] = category.trim();
    }

    final path = ApiResponseHelpers.pathWithQuery(ApiConstants.music, params);
    final response = await _apiClient.get(
      path,
      headers: ApiResponseHelpers.authHeaders(
        sessionToken: sessionToken,
        refreshToken: refreshToken,
      ),
    );

    final rows = ApiResponseHelpers.dataAsList(
      response,
      nestedKeys: const ['tracks', 'items', 'list'],
    );

    return rows
        .map(MusicTrack.fromJson)
        .where((t) => t.id.isNotEmpty)
        .toList();
  }

  Future<MusicTrack?> getMusicById({
    required String id,
    String? sessionToken,
    String? refreshToken,
  }) async {
    final cleanId = id.trim();
    if (cleanId.isEmpty) return null;

    final response = await _apiClient.get(
      ApiConstants.musicById(cleanId),
      headers: ApiResponseHelpers.authHeaders(
        sessionToken: sessionToken,
        refreshToken: refreshToken,
      ),
    );

    final data = ApiResponseHelpers.dataAsMap(response);
    if (data != null) {
      final track = MusicTrack.fromJson(data);
      return track.id.isNotEmpty ? track : null;
    }

    return null;
  }
}