import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';
import 'package:artable_app/features/studio/presentation/bloc/studio_cubit.dart';
import 'package:artable_app/data/datasources/music_api_service.dart';
import 'package:artable_app/core/widgets/app_network_image.dart';
import 'package:artable_app/core/widgets/app_screen_header.dart';
import 'package:artable_app/core/widgets/gradient_button.dart';
import 'package:artable_app/features/studio/presentation/widgets/song_trimmer_sheet.dart';

class StudioMusicScreen extends StatefulWidget {
  const StudioMusicScreen({super.key, this.challengeId});

  final String? challengeId;

  @override
  State<StudioMusicScreen> createState() => _StudioMusicScreenState();
}

class _StudioMusicScreenState extends State<StudioMusicScreen> {
  List<FreeToUseTrack> _tracks = [];
  bool _isRefreshing = false;
  bool _isInitialLoad = true;
  String? _loadError;
  String _activeCategory = 'All';
  String _query = '';
  String? _playingTrackId;
  final _likedIds = <String>{};

  @override
  void initState() {
    super.initState();
    final cached = MusicApiService.cachedTracks;
    _tracks = (cached != null && cached.isNotEmpty)
        ? cached
        : MusicApiService.fallbackTracks;
    _isInitialLoad = false;
    _loadTracks();
  }

  Future<void> _loadTracks({bool forceRefresh = false}) async {
    final hasVisibleTracks = _tracks.isNotEmpty;
    if (mounted) {
      setState(() {
        _isRefreshing = !hasVisibleTracks || forceRefresh;
        _loadError = null;
      });
    }

    try {
      final fetched = await MusicApiService.fetchTracks(forceRefresh: forceRefresh);
      if (mounted) {
        setState(() {
          _tracks = fetched;
          _isRefreshing = false;
          _isInitialLoad = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = 'Failed to load music. Tap retry.';
          _isRefreshing = false;
          _isInitialLoad = false;
        });
      }
    }
  }

  List<String> get _categories {
    final cats = {'All', 'Ambient', 'Chill', 'Easy Listening', 'Pop'};
    for (final t in _tracks) {
      if (t.category.isNotEmpty && t.category != 'All') {
        cats.add(t.category);
      }
    }
    return cats.toList();
  }

  List<FreeToUseTrack> get _filtered {
    return _tracks.where((t) {
      final matchesQuery = _query.isEmpty ||
          t.title.toLowerCase().contains(_query.toLowerCase()) ||
          t.artist.toLowerCase().contains(_query.toLowerCase()) ||
          t.category.toLowerCase().contains(_query.toLowerCase());
      final matchesCategory =
          _activeCategory == 'All' || t.category.toLowerCase() == _activeCategory.toLowerCase();
      return matchesQuery && matchesCategory;
    }).toList();
  }

  void _openTrimmer(FreeToUseTrack track) {
    SongTrimmerSheet.show(context, track: track);
  }

  @override
  Widget build(BuildContext context) {
    final selectedTrack = context.select<StudioCubit, FreeToUseTrack?>(
      (s) => s.state.selectedTrack,
    );
    final cropDuration = context.select<StudioCubit, int>(
      (s) => s.state.musicCropDuration.toInt(),
    );
    final selectedMusic = context.select<StudioCubit, String?>(
      (s) => s.state.selectedMusic,
    );

    final filtered = _filtered;
    final showSkeleton = _isInitialLoad && _tracks.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                AppScreenHeader(
                  title: 'Add Music',
                  trailing: _isRefreshing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.purple,
                          ),
                        )
                      : null,
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => _loadTracks(forceRefresh: true),
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              Container(
                                height: 46,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF6F3FC),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.search,
                                      size: 18,
                                      color: Color(0xFF9E95B4),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextField(
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF1E1633),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        decoration: const InputDecoration(
                                          filled: false,
                                          hintText: 'Search music',
                                          hintStyle: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFFB3A9C9),
                                            fontWeight: FontWeight.w400,
                                          ),
                                          border: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        onChanged: (v) => setState(() => _query = v.trim()),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: _categories.map((cat) {
                                    final active =
                                        _activeCategory.toLowerCase() ==
                                            cat.toLowerCase();
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: GestureDetector(
                                        onTap: () =>
                                            setState(() => _activeCategory = cat),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 18,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient:
                                                active ? AppGradients.button : null,
                                            color: active
                                                ? null
                                                : Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(999),
                                            border: active
                                                ? null
                                                : Border.all(
                                                    color: const Color(0xFFEFEBF7),
                                                    width: 1.2,
                                                  ),
                                          ),
                                          child: Text(
                                            cat,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: active
                                                  ? FontWeight.w700
                                                  : FontWeight.w600,
                                              color: active
                                                  ? Colors.white
                                                  : const Color(0xFF6E6485),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_loadError != null) ...[
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Text(
                                    _loadError!,
                                    style: AppTextStyles.hint12.copyWith(
                                      color: AppColors.pink,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ]),
                          ),
                        ),
                        if (showSkeleton)
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => const _TrackSkeleton(),
                                childCount: 6,
                              ),
                            ),
                          )
                        else if (filtered.isEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text(
                                _isRefreshing
                                    ? 'Loading tracks...'
                                    : 'No tracks found for "$_query".',
                                style: AppTextStyles.hint12,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              22,
                              0,
                              22,
                              selectedTrack != null ? 110 : 24,
                            ),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final t = filtered[index];
                                  final isSelected = selectedTrack?.id == t.id;
                                  final isPlaying = _playingTrackId == t.id;
                                  final isLiked = _likedIds.contains(t.id);

                                  return _TrackCard(
                                    track: t,
                                    selected: isSelected,
                                    playing: isPlaying,
                                    liked: isLiked,
                                    onPlay: () {
                                      setState(() {
                                        _playingTrackId =
                                            isPlaying ? null : t.id;
                                      });
                                    },
                                    onLike: () {
                                      setState(() {
                                        if (isLiked) {
                                          _likedIds.remove(t.id);
                                        } else {
                                          _likedIds.add(t.id);
                                        }
                                      });
                                    },
                                    onUse: () => _openTrimmer(t),
                                  );
                                },
                                childCount: filtered.length,
                              ),
                            ),
                          ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              22,
                              14,
                              22,
                              selectedTrack != null ? 120 : 24,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  size: 13,
                                  color: Color(0xFF9B90B2),
                                ),
                                const SizedBox(width: 6),
                                const Flexible(
                                  child: Text(
                                    'All music is from the Artable music library.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF9B90B2),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (selectedTrack != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                    border: const Border(
                      top: BorderSide(color: AppColors.inputBorder),
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AppNetworkImage(
                          url: selectedTrack.coverUrl,
                          width: 36,
                          height: 36,
                          alt: selectedTrack.title,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              selectedMusic ??
                                  '${selectedTrack.title} — ${selectedTrack.artist}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Cropped: ${cropDuration}s clip',
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: AppColors.purple,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => _openTrimmer(selectedTrack),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.purple,
                          side: const BorderSide(color: AppColors.purple),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Edit Crop',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GradientButton(
                        label: 'Use',
                        fullWidth: false,
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        onPressed: () => context.pop(),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TrackSkeleton extends StatelessWidget {
  const _TrackSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFF0ECFA),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFF5F2FC),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0ECFA),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  width: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F2FC),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackCard extends StatelessWidget {
  const _TrackCard({
    required this.track,
    required this.selected,
    required this.playing,
    required this.liked,
    required this.onPlay,
    required this.onLike,
    required this.onUse,
  });

  final FreeToUseTrack track;
  final bool selected;
  final bool playing;
  final bool liked;
  final VoidCallback onPlay;
  final VoidCallback onLike;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? AppColors.purple : const Color(0xFFF1ECFA),
          width: selected ? 1.8 : 1.0,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AppNetworkImage(
              url: track.coverUrl,
              width: 44,
              height: 44,
              alt: track.title,
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onPlay,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFF6F2FC),
                shape: BoxShape.circle,
              ),
              child: Icon(
                playing ? Icons.pause : Icons.play_arrow,
                size: 16,
                color: AppColors.purple,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF1E1633),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${track.artist} · ${track.formattedDuration}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9B90B2),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onLike,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                liked ? Icons.favorite : Icons.favorite_border,
                size: 18,
                color: liked ? AppColors.pink : const Color(0xFFC0B5D7),
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onUse,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                gradient: selected ? null : AppGradients.button,
                color: selected ? const Color(0xFFE9E4F7) : null,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                selected ? 'Selected' : 'Use',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.purple : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
