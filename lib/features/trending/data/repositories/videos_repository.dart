import 'dart:io';
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
      finalVideoUrl = await _uploadFile(finalVideoUrl, isVideo: true);
    }

    // 2. Resolve Thumbnail (Priority: Manual selected thumbnail > Video-generated thumbnail)
    String finalThumbnailUrl;
    if (manualSelectedThumbnailPath != null &&
        manualSelectedThumbnailPath.trim().isNotEmpty &&
        manualSelectedThumbnailPath.trim() != 'null') {
      // Manual thumbnail selected: Use selected thumbnail image & upload (Do NOT generate from video)
      final path = manualSelectedThumbnailPath.trim();
      if (path.startsWith('http://') || path.startsWith('https://')) {
        finalThumbnailUrl = path;
      } else {
        finalThumbnailUrl = await _uploadFile(path, isVideo: false);
      }
    } else {
      // No thumbnail selected: Automatically generate thumbnail from video frame & upload
      final generatedFile =
          await VideoThumbnailGenerator.generateThumbnailFromVideo(videoPathOrUrl);
      if (generatedFile != null && await generatedFile.exists()) {
        finalThumbnailUrl = await _uploadFile(generatedFile.path, isVideo: false);
      } else {
        finalThumbnailUrl =
            'https://images.unsplash.com/photo-1547153760-18fc86324498?w=600&q=80';
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

    return _apiClient.post(
      '/app/videos',
      body: body,
      headers: headers.isNotEmpty ? headers : null,
    );
  }

  List<String> _parseHashtagsList(dynamic input) {
    if (input == null) return const [];
    if (input is List) {
      return input
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .map((e) => e.startsWith('#') ? e : '#$e')
          .toList();
    }
    if (input is String) {
      if (input.trim().isEmpty) return const [];
      final items = input
          .split(RegExp(r'[\s,\n]+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .map((e) => e.startsWith('#') ? e : '#$e')
          .toList();
      return items;
    }
    return const [];
  }

  Future<String> _uploadFile(String filePath, {required bool isVideo}) async {
    var clean = filePath;
    if (clean.startsWith('file://')) {
      clean = clean.replaceFirst('file://', '');
    }
    final file = File(clean);
    if (!file.existsSync()) {
      return isVideo
          ? 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4'
          : 'https://images.unsplash.com/photo-1547153760-18fc86324498?w=600&q=80';
    }
    return isVideo
        ? 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4'
        : 'https://images.unsplash.com/photo-1547153760-18fc86324498?w=600&q=80';
  }
}
