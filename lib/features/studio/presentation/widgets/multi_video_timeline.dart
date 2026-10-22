import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:artable_app/core/widgets/app_image.dart';
import '../../data/services/video_thumbnail_generator.dart';
import 'editor_clip.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────
const double _kPixelsPerSecond = 50.0; // px per second in the timeline
const double _kTrackHeight = 56.0;
const double _kHandleWidth = 14.0;
const double _kMinClipPx = 40.0; // minimum visual width for any clip
const double _kAddBtnWidth = 44.0;

// ─────────────────────────────────────────────────────────────────────────────
// MultiVideoTimeline — the main horizontally scrollable editor timeline
// ─────────────────────────────────────────────────────────────────────────────
class MultiVideoTimeline extends StatefulWidget {
  const MultiVideoTimeline({
    super.key,
    required this.notifier,
    required this.globalPositionMs,
    required this.onGlobalSeek,
    required this.onAddVideo,
    required this.onClipSelected,
    required this.onClipRemoved,
    required this.onTrimChanged,
    required this.isPlaying,
    this.isMerging = false,
  });

  final EditorClipListNotifier notifier;
  final bool isMerging;

  /// Current global playback position in milliseconds.
  final int globalPositionMs;

  /// Called when user manually scrubs the timeline. Provides new global ms.
  final ValueChanged<int> onGlobalSeek;

  /// Called when user taps the + add video button.
  final VoidCallback onAddVideo;

  /// Called when a clip is tapped / selected.
  final ValueChanged<int> onClipSelected;

  /// Called when the selected clip's delete button is pressed.
  final ValueChanged<int> onClipRemoved;

  /// Called continuously while a trim handle is dragged.
  final void Function(int clipIndex, Duration trimStart, Duration trimEnd) onTrimChanged;

  final bool isPlaying;

  @override
  State<MultiVideoTimeline> createState() => _MultiVideoTimelineState();
}

class _MultiVideoTimelineState extends State<MultiVideoTimeline> {
  final ScrollController _scrollController = ScrollController();

  // Scrubbing & trim drag state
  bool _isUserScrubbing = false;
  bool _isDraggingLeft = false;
  bool _isDraggingRight = false;

  @override
  void initState() {
    super.initState();
    widget.notifier.addListener(_onNotifierChange);
  }

  @override
  void didUpdateWidget(MultiVideoTimeline old) {
    super.didUpdateWidget(old);
    if (old.notifier != widget.notifier) {
      old.notifier.removeListener(_onNotifierChange);
      widget.notifier.addListener(_onNotifierChange);
    }
    // Auto-scroll during playback to keep playhead visually centered
    if (widget.isPlaying && widget.globalPositionMs != old.globalPositionMs) {
      _autoScrollToPlayhead();
    }
  }

  void _onNotifierChange() {
    if (mounted) setState(() {});
  }

  double _calculatePlayheadX() {
    final clips = widget.notifier.clips;
    if (clips.isEmpty) return 16.0 + _kHandleWidth;

    final globalMs = widget.globalPositionMs;

    int activeIndex = 0;
    int accumulatedMs = 0;

    for (int i = 0; i < clips.length; i++) {
      final clipDurMs = clips[i].trimmedDuration.inMilliseconds;
      if (globalMs < accumulatedMs + clipDurMs || i == clips.length - 1) {
        activeIndex = i;
        break;
      }
      accumulatedMs += clipDurMs;
    }

    double startOffsetPx = 16.0; // Left margin inside Stack
    for (int i = 0; i < activeIndex; i++) {
      final px = _clipTrimmedPx(clips[i]);
      startOffsetPx += (_kHandleWidth * 2 + px);
    }

    final activeClip = clips[activeIndex];
    final activeClipPx = _clipTrimmedPx(activeClip);
    final activeDurMs = activeClip.trimmedDuration.inMilliseconds;

    double progress = 0.0;
    if (activeDurMs > 0) {
      final playedInsideTrimMs = globalMs - accumulatedMs;
      progress = (playedInsideTrimMs / activeDurMs).clamp(0.0, 1.0);
    }

    final playheadX = startOffsetPx + _kHandleWidth + (progress * activeClipPx);

    debugPrint(
      '[PLAYHEAD DEBUG] globalMs: $globalMs, activeClip: $activeIndex, progress: ${(progress * 100).toStringAsFixed(1)}%, playheadX: $playheadX',
    );

    return playheadX;
  }

  void _onSeekInsideClip(int clipIndex, double progress) {
    _isUserScrubbing = true;
    final clips = widget.notifier.clips;
    if (clipIndex >= clips.length) {
      _isUserScrubbing = false;
      return;
    }
    final clip = clips[clipIndex];

    int accumulatedMs = 0;
    for (int i = 0; i < clipIndex; i++) {
      accumulatedMs += clips[i].trimmedDuration.inMilliseconds;
    }

    final localMs = (clip.trimmedDuration.inMilliseconds * progress).round();
    final globalMs = accumulatedMs + localMs;

    // Call only onGlobalSeek to atomically activate and seek to the exact frame
    widget.onGlobalSeek(globalMs);
    _isUserScrubbing = false;
  }

  void _autoScrollToPlayhead() {
    if (!_scrollController.hasClients || _isUserScrubbing || _isDraggingLeft || _isDraggingRight) return;
    final playheadX = _calculatePlayheadX();
    final screenWidth = MediaQuery.of(context).size.width;
    final currentOffset = _scrollController.offset;

    // Keep playhead within visible screen bounds when video is playing
    if (playheadX > currentOffset + screenWidth - 80) {
      final target = (playheadX - screenWidth + 80).clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.jumpTo(target);
    } else if (playheadX < currentOffset + 20) {
      final target = (playheadX - 20).clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.jumpTo(target);
    }
  }

  double _clipTrimmedPx(EditorClip clip) {
    final secs = clip.trimmedDuration.inMilliseconds / 1000.0;
    return (secs * _kPixelsPerSecond).clamp(_kMinClipPx, double.infinity);
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_onNotifierChange);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clips = widget.notifier.clips;
    final selectedIndex = widget.notifier.selectedIndex;
    final playheadX = _calculatePlayheadX();

    return Container(
      color: const Color(0xFF111113),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Time Ruler ──────────────────────────────────────────────────
          _buildRuler(),
          const SizedBox(height: 4),

          // ── Horizontal Timeline + Moving White Playhead overlay ──────────
          SizedBox(
            height: _kTrackHeight + 20,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: _isDraggingLeft || _isDraggingRight
                  ? const NeverScrollableScrollPhysics()
                  : const ClampingScrollPhysics(),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Row of clip tiles
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ...List.generate(clips.length, (i) {
                          final clip = clips[i];
                          return _ClipTile(
                            clip: clip,
                            clipIndex: i,
                            isSelected: i == selectedIndex,
                            clipPx: _clipTrimmedPx(clip),
                            isMerging: clip.isMerging,
                            onTap: () => widget.onClipSelected(i),
                            onRemove: () => widget.onClipRemoved(i),
                            onSeekInsideClip: (progress) => _onSeekInsideClip(i, progress),
                            onLeftHandleDrag: (delta) => _handleLeftDrag(i, delta),
                            onRightHandleDrag: (delta) => _handleRightDrag(i, delta),
                            onHandleDragStart: (isLeft) {
                              setState(() {
                                _isDraggingLeft = isLeft;
                                _isDraggingRight = !isLeft;
                              });
                            },
                            onHandleDragEnd: () {
                              setState(() {
                                _isDraggingLeft = false;
                                _isDraggingRight = false;
                              });
                            },
                          );
                        }),

                        const SizedBox(width: 8),
                        _AddClipButton(
                          count: clips.length,
                          maxClips: EditorClipListNotifier.maxClips,
                          onTap: clips.length < EditorClipListNotifier.maxClips
                              ? widget.onAddVideo
                              : null,
                        ),
                        const SizedBox(width: 32),
                      ],
                    ),
                  ),

                  // Moving white playhead cursor
                  Positioned(
                    left: playheadX - 6,
                    top: 12,
                    bottom: 0,
                    child: IgnorePointer(
                      child: SizedBox(
                        width: 12,
                        child: Column(
                          children: [
                            CustomPaint(
                              size: const Size(12, 8),
                              painter: _PlayheadArrowPainter(),
                            ),
                            Expanded(
                              child: Center(
                                child: Container(
                                  width: 2.5,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(1.25),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.white54,
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildRuler() {
    final totalSec = widget.notifier.totalTrimmedDuration.inMilliseconds / 1000.0;
    return SizedBox(
      height: 22,
      child: AnimatedBuilder(
        animation: _scrollController,
        builder: (context, child) {
          final scrollOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;
          return CustomPaint(
            size: Size.infinite,
            painter: _RulerPainter(
              totalSeconds: totalSec.clamp(1.0, 3600.0),
              scrollOffset: scrollOffset,
              leftMargin: 16.0,
            ),
          );
        },
      ),
    );
  }

  void _handleLeftDrag(int clipIndex, double delta) {
    final clips = widget.notifier.clips;
    if (clipIndex >= clips.length) return;
    final clip = clips[clipIndex];
    final deltaMs = ((delta / _kPixelsPerSecond) * 1000).round();
    final newStart = clip.trimStart + Duration(milliseconds: deltaMs);
    final clampedStart = newStart.clamp(Duration.zero, clip.trimEnd - const Duration(milliseconds: 500));
    widget.notifier.updateTrim(clipIndex, clampedStart, clip.trimEnd);
    widget.onTrimChanged(clipIndex, clampedStart, clip.trimEnd);
  }

  void _handleRightDrag(int clipIndex, double delta) {
    final clips = widget.notifier.clips;
    if (clipIndex >= clips.length) return;
    final clip = clips[clipIndex];
    final deltaMs = ((delta / _kPixelsPerSecond) * 1000).round();
    final newEnd = clip.trimEnd + Duration(milliseconds: deltaMs);
    final clampedEnd = newEnd.clamp(clip.trimStart + const Duration(milliseconds: 500), clip.originalDuration);
    widget.notifier.updateTrim(clipIndex, clip.trimStart, clampedEnd);
    widget.onTrimChanged(clipIndex, clip.trimStart, clampedEnd);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual Clip Tile
// ─────────────────────────────────────────────────────────────────────────────
class _ClipTile extends StatelessWidget {
  const _ClipTile({
    required this.clip,
    required this.clipIndex,
    required this.isSelected,
    required this.clipPx,
    this.isMerging = false,
    required this.onTap,
    required this.onRemove,
    required this.onSeekInsideClip,
    required this.onLeftHandleDrag,
    required this.onRightHandleDrag,
    required this.onHandleDragStart,
    required this.onHandleDragEnd,
  });

  final EditorClip clip;
  final int clipIndex;
  final bool isSelected;
  final double clipPx;
  final bool isMerging;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final ValueChanged<double> onSeekInsideClip;
  final ValueChanged<double> onLeftHandleDrag;
  final ValueChanged<double> onRightHandleDrag;
  final ValueChanged<bool> onHandleDragStart;
  final VoidCallback onHandleDragEnd;

  static const Color _yellow = Color(0xFFFFD54F);
  static const Color _unselectedBorder = Color(0xFF4A4A5A);

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? _yellow : _unselectedBorder;
    final borderWidth = isSelected ? 2.5 : 1.2;
    final thumbnailCount = (clipPx / 44).clamp(1.0, 20.0).round();

    return GestureDetector(
      onTapUp: (details) {
        if (isMerging || clip.isMerging) return;
        final dx = details.localPosition.dx;
        if (dx >= _kHandleWidth && dx <= clipPx + _kHandleWidth) {
          final tapInsideTrack = dx - _kHandleWidth;
          final progress = (tapInsideTrack / clipPx).clamp(0.0, 1.0);
          onSeekInsideClip(progress);
        } else {
          onTap();
        }
      },
      onPanUpdate: (details) {
        if (!isSelected || isMerging || clip.isMerging) return;
        final dx = details.localPosition.dx;
        if (dx >= _kHandleWidth && dx <= clipPx + _kHandleWidth) {
          final tapInsideTrack = dx - _kHandleWidth;
          final progress = (tapInsideTrack / clipPx).clamp(0.0, 1.0);
          onSeekInsideClip(progress);
        }
      },
      child: SizedBox(
        width: clipPx + _kHandleWidth * 2,
        height: _kTrackHeight + 20,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Selected clip: delete button top-right
            if (isSelected && !isMerging && !clip.isMerging)
              Positioned(
                top: 0,
                right: _kHandleWidth + 2,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_outline, color: Colors.white, size: 10),
                        SizedBox(width: 2),
                        Text(
                          'Remove',
                          style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Main track body at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: _kTrackHeight,
              child: Row(
                children: [
                  // Left trim handle
                  GestureDetector(
                    onPanStart: (_) {
                      if (isMerging || clip.isMerging) return;
                      onHandleDragStart(true);
                    },
                    onPanUpdate: (d) {
                      if (isMerging || clip.isMerging) return;
                      onLeftHandleDrag(d.delta.dx);
                    },
                    onPanEnd: (_) {
                      if (isMerging || clip.isMerging) return;
                      onHandleDragEnd();
                    },
                    child: _Handle(isLeft: true, isSelected: isSelected, color: borderColor),
                  ),

                  // Thumbnail strip with real video frames
                  Expanded(
                    child: _ClipFilmstripStrip(
                      key: ValueKey('${clip.id}_${clip.filePath}'),
                      clip: clip,
                      frameCount: thumbnailCount,
                      borderColor: borderColor,
                      borderWidth: borderWidth,
                      isMerging: isMerging || clip.isMerging,
                    ),
                  ),

                  // Right trim handle
                  GestureDetector(
                    onPanStart: (_) {
                      if (isMerging || clip.isMerging) return;
                      onHandleDragStart(false);
                    },
                    onPanUpdate: (d) {
                      if (isMerging || clip.isMerging) return;
                      onRightHandleDrag(d.delta.dx);
                    },
                    onPanEnd: (_) {
                      if (isMerging || clip.isMerging) return;
                      onHandleDragEnd();
                    },
                    child: _Handle(isLeft: false, isSelected: isSelected, color: borderColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Real Video Filmstrip Strip
// ─────────────────────────────────────────────────────────────────────────────
class _ClipFilmstripStrip extends StatefulWidget {
  const _ClipFilmstripStrip({
    super.key,
    required this.clip,
    required this.frameCount,
    required this.borderColor,
    required this.borderWidth,
    this.isMerging = false,
  });

  final EditorClip clip;
  final int frameCount;
  final Color borderColor;
  final double borderWidth;
  final bool isMerging;

  @override
  State<_ClipFilmstripStrip> createState() => _ClipFilmstripStripState();
}

class _ClipFilmstripStripState extends State<_ClipFilmstripStrip> {
  static final Map<String, List<Uint8List>> _framesCache = {};
  static final Map<String, Uint8List> _singleThumbCache = {};
  static final Set<String> _inFlight = {};
  bool _isLoading = true;

  String _cleanPath(String path) {
    var p = path.trim();
    if (p.startsWith('file://')) {
      p = p.replaceFirst('file://', '');
    }
    return p;
  }

  String _cacheKey() {
    final rawPath = _cleanPath(widget.clip.filePath);
    return VideoThumbnailGenerator.buildCacheKey(
      rawPath,
      trimStart: widget.clip.trimStart,
      trimEnd: widget.clip.trimEnd,
      count: widget.frameCount,
      extra: widget.clip.id,
    );
  }

  @override
  void initState() {
    super.initState();
    final key = _cacheKey();
    final cached = _framesCache[key] ?? VideoThumbnailGenerator.getCachedFilmstripFrames(key);
    if (cached != null && cached.length > 1) {
      _framesCache[key] = cached;
      _singleThumbCache[key] = cached.first;
      _isLoading = false;
    } else {
      _isLoading = true;
      _loadThumbnails();
    }
  }

  @override
  void didUpdateWidget(covariant _ClipFilmstripStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldKey = VideoThumbnailGenerator.buildCacheKey(
      _cleanPath(oldWidget.clip.filePath),
      trimStart: oldWidget.clip.trimStart,
      trimEnd: oldWidget.clip.trimEnd,
      count: oldWidget.frameCount,
      extra: oldWidget.clip.id,
    );
    final newKey = _cacheKey();

    if (oldKey != newKey ||
        oldWidget.clip.isMerging != widget.clip.isMerging ||
        oldWidget.isMerging != widget.isMerging ||
        oldWidget.clip.thumbnailBytes != widget.clip.thumbnailBytes ||
        oldWidget.clip.thumbnailPath != widget.clip.thumbnailPath) {
      final cached = _framesCache[newKey] ?? VideoThumbnailGenerator.getCachedFilmstripFrames(newKey);
      if (cached != null && cached.length > 1) {
        _framesCache[newKey] = cached;
        if (_isLoading) {
          setState(() => _isLoading = false);
        }
      } else {
        _loadThumbnails();
      }
    } else if (_isLoading && _framesCache.containsKey(newKey) && _framesCache[newKey]!.length > 1) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadThumbnails() async {
    final rawPath = _cleanPath(widget.clip.filePath);
    if (rawPath.isEmpty) return;

    final key = _cacheKey();
    final frameCount = widget.frameCount.clamp(1, 15);

    // 1. Instant check if frames already cached for this exact clip and trim interval
    if (_framesCache.containsKey(key) && _framesCache[key]!.length > 1) {
      if (_isLoading && mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    final genCached = VideoThumbnailGenerator.getCachedFilmstripFrames(key);
    if (genCached != null && genCached.length > 1) {
      _framesCache[key] = genCached;
      _singleThumbCache[key] = genCached.first;
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    // 2. Check clip thumbnail bytes for immediate non-empty display while frames extract
    Uint8List? existingThumb = widget.clip.thumbnailBytes ??
        _singleThumbCache[key] ??
        _singleThumbCache[rawPath] ??
        AppImage.getCachedThumbnail(rawPath);

    if (existingThumb == null && widget.clip.thumbnailPath != null && widget.clip.thumbnailPath!.isNotEmpty) {
      try {
        final f = File(_cleanPath(widget.clip.thumbnailPath!));
        if (f.existsSync()) {
          final b = f.readAsBytesSync();
          if (b.isNotEmpty && b.length > 200) {
            existingThumb = b;
          }
        }
      } catch (_) {}
    }

    if (existingThumb != null && existingThumb.isNotEmpty) {
      _singleThumbCache[key] = existingThumb;
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }

    if (_inFlight.contains(key)) return;
    _inFlight.add(key);

    try {
      final frames = await VideoThumbnailGenerator.extractFilmstripFrames(
        rawPath,
        targetCount: frameCount,
        trimStart: widget.clip.trimStart,
        trimEnd: widget.clip.trimEnd,
        duration: widget.clip.originalDuration,
        cacheKeyExtra: widget.clip.id,
      );

      if (frames.isNotEmpty) {
        _framesCache[key] = frames;
        _singleThumbCache[key] = frames.first;
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (_) {
    } finally {
      _inFlight.remove(key);
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildCell(int index, int totalCount, List<Uint8List>? frames) {
    if (frames != null && frames.isNotEmpty) {
      // 1-to-1 mapping if exact frameCount was extracted, otherwise proportional
      final int frameIdx = (frames.length == totalCount)
          ? index.clamp(0, frames.length - 1)
          : ((index / (totalCount <= 1 ? 1 : totalCount - 1)) * (frames.length - 1)).round().clamp(0, frames.length - 1);
      final Uint8List cellBytes = frames[frameIdx];
      return Image.memory(
        cellBytes,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
      );
    }

    final key = _cacheKey();
    final rawPath = _cleanPath(widget.clip.filePath);
    final single = widget.clip.thumbnailBytes ??
        _singleThumbCache[key] ??
        _singleThumbCache[rawPath] ??
        AppImage.getCachedThumbnail(rawPath);
    if (single != null && single.isNotEmpty) {
      return Image.memory(
        single,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
      );
    }

    final thumbPath = widget.clip.thumbnailPath;
    if (thumbPath != null && thumbPath.trim().isNotEmpty) {
      final cleanThumb = _cleanPath(thumbPath);
      final f = File(cleanThumb);
      if (f.existsSync()) {
        return Image.file(
          f,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          gaplessPlayback: true,
        );
      }
    }

    // High quality filmstrip cell placeholder (never spawn video controller in cells)
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1435),
      ),
      child: Center(
        child: Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0x22FFFFFF),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawPath = _cleanPath(widget.clip.filePath);
    final key = _cacheKey();
    final frameCount = widget.frameCount.clamp(1, 15);
    final frames = _framesCache[key] ?? VideoThumbnailGenerator.getCachedFilmstripFrames(key);

    final bool isMergingNow = widget.isMerging || widget.clip.isMerging;
    final bool hasFrames = frames != null && frames.isNotEmpty;
    final bool hasThumbBytes = (widget.clip.thumbnailBytes != null && widget.clip.thumbnailBytes!.isNotEmpty) ||
        _singleThumbCache.containsKey(key) ||
        _singleThumbCache.containsKey(rawPath) ||
        AppImage.getCachedThumbnail(rawPath) != null;
    final bool hasThumbPath = widget.clip.thumbnailPath != null && widget.clip.thumbnailPath!.trim().isNotEmpty;
    final bool hasAnyVisual = hasFrames || hasThumbBytes || hasThumbPath;

    // While merging is active, ALWAYS show the loader in this row.
    // If not merging, show loader ONLY while actively loading frames and no visual is ready.
    final bool showLoader = isMergingNow || (_isLoading && !hasAnyVisual);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF140D24),
        border: Border(
          top: BorderSide(color: widget.borderColor, width: widget.borderWidth),
          bottom: BorderSide(color: widget.borderColor, width: widget.borderWidth),
        ),
      ),
      child: ClipRect(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // When ready: display clean frames/thumbnails across the strip
            if (!showLoader)
              Row(
                children: List.generate(frameCount, (i) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 0.75, vertical: 1.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1435),
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _buildCell(i, frameCount, frames),
                    ),
                  );
                }),
              ),

            // While loading or merging: show ONLY the centered loader (no text)
            if (showLoader)
              Container(
                color: const Color(0xFF140D24),
                child: const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD54F)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Handle Widget
// ─────────────────────────────────────────────────────────────────────────────
class _Handle extends StatelessWidget {
  const _Handle({required this.isLeft, required this.isSelected, required this.color});
  final bool isLeft;
  final bool isSelected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _kHandleWidth,
      height: _kTrackHeight,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isLeft ? 6 : 0),
          bottomLeft: Radius.circular(isLeft ? 6 : 0),
          topRight: Radius.circular(isLeft ? 0 : 6),
          bottomRight: Radius.circular(isLeft ? 0 : 6),
        ),
      ),
      child: Center(
        child: Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Clip Button
// ─────────────────────────────────────────────────────────────────────────────
class _AddClipButton extends StatelessWidget {
  const _AddClipButton({required this.count, required this.maxClips, this.onTap});
  final int count;
  final int maxClips;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: _kAddBtnWidth,
            height: _kTrackHeight * 0.75,
            decoration: BoxDecoration(
              color: disabled ? const Color(0xFF1C1C1E) : const Color(0xFF252530),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: disabled ? Colors.white12 : Colors.white30,
                width: 1.2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_rounded,
                  color: disabled ? Colors.white24 : Colors.white,
                  size: 22,
                ),
                const SizedBox(height: 2),
                Text(
                  '$count/$maxClips',
                  style: TextStyle(
                    color: disabled ? Colors.white24 : Colors.white54,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
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

// ─────────────────────────────────────────────────────────────────────────────
// Ruler CustomPainter
// ─────────────────────────────────────────────────────────────────────────────
class _RulerPainter extends CustomPainter {
  _RulerPainter({
    required this.totalSeconds,
    required this.scrollOffset,
    required this.leftMargin,
  });

  final double totalSeconds;
  final double scrollOffset;
  final double leftMargin;

  @override
  void paint(Canvas canvas, Size size) {
    final tickPaint = Paint()
      ..color = Colors.white30
      ..strokeWidth = 1;
    final bigTickPaint = Paint()
      ..color = Colors.white54
      ..strokeWidth = 1.5;
    final tp = TextPainter(textDirection: ui.TextDirection.ltr);

    // Determine a sensible tick interval
    int tickIntervalSec = 1;
    if (totalSeconds > 60) {
      tickIntervalSec = 10;
    } else if (totalSeconds > 30) {
      tickIntervalSec = 5;
    } else if (totalSeconds > 15) {
      tickIntervalSec = 2;
    }

    final pxPerSec = _kPixelsPerSecond;
    final totalTicks = (totalSeconds / tickIntervalSec).ceil();

    final startOffset = leftMargin + _kHandleWidth;

    final minSecIndex = (((0 - startOffset + scrollOffset) / pxPerSec) / tickIntervalSec).floor().clamp(0, totalTicks);
    final maxSecIndex = (((size.width - startOffset + scrollOffset) / pxPerSec) / tickIntervalSec).ceil().clamp(0, totalTicks);

    for (int i = minSecIndex; i <= maxSecIndex; i++) {
      final sec = i * tickIntervalSec;
      final x = startOffset + (sec * pxPerSec) - scrollOffset;

      final isBig = sec % (tickIntervalSec * 5) == 0 || totalSeconds <= 10;
      final tickH = isBig ? 10.0 : 5.0;
      canvas.drawLine(
        Offset(x, size.height - tickH),
        Offset(x, size.height),
        isBig ? bigTickPaint : tickPaint,
      );

      if (isBig) {
        final label = sec >= 60 ? '${sec ~/ 60}:${(sec % 60).toString().padLeft(2, '0')}' : '${sec}s';
        tp.text = TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 9,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
        );
        tp.layout();
        tp.paint(canvas, Offset((x - tp.width / 2).clamp(0.0, size.width - tp.width), 0));
      }
    }

    // Bottom line
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      Paint()
        ..color = Colors.white12
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_RulerPainter old) =>
      old.totalSeconds != totalSeconds ||
      old.scrollOffset != scrollOffset ||
      old.leftMargin != leftMargin;
}

// ─────────────────────────────────────────────────────────────────────────────
// Playhead Arrow Painter (small downward triangle)
// ─────────────────────────────────────────────────────────────────────────────
class _PlayheadArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PlayheadArrowPainter _) => false;
}
