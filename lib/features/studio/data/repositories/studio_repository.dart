import 'dart:io';
import 'package:artable_app/core/network/api_auth_headers.dart';
import 'package:artable_app/core/network/api_client.dart';
import 'package:artable_app/core/network/api_session_callbacks_factory.dart';
import 'package:artable_app/core/storage/auth_storage_service.dart';
import '../models/save_studio_draft_response.dart';
import '../models/studio_drafts_list_response.dart';
import '../models/studio_filters_response.dart';
import '../models/studio_setup_response.dart';

class StudioRepository {
  StudioRepository({
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

  Future<StudioFiltersResponse> getStudioFiltersConfig({
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
        : null;

    final data = await _apiClient.get(
      '/app/studio/filters',
      headers: headers,
    );

    return StudioFiltersResponse.fromJson(data);
  }

  Future<StudioSetupResponse?> getStudioSetup({
    required String challengeId,
    String? sessionToken,
    String? refreshToken,
  }) async {
    final cleanId = challengeId.trim();
    if (cleanId.isEmpty) return null;

    final headers = (sessionToken != null &&
            sessionToken.isNotEmpty &&
            refreshToken != null &&
            refreshToken.isNotEmpty)
        ? ApiAuthHeaders.authenticated(
            sessionToken: sessionToken,
            refreshToken: refreshToken,
          )
        : null;

    final data = await _apiClient.get(
      '/app/studio/challenges/$cleanId/setup',
      headers: headers,
    );

    return StudioSetupResponse.fromJson(data);
  }

  Future<SaveStudioDraftResponse> saveDraft({
    required Map<String, dynamic> body,
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
        : null;

    final data = await _apiClient.post(
      '/app/studio/drafts',
      body: body,
      headers: headers,
    );

    return SaveStudioDraftResponse.fromJson(data);
  }

  Future<SaveStudioDraftResponse> updateDraft({
    required String videoId,
    required Map<String, dynamic> body,
    String? sessionToken,
    String? refreshToken,
  }) async {
    final cleanId = videoId.trim();
    final headers = (sessionToken != null &&
            sessionToken.isNotEmpty &&
            refreshToken != null &&
            refreshToken.isNotEmpty)
        ? ApiAuthHeaders.authenticated(
            sessionToken: sessionToken,
            refreshToken: refreshToken,
          )
        : null;

    final data = await _apiClient.put(
      '/app/studio/drafts/$cleanId',
      body: body,
      headers: headers,
    );

    return SaveStudioDraftResponse.fromJson(data);
  }

  Future<Map<String, dynamic>> deleteDraft({
    required String videoId,
    String? sessionToken,
    String? refreshToken,
  }) async {
    final cleanId = videoId.trim();
    final headers = (sessionToken != null &&
            sessionToken.isNotEmpty &&
            refreshToken != null &&
            refreshToken.isNotEmpty)
        ? ApiAuthHeaders.authenticated(
            sessionToken: sessionToken,
            refreshToken: refreshToken,
          )
        : null;

    final data = await _apiClient.delete(
      '/app/studio/drafts/$cleanId',
      headers: headers,
    );

    return data;
  }

  Future<StudioDraftsListResponse> getDraftsList({
    String? challengeId,
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
        : null;

    final cleanId = challengeId?.trim();
    final path = (cleanId != null && cleanId.isNotEmpty)
        ? '/app/studio/drafts?challengeId=$cleanId'
        : '/app/studio/drafts';

    final data = await _apiClient.get(
      path,
      headers: headers,
    );

    return StudioDraftsListResponse.fromJson(data);
  }

  Future<String> uploadFile(
    String filePath, {
    required bool isVideo,
    String? sessionToken,
    String? refreshToken,
  }) async {
    var clean = filePath.trim();
    if (clean.startsWith('file://')) {
      clean = clean.replaceFirst('file://', '');
    }

    final file = File(clean);
    if (!await file.exists()) {
      throw Exception('Local file does not exist at $clean');
    }

    final fileSize = await file.length();
    if (fileSize <= 0) {
      throw Exception('File size is 0 bytes');
    }

    final rawName = file.path.split(Platform.pathSeparator).last;
    final fileName = rawName.isNotEmpty
        ? rawName
        : (isVideo
            ? 'video_${DateTime.now().millisecondsSinceEpoch}.mp4'
            : 'thumb_${DateTime.now().millisecondsSinceEpoch}.jpg');
    final fileType = isVideo ? 'video/mp4' : 'image/jpeg';
    final folder = isVideo ? 'videos' : 'thumbnails';

    final headers = (sessionToken != null &&
            sessionToken.isNotEmpty &&
            refreshToken != null &&
            refreshToken.isNotEmpty)
        ? ApiAuthHeaders.authenticated(
            sessionToken: sessionToken,
            refreshToken: refreshToken,
          )
        : null;

    final presignedRes = await _apiClient.getPresignedUrl(
      fileName: fileName,
      fileType: fileType,
      folder: folder,
      headers: headers,
    );

    if (presignedRes['success'] != true || presignedRes['data'] is! Map) {
      final msg = presignedRes['message']?.toString() ?? 'Failed to get presigned upload URL';
      throw Exception(msg);
    }

    final data = Map<String, dynamic>.from(presignedRes['data'] as Map);
    final uploadUrl = data['uploadUrl']?.toString();
    final fileUrl = data['fileUrl']?.toString();
    final contentType = data['contentType']?.toString() ?? fileType;

    if (uploadUrl == null || uploadUrl.isEmpty || fileUrl == null || fileUrl.isEmpty) {
      throw Exception('Presigned URL response missing uploadUrl or fileUrl');
    }

    final bytes = await file.readAsBytes();

    final uploadSuccess = await _apiClient.uploadFileToPresignedUrl(
      uploadUrl: uploadUrl,
      bytes: bytes,
      contentType: contentType,
    );

    if (!uploadSuccess) {
      throw Exception('Storage PUT upload failed for $fileName');
    }

    return fileUrl;
  }
}
