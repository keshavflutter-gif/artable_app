import 'package:flutter/foundation.dart';

/// Represents a single video clip in the multi-video editor timeline.
class EditorClip {
  EditorClip({
    required this.id,
    required this.filePath,
    required this.originalDuration,
    Duration? trimStart,
    Duration? trimEnd,
  })  : trimStart = trimStart ?? Duration.zero,
        trimEnd = trimEnd ?? originalDuration,
        thumbnailColors = _generateColors(filePath);

  final String id;
  final String filePath;
  final Duration originalDuration;
  Duration trimStart;
  Duration trimEnd;

  /// Stable list of placeholder colors keyed to this clip — used until real
  /// thumbnails are extracted (video_thumbnail is not in pubspec, so we use
  /// representative colored blocks).
  final List<int> thumbnailColors;

  Duration get trimmedDuration {
    final d = trimEnd - trimStart;
    return d.isNegative ? Duration.zero : d;
  }

  bool get isValid => trimEnd > trimStart;

  EditorClip copyWith({
    Duration? trimStart,
    Duration? trimEnd,
  }) {
    return EditorClip(
      id: id,
      filePath: filePath,
      originalDuration: originalDuration,
      trimStart: trimStart ?? this.trimStart,
      trimEnd: trimEnd ?? this.trimEnd,
    );
  }

  /// Generate stable pseudo-random hue values from the file path hash so that
  /// each clip gets a consistent distinctive colour without a thumbnail lib.
  static List<int> _generateColors(String path) {
    final base = path.hashCode.abs();
    return List.generate(8, (i) => (base + i * 37) % 360);
  }
}

/// Notifier that holds the full clip list for the editor.
class EditorClipListNotifier extends ChangeNotifier {
  final List<EditorClip> _clips = [];

  List<EditorClip> get clips => List.unmodifiable(_clips);

  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex.clamp(0, _clips.isEmpty ? 0 : _clips.length - 1);

  EditorClip? get selectedClip => _clips.isEmpty ? null : _clips[selectedIndex];

  static const int maxClips = 10;

  void setClips(List<EditorClip> clips, {int selectedIndex = 0}) {
    _clips
      ..clear()
      ..addAll(clips);
    _selectedIndex = selectedIndex.clamp(0, _clips.isEmpty ? 0 : _clips.length - 1);
    notifyListeners();
  }

  void selectClip(int index) {
    if (index < 0 || index >= _clips.length) return;
    _selectedIndex = index;
    notifyListeners();
  }

  bool addClip(EditorClip clip) {
    if (_clips.length >= maxClips) return false;
    _clips.add(clip);
    _selectedIndex = _clips.length - 1;
    notifyListeners();
    return true;
  }

  void removeClip(int index) {
    if (index < 0 || index >= _clips.length) return;
    _clips.removeAt(index);
    _selectedIndex = (_selectedIndex >= _clips.length
            ? _clips.length - 1
            : _selectedIndex)
        .clamp(0, _clips.isEmpty ? 0 : _clips.length - 1);
    notifyListeners();
  }

  void updateTrim(int index, Duration trimStart, Duration trimEnd) {
    if (index < 0 || index >= _clips.length) return;
    final clip = _clips[index];
    final safeStart = trimStart.clamp(Duration.zero, clip.originalDuration);
    final safeEnd = trimEnd.clamp(const Duration(milliseconds: 500), clip.originalDuration);
    if (safeEnd <= safeStart) return;
    _clips[index] = clip.copyWith(trimStart: safeStart, trimEnd: safeEnd);
    notifyListeners();
  }

  void reorderClip(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _clips.length) return;
    if (newIndex < 0 || newIndex >= _clips.length) return;
    final clip = _clips.removeAt(oldIndex);
    _clips.insert(newIndex, clip);
    _selectedIndex = newIndex;
    notifyListeners();
  }

  /// Total trimmed duration across all clips
  Duration get totalTrimmedDuration {
    Duration total = Duration.zero;
    for (final c in _clips) {
      total += c.trimmedDuration;
    }
    return total;
  }

  /// Given a global millisecond offset, return which clip index contains it,
  /// and the local seek position inside that clip (trimStart + local offset).
  ({int clipIndex, Duration seekPosition}) resolveGlobalMs(int globalMs) {
    int accumulated = 0;
    for (int i = 0; i < _clips.length; i++) {
      final clipMs = _clips[i].trimmedDuration.inMilliseconds;
      if (accumulated + clipMs > globalMs || i == _clips.length - 1) {
        final localMs = (globalMs - accumulated).clamp(0, clipMs);
        final seekPos = _clips[i].trimStart + Duration(milliseconds: localMs);
        return (clipIndex: i, seekPosition: seekPos);
      }
      accumulated += clipMs;
    }
    return (clipIndex: 0, seekPosition: Duration.zero);
  }
}

extension DurationClamp on Duration {
  Duration clamp(Duration min, Duration max) {
    if (this < min) return min;
    if (this > max) return max;
    return this;
  }
}
