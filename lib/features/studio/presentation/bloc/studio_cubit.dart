import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';

import 'package:artable_app/data/datasources/mock_data.dart';
import 'package:artable_app/data/datasources/music_api_service.dart';
import 'studio_state.dart';

class StudioCubit extends Cubit<StudioState> {
  StudioCubit() : super(StudioState());

  String get recordedDuration => state.recordedDuration;
  String? get recordedVideoPath => state.recordedVideoPath;
  String? get selectedThumbnailPath => state.selectedThumbnailPath;
  String? get videoTitle => state.videoTitle;
  String? get videoDescription => state.videoDescription;
  String? get videoCategoryId => state.videoCategoryId;
  String? get videoHashtags => state.videoHashtags;
  String? get videoChallengeId => state.videoChallengeId;
  VideoPlayerController? get activeVideoController => state.activeVideoController;

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
  }) {
    emit(state.copyWith(
      videoTitle: title,
      videoDescription: description,
      videoCategoryId: categoryId,
      videoHashtags: hashtags,
      videoChallengeId: challengeId,
    ));
  }
  String? get selectedMusic => state.selectedMusic;
  FreeToUseTrack? get selectedTrack => state.selectedTrack;
  double get musicStartSeconds => state.musicStartSeconds;
  double get musicCropDuration => state.musicCropDuration;
  double get musicEndSeconds => state.musicEndSeconds;
  StudioCameraMode get cameraMode => state.cameraMode;
  bool get isFrontCamera => state.isFrontCamera;
  String get selectedFilter => state.selectedFilter;
  String get selectedSpeed => state.selectedSpeed;
  bool get beautyOn => state.beautyOn;
  double get beautyIntensity => state.beautyIntensity;
  String get recordingFilter => state.recordingFilter;
  bool get recordingBeautyOn => state.recordingBeautyOn;
  double get recordingBeautyIntensity => state.recordingBeautyIntensity;
  List<Map<String, dynamic>> get drafts => state.drafts;
  Map<String, dynamic> get recordingEffectsPayload => state.recordingEffectsPayload;

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
  }) {
    emit(state.copyWith(
      recordingFilter: filterId ?? state.selectedFilter,
      recordingBeautyOn: beautyOn ?? state.beautyOn,
      recordingBeautyIntensity: beautyIntensity ?? state.beautyIntensity,
    ));
  }

  void setRecordedDuration(String duration) {
    emit(state.copyWith(recordedDuration: duration));
  }

  void setRecordedVideoPath(String? path) {
    if (path == null) {
      emit(state.copyWith(
        clearRecordedVideoPath: true,
        recordingFilter: state.selectedFilter,
        recordingBeautyOn: state.beautyOn,
        recordingBeautyIntensity: state.beautyIntensity,
      ));
    } else {
      emit(state.copyWith(recordedVideoPath: path));
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
    final updated = List<Map<String, dynamic>>.from(state.drafts);
    updated.insert(0, draft);
    if (!MockData.DRAFTS.contains(draft)) {
      MockData.DRAFTS.insert(0, draft);
    }
    emit(state.copyWith(drafts: updated));
  }

  void deleteDraft(String id) {
    final updated = List<Map<String, dynamic>>.from(state.drafts)
      ..removeWhere((d) => d['id'] == id);
    MockData.DRAFTS.removeWhere((d) => d['id'] == id);
    emit(state.copyWith(drafts: updated));
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
      drafts: state.drafts,
    ));
  }

  @override
  Future<void> close() {
    state.activeVideoController?.dispose();
    return super.close();
  }
}
