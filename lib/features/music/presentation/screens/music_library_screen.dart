import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';
import 'package:artable_app/core/widgets/app_back_header.dart';
import 'package:artable_app/core/widgets/app_network_image.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';
import 'package:artable_app/core/widgets/filter_pills.dart' show FilterPills, EmptyNote;
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:artable_app/features/music/data/models/music_track.dart';
import 'package:artable_app/features/music/data/repositories/music_repository.dart';

class MusicLibraryScreen extends StatefulWidget {
  const MusicLibraryScreen({super.key});

  @override
  State<MusicLibraryScreen> createState() => _MusicLibraryScreenState();
}

class _MusicLibraryScreenState extends State<MusicLibraryScreen> {
  static const _tabs = ['All', 'Trending', 'Popular', 'New'];
  var _tab = 'All';
  var _loading = true;
  String? _error;
  List<MusicTrack> _tracks = const [];
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_load());
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthCubit>();
      final category = _tab == 'All' ? null : _tab;
      final tracks = await _repository().getMusic(
        category: category,
        sessionToken: auth.sessionToken,
        refreshToken: auth.refreshToken,
      );
      if (!mounted) return;
      setState(() {
        _tracks = tracks;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load music library.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      child: Column(
        children: [
          const AppBackHeader(title: 'Music Library'),
          FilterPills(
            items: _tabs,
            selected: _tab,
            onSelected: (t) {
              setState(() => _tab = t);
              unawaited(_load());
            },
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _tracks.isEmpty
                        ? const Center(
                            child: EmptyNote(
                              message: 'No tracks in this category yet.',
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
                            itemCount: _tracks.length,
                            itemBuilder: (_, i) {
                              final t = _tracks[i];
                              return GestureDetector(
                                onTap: () => context.push(
                                  '/music-preview?id=${Uri.encodeComponent(t.id)}',
                                ),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border:
                                        Border.all(color: AppColors.inputBorder),
                                  ),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: AppNetworkImage(
                                          url: t.coverUrl,
                                          width: 48,
                                          height: 48,
                                          alt: t.title,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              t.title,
                                              style: AppTextStyles.body.copyWith(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                              ),
                                            ),
                                            Text(
                                              '${t.artist} · ${t.formattedDuration}',
                                              style: AppTextStyles.bodySoft
                                                  .copyWith(fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right,
                                        color: AppColors.textFaint,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}