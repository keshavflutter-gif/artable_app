import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';

import 'package:artable_app/data/datasources/music_api_service.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:artable_app/features/studio/data/models/studio_filters_response.dart';
import 'package:artable_app/features/studio/data/repositories/studio_repository.dart';
import 'package:artable_app/features/studio/data/services/video_thumbnail_generator.dart';
import 'package:artable_app/core/utils/studio_video_player_utils.dart';
import 'studio_state.dart';

class StudioCubit extends Cubit<StudioState> {
  StudioCubit({
    AuthCubit? authCubit,
    StudioRepository? repository,
  })  : _authCubit = authCubit,
        _repository = repository ??
            StudioRepository(
              onTokensRefreshed: authCubit?.applyRefreshedTokens,
              onSessionRefreshFailed: authCubit?.handleSessionRefreshFailed,
            ),
        super(StudioState());

  AuthCubit? _authCubit;
  final StudioRepository _repository;

  void updateAuth(AuthCubit authCubit) {
    _authCubit = authCubit;
  }

  StudioFiltersConfig? get filtersConfig => state.filtersConfig;

  Future<void> loadFiltersConfig({bool forceRefresh = false}) async {
    if (state.isLoadingFilters) return;
    if (state.filtersConfig != null && !forceRefresh) return;

    emit(state.copyWith(isLoadingFilters: true));

    final token = _authCubit?.sessionToken;
    final refresh = _authCubit?.refreshToken;

    try {
      final res = await _repository.getStudioFiltersConfig(
        sessionToken: (token != null && token != 'design_preview') ? token : null,
        refreshToken: (refresh != null && refresh != 'design_preview') ? refresh : null,
      );

      emit(state.copyWith(
        filtersConfig: res.data,
        isLoadingFilters: false,
      ));
    } catch (e) {
      debugPrint('StudioCubit loadFiltersConfig error: $e');
      emit(state.copyWith(
        filtersConfig: const StudioFiltersConfig.empty(),
        isLoadingFilters: false,
      ));
    }
  }

  Future<void> fetchStudioSetup(String challengeId, {bool forceRefresh = false}) async {
    final cleanId = challengeId.trim();
    if (cleanId.isEmpty) return;

    if (state.studioSetup != null &&
        state.studioSetup!.challenge.id == cleanId &&
        !forceRefresh) {
      return;
    }

    emit(state.copyWith(isSetupLoading: true));

    final token = _authCubit?.sessionToken;
    final refresh = _authCubit?.refreshToken;

    try {
      final res = await _repository.getStudioSetup(
        challengeId: cleanId,
        sessionToken: (token != null && token != 'design_preview') ? token : null,
        refreshToken: (refresh != null && refresh != 'design_preview') ? refresh : null,
      );

      if (res != null && res.success) {
        emit(state.copyWith(
          studioSetup: res.data,
          isSetupLoading: false,
        ));
      } else {
        emit(state.copyWith(isSetupLoading: false));
      }
    } catch (e) {
      debugPrint('StudioCubit fetchStudioSetup error: $e');
      emit(state.copyWith(isSetupLoading: false));
    }
  }

  static const int maxDraftsLimit = 20;

  Future<Map<String, dynamic>?> mergeDrafts({
    required List<String> draftIds,
    String? customTitle,
  }) async {
    if (draftIds.length < 2) return null;

    if (state.drafts.length >= maxDraftsLimit) {
      emit(state.copyWith(
        isSavingDraft: false,
        saveDraftError: 'Draft limit reached (Max $maxDraftsLimit drafts). Please delete a draft to save a merged video.',
      ));
      return null;
    }

    final selectedDrafts = state.drafts.where((d) => draftIds.contains(d['id'])).toList();
    if (selectedDrafts.isEmpty) return null;

    int totalSecs = 0;
    for (final d in selectedDrafts) {
      final dur = d['duration']?.toString() ?? '0:30';
      final parts = dur.split(':');
      if (parts.length == 2) {
        final m = int.tryParse(parts[0]) ?? 0;
        final s = int.tryParse(parts[1]) ?? 0;
        totalSecs += (m * 60 + s);
      } else {
        totalSecs += (d['durationSeconds'] as num?)?.toInt() ?? 30;
      }
    }

    final first = selectedDrafts.first;
    final title1 = first['challengeTitle']?.toString() ?? first['title']?.toString() ?? 'Draft';
    final mergedTitle = customTitle ?? '$title1 (Merged ${selectedDrafts.length} Clips)';

    String resolvedThumb = first['thumbnailUrl']?.toString() ?? first['imageUrl']?.toString() ?? '';
    if (resolvedThumb.isEmpty || resolvedThumb.contains('storage.example')) {
      for (final d in selectedDrafts) {
        final t = d['thumbnailUrl']?.toString() ?? d['imageUrl']?.toString() ?? '';
        if (t.isNotEmpty && !t.contains('storage.example')) {
          resolvedThumb = t;
          break;
        }
      }
    }

    final mins = totalSecs ~/ 60;
    final secs = totalSecs % 60;
    final formattedDur = '$mins:${secs.toString().padLeft(2, '0')}';

    final mergedClipPaths = selectedDrafts
        .map((d) => (d['videoPath']?.toString() ?? d['videoUrl']?.toString() ?? '').trim())
        .where((p) => p.isNotEmpty)
        .toList();

    final combinedFile = await StudioVideoPlayerUtils.combineVideoFiles(mergedClipPaths);
    final finalVideoPath = (combinedFile != null && await combinedFile.exists())
        ? combinedFile.path
        : (mergedClipPaths.isNotEmpty ? mergedClipPaths.first : '');

    emit(state.copyWith(
      recordedDuration: formattedDur,
      videoTrimStartSeconds: 0.0,
      videoTrimEndSeconds: totalSecs.toDouble(),
      recordedVideoPath: finalVideoPath.isNotEmpty ? finalVideoPath : null,
      mergedClipPaths: mergedClipPaths,
    ));

    final res = await saveDraftFromPreview(
      challenge: {'id': first['challengeId'] ?? 'c1', 'title': mergedTitle},
      title: mergedTitle,
      description: 'Merged video from ${selectedDrafts.length} drafts',
      videoUrl: finalVideoPath.isNotEmpty ? finalVideoPath : null,
      thumbnailUrl: resolvedThumb.isNotEmpty ? resolvedThumb : null,
      durationSeconds: totalSecs,
    );

    if (res != null) {
      res['duration'] = formattedDur;
      res['durationSeconds'] = totalSecs;
      res['videoTrimStartSeconds'] = 0.0;
      res['videoTrimEndSeconds'] = totalSecs.toDouble();
      res['videoPath'] = finalVideoPath;
      res['videoUrl'] = finalVideoPath;
      res['mergedClipPaths'] = mergedClipPaths;
    }

    return res;
  }

  Future<Map<String, dynamic>?> saveDraftFromPreview({
    required Map<String, dynamic> challenge,
    String? title,
    String? description,
    String? videoUrl,
    String? thumbnailUrl,
    List<String>? hashtags,
    int? durationSeconds,
  }) async {
    if (state.drafts.length >= maxDraftsLimit) {
      emit(state.copyWith(
        isSavingDraft: false,
        saveDraftError: 'Draft limit reached (Max $maxDraftsLimit drafts). Please delete an existing draft to save a new video.',
      ));
      return null;
    }

    emit(state.copyWith(isSavingDraft: true, clearSaveDraftError: true));

    final token = _authCubit?.sessionToken;
    final refresh = _authCubit?.refreshToken;

    final cleanChallengeId = (challenge['id']?.toString() ?? state.videoChallengeId ?? '').trim();
    final cleanCategoryId = (challenge['categoryId']?.toString() ?? state.videoCategoryId)?.trim();
    final draftTitle = (title ?? challenge['title']?.toString() ?? 'Studio Draft').trim();
    final draftDescription = description ?? 'Draft from studio preview';
    final recVideoPath = (videoUrl ?? state.recordedVideoPath ?? '').trim();

    String resolvedThumbPath = (thumbnailUrl ?? state.selectedThumbnailPath ?? '').trim();

    if (resolvedThumbPath.isEmpty || resolvedThumbPath.contains('storage.example')) {
      if (recVideoPath.isNotEmpty) {
        try {
          final genFile = await VideoThumbnailGenerator.generateThumbnailFromVideo(recVideoPath);
          if (genFile != null && await genFile.exists()) {
            resolvedThumbPath = genFile.path;
            emit(state.copyWith(selectedThumbnailPath: resolvedThumbPath));
          }
        } catch (e) {
          debugPrint('Video frame thumbnail generation warning: $e');
        }
      }
    }

    if (resolvedThumbPath.isEmpty) {
      resolvedThumbPath = (challenge['bannerUrl']?.toString() ?? challenge['imageUrl']?.toString() ?? '').trim();
    }

    final sToken = (token != null && token != 'design_preview') ? token : null;
    final rToken = (refresh != null && refresh != 'design_preview') ? refresh : null;

    String vUrl = recVideoPath;
    if (vUrl.isNotEmpty) {
      final cleanVPath = vUrl.replaceFirst('file://', '').trim();
      final isLocalV = !cleanVPath.startsWith('http://') && !cleanVPath.startsWith('https://');
      if (isLocalV && await File(cleanVPath).exists()) {
        try {
          debugPrint('=== DRAFT SAVE PRESIGNED URL === Uploading local video file to storage: $cleanVPath');
          final uploadedVUrl = await _repository.uploadFile(
            cleanVPath,
            isVideo: true,
            sessionToken: sToken,
            refreshToken: rToken,
          );
          if (uploadedVUrl.isNotEmpty) {
            vUrl = uploadedVUrl;
            debugPrint('=== DRAFT SAVE PRESIGNED URL === Real video URL obtained: $vUrl');
          }
        } catch (e) {
          debugPrint('=== DRAFT SAVE PRESIGNED URL === Video upload warning: $e');
        }
      }
    }

    String tUrl = resolvedThumbPath;
    if (tUrl.isNotEmpty) {
      final cleanTPath = tUrl.replaceFirst('file://', '').trim();
      final isLocalT = !cleanTPath.startsWith('http://') && !cleanTPath.startsWith('https://');
      if (isLocalT && await File(cleanTPath).exists()) {
        try {
          debugPrint('=== DRAFT SAVE PRESIGNED URL === Uploading local thumbnail file to storage: $cleanTPath');
          final uploadedTUrl = await _repository.uploadFile(
            cleanTPath,
            isVideo: false,
            sessionToken: sToken,
            refreshToken: rToken,
          );
          if (uploadedTUrl.isNotEmpty) {
            tUrl = uploadedTUrl;
            debugPrint('=== DRAFT SAVE PRESIGNED URL === Real thumbnail URL obtained: $tUrl');
          }
        } catch (e) {
          debugPrint('=== DRAFT SAVE PRESIGNED URL === Thumbnail upload warning: $e');
        }
      }
    }


    if (tUrl.isEmpty || tUrl.contains('storage.example')) {
      tUrl = 'https://loremflickr.com/700/440/talent,stage?lock=501';
    }

    int durSecs = durationSeconds ?? 42;
    if (durationSeconds == null) {
      final durParts = state.recordedDuration.split(':');
      if (durParts.length == 2) {
        final m = int.tryParse(durParts[0]) ?? 0;
        final s = int.tryParse(durParts[1]) ?? 0;
        durSecs = m * 60 + s;
      }
    }

    final body = {
      if (cleanChallengeId.isNotEmpty) 'challengeId': cleanChallengeId,
      if (cleanCategoryId != null && cleanCategoryId.isNotEmpty) 'categoryId': cleanCategoryId,
      'title': draftTitle,
      'description': draftDescription,
      'videoUrl': vUrl,
      'thumbnailUrl': tUrl,
      'hashtags': (hashtags != null && hashtags.isNotEmpty) ? hashtags : ['dance', 'talent', 'artable'],
      'durationSeconds': durSecs > 0 ? durSecs : 42,
    };

    try {
      final res = await _repository.saveDraft(
        body: body,
        sessionToken: sToken,
        refreshToken: rToken,
      );

      if (res.success && res.data != null) {
        final uiDraftMap = res.data!.toUiMap();
        if ((uiDraftMap['thumbnailUrl'] == null || uiDraftMap['thumbnailUrl'].toString().contains('storage.example')) && tUrl.isNotEmpty) {
          uiDraftMap['thumbnailUrl'] = tUrl;
        }
        addDraft(uiDraftMap);
        emit(state.copyWith(isSavingDraft: false));
        return uiDraftMap;
      } else {
        emit(state.copyWith(
          isSavingDraft: false,
          saveDraftError: res.message.isNotEmpty ? res.message : 'Failed to save draft',
        ));
        return null;
      }
    } catch (e) {
      debugPrint('StudioCubit saveDraftFromPreview error: $e');
      final localDraft = {
        'id': 'd${DateTime.now().millisecondsSinceEpoch}',
        'challengeId': cleanChallengeId,
        'challengeTitle': draftTitle,
        'duration': state.recordedDuration,
        'recordedAt': DateTime.now().toIso8601String(),
        'thumbnailUrl': tUrl,
        'videoPath': state.recordedVideoPath,
        ...state.recordingEffectsPayload,
      };
      addDraft(localDraft);
      emit(state.copyWith(isSavingDraft: false));
      return localDraft;
    }
  }

  Future<Map<String, dynamic>?> updateDraftDetails({
    required String videoId,
    Map<String, dynamic>? challenge,
    String? challengeId,
    String? categoryId,
    String? title,
    String? description,
    String? thumbnailUrl,
    List<String>? hashtags,
    int? durationSeconds,
  }) async {
    final cleanVideoId = videoId.trim();
    if (cleanVideoId.isEmpty) return null;

    emit(state.copyWith(isSavingDraft: true, clearSaveDraftError: true));

    final token = _authCubit?.sessionToken;
    final refresh = _authCubit?.refreshToken;

    final cleanChallengeId = (challengeId ?? challenge?['id']?.toString() ?? state.videoChallengeId ?? '').trim();
    final cleanCategoryId = (categoryId ?? challenge?['categoryId']?.toString() ?? state.videoCategoryId)?.trim();
    final draftTitle = (title ?? challenge?['title']?.toString() ?? 'My Dance Entry').trim();
    final draftDescription = description ?? 'This is my challenge performance.';
    final recVideoPath = (state.recordedVideoPath ?? '').trim();

    String resolvedThumbPath = (thumbnailUrl ?? state.selectedThumbnailPath ?? '').trim();

    if (resolvedThumbPath.isEmpty || resolvedThumbPath.contains('storage.example')) {
      if (recVideoPath.isNotEmpty) {
        try {
          final genFile = await VideoThumbnailGenerator.generateThumbnailFromVideo(recVideoPath);
          if (genFile != null && await genFile.exists()) {
            resolvedThumbPath = genFile.path;
            emit(state.copyWith(selectedThumbnailPath: resolvedThumbPath));
          }
        } catch (e) {
          debugPrint('Video frame thumbnail generation warning: $e');
        }
      }
    }

    if (resolvedThumbPath.isEmpty && challenge != null) {
      resolvedThumbPath = (challenge['bannerUrl']?.toString() ?? challenge['imageUrl']?.toString() ?? '').trim();
    }

    final sToken = (token != null && token != 'design_preview') ? token : null;
    final rToken = (refresh != null && refresh != 'design_preview') ? refresh : null;

    String tUrl = resolvedThumbPath;
    if (tUrl.isNotEmpty) {
      final cleanTPath = tUrl.replaceFirst('file://', '').trim();
      final isLocalT = !cleanTPath.startsWith('http://') && !cleanTPath.startsWith('https://');
      if (isLocalT && await File(cleanTPath).exists()) {
        try {
          debugPrint('=== DRAFT UPDATE PRESIGNED URL === Uploading thumbnail file to storage: $cleanTPath');
          final uploadedTUrl = await _repository.uploadFile(
            cleanTPath,
            isVideo: false,
            sessionToken: sToken,
            refreshToken: rToken,
          );
          if (uploadedTUrl.isNotEmpty) {
            tUrl = uploadedTUrl;
          }
        } catch (e) {
          debugPrint('=== DRAFT UPDATE PRESIGNED URL === Thumbnail upload warning: $e');
        }
      }
    }

    if (tUrl.isEmpty || tUrl.contains('storage.example')) {
      tUrl = 'https://loremflickr.com/700/440/talent,stage?lock=501';
    }

    int durSecs = durationSeconds ?? 42;
    if (durationSeconds == null) {
      final durParts = state.recordedDuration.split(':');
      if (durParts.length == 2) {
        final m = int.tryParse(durParts[0]) ?? 0;
        final s = int.tryParse(durParts[1]) ?? 0;
        durSecs = m * 60 + s;
      }
    }

    final body = <String, dynamic>{
      'challengeId': cleanChallengeId,
      'categoryId': (cleanCategoryId != null && cleanCategoryId.isNotEmpty) ? cleanCategoryId : null,
      'title': draftTitle,
      'description': draftDescription,
      'thumbnailUrl': tUrl,
      'hashtags': (hashtags != null && hashtags.isNotEmpty) ? hashtags : ['dance', 'talent', 'artable'],
      'durationSeconds': durSecs > 0 ? durSecs : 42,
    };

    try {
      final res = await _repository.updateDraft(
        videoId: cleanVideoId,
        body: body,
        sessionToken: (token != null && token != 'design_preview') ? token : null,
        refreshToken: (refresh != null && refresh != 'design_preview') ? refresh : null,
      );

      if (res.success && res.data != null) {
        final uiDraftMap = res.data!.toUiMap();
        if ((uiDraftMap['thumbnailUrl'] == null || uiDraftMap['thumbnailUrl'].toString().contains('storage.example')) && tUrl.isNotEmpty) {
          uiDraftMap['thumbnailUrl'] = tUrl;
        }

        final updatedDrafts = state.drafts.map((d) {
          if (d['id'] == cleanVideoId) {
            return {...d, ...uiDraftMap};
          }
          return d;
        }).toList();

        emit(state.copyWith(
          drafts: updatedDrafts,
          isSavingDraft: false,
        ));
        return uiDraftMap;
      } else {
        emit(state.copyWith(
          isSavingDraft: false,
          saveDraftError: res.message.isNotEmpty ? res.message : 'Failed to update draft',
        ));
        return null;
      }
    } catch (e) {
      debugPrint('StudioCubit updateDraftDetails error: $e');
      emit(state.copyWith(
        isSavingDraft: false,
        saveDraftError: e.toString(),
      ));
      return null;
    }
  }

  Future<void> fetchDraftsList({String? challengeId, bool forceRefresh = false}) async {
    if (state.isLoadingDrafts) return;

    emit(state.copyWith(isLoadingDrafts: true));

    final token = _authCubit?.sessionToken;
    final refresh = _authCubit?.refreshToken;

    try {
      final res = await _repository.getDraftsList(
        challengeId: challengeId,
        sessionToken: (token != null && token != 'design_preview') ? token : null,
        refreshToken: (refresh != null && refresh != 'design_preview') ? refresh : null,
      );

      if (res.success) {
        final uiDrafts = res.data.map((d) => d.toUiMap()).toList();
        emit(state.copyWith(
          drafts: uiDrafts,
          isLoadingDrafts: false,
        ));
      } else {
        emit(state.copyWith(isLoadingDrafts: false));
      }
    } catch (e) {
      debugPrint('StudioCubit fetchDraftsList error: $e');
      emit(state.copyWith(isLoadingDrafts: false));
    }
  }

  String get recordedDuration => state.recordedDuration;
  String? get recordedVideoPath => state.recordedVideoPath;
  String? get selectedThumbnailPath => state.selectedThumbnailPath;
  String? get videoTitle => state.videoTitle;
  String? get videoDescription => state.videoDescription;
  String? get videoCategoryId => state.videoCategoryId;
  String? get videoHashtags => state.videoHashtags;
  String? get videoChallengeId => state.videoChallengeId;
  VideoPlayerController? get activeVideoController => state.activeVideoController;

  String? get activeDraftId => state.activeDraftId;

  void setActiveDraftId(String? draftId) {
    if (draftId == null) {
      emit(state.copyWith(clearActiveDraftId: true));
    } else {
      emit(state.copyWith(activeDraftId: draftId));
    }
  }

  void setSelectedThumbnailPath(String? path) {
    if (path == null) {
      emit(state.copyWith(clearSelectedThumbnailPath: true));
    } else {
      emit(state.copyWith(selectedThumbnailPath: path));
    }
  }

  void setVideoSubmissionDetails({
    required String title,
    String? description,
    String? categoryId,
    String? hashtags,
    String? challengeId,
    String? draftId,
  }) {
    emit(state.copyWith(
      videoTitle: title,
      videoDescription: description,
      videoCategoryId: categoryId,
      videoHashtags: hashtags,
      videoChallengeId: challengeId,
      activeDraftId: draftId,
    ));
  }
  String? get selectedMusic => state.selectedMusic;
  FreeToUseTrack? get selectedTrack => state.selectedTrack;
  double get musicStartSeconds => state.musicStartSeconds;
  double get musicCropDuration => state.musicCropDuration;
  double get musicEndSeconds => state.musicEndSeconds;
  String get videoCropAspectRatio => state.videoCropAspectRatio;
  StudioCameraMode get cameraMode => state.cameraMode;
  bool get isFrontCamera => state.isFrontCamera;
  String get selectedFilter => state.selectedFilter;
  String get selectedSpeed => state.selectedSpeed;
  bool get beautyOn => state.beautyOn;
  double get beautyIntensity => state.beautyIntensity;
  String get recordingFilter => state.recordingFilter;
  bool get recordingBeautyOn => state.recordingBeautyOn;
  double get recordingBeautyIntensity => state.recordingBeautyIntensity;
  bool get isMuted => state.isMuted;
  List<Map<String, dynamic>> get drafts => state.drafts;
  Map<String, dynamic> get recordingEffectsPayload => state.recordingEffectsPayload;

  void toggleMute() {
    emit(state.copyWith(isMuted: !state.isMuted));
  }

  void setMuted(bool value) {
    emit(state.copyWith(isMuted: value));
  }

  double get speedMultiplier {
    final clean = state.selectedSpeed.replaceAll('x', '').trim();
    return double.tryParse(clean) ?? 1.0;
  }

  void snapshotRecordingEffects() {
    emit(state.copyWith(
      recordingFilter: state.selectedFilter,
      recordingBeautyOn: state.beautyOn,
      recordingBeautyIntensity: state.beautyIntensity,
    ));
  }

  void restoreRecordingEffects({
    String? filterId,
    bool? beautyOn,
    double? beautyIntensity,
    String? cropAspectRatio,
    double? trimStart,
    double? trimEnd,
    bool? isMuted,
    String? speed,
  }) {
    emit(state.copyWith(
      recordingFilter: filterId ?? state.selectedFilter,
      recordingBeautyOn: beautyOn ?? state.beautyOn,
      recordingBeautyIntensity: beautyIntensity ?? state.beautyIntensity,
      videoCropAspectRatio: cropAspectRatio ?? state.videoCropAspectRatio,
      videoTrimStartSeconds: trimStart ?? state.videoTrimStartSeconds,
      videoTrimEndSeconds: trimEnd ?? state.videoTrimEndSeconds,
      isMuted: isMuted ?? state.isMuted,
      selectedSpeed: speed ?? state.selectedSpeed,
    ));
  }

  void setRecordedDuration(String duration) {
    emit(state.copyWith(recordedDuration: duration));
  }

  void setRecordedVideoPath(String? path, {List<String>? mergedClipPaths, bool clearMergedClips = true}) {
    if (path == null) {
      emit(state.copyWith(
        clearRecordedVideoPath: true,
        clearMergedClipPaths: true,
        recordingFilter: state.selectedFilter,
        recordingBeautyOn: state.beautyOn,
        recordingBeautyIntensity: state.beautyIntensity,
      ));
    } else {
      emit(state.copyWith(
        recordedVideoPath: path,
        mergedClipPaths: mergedClipPaths,
        clearMergedClipPaths: clearMergedClips && (mergedClipPaths == null || mergedClipPaths.isEmpty),
      ));
    }
  }

  Future<VideoPlayerController?> prepareVideoPreview(String path) async {
    if (state.recordedVideoPath != path && state.activeVideoController != null) {
      await state.activeVideoController?.dispose();
      emit(state.copyWith(clearActiveVideoController: true));
    }

    if (state.activeVideoController != null &&
        state.activeVideoController!.value.isInitialized) {
      return state.activeVideoController;
    }

    String cleanPath = path;
    if (cleanPath.startsWith('file://')) {
      cleanPath = cleanPath.replaceFirst('file://', '');
    }

    try {
      final controller = cleanPath.startsWith('http://') ||
              cleanPath.startsWith('https://')
          ? VideoPlayerController.networkUrl(Uri.parse(cleanPath))
          : VideoPlayerController.file(File(cleanPath));

      await controller.initialize();
      await controller.setLooping(true);
      emit(state.copyWith(activeVideoController: controller));
      return controller;
    } catch (e) {
      debugPrint('StudioCubit prepareVideoPreview error for $path: $e');
      return null;
    }
  }

  void clearActiveVideoController({bool dispose = true}) {
    if (dispose) {
      state.activeVideoController?.dispose();
    }
    emit(state.copyWith(clearActiveVideoController: true));
  }

  void setSelectedMusic(String? music) {
    if (music == null) {
      emit(state.copyWith(clearSelectedMusic: true));
    } else {
      emit(state.copyWith(selectedMusic: music));
    }
  }

  void setSelectedTrack(
    FreeToUseTrack? track, {
    double start = 0.0,
    double duration = 30.0,
  }) {
    if (track != null) {
      final validStart = start.clamp(0.0, track.duration);
      final validDuration = duration.clamp(5.0, track.duration - validStart);
      emit(state.copyWith(
        selectedTrack: track,
        selectedMusic: '${track.title} — ${track.artist}',
        musicStartSeconds: validStart,
        musicCropDuration: validDuration,
      ));
    } else {
      emit(state.copyWith(
        clearSelectedMusic: true,
        musicStartSeconds: 0.0,
        musicCropDuration: 30.0,
      ));
    }
  }

  void updateMusicCrop(double start, double duration) {
    emit(state.copyWith(
      musicStartSeconds: start,
      musicCropDuration: duration,
    ));
  }

  void setVideoCropAspectRatio(String aspectRatio) {
    emit(state.copyWith(videoCropAspectRatio: aspectRatio));
  }

  void setVideoTrimRange({
    required double start,
    required double end,
    required String formattedDuration,
  }) {
    emit(state.copyWith(
      videoTrimStartSeconds: start,
      videoTrimEndSeconds: end,
      recordedDuration: formattedDuration,
    ));
  }

  void toggleCameraMode() {
    final nextMode = state.cameraMode == StudioCameraMode.back
        ? StudioCameraMode.front
        : StudioCameraMode.back;
    emit(state.copyWith(cameraMode: nextMode));
  }

  void setCameraMode(StudioCameraMode mode) {
    emit(state.copyWith(cameraMode: mode));
  }

  void setFilter(String filter) {
    emit(state.copyWith(selectedFilter: filter));
  }

  void setSpeed(String speed) {
    emit(state.copyWith(selectedSpeed: speed));
  }

  void setBeautyOn(bool value) {
    emit(state.copyWith(beautyOn: value));
  }

  void setBeautyIntensity(double value) {
    emit(state.copyWith(beautyIntensity: value));
  }

  void addDraft(Map<String, dynamic> draft) {
    if (state.drafts.length >= maxDraftsLimit) return;
    final updated = List<Map<String, dynamic>>.from(state.drafts);
    updated.insert(0, draft);
    emit(state.copyWith(drafts: updated));
  }

  Future<bool> deleteDraft(String id) async {
    final cleanId = id.trim();
    if (cleanId.isEmpty) return false;

    final previousDrafts = List<Map<String, dynamic>>.from(state.drafts);
    final updated = List<Map<String, dynamic>>.from(state.drafts)
      ..removeWhere((d) => d['id'] == cleanId);
    emit(state.copyWith(drafts: updated));

    final token = _authCubit?.sessionToken;
    final refresh = _authCubit?.refreshToken;

    try {
      final res = await _repository.deleteDraft(
        videoId: cleanId,
        sessionToken: (token != null && token != 'design_preview') ? token : null,
        refreshToken: (refresh != null && refresh != 'design_preview') ? refresh : null,
      );

      final isSuccess = res['success'] == true;
      if (!isSuccess && !cleanId.startsWith('d')) {
        emit(state.copyWith(drafts: previousDrafts));
      }
      return isSuccess || cleanId.startsWith('d');
    } catch (e) {
      debugPrint('StudioCubit deleteDraft error for $cleanId: $e');
      if (!cleanId.startsWith('d')) {
        emit(state.copyWith(drafts: previousDrafts));
      }
      return cleanId.startsWith('d');
    }
  }

  void resetSession() {
    state.activeVideoController?.dispose();
    emit(StudioState(
      recordedDuration: '0:00',
      recordedVideoPath: null,
      activeVideoController: null,
      selectedMusic: null,
      selectedTrack: null,
      musicStartSeconds: 0.0,
      musicCropDuration: 30.0,
      cameraMode: StudioCameraMode.back,
      selectedFilter: 'natural',
      selectedSpeed: '1x',
      beautyOn: false,
      beautyIntensity: 50,
      recordingFilter: 'natural',
      recordingBeautyOn: false,
      recordingBeautyIntensity: 50,
      isMuted: false,
      drafts: state.drafts,
    ));
  }

  @override
  Future<void> close() {
    state.activeVideoController?.dispose();
    return super.close();
  }
}
