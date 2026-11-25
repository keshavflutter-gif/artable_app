import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import 'package:artable_app/app/routes/app_routes.dart';
import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';
import 'package:artable_app/core/widgets/app_back_header.dart';
import 'package:artable_app/core/widgets/app_network_image.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';
import 'package:artable_app/core/widgets/filter_pills.dart';
import 'package:artable_app/data/datasources/music_api_service.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:artable_app/features/music/data/models/music_track.dart';
import 'package:artable_app/features/music/data/repositories/music_repository.dart';
import 'package:artable_app/features/studio/presentation/bloc/studio_cubit.dart';
import 'package:artable_app/features/studio/data/services/studio_music_playback_service.dart';

class MusicPreviewScreen extends StatefulWidget {
  const MusicPreviewScreen({
    super.key,
    this.trackId,
    this.initialTrack,
  });

  final String? trackId;
  final MusicTrack? initialTrack;

  @override
  State<MusicPreviewScreen> createState() => _MusicPreviewScreenState();
}

class _MusicPreviewScreenState extends State<MusicPreviewScreen>
    with WidgetsBindingObserver {
  MusicTrack? _track;
  var _loading = true;
  String? _error;
  var _isLoading = false;
  var _isLoaded = false;
  String? _loadedAudioUrl;
  Future<void>? _preloadFuture;

  late final AudioPlayer _player;
  StreamSubscription<Duration?>? _durationSub;
  MusicRepository? _repo;

  MusicRepository _repository() {
    final auth = context.read<AuthCubit>();
    return _repo ??= MusicRepository(
      onTokensRefreshed: auth.applyRefreshedTokens,
      onSessionRefreshFailed: auth.handleSessionRefreshFailed,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _player = AudioPlayer();

    if (widget.initialTrack != null) {
      _track = widget.initialTrack;
      _loading = false;
      final audio = widget.initialTrack!.audioUrl.trim();
      if (audio.isNotEmpty) {
        unawaited(_preloadAudio(audio));
      }
    }

    _durationSub = _player.durationStream.listen((dur) {
      if (!mounted || dur == null) return;
      final current = _track;
      if (current != null && current.duration <= 0 && dur.inSeconds > 0) {
        setState(() {
          _track = current.copyWith(duration: dur.inSeconds.toDouble());
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_load());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.inactive) {
      try {
        _player.pause();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _durationSub?.cancel();
    try {
      _player.stop();
      _player.dispose();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _preloadAudio(String url) {
    final clean = url.trim();
    if (clean.isEmpty) return Future.value();
    if (_isLoaded && _loadedAudioUrl == clean) return Future.value();
    if (_preloadFuture != null) return _preloadFuture!;

    _loadedAudioUrl = clean;
    final future = () async {
      try {
        await _player.setUrl(clean);
        _isLoaded = true;
      } catch (e) {
        debugPrint('Preload audio error: $e');
        _isLoaded = false;
        _loadedAudioUrl = null;
      } finally {
        _preloadFuture = null;
      }
    }();
    _preloadFuture = future;
    return future;
  }

  Future<void> _load() async {
    final id = widget.trackId?.trim() ?? '';
    if (id.isEmpty) {
      if (_track == null) {
        setState(() {
          _loading = false;
          _error = 'Track not found.';
        });
      }
      return;
    }

    try {
      final auth = context.read<AuthCubit>();
      final track = await _repository().getMusicById(
        id: id,
        sessionToken: auth.sessionToken,
        refreshToken: auth.refreshToken,
      );
      if (!mounted) return;
      setState(() {
        if (track != null) {
          _track = track;
          _error = null;
          if (!_isLoaded && track.audioUrl.trim().isNotEmpty) {
            unawaited(_preloadAudio(track.audioUrl.trim()));
          }
        } else if (_track == null) {
          _error = 'Track not found.';
        }
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (_track == null) {
          _error = 'Unable to load track.';
        }
        _loading = false;
      });
    }
  }

  Future<void> _togglePlay() async {
    final track = _track;
    if (track == null || track.audioUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio URL is not available.')),
      );
      return;
    }

    final url = track.audioUrl.trim();

    // Prevent double taps while setting up URL
    if (_isLoading) return;

    try {
      // 1. If currently playing, pause immediately.
      if (_player.playing) {
        await _player.pause();
        return;
      }

      // 2. If finished playing, seek to beginning and play.
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
        await _player.play();
        return;
      }

      // 3. If preload is in flight, await it.
      if (_preloadFuture != null && _loadedAudioUrl == url) {
        setState(() => _isLoading = true);
        await _preloadFuture;
        if (!mounted) return;
        if (_isLoaded) {
          await _player.play();
          return;
        }
      }

      // 4. If audio is already loaded, simply play/resume.
      if (_isLoaded && _loadedAudioUrl == url) {
        await _player.play();
        return;
      }

      // 5. Otherwise, load the audio URL and start playback.
      setState(() => _isLoading = true);
      StudioMusicPlaybackService.directPause();
      await _player.stop();
      await _player.setUrl(url);
      _loadedAudioUrl = url;
      _isLoaded = true;
      if (!mounted) return;
      await _player.play();
    } catch (e) {
      debugPrint('MusicPreviewScreen playback error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to play audio.')),
        );
      }
    } finally {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _useInStudio() async {
    try {
      await _player.pause();
      await _player.stop();
    } catch (_) {}

    final track = _track;
    if (track != null && mounted) {
      final freeTrack = FreeToUseTrack(
        id: track.id,
        title: track.title,
        artist: track.artist,
        duration: track.duration > 0 ? track.duration : 30.0,
        coverUrl: track.coverUrl,
        audioUrl: track.audioUrl,
        waveform: track.waveform,
        category: track.category.isNotEmpty ? track.category : 'Music Library',
      );
      final studio = context.read<StudioCubit>();
      studio.setSelectedTrack(
        freeTrack,
        start: 0.0,
        duration: freeTrack.duration > 0
            ? freeTrack.duration.clamp(1.0, 60.0)
            : 30.0,
      );
      StudioMusicPlaybackService.directPause();
      StudioMusicPlaybackService.invalidateLoadedTrack();
      unawaited(StudioMusicPlaybackService.preloadForStudio(studio));
    }

    if (!mounted) return;

    // Check if StudioCameraScreen is already in the navigation stack below us
    bool foundCamera = false;
    Navigator.of(context).popUntil((route) {
      final name = route.settings.name;
      if (name == AppRoutes.studioCamera ||
          name == '/studio-camera' ||
          name == 'studio-camera') {
        foundCamera = true;
        return true;
      }
      return route.isFirst;
    });

    if (!foundCamera && mounted) {
      context.push(AppRoutes.studioCamera);
    }
  }

  @override
  Widget build(BuildContext context) {
    final track = _track;

    return AppScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppBackHeader(title: 'Music Preview'),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: EmptyNote(message: _error ?? ''))
                    : track == null
                        ? const Center(
                            child: EmptyNote(message: 'Track not found.'),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(22),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: AppNetworkImage(
                                    url: track.coverUrl,
                                    width: 220,
                                    height: 220,
                                    alt: track.title,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  track.title,
                                  style: AppTextStyles.displayBold
                                      .copyWith(fontSize: 18),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  track.artist,
                                  style: AppTextStyles.bodySoft,
                                ),
                                const SizedBox(height: 24),
                                StreamBuilder<PlayerState>(
                                  stream: _player.playerStateStream,
                                  builder: (context, snapshot) {
                                    final state = snapshot.data;
                                    final playing = state?.playing ?? false;
                                    final processing = state?.processingState ??
                                        ProcessingState.idle;

                                    final isBuffering =
                                        processing == ProcessingState.loading ||
                                            (_isLoading && !playing);

                                    if (isBuffering) {
                                      return const SizedBox(
                                        width: 56,
                                        height: 56,
                                        child: Padding(
                                          padding: EdgeInsets.all(12),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              AppColors.purple,
                                            ),
                                          ),
                                        ),
                                      );
                                    }

                                    final isCompleted = processing ==
                                        ProcessingState.completed;
                                    final showPause = playing && !isCompleted;

                                    return IconButton(
                                      iconSize: 56,
                                      onPressed: _togglePlay,
                                      icon: Icon(
                                        showPause
                                            ? Icons.pause_circle_filled
                                            : Icons.play_circle_filled,
                                        color: AppColors.purple,
                                      ),
                                    );
                                  },
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: _useInStudio,
                                  child: Text(
                                    'Use in Studio',
                                    style: AppTextStyles.body.copyWith(
                                      color: AppColors.purple,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}