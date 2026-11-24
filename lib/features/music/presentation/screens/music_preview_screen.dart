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
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:artable_app/features/music/data/models/music_track.dart';
import 'package:artable_app/features/music/data/repositories/music_repository.dart';

class MusicPreviewScreen extends StatefulWidget {
  const MusicPreviewScreen({super.key, this.trackId});

  final String? trackId;

  @override
  State<MusicPreviewScreen> createState() => _MusicPreviewScreenState();
}

class _MusicPreviewScreenState extends State<MusicPreviewScreen> {
  MusicTrack? _track;
  var _loading = true;
  String? _error;
  var _playing = false;
  AudioPlayer? _player;
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
    _player = AudioPlayer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_load());
    });
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final id = widget.trackId?.trim() ?? '';
    if (id.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Track not found.';
      });
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
        _track = track;
        _loading = false;
        _error = track == null ? 'Track not found.' : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load track.';
      });
    }
  }

  Future<void> _togglePlay() async {
    final track = _track;
    if (track == null || track.audioUrl.isEmpty) return;
    try {
      if (_playing) {
        await _player?.pause();
        setState(() => _playing = false);
        return;
      }
      await _player?.setUrl(track.audioUrl);
      await _player?.play();
      setState(() => _playing = true);
    } catch (_) {}
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
                                IconButton(
                                  iconSize: 56,
                                  onPressed: _togglePlay,
                                  icon: Icon(
                                    _playing
                                        ? Icons.pause_circle_filled
                                        : Icons.play_circle_filled,
                                    color: AppColors.purple,
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () =>
                                      context.push(AppRoutes.studioMusic),
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