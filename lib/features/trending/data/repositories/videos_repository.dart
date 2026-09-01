import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:artable_app/core/network/api_auth_headers.dart';
import 'package:artable_app/core/network/api_client.dart';
import 'package:artable_app/core/network/api_session_callbacks_factory.dart';
import 'package:artable_app/core/storage/auth_storage_service.dart';
import 'package:artable_app/features/studio/data/services/video_thumbnail_generator.dart';
import '../models/trending_videos_response.dart';

class VideosRepository {
  VideosRepository({
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

  Future<TrendingVideosResponse> getTrendingVideos({
    String? tab,
    String? category,
    String? categoryId,
    int page = 1,
    int limit = 20,
    String? sessionToken,
    String? refreshToken,
  }) async {
    final queryParams = <String, String>{
      if (tab != null && tab.trim().isNotEmpty) 'tab': tab.trim(),
      if (category != null && category.trim().isNotEmpty)
        'category': category.trim(),
      if (categoryId != null && categoryId.trim().isNotEmpty)
        'categoryId': categoryId.trim(),
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final queryString = Uri(queryParameters: queryParams).query;
    final path = queryParams.isNotEmpty
        ? '/app/videos/trending?$queryString'
        : '/app/videos/trending';

    final headers = (sessionToken != null &&
            sessionToken.isNotEmpty &&
            refreshToken != null &&
            refreshToken.isNotEmpty)
        ? ApiAuthHeaders.authenticated(
            sessionToken: sessionToken,
            refreshToken: refreshToken,
          )
        : <String, String>{};

    final data = await _apiClient.get(
      path,
      headers: headers.isNotEmpty ? headers : null,
    );

    return TrendingVideosResponse.fromJson(data);
  }

  Future<TrendingVideoItem?> getVideoById(
    String videoId, {
    String? sessionToken,
    String? refreshToken,
  }) async {
    final cleanId = videoId.trim();
    if (cleanId.isEmpty) return null;

    final headers = (sessionToken != null &&
            sessionToken.isNotEmpty &&
            refreshToken != null &&
            refreshToken.isNotEmpty)
        ? ApiAuthHeaders.authenticated(
            sessionToken: sessionToken,
            refreshToken: refreshToken,
          )
        : <String, String>{};

    try {
      final res = await _apiClient.get(
        '/app/videos/$cleanId',
        headers: headers.isNotEmpty ? headers : null,
      );
      if (res['success'] == true && res['data'] is Map) {
        return TrendingVideoItem.fromJson(
          Map<String, dynamic>.from(res['data'] as Map),
        );
      }
    } catch (_) {}

    final res = await getTrendingVideos(
      sessionToken: sessionToken,
      refreshToken: refreshToken,
    );
    if (res.data != null) {
      if (res.data!.hero?.id == cleanId) {
        return res.data!.hero;
      }
      for (final v in res.data!.gridVideos) {
        if (v.id == cleanId) return v;
      }
    }
    return null;
  }

  Future<Map<String, dynamic>> createVideo({
    required String title,
    required String videoPathOrUrl,
    String? manualSelectedThumbnailPath,
    String? description,
    String? categoryId,
    String? hashtags,
    String? challengeId,
    String? sessionToken,
    String? refreshToken,
  }) async {
    // 1. Ensure video URL is ready
    String finalVideoUrl = videoPathOrUrl;
    if (!finalVideoUrl.startsWith('http://') && !finalVideoUrl.startsWith('https://')) {
      finalVideoUrl = await _uploadFile(
        finalVideoUrl,
        isVideo: true,
        sessionToken: sessionToken,
        refreshToken: refreshToken,
      );
    }

    // 2. Resolve Thumbnail (Priority: Manual selected thumbnail > Video-generated thumbnail)
    String finalThumbnailUrl = 'https://images.unsplash.com/photo-1547153760-18fc86324498?w=600&q=80';
    if (manualSelectedThumbnailPath != null &&
        manualSelectedThumbnailPath.trim().isNotEmpty &&
        manualSelectedThumbnailPath.trim() != 'null') {
      final path = manualSelectedThumbnailPath.trim();
      if (path.startsWith('http://') || path.startsWith('https://')) {
        finalThumbnailUrl = path;
      } else {
        try {
          finalThumbnailUrl = await _uploadFile(
            path,
            isVideo: false,
            sessionToken: sessionToken,
            refreshToken: refreshToken,
          );
        } catch (e) {
          debugPrint('Thumbnail upload error fallback to default: $e');
        }
      }
    } else {
      try {
        final generatedFile =
            await VideoThumbnailGenerator.generateThumbnailFromVideo(videoPathOrUrl);
        if (generatedFile != null && await generatedFile.exists()) {
          finalThumbnailUrl = await _uploadFile(
            generatedFile.path,
            isVideo: false,
            sessionToken: sessionToken,
            refreshToken: refreshToken,
          );
        }
      } catch (e) {
        debugPrint('Generated thumbnail upload error fallback to default: $e');
      }
    }

    // 3. Call Create Video API (POST /app/videos) with ready videoUrl & thumbnailUrl
    final headers = (sessionToken != null &&
            sessionToken.isNotEmpty &&
            refreshToken != null &&
            refreshToken.isNotEmpty)
        ? ApiAuthHeaders.authenticated(
            sessionToken: sessionToken,
            refreshToken: refreshToken,
          )
        : <String, String>{};

    final isChallengeIdAsCategory = (categoryId != null &&
        challengeId != null &&
        categoryId.trim() == challengeId.trim());

    final isRealCategoryId = categoryId != null &&
        categoryId.trim().isNotEmpty &&
        !isChallengeIdAsCategory &&
        !categoryId.trim().toLowerCase().startsWith('cat_') &&
        !RegExp(r'^cat_\w+$', caseSensitive: false).hasMatch(categoryId.trim());

    final hashtagsList = _parseHashtagsList(hashtags);

    final body = <String, dynamic>{
      'title': title,
      'videoUrl': finalVideoUrl,
      'thumbnailUrl': finalThumbnailUrl,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      if (isRealCategoryId)
        'categoryId': categoryId.trim(),
      if (hashtagsList.isNotEmpty)
        'hashtags': hashtagsList,
      if (challengeId != null && challengeId.trim().isNotEmpty)
        'challengeId': challengeId.trim(),
    };

    debugPrint('=== CREATE VIDEO === Create Video videoUrl: $finalVideoUrl');
    debugPrint('=== CREATE VIDEO === Create Video API request payload: $body');

    final response = await _apiClient.post(
      '/app/videos',
      body: body,
      headers: headers.isNotEmpty ? headers : null,
    );

    final isSuccess = response['success'] == true || response['status'] == 200 || response['status'] == 201;
    final createdData = response['data'] is Map ? Map<String, dynamic>.from(response['data'] as Map) : null;
    final createdId = createdData?['id']?.toString() ?? 'N/A';

    debugPrint('=== CREATE VIDEO === Create Video API status: ${response['status'] ?? 200}');
    debugPrint('=== CREATE VIDEO === Create Video success: $isSuccess');
    debugPrint('=== CREATE VIDEO === Created video ID: $createdId');

    return response;
  }

  List<String> _parseHashtagsList(dynamic input) {
    if (input == null) return const [];
    if (input is List) {
      return input
          .map((e) => e.toString().trim().replaceAll(RegExp(r'^#+'), ''))
          .where((e) => e.isNotEmpty)
          .map((e) => '#$e')
          .toList();
    }
    if (input is String) {
      if (input.trim().isEmpty) return const [];
      final items = input
          .split(RegExp(r'[\s,\n]+'))
          .map((e) => e.trim().replaceAll(RegExp(r'^#+'), ''))
          .where((e) => e.isNotEmpty)
          .map((e) => '#$e')
          .toList();
      return items;
    }
    return const [];
  }

  Future<Map<String, dynamic>> likeVideo({
    required String videoId,
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

    return _apiClient.post(
      '/app/videos/$videoId/like',
      headers: headers.isNotEmpty ? headers : null,
    );
  }

  Future<Map<String, dynamic>> saveVideo({
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
        : <String, String>{};

    return _apiClient.post(
      '/app/videos/$cleanId/save',
      headers: headers.isNotEmpty ? headers : null,
    );
  }

  Future<Map<String, dynamic>> rateVideo({
    required String videoId,
    required double score,
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
        : <String, String>{};

    final formattedScore = score.toStringAsFixed(1);

    return _apiClient.post(
      '/app/videos/$cleanId/rate',
      body: {
        'score': formattedScore,
      },
      headers: headers.isNotEmpty ? headers : null,
    );
  }

  Future<Map<String, dynamic>> createComment({
    required String videoId,
    required String text,
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

    return _apiClient.post(
      '/app/comments',
      body: {
        'videoId': videoId,
        'text': text,
      },
      headers: headers.isNotEmpty ? headers : null,
    );
  }

  Future<Map<String, dynamic>> getComments({
    required String videoId,
    int page = 1,
    int limit = 20,
    String? sessionToken,
    String? refreshToken,
  }) async {
    final queryParams = <String, String>{
      'videoId': videoId.trim(),
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final queryString = Uri(queryParameters: queryParams).query;
    final path = '/app/comments?$queryString';

    final headers = (sessionToken != null &&
            sessionToken.isNotEmpty &&
            refreshToken != null &&
            refreshToken.isNotEmpty)
        ? ApiAuthHeaders.authenticated(
            sessionToken: sessionToken,
            refreshToken: refreshToken,
          )
        : <String, String>{};

    return _apiClient.get(
      path,
      headers: headers.isNotEmpty ? headers : null,
    );
  }

  Future<Map<String, dynamic>> deleteComment({
    required String commentId,
    String? sessionToken,
    String? refreshToken,
  }) async {
    final cleanId = commentId.trim();
    final headers = (sessionToken != null &&
            sessionToken.isNotEmpty &&
            refreshToken != null &&
            refreshToken.isNotEmpty)
        ? ApiAuthHeaders.authenticated(
            sessionToken: sessionToken,
            refreshToken: refreshToken,
          )
        : <String, String>{};

    return _apiClient.delete(
      '/app/comments/$cleanId',
      headers: headers.isNotEmpty ? headers : null,
    );
  }

  Future<String> _uploadFile(
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
      throw Exception('Recorded file size is 0 bytes');
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
        : <String, String>{};

    debugPrint('=== PRESIGNED URL === Presigned URL API called');
    debugPrint(
        '=== PRESIGNED URL === fileName: $fileName, fileType: $fileType, folder: $folder');

    final presignedRes = await _apiClient.getPresignedUrl(
      fileName: fileName,
      fileType: fileType,
      folder: folder,
      headers: headers.isNotEmpty ? headers : null,
    );

    if (presignedRes['success'] != true || presignedRes['data'] is! Map) {
      final msg = presignedRes['message']?.toString() ??
          'Failed to get presigned upload URL';
      debugPrint('=== PRESIGNED URL ERROR === $msg');
      throw Exception(msg);
    }

    final data = Map<String, dynamic>.from(presignedRes['data'] as Map);
    final uploadUrl = data['uploadUrl']?.toString();
    final fileUrl = data['fileUrl']?.toString();
    final key = data['key']?.toString();
    final contentType = data['contentType']?.toString() ?? fileType;

    if (uploadUrl == null || uploadUrl.isEmpty) {
      throw Exception('Presigned URL response missing uploadUrl');
    }
    if (fileUrl == null || fileUrl.isEmpty) {
      throw Exception('Presigned URL response missing fileUrl');
    }

    final uploadUri = Uri.tryParse(uploadUrl);
    final sanitizedUploadUrl = uploadUri != null
        ? '${uploadUri.scheme}://${uploadUri.host}${uploadUri.path}'
        : '***uploadUrl***';

    debugPrint(
        '=== PRESIGNED URL === uploadUrl received: $sanitizedUploadUrl');
    debugPrint('=== PRESIGNED URL === fileUrl received: $fileUrl');
    debugPrint('=== PRESIGNED URL === contentType: $contentType');
    debugPrint('=== PRESIGNED URL === key: $key');

    debugPrint(
        '=== STORAGE UPLOAD === Video PUT upload started for $fileSize bytes');
    final bytes = await file.readAsBytes();

    final uploadSuccess = await _apiClient.uploadFileToPresignedUrl(
      uploadUrl: uploadUrl,
      bytes: bytes,
      contentType: contentType,
    );

    if (!uploadSuccess) {
      debugPrint('=== STORAGE UPLOAD === Storage PUT upload failed');
      throw Exception('Storage PUT upload failed for $fileName');
    }

    debugPrint(
        '=== STORAGE UPLOAD === Video PUT upload completed successfully');
    return fileUrl;
  }
}
