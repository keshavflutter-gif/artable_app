import 'package:video_player/video_player.dart';
import 'package:artable_app/data/datasources/mock_data.dart';
import 'package:artable_app/data/datasources/music_api_service.dart';

enum StudioCameraMode { back, front }

class StudioState {
  StudioState({
    this.recordedDuration = '0:42',
    this.recordedVideoPath,
    this.selectedThumbnailPath,
    this.videoTitle,
    this.videoDescription,
    this.videoCategoryId,
    this.videoHashtags,
    this.videoChallengeId,
    this.activeVideoController,
    this.selectedMusic,
    this.selectedTrack,
    this.musicStartSeconds = 0.0,
    this.musicCropDuration = 30.0,
    this.cameraMode = StudioCameraMode.back,
    this.selectedFilter = 'natural',
    this.selectedSpeed = '1x',
    this.beautyOn = false,
    this.beautyIntensity = 50,
    this.recordingFilter = 'natural',
    this.recordingBeautyOn = false,
    this.recordingBeautyIntensity = 50,
    List<Map<String, dynamic>>? drafts,
  }) : drafts = drafts ?? List<Map<String, dynamic>>.from(MockData.DRAFTS);

  final String recordedDuration;
  final String? recordedVideoPath;
  final String? selectedThumbnailPath;
  final String? videoTitle;
  final String? videoDescription;
  final String? videoCategoryId;
  final String? videoHashtags;
  final String? videoChallengeId;
  final VideoPlayerController? activeVideoController;

  final String? selectedMusic;
  final FreeToUseTrack? selectedTrack;
  final double musicStartSeconds;
  final double musicCropDuration;

  final StudioCameraMode cameraMode;
  final String selectedFilter;
  final String selectedSpeed;
  final bool beautyOn;
  final double beautyIntensity;

  final String recordingFilter;
  final bool recordingBeautyOn;
  final double recordingBeautyIntensity;

  final List<Map<String, dynamic>> drafts;

  double get musicEndSeconds => musicStartSeconds + musicCropDuration;
  bool get isFrontCamera => cameraMode == StudioCameraMode.front;

  Map<String, dynamic> get recordingEffectsPayload => {
        'filterId': recordingFilter,
        'beautyOn': recordingBeautyOn,
        'beautyIntensity': recordingBeautyIntensity,
      };

  StudioState copyWith({
    String? recordedDuration,
    String? recordedVideoPath,
    String? selectedThumbnailPath,
    String? videoTitle,
    String? videoDescription,
    String? videoCategoryId,
    String? videoHashtags,
    String? videoChallengeId,
    VideoPlayerController? activeVideoController,
    String? selectedMusic,
    FreeToUseTrack? selectedTrack,
    double? musicStartSeconds,
    double? musicCropDuration,
    StudioCameraMode? cameraMode,
    String? selectedFilter,
    String? selectedSpeed,
    bool? beautyOn,
    double? beautyIntensity,
    String? recordingFilter,
    bool? recordingBeautyOn,
    double? recordingBeautyIntensity,
    List<Map<String, dynamic>>? drafts,
    bool clearRecordedVideoPath = false,
    bool clearSelectedThumbnailPath = false,
    bool clearSelectedMusic = false,
    bool clearActiveVideoController = false,
  }) {
    return StudioState(
      recordedDuration: recordedDuration ?? this.recordedDuration,
      recordedVideoPath: clearRecordedVideoPath ? null : (recordedVideoPath ?? this.recordedVideoPath),
      selectedThumbnailPath: clearSelectedThumbnailPath ? null : (selectedThumbnailPath ?? this.selectedThumbnailPath),
      videoTitle: videoTitle ?? this.videoTitle,
      videoDescription: videoDescription ?? this.videoDescription,
      videoCategoryId: videoCategoryId ?? this.videoCategoryId,
      videoHashtags: videoHashtags ?? this.videoHashtags,
      videoChallengeId: videoChallengeId ?? this.videoChallengeId,
      activeVideoController: clearActiveVideoController ? null : (activeVideoController ?? this.activeVideoController),
      selectedMusic: clearSelectedMusic ? null : (selectedMusic ?? this.selectedMusic),
      selectedTrack: clearSelectedMusic ? null : (selectedTrack ?? this.selectedTrack),
      musicStartSeconds: musicStartSeconds ?? this.musicStartSeconds,
      musicCropDuration: musicCropDuration ?? this.musicCropDuration,
      cameraMode: cameraMode ?? this.cameraMode,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      selectedSpeed: selectedSpeed ?? this.selectedSpeed,
      beautyOn: beautyOn ?? this.beautyOn,
      beautyIntensity: beautyIntensity ?? this.beautyIntensity,
      recordingFilter: recordingFilter ?? this.recordingFilter,
      recordingBeautyOn: recordingBeautyOn ?? this.recordingBeautyOn,
      recordingBeautyIntensity: recordingBeautyIntensity ?? this.recordingBeautyIntensity,
      drafts: drafts ?? this.drafts,
    );
  }
}
