import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/features/studio/presentation/bloc/studio_cubit.dart';
import 'package:artable_app/features/studio/presentation/bloc/studio_state.dart';
import 'package:artable_app/app/routes/app_routes.dart';
import 'package:artable_app/core/utils/app_filter_utils.dart';
import 'package:artable_app/core/utils/reel_helpers.dart';
import 'package:artable_app/data/datasources/music_api_service.dart';
import 'package:artable_app/features/studio/data/services/studio_music_playback_service.dart';
import 'package:artable_app/core/utils/studio_video_player_utils.dart';
import 'package:artable_app/features/studio/presentation/widgets/song_trimmer_sheet.dart';

enum _CameraState { idle, recording, recorded }

class StudioCameraScreen extends StatefulWidget {
  const StudioCameraScreen({super.key, this.challengeId});

  final String? challengeId;

  @override
  State<StudioCameraScreen> createState() => _StudioCameraScreenState();
}

class _StudioCameraScreenState extends State<StudioCameraScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _maxSeconds = 60;
  static const _ringLength = 264.0;

  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;
  bool _isCameraInitializing = false;
  String? _cameraError;

  int _seconds = 0;
  final ValueNotifier<int> _secondsNotifier = ValueNotifier(0);
  Timer? _timer;
  _CameraState _state = _CameraState.idle;
  bool _flashOn = false;
  bool _timerActive = false;
  int _speedIdx = 0;
  final _speeds = ['1x', '1.5x', '2x', '0.5x'];
  late AnimationController _spinController;
  VideoPlayerController? _recordedVideoController;
  bool _recordedVideoReady = false;
  bool _recordedVideoPlaying = false;
  bool _recordedVideoError = false;
  StudioCubit? _studioCubit;
  StreamSubscription<StudioState>? _studioSubscription;
  String? _lastPreloadedTrackId;
  int _cameraSetupGeneration = 0;
  int _livePreviewToken = 0;
  bool _isSwitchingCamera = false;
  VoidCallback? _cameraValueListener;

  Map<String, dynamic> get _challenge =>
      ReelHelpers.challengeById(widget.challengeId ?? 'c1')!;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _studioCubit = context.read<StudioCubit>();
      _studioSubscription = _studioCubit!.stream.listen((_) => _preloadSelectedMusic());
      _preloadSelectedMusic();
    });
    _initDeviceCamera();
  }

  void _preloadSelectedMusic() {
    final studio = _studioCubit;
    if (studio == null) return;
    final trackId = studio.selectedTrack?.id;
    if (trackId == null || trackId == _lastPreloadedTrackId) return;
    _lastPreloadedTrackId = trackId;
    StudioMusicPlaybackService.preloadForStudio(studio);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _studioSubscription?.cancel();
    _timer?.cancel();
    _secondsNotifier.dispose();
    _spinController.dispose();
    _detachCameraListener();
    unawaited(StudioMusicPlaybackService.stop());
    final cam = _cameraController;
    _cameraController = null;
    try {
      cam?.dispose();
    } catch (_) {}
    _recordedVideoController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      unawaited(_detachAndDisposeCamera(_cameraController));
    } else if (state == AppLifecycleState.resumed) {
      _initDeviceCamera();
    }
  }

  Future<void> _detachAndDisposeCamera(CameraController? controller) async {
    if (controller == null) return;
    _detachCameraListener();
    if (identical(_cameraController, controller)) {
      _cameraController = null;
    }
    if (mounted) setState(() {});
    await WidgetsBinding.instance.endOfFrame;
    try {
      await controller.dispose();
    } catch (_) {}
  }

  CameraDescription? _cameraForDirection(CameraLensDirection direction) {
    for (final camera in _cameras) {
      if (camera.lensDirection == direction) {
        return camera;
      }
    }
    return null;
  }

  CameraDescription? _pickAlternateCamera() {
    if (_cameras.length < 2) return null;

    final current = _cameraController?.description;
    final currentDirection = current?.lensDirection ??
        (context.read<StudioCubit>().isFrontCamera
            ? CameraLensDirection.front
            : CameraLensDirection.back);

    final nextDirection = currentDirection == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;

    return _cameraForDirection(nextDirection);
  }

  Future<void> _refreshCameras() async {
    try {
      _cameras = await availableCameras().timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Camera refresh error: $e');
    }
  }

  Future<void> _initDeviceCamera() async {
    if (_isCameraInitializing) return;
    setState(() {
      _isCameraInitializing = true;
      _cameraError = null;
    });

    try {
      _cameras = await availableCameras().timeout(const Duration(seconds: 5));
      if (_cameras.isNotEmpty) {
        if (!mounted) return;
        final studioProvider = context.read<StudioCubit>();
        final targetDirection = studioProvider.isFrontCamera
            ? CameraLensDirection.front
            : CameraLensDirection.back;

        CameraDescription? selectedCamera = _cameraForDirection(targetDirection);
        selectedCamera ??= _cameras.first;

        await _setupCameraController(selectedCamera);
        if (mounted) {
          context.read<StudioCubit>().setCameraMode(
                selectedCamera.lensDirection == CameraLensDirection.front
                    ? StudioCameraMode.front
                    : StudioCameraMode.back,
              );
        }
        return;
      }
    } catch (e) {
      debugPrint('Camera list error or timeout: $e');
    }

    if (mounted) {
      setState(() {
        _isCameraInitializing = false;
        _cameraError = 'Camera not available on this device.';
      });
    }
  }

  void _detachCameraListener() {
    final listener = _cameraValueListener;
    final controller = _cameraController;
    if (listener != null && controller != null) {
      controller.removeListener(listener);
    }
    _cameraValueListener = null;
  }

  bool _isIgnorableCameraError(String? error) {
    if (error == null || error.isEmpty) return false;
    final lower = error.toLowerCase();
    return lower.contains('flash') || lower.contains('no flash unit');
  }

  Future<void> _disableFlashBeforeFrontSwitch(CameraController controller) async {
    _flashOn = false;
    if (controller.description.lensDirection == CameraLensDirection.back &&
        controller.value.isInitialized) {
      try {
        await controller.setFlashMode(FlashMode.off);
      } catch (_) {}
    }
    if (mounted) {
      setState(() => _cameraError = null);
    }
  }

  void _attachCameraListener(CameraController controller) {
    _detachCameraListener();
    _cameraValueListener = () {
      if (!mounted || !controller.value.hasError) return;
      final error = controller.value.errorDescription;
      if (_isIgnorableCameraError(error)) {
        if (mounted) {
          setState(() {
            _flashOn = false;
            _cameraError = null;
          });
        }
        return;
      }
      setState(() {
        _cameraError = error ?? 'Camera error. Please try again.';
        _isCameraInitializing = false;
      });
    };
    controller.addListener(_cameraValueListener!);
  }

  List<ResolutionPreset> _presetsForCamera(CameraDescription description) {
    if (description.lensDirection == CameraLensDirection.front) {
      return [ResolutionPreset.medium, ResolutionPreset.low];
    }
    return [ResolutionPreset.high, ResolutionPreset.medium, ResolutionPreset.low];
  }

  ImageFormatGroup _imageFormatForCamera(CameraDescription description) {
    if (description.lensDirection == CameraLensDirection.front) {
      return ImageFormatGroup.unknown;
    }
    return ImageFormatGroup.yuv420;
  }

  Future<void> _applyCameraRecordingSettings(CameraController controller) async {
    try {
      await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
    } catch (_) {}
    if (controller.description.lensDirection == CameraLensDirection.back) {
      try {
        await controller.setVideoStabilizationMode(VideoStabilizationMode.level1);
      } catch (_) {}
    }
  }

  Future<void> _applyFlashForCamera(CameraController controller, CameraDescription description) async {
    if (description.lensDirection == CameraLensDirection.front) {
      if (_flashOn && mounted) {
        setState(() => _flashOn = false);
      } else {
        _flashOn = false;
      }
      return;
    }

    if (_flashOn) {
      try {
        await controller.setFlashMode(FlashMode.torch);
      } catch (_) {
        if (mounted) setState(() => _flashOn = false);
      }
    } else {
      try {
        await controller.setFlashMode(FlashMode.off);
      } catch (_) {}
    }
  }

  Future<bool> _setupCameraController(CameraDescription description) async {
    final setupId = ++_cameraSetupGeneration;

    final oldController = _cameraController;
    _detachCameraListener();
    _cameraController = null;
    if (mounted) {
      setState(() {
        _isCameraInitializing = true;
        _cameraError = null;
      });
    }
    if (oldController != null) {
      if (description.lensDirection == CameraLensDirection.front && _flashOn) {
        await _disableFlashBeforeFrontSwitch(oldController);
      }
      try {
        if (oldController.value.isRecordingVideo) {
          final partial = await oldController.stopVideoRecording();
          try {
            await File(partial.path).delete();
          } catch (_) {}
        }
      } catch (_) {}
      await WidgetsBinding.instance.endOfFrame;
      try {
        await oldController.dispose();
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    final presets = _presetsForCamera(description);
    for (final preset in presets) {
      try {
        final newController = CameraController(
          description,
          preset,
          enableAudio: true,
          imageFormatGroup: _imageFormatForCamera(description),
        );
        await newController.initialize().timeout(const Duration(seconds: 6));
        if (!mounted || setupId != _cameraSetupGeneration) {
          try {
            await newController.dispose();
          } catch (_) {}
          return false;
        }
        await _applyFlashForCamera(newController, description);
        await _applyCameraRecordingSettings(newController);
        _livePreviewToken++;
        setState(() {
          _cameraController = newController;
          _isCameraInitializing = false;
          _cameraError = null;
        });
        _attachCameraListener(newController);
        debugPrint('Camera initialized with $preset preset');
        return true;
      } catch (e) {
        debugPrint('Camera init error ($preset): $e');
      }
    }

    if (!mounted || setupId != _cameraSetupGeneration) return false;

    if (mounted) {
      setState(() {
        _isCameraInitializing = false;
        _cameraError = 'Could not switch camera. Please try again.';
      });
    }
    return false;
  }

  String get _timerText {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _startRecording() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera is not ready. Please wait and try again.')),
        );
      }
      return;
    }

    var started = false;
    try {
      await _applyCameraRecordingSettings(controller);
      await controller.startVideoRecording(enablePersistentRecording: true);
      started = controller.value.isRecordingVideo;
    } catch (e) {
      debugPrint('Error starting video recording: $e');
    }

    if (!started) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not start recording. Please try again.')),
        );
      }
      return;
    }

    if (mounted) {
      context.read<StudioCubit>().snapshotRecordingEffects();
    }

    _timer?.cancel();
    _seconds = 0;
    _secondsNotifier.value = 0;

    if (mounted) {
      unawaited(
        StudioMusicPlaybackService.playForRecording(context.read<StudioCubit>()),
      );
    }

    if (mounted) {
      setState(() => _state = _CameraState.recording);
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_seconds >= _maxSeconds) {
        _stopRecording();
        return;
      }
      _seconds++;
      _secondsNotifier.value = _seconds;
    });
  }

  Future<void> _releaseCameraForPlayback() async {
    await _detachAndDisposeCamera(_cameraController);
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();

    final controller = _cameraController;
    String? savedPath;

    if (controller != null && controller.value.isRecordingVideo) {
      try {
        await StudioMusicPlaybackService.releaseForVideoPlayback();
        final XFile videoFile = await controller.stopVideoRecording();
        savedPath = videoFile.path;
        debugPrint('Recorded video saved to: $savedPath');
      } catch (e) {
        debugPrint('Error stopping video recording: $e');
      }
    } else {
      await StudioMusicPlaybackService.releaseForVideoPlayback();
    }

    await _releaseCameraForPlayback();

    if (!mounted) return;

    if (savedPath == null || savedPath.isEmpty) {
      _seconds = 0;
      _secondsNotifier.value = 0;
      setState(() {
        _state = _CameraState.idle;
        _recordedVideoReady = false;
        _recordedVideoPlaying = false;
        _recordedVideoError = false;
      });
      await _initDeviceCamera();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recording failed. Please try again.')),
      );
      return;
    }

    context.read<StudioCubit>().setRecordedVideoPath(savedPath);
    setRecordedDuration(_timerText);

    await _initRecordedVideoPreview(savedPath);

    if (mounted) {
      setState(() {
        _state = _CameraState.recorded;
      });
    }
  }

  void setRecordedDuration(String duration) {
    if (mounted) {
      context.read<StudioCubit>().setRecordedDuration(duration);
    }
  }

  Future<void> _initRecordedVideoPreview(String path) async {
    await _recordedVideoController?.dispose();
    _recordedVideoController = null;

    VideoPlayerController? controller;
    try {
      controller = await StudioVideoPlayerUtils.initializeRecordedVideo(path);
    } catch (e) {
      debugPrint('Recorded preview init error: $e');
      controller = null;
    }

    if (!mounted) {
      await controller?.dispose();
      return;
    }

    if (controller != null) {
      setState(() {
        _recordedVideoController = controller;
        _recordedVideoReady = true;
        _recordedVideoPlaying = true;
        _recordedVideoError = false;
      });
    } else {
      setState(() {
        _recordedVideoReady = false;
        _recordedVideoError = true;
      });
    }
  }

  void _toggleRecordedVideoPlayback() {
    final controller = _recordedVideoController;
    if (controller == null || !_recordedVideoReady) return;

    if (controller.value.isPlaying) {
      controller.pause();
      setState(() => _recordedVideoPlaying = false);
    } else {
      controller.play();
      setState(() => _recordedVideoPlaying = true);
    }
  }

  void _retake() async {
    _timer?.cancel();
    await StudioMusicPlaybackService.stop();
    await _recordedVideoController?.dispose();
    _recordedVideoController = null;
    if (mounted) {
      final studio = context.read<StudioCubit>();
      studio.setRecordedVideoPath(null);
    }
    try {
      await _cameraController?.resumePreview();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _seconds = 0;
        _secondsNotifier.value = 0;
        _state = _CameraState.idle;
        _recordedVideoReady = false;
        _recordedVideoPlaying = false;
        _recordedVideoError = false;
      });
      await _initDeviceCamera();
    }
  }

  Future<bool> _switchActiveCamera(
    CameraDescription nextCam, {
    required bool resumeRecording,
  }) async {
    final controller = _cameraController;
    if (controller != null && controller.value.isInitialized) {
      try {
        if (nextCam.lensDirection == CameraLensDirection.front) {
          await _disableFlashBeforeFrontSwitch(controller);
        }

        await controller.setDescription(nextCam);
        if (!mounted) return false;

        await _applyFlashForCamera(controller, nextCam);
        await _applyCameraRecordingSettings(controller);
        _livePreviewToken++;
        if (mounted) {
          setState(() {
            _cameraError = null;
          });
        }
        return true;
      } catch (e) {
        debugPrint('In-place camera switch failed: $e');
        if (nextCam.lensDirection == CameraLensDirection.front) {
          try {
            await _disableFlashBeforeFrontSwitch(controller);
            await controller.setDescription(nextCam);
            if (!mounted) return false;
            await _applyFlashForCamera(controller, nextCam);
            await _applyCameraRecordingSettings(controller);
            _livePreviewToken++;
            if (mounted) {
              setState(() {
                _cameraError = null;
              });
            }
            return true;
          } catch (retryError) {
            debugPrint('Front camera switch retry failed: $retryError');
          }
        }
      }
    }

    final switched = await _setupCameraController(nextCam);
    if (!switched || !resumeRecording) return switched;

    final newController = _cameraController;
    if (newController == null || !newController.value.isInitialized) return false;

    try {
      await _applyCameraRecordingSettings(newController);
      await newController.startVideoRecording(enablePersistentRecording: true);
      return newController.value.isRecordingVideo;
    } catch (e) {
      debugPrint('Resume recording after camera setup failed: $e');
      return false;
    }
  }

  Future<void> _handleFlipCamera() async {
    if (_isSwitchingCamera) return;
    if (_state == _CameraState.recorded) return;
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    final resumeRecording = _state == _CameraState.recording;

    _spinController.forward(from: 0);
    if (mounted) setState(() => _isSwitchingCamera = true);

    try {
      if (!mounted) return;
      final studioProvider = context.read<StudioCubit>();

      if (_cameras.length < 2) {
        await _refreshCameras();
      }

      final nextCam = _pickAlternateCamera();
      if (nextCam == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not switch camera on this device.')),
          );
        }
        return;
      }

      final switched = await _switchActiveCamera(
        nextCam,
        resumeRecording: resumeRecording,
      );
      if (!mounted) return;

      if (switched) {
        studioProvider.setCameraMode(
          nextCam.lensDirection == CameraLensDirection.front
              ? StudioCameraMode.front
              : StudioCameraMode.back,
        );
        setState(() {});
      } else {
        if (resumeRecording) {
          _timer?.cancel();
          setState(() => _state = _CameraState.idle);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not switch camera. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSwitchingCamera = false);
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.description.lensDirection == CameraLensDirection.front) {
      if (_flashOn && mounted) setState(() => _flashOn = false);
      return;
    }

    final turnOn = !_flashOn;
    if (mounted) setState(() => _flashOn = turnOn);
    try {
      await controller.setFlashMode(turnOn ? FlashMode.torch : FlashMode.off);
    } catch (e) {
      debugPrint('Flash mode error: $e');
      if (mounted) setState(() => _flashOn = false);
    }
  }

  Widget _buildCameraViewfinder() {
    final controller = _cameraController;
    final isLiveReady = controller != null &&
        controller.value.isInitialized &&
        !controller.value.hasError &&
        !_isSwitchingCamera;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Base studio viewfinder background with animated live feel
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF100727),
                Color(0xFF1F0C48),
                Color(0xFF140833),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Rule of thirds grid lines
              Positioned.fill(
                child: CustomPaint(
                  painter: _StudioGridPainter(),
                ),
              ),
              // Center focus reticle
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1.2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.purple,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Live camera texture when ready
        if (isLiveReady)
          Positioned.fill(
            child: _LiveCameraPreview(
              key: ValueKey(_livePreviewToken),
              controller: controller,
              isActive: () => identical(_cameraController, controller),
            ),
          ),

        if (_isCameraInitializing && !isLiveReady)
          const Center(
            child: CircularProgressIndicator(
              color: AppColors.purple,
              strokeWidth: 3,
            ),
          ),

        if (_cameraError != null && !isLiveReady)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.videocam_off, color: Colors.white54, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    _cameraError!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: _initDeviceCamera,
                    child: const Text('Retry Camera'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRecordedVideoPreview() {
    final controller = _recordedVideoController;
    final isReady = controller != null &&
        _recordedVideoReady &&
        controller.value.isInitialized;

    if (!isReady) {
      return Container(
        color: const Color(0xFF150C2B),
        child: Center(
          child: _recordedVideoError
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white54, size: 36),
                    const SizedBox(height: 10),
                    Text(
                      'Could not play video preview',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        final path = context.read<StudioCubit>().recordedVideoPath;
                        if (path != null) {
                          setState(() => _recordedVideoError = false);
                          _initRecordedVideoPreview(path);
                        }
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                )
              : const CircularProgressIndicator(
                  color: AppColors.purple,
                  strokeWidth: 3,
                ),
        ),
      );
    }

    final readyController = controller;

    return LayoutBuilder(
      builder: (context, constraints) {
        var aspectRatio = readyController.value.aspectRatio;
        if (constraints.maxHeight > constraints.maxWidth && aspectRatio > 0) {
          aspectRatio = 1 / aspectRatio;
        }

        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: constraints.maxWidth,
                height: aspectRatio > 0
                    ? constraints.maxWidth / aspectRatio
                    : constraints.maxHeight,
                child: VideoPlayer(readyController),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainViewfinder(StudioCubit studioProvider) {
    if (_state == _CameraState.recorded) {
      return AppFilterUtils.buildFilteredView(
        filterId: studioProvider.recordingFilter,
        beautyOn: studioProvider.recordingBeautyOn,
        beautyIntensity: studioProvider.recordingBeautyIntensity,
        child: _buildRecordedVideoPreview(),
      );
    }

    // Live camera must stay unfiltered — ColorFiltered/RepaintBoundary breaks
    // Android camera preview on Realme/Oppo/Vivo devices.
    return _buildCameraViewfinder();
  }

  @override
  Widget build(BuildContext context) {
    final challenge = _challenge;
    final isFrontCamera = context.select<StudioCubit, bool>((s) => s.isFrontCamera);

    return Scaffold(
      backgroundColor: const Color(0xFF150C2B),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildMainViewfinder(context.read<StudioCubit>()),

          if (_state == _CameraState.recorded)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleRecordedVideoPlayback,
                child: Center(
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _recordedVideoPlaying ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.4),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.7),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Gradient overlay & recording border indicator
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x8C0A0519),
                  Color(0x0D0A0519),
                  Color(0x1A0A0519),
                  Color(0xBF0A0519),
                ],
                stops: [0, 0.2, 0.6, 1],
              ),
              border: _state == _CameraState.recording
                  ? Border.all(color: const Color(0xD9FF3D77), width: 3.5)
                  : null,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Header Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CircleBtn(icon: Icons.chevron_left, onTap: () => context.pop()),
                      Column(
                        children: [
                          const Text(
                            'Artable Studio',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          // Camera Position Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isFrontCamera ? Icons.person : Icons.photo_camera,
                                  size: 10,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isFrontCamera ? 'FRONT CAM' : 'BACK CAM',
                                  style: const TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 38),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Selected Music Banner Button (Instagram Style)
                BlocSelector<StudioCubit, StudioState, (FreeToUseTrack?, String?, int)>(
                  selector: (studio) => (
                    studio.selectedTrack,
                    studio.selectedMusic,
                    studio.musicCropDuration.toInt(),
                  ),
                  builder: (context, musicData) {
                    final selectedTrack = musicData.$1;
                    final selectedMusic = musicData.$2;
                    final cropDuration = musicData.$3;

                    return GestureDetector(
                      onTap: () {
                        if (selectedTrack != null) {
                          SongTrimmerSheet.show(context, track: selectedTrack);
                        } else {
                          context.push('${AppRoutes.studioMusic}?id=${challenge['id']}');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.music_note, size: 14, color: Color(0xFFFF528E)),
                            const SizedBox(width: 6),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 180),
                              child: Text(
                                selectedMusic ?? 'Add Music',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (selectedTrack != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.purple,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${cropDuration}s',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Live Recording Timer Indicator
                ValueListenableBuilder<int>(
                  valueListenable: _secondsNotifier,
                  builder: (context, seconds, _) {
                    final m = (seconds ~/ 60).toString().padLeft(2, '0');
                    final s = (seconds % 60).toString().padLeft(2, '0');
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_state == _CameraState.recording)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 7),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF3D3D),
                              shape: BoxShape.circle,
                            ),
                          ),
                        Text(
                          '$m:$s',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const Spacer(),

                // Side Control Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Flip Camera Button — label shows the camera to switch to
                      _ControlItem(
                        icon: Icons.cameraswitch,
                        label: isFrontCamera ? 'Back' : 'Front',
                        spinning: _isSwitchingCamera ? _spinController : null,
                        onTap: _state != _CameraState.recorded &&
                                !_isSwitchingCamera &&
                                (_cameraController?.value.isInitialized ?? false)
                            ? () => unawaited(_handleFlipCamera())
                            : null,
                      ),
                      _ControlItem(
                        icon: _flashOn ? Icons.flash_on : Icons.flash_off,
                        label: 'Flash',
                        active: _flashOn,
                        onTap: _toggleFlash,
                      ),
                      _ControlItem(
                        icon: Icons.timer_outlined,
                        label: 'Timer',
                        active: _timerActive,
                        onTap: () => setState(() => _timerActive = !_timerActive),
                      ),
                      _ControlItem(
                        icon: Icons.auto_awesome,
                        label: 'Filters',
                        onTap: _state == _CameraState.recording
                            ? null
                            : () => context.push(
                                  '${AppRoutes.studioFilters}?id=${challenge['id']}',
                                ),
                      ),
                      _ControlItem(
                        icon: Icons.bolt,
                        label: _speeds[_speedIdx],
                        active: _speedIdx != 0,
                        onTap: () => setState(() {
                          _speedIdx = (_speedIdx + 1) % _speeds.length;
                        }),
                      ),
                      _ControlItem(
                        icon: Icons.music_note,
                        label: 'Music',
                        active: context.select<StudioCubit, bool>(
                          (s) => s.selectedTrack != null,
                        ),
                        onTap: () => context.push(
                          '${AppRoutes.studioMusic}?id=${challenge['id']}',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Record Shutter Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_state == _CameraState.recorded)
                        _SideBtn(icon: Icons.refresh, onTap: _retake)
                      else
                        const SizedBox(width: 52),
                      const SizedBox(width: 34),
                      if (_state != _CameraState.recorded)
                        GestureDetector(
                          onTap: _isCameraInitializing ||
                                  _cameraController == null ||
                                  !(_cameraController?.value.isInitialized ?? false)
                              ? null
                              : () {
                                  if (_state == _CameraState.idle) {
                                    _startRecording();
                                  } else if (_state == _CameraState.recording) {
                                    _stopRecording();
                                  }
                                },
                          child: SizedBox(
                            width: 76,
                            height: 76,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                ValueListenableBuilder<int>(
                                  valueListenable: _secondsNotifier,
                                  builder: (context, seconds, _) {
                                    final ringOffset =
                                        _ringLength - (_ringLength * seconds / _maxSeconds);
                                    return Transform.rotate(
                                      angle: -math.pi / 2,
                                      child: CustomPaint(
                                        size: const Size(76, 76),
                                        painter: _RecordRingPainter(
                                          progressOffset: ringOffset,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: _state == _CameraState.recording ? 30 : 56,
                                  height: _state == _CameraState.recording ? 30 : 56,
                                  decoration: BoxDecoration(
                                    gradient: AppGradients.button,
                                    borderRadius: BorderRadius.circular(
                                      _state == _CameraState.recording ? 8 : 28,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFF3D77).withValues(alpha: 0.45),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 76),
                      const SizedBox(width: 34),
                      if (_state == _CameraState.recorded)
                        _SideBtn(
                          icon: Icons.check,
                          gradient: true,
                          onTap: () async {
                            await StudioMusicPlaybackService.releaseForVideoPlayback();
                            await _recordedVideoController?.dispose();
                            _recordedVideoController = null;

                            if (!context.mounted) return;
                            final studio = context.read<StudioCubit>();
                            if (studio.recordedVideoPath == null || studio.recordedVideoPath!.isEmpty) {
                              final controller = _cameraController;
                              if (controller != null && controller.value.isRecordingVideo) {
                                await _stopRecording();
                              }
                            }
                            final videoPath = studio.recordedVideoPath;
                            if (context.mounted && videoPath != null && videoPath.isNotEmpty) {
                              context.push('${AppRoutes.studioPreview}?id=${challenge['id']}');
                            } else if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Recorded video not found. Please retake.')),
                              );
                            }
                          },
                        )
                      else
                        const SizedBox(width: 52),
                    ],
                  ),
                ),
                const Text(
                  'Max 60 seconds',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xA6FFFFFF),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveCameraPreview extends StatelessWidget {
  const _LiveCameraPreview({
    super.key,
    required this.controller,
    required this.isActive,
  });

  final CameraController controller;
  final bool Function() isActive;

  @override
  Widget build(BuildContext context) {
    if (!isActive() || !controller.value.isInitialized || controller.value.hasError) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!isActive() || !controller.value.isInitialized || controller.value.hasError) {
          return const SizedBox.shrink();
        }

        final previewSize = controller.value.previewSize;
        var cameraAspectRatio = controller.value.aspectRatio;
        if (cameraAspectRatio <= 0 && previewSize != null && previewSize.height > 0) {
          cameraAspectRatio = previewSize.width / previewSize.height;
        }
        if (constraints.maxHeight > constraints.maxWidth && cameraAspectRatio > 0) {
          cameraAspectRatio = 1 / cameraAspectRatio;
        }

        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: constraints.maxWidth,
                height: cameraAspectRatio > 0
                    ? constraints.maxWidth / cameraAspectRatio
                    : constraints.maxHeight,
                child: CameraPreview(controller),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RecordRingPainter extends CustomPainter {
  _RecordRingPainter({required this.progressOffset});
  final double progressOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const radius = 42.0;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = Colors.white.withValues(alpha: 0.25),
    );
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      0,
      2 * math.pi * (1 - progressOffset / 264),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          colors: [Color(0xFFFF3D77), Color(0xFF8B3DFF)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _RecordRingPainter oldDelegate) =>
      oldDelegate.progressOffset != progressOffset;
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: Icon(icon, size: 17, color: Colors.white),
      ),
    );
  }
}

class _SideBtn extends StatelessWidget {
  const _SideBtn({required this.icon, required this.onTap, this.gradient = false});
  final IconData icon;
  final VoidCallback onTap;
  final bool gradient;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: gradient ? AppGradients.button : null,
          color: gradient ? null : Colors.white.withValues(alpha: 0.14),
          border: gradient ? null : Border.all(color: Colors.white.withValues(alpha: 0.24)),
        ),
        child: Icon(icon, size: 20, color: Colors.white),
      ),
    );
  }
}

class _ControlItem extends StatelessWidget {
  const _ControlItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.active = false,
    this.spinning,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;
  final AnimationController? spinning;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: active ? AppGradients.button : null,
              color: active ? null : Colors.white.withValues(alpha: 0.14),
              border: active ? null : Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: spinning != null
                ? RotationTransition(
                    turns: spinning!,
                    child: Icon(icon, size: 15, color: Colors.white),
                  )
                : Icon(icon, size: 15, color: Colors.white),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudioGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final x1 = size.width / 3;
    final x2 = size.width * 2 / 3;
    final y1 = size.height / 3;
    final y2 = size.height * 2 / 3;

    canvas.drawLine(Offset(x1, 0), Offset(x1, size.height), paint);
    canvas.drawLine(Offset(x2, 0), Offset(x2, size.height), paint);
    canvas.drawLine(Offset(0, y1), Offset(size.width, y1), paint);
    canvas.drawLine(Offset(0, y2), Offset(size.width, y2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


