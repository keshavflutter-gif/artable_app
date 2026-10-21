import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:artable_app/core/network/api_auth_headers.dart';
import 'package:artable_app/core/network/api_client.dart';
import 'package:artable_app/core/network/api_session_callbacks_factory.dart';
import 'package:artable_app/core/storage/auth_storage_service.dart';
import 'package:artable_app/features/studio/data/services/video_thumbnail_generator.dart';
import 'package:artable_app/data/datasources/mock_data.dart';
import 'package:artable_app/core/utils/validators.dart';
import 'package:artable_app/core/utils/reel_helpers.dart';
import 'package:artable_app/core/widgets/app_image.dart';
import 'package:artable_app/core/utils/media_url_utils.dart';
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
    final cleanTab = tab?.trim();

    final queryParams = <String, String>{
      if (cleanTab != null && cleanTab.isNotEmpty) 'tab': cleanTab,
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

    Map<String, dynamic> data = {};
    try {
      data = await _apiClient.get(
        path,
        headers: headers.isNotEmpty ? headers : null,
      );
    } catch (e) {
      debugPrint('[VideosRepository] getTrendingVideos API error for $path: $e');
    }

    var res = TrendingVideosResponse.fromJson(data);

    if (res.data == null || (res.data!.hero == null && res.data!.gridVideos.isEmpty)) {
      final altQueryParams = <String, String>{
        if (cleanTab != null && cleanTab.isNotEmpty) 'tab': cleanTab.toLowerCase(),
        if (category != null && category.trim().isNotEmpty) 'category': category.trim(),
        if (categoryId != null && categoryId.trim().isNotEmpty) 'categoryId': categoryId.trim(),
        'page': page.toString(),
        'limit': limit.toString(),
      };
      final altQueryString = Uri(queryParameters: altQueryParams).query;
      final altPath = '/app/videos/trending?$altQueryString';
      try {
        final altData = await _apiClient.get(
          altPath,
          headers: headers.isNotEmpty ? headers : null,
        );
        final altRes = TrendingVideosResponse.fromJson(altData);
        if (altRes.data != null && (altRes.data!.hero != null || altRes.data!.gridVideos.isNotEmpty)) {
          res = altRes;
        }
      } catch (_) {}
    }

    if (res.data == null || (res.data!.hero == null && res.data!.gridVideos.isEmpty)) {
      final fallbackItems = _getMockTrendingVideos(category: category ?? cleanTab);
      if (fallbackItems.isNotEmpty) {
        final heroItem = fallbackItems.first;
        final videoList = fallbackItems.length > 1 ? fallbackItems.sublist(1) : fallbackItems;
        res = TrendingVideosResponse(
          success: true,
          message: 'Loaded trending videos',
          data: TrendingVideosData(
            hero: heroItem,
            videos: videoList,
            moreTrendingTalent: videoList,
            tabs: const ['Trending', 'Popular', 'Newest', 'Dance', 'Singing', 'Comedy', 'Fitness'],
          ),
        );
      }
    }

    return res;
  }

  List<TrendingVideoItem> _getMockTrendingVideos({String? category}) {
    final list = <TrendingVideoItem>[];
    final cleanCategory = category?.trim().toLowerCase();

    for (final raw in MockData.REELS) {
      final item = TrendingVideoItem.fromJson(Map<String, dynamic>.from(raw));
      if (cleanCategory != null &&
          cleanCategory.isNotEmpty &&
          cleanCategory != 'trending' &&
          cleanCategory != 'popular' &&
          cleanCategory != 'newest') {
        final itemCat = item.displayCategoryName.toLowerCase();
        if (itemCat.contains(cleanCategory) || cleanCategory.contains(itemCat)) {
          list.add(item);
        }
      } else {
        list.add(item);
      }
    }

    if (list.isEmpty) {
      for (final raw in MockData.REELS) {
        list.add(TrendingVideoItem.fromJson(Map<String, dynamic>.from(raw)));
      }
    }
    return list;
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
    double? videoTrimStartSeconds,
    double? videoTrimEndSeconds,
    List<String>? mergedClipPaths,
    String? creator,
    String? handle,
    String? username,
    String? avatarUrl,
    String? userId,
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

    // 1b. Ensure merged clip URLs are uploaded if present
    final List<String> finalMergedClipUrls = [];
    if (mergedClipPaths != null && mergedClipPaths.isNotEmpty) {
      for (final clip in mergedClipPaths) {
        var cleanClip = clip.trim();
        if (cleanClip.startsWith('file://')) cleanClip = cleanClip.replaceFirst('file://', '');
        if (cleanClip.isEmpty) continue;
        if (cleanClip.startsWith('http://') || cleanClip.startsWith('https://')) {
          finalMergedClipUrls.add(cleanClip);
        } else if (cleanClip.startsWith('/') && !File(cleanClip).existsSync()) {
          final fullUrl = 'http://server.keshavinfotechdemo2.com:3055$cleanClip';
          finalMergedClipUrls.add(fullUrl);
        } else if (cleanClip.contains('uploads/') && !File(cleanClip).existsSync()) {
          final fullUrl = 'http://server.keshavinfotechdemo2.com:3055/${cleanClip.replaceFirst(RegExp(r'^/+'), '')}';
          finalMergedClipUrls.add(fullUrl);
        } else {
          try {
            final uploadedClip = await _uploadFile(
              cleanClip,
              isVideo: true,
              sessionToken: sessionToken,
              refreshToken: refreshToken,
            );
            if (uploadedClip.isNotEmpty) {
              finalMergedClipUrls.add(uploadedClip);
            } else {
              finalMergedClipUrls.add(cleanClip);
            }
          } catch (e) {
            debugPrint('Error uploading clip in createVideo: $e');
            finalMergedClipUrls.add(cleanClip);
          }
        }
      }
    }

    // 2. Resolve Thumbnail (Priority: Non-dummy manual thumbnail > Video-generated frame)
    String finalThumbnailUrl = '';
    Uint8List? localThumbBytes;
    final isManualValid = manualSelectedThumbnailPath != null &&
        manualSelectedThumbnailPath.trim().isNotEmpty &&
        manualSelectedThumbnailPath.trim() != 'null' &&
        !MediaUrlUtils.isDummyThumbnail(manualSelectedThumbnailPath);

    if (isManualValid) {
      final path = manualSelectedThumbnailPath.trim();
      if (path.startsWith('http://') || path.startsWith('https://')) {
        finalThumbnailUrl = path;
      } else {
        try {
          final file = File(path);
          if (await file.exists()) {
            localThumbBytes = await file.readAsBytes();
          }
          finalThumbnailUrl = await _uploadFile(
            path,
            isVideo: false,
            sessionToken: sessionToken,
            refreshToken: refreshToken,
          );
        } catch (e) {
          debugPrint('Thumbnail upload error fallback to video frame: $e');
        }
      }
    }

    // If manual thumbnail is missing, dummy, or failed to upload, generate frame directly from video
    if (finalThumbnailUrl.isEmpty) {
      try {
        var generatedFile =
            await VideoThumbnailGenerator.generateThumbnailFromVideo(videoPathOrUrl);

        if ((generatedFile == null || !await generatedFile.exists()) &&
            mergedClipPaths != null &&
            mergedClipPaths.isNotEmpty) {
          for (final clip in mergedClipPaths) {
            generatedFile =
                await VideoThumbnailGenerator.generateThumbnailFromVideo(clip);
            if (generatedFile != null && await generatedFile.exists()) break;
          }
        }

        if (generatedFile != null && await generatedFile.exists()) {
          localThumbBytes = await generatedFile.readAsBytes();
          finalThumbnailUrl = await _uploadFile(
            generatedFile.path,
            isVideo: false,
            sessionToken: sessionToken,
            refreshToken: refreshToken,
          );
        }
      } catch (e) {
        debugPrint('Generated thumbnail upload error: $e');
      }
    }

    if (localThumbBytes != null && localThumbBytes.isNotEmpty) {
      if (finalThumbnailUrl.isNotEmpty) {
        AppImage.cacheThumbnail(finalThumbnailUrl, localThumbBytes);
      }
      if (finalVideoUrl.isNotEmpty) {
        AppImage.cacheThumbnail(finalVideoUrl, localThumbBytes);
      }
      AppImage.cacheThumbnail(videoPathOrUrl, localThumbBytes);
    }

    // 3. Call Create Video API (POST /app/videos) with ready videoUrl & thumbnailUrl
    final effectiveToken = (sessionToken != null && sessionToken.trim().isNotEmpty)
        ? sessionToken.trim()
        : await _storageService.getSessionToken();
    final effectiveRefresh = (refreshToken != null && refreshToken.trim().isNotEmpty)
        ? refreshToken.trim()
        : await _storageService.getRefreshToken();

    final headers = ApiAuthHeaders.authenticated(
      sessionToken: effectiveToken,
      refreshToken: effectiveRefresh,
    );

    final realCategoryId = Validators.isRealDatabaseId(categoryId) ? categoryId!.trim() : null;
    final realChallengeId = Validators.isRealDatabaseId(challengeId) ? challengeId!.trim() : null;

    final hashtagsList = _parseHashtagsList(hashtags);

    final effectiveDescription = ReelHelpers.embedClipsInDescription(
      description,
      finalMergedClipUrls,
    );

    final body = <String, dynamic>{
      'title': title,
      'videoUrl': finalVideoUrl,
      'thumbnailUrl': finalThumbnailUrl,
      if (finalMergedClipUrls.isNotEmpty)
        'mergedClipPaths': finalMergedClipUrls,
      if (effectiveDescription.isNotEmpty)
        'description': effectiveDescription,
      if (realCategoryId != null)
        'categoryId': realCategoryId,
      if (realChallengeId != null)
        'challengeId': realChallengeId,
      if (hashtagsList.isNotEmpty)
        'hashtags': hashtagsList,
      if (videoTrimStartSeconds != null)
        'videoTrimStartSeconds': videoTrimStartSeconds,
      if (videoTrimEndSeconds != null)
        'videoTrimEndSeconds': videoTrimEndSeconds,
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

    final profileDetails = await _storageService.getProfileDetails();
    final storedDisplayName = await _storageService.getUserDisplayName();
    final storedUserId = await _storageService.getUserId();

    final userObj = createdData?['user'] is Map
        ? Map<String, dynamic>.from(createdData!['user'] as Map)
        : null;

    final resolvedUserId = userId?.trim().isNotEmpty == true
        ? userId!.trim()
        : (createdData?['userId']?.toString().trim().isNotEmpty == true
            ? createdData!['userId'].toString().trim()
            : (userObj?['id']?.toString().trim().isNotEmpty == true
                ? userObj!['id'].toString().trim()
                : (storedUserId ?? '')));

    final resolvedUsername = (username?.trim().isNotEmpty == true
            ? username!.trim()
            : null) ??
        (createdData?['username']?.toString().trim().isNotEmpty == true
            ? createdData!['username'].toString().trim()
            : null) ??
        (userObj?['username']?.toString().trim().isNotEmpty == true
            ? userObj!['username'].toString().trim()
            : null) ??
        (profileDetails?.username?.trim().isNotEmpty == true
            ? profileDetails!.username!.trim()
            : null) ??
        '';

    final resolvedCreator = (creator != null && creator.trim().isNotEmpty && creator.trim().toLowerCase() != 'you'
            ? creator.trim()
            : null) ??
        (createdData?['creator']?.toString().trim().isNotEmpty == true &&
                createdData!['creator'].toString().trim().toLowerCase() != 'you'
            ? createdData['creator'].toString().trim()
            : null) ??
        ((userObj?['fullName'] ?? userObj?['name'] ?? userObj?['displayName'])?.toString().trim().isNotEmpty == true
            ? (userObj?['fullName'] ?? userObj?['name'] ?? userObj?['displayName']).toString().trim()
            : null) ??
        (profileDetails != null && profileDetails.fullName.isNotEmpty
            ? profileDetails.fullName
            : (storedDisplayName?.isNotEmpty == true
                ? storedDisplayName
                : (resolvedUsername.isNotEmpty ? resolvedUsername : 'You')));

    final resolvedHandle = (handle != null && handle.trim().isNotEmpty && handle.trim() != '@user'
            ? (handle.startsWith('@') ? handle : '@$handle')
            : null) ??
        (resolvedUsername.isNotEmpty
            ? (resolvedUsername.startsWith('@') ? resolvedUsername : '@$resolvedUsername')
            : (createdData?['handle']?.toString().trim().isNotEmpty == true && createdData!['handle'] != '@user'
                ? createdData['handle'].toString().trim()
                : (resolvedCreator != null && resolvedCreator != 'You'
                    ? '@${resolvedCreator.toLowerCase().replaceAll(' ', '_')}'
                    : '@user')));

    final resolvedAvatar = (avatarUrl != null && avatarUrl.trim().isNotEmpty && !avatarUrl.contains('pravatar.cc')
            ? avatarUrl.trim()
            : null) ??
        ((createdData?['avatarUrl'] ?? createdData?['avatar'] ?? userObj?['avatarUrl'] ?? userObj?['avatar'] ?? userObj?['profilePhotoUrl'])?.toString().trim().isNotEmpty == true
            ? (createdData?['avatarUrl'] ?? createdData?['avatar'] ?? userObj?['avatarUrl'] ?? userObj?['avatar'] ?? userObj?['profilePhotoUrl']).toString().trim()
            : '');

    final newReelItem = <String, dynamic>{
      'id': createdId != 'N/A' && createdId.isNotEmpty
          ? createdId
          : 'r_${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'creator': resolvedCreator ?? 'User',
      'handle': resolvedHandle,
      'username': resolvedUsername,
      'userId': resolvedUserId,
      'user_id': resolvedUserId,
      'isMyVideo': true,
      'user': {
        'id': resolvedUserId,
        'username': resolvedUsername,
        'handle': resolvedHandle,
        'name': resolvedCreator,
        'fullName': resolvedCreator,
        'avatar': resolvedAvatar,
        'profilePhotoUrl': resolvedAvatar,
      },
      'category': 'Dance',
      'verified': true,
      'imageUrl': finalThumbnailUrl,
      'thumbnailUrl': finalThumbnailUrl,
      'videoUrl': finalVideoUrl,
      if (finalMergedClipUrls.isNotEmpty)
        'mergedClipPaths': finalMergedClipUrls,
      'avatarUrl': resolvedAvatar,
      'views': '1',
      'challengeId': challengeId ?? 'c1',
      'musicName': 'Original Sound',
      'caption': title,
      'likes': '0',
      'comments': '0',
      'shares': '0',
      'talentScore': 8.0,
      if (videoTrimStartSeconds != null)
        'videoTrimStartSeconds': videoTrimStartSeconds,
      if (videoTrimEndSeconds != null)
        'videoTrimEndSeconds': videoTrimEndSeconds,
    };
    if (finalMergedClipUrls.isNotEmpty) {
      if (createdId != 'N/A' && createdId.isNotEmpty) {
        ReelHelpers.cacheMergedClips(createdId, finalMergedClipUrls);
      }
      ReelHelpers.cacheMergedClips(finalVideoUrl, finalMergedClipUrls);
      newReelItem['mergedClipPaths'] = finalMergedClipUrls;
    }
    MockData.REELS.insert(0, Map<String, Object>.from(newReelItem));

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

    final effectiveToken = (sessionToken != null && sessionToken.trim().isNotEmpty)
        ? sessionToken.trim()
        : await _storageService.getSessionToken();
    final effectiveRefresh = (refreshToken != null && refreshToken.trim().isNotEmpty)
        ? refreshToken.trim()
        : await _storageService.getRefreshToken();

    final headers = ApiAuthHeaders.authenticated(
      sessionToken: effectiveToken,
      refreshToken: effectiveRefresh,
    );

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
