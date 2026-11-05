import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Local FFmpeg helpers to bake editor trim ranges into MP4 files.
abstract final class VideoTrimUtils {
  VideoTrimUtils._();

  /// Cuts [inputPath] to `[startSeconds, endSeconds)`.
  /// Returns null when trim is a no-op / remote / failed.
  static Future<File?> trimFile(
    String inputPath, {
    required double startSeconds,
    required double endSeconds,
  }) async {
    final start = startSeconds < 0 ? 0.0 : startSeconds;
    final end = endSeconds;
    if (end <= start + 0.05) return null;

    var clean = inputPath.trim();
    if (clean.startsWith('file://')) {
      clean = clean.replaceFirst('file://', '');
    }
    if (clean.isEmpty ||
        clean.startsWith('http://') ||
        clean.startsWith('https://')) {
      return null;
    }

    final input = File(clean);
    if (!await input.exists() || await input.length() <= 0) return null;

    // Near full-file trim — skip re-encode.
    // (Caller still gets original path when we return null.)
    if (start < 0.05) {
      // Still need end cut unless end covers whole file — unknown without probe,
      // so always cut when start/end provided meaningfully.
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${tempDir.path}/studio_trim');
      if (!cacheDir.existsSync()) {
        cacheDir.createSync(recursive: true);
      }

      final key = md5
          .convert(utf8.encode(
            '${input.absolute.path}|$start|$end|v1',
          ))
          .toString();
      final outFile = File('${cacheDir.path}/trim_$key.mp4');
      if (await outFile.exists() && (await outFile.length()) > 1024) {
        return outFile;
      }

      final duration = (end - start).clamp(0.1, 36000.0);
      // Accurate cut: decode from start, stop at duration.
      final args = <String>[
        '-y',
        '-ss',
        start.toStringAsFixed(3),
        '-i',
        input.path,
        '-t',
        duration.toStringAsFixed(3),
        '-c:v',
        'libx264',
        '-preset',
        'ultrafast',
        '-crf',
        '26',
        '-pix_fmt',
        'yuv420p',
        '-c:a',
        'aac',
        '-b:a',
        '128k',
        '-movflags',
        '+faststart',
        outFile.path,
      ];

      debugPrint('VideoTrimUtils: ${args.join(' ')}');
      var session = await FFmpegKit.executeWithArguments(args);
      var code = await session.getReturnCode();

      if (!ReturnCode.isSuccess(code)) {
        // Retry video-only (source may lack audio).
        final retryArgs = <String>[
          '-y',
          '-ss',
          start.toStringAsFixed(3),
          '-i',
          input.path,
          '-t',
          duration.toStringAsFixed(3),
          '-an',
          '-c:v',
          'libx264',
          '-preset',
          'ultrafast',
          '-crf',
          '26',
          '-pix_fmt',
          'yuv420p',
          '-movflags',
          '+faststart',
          outFile.path,
        ];
        debugPrint('VideoTrimUtils: retry video-only');
        session = await FFmpegKit.executeWithArguments(retryArgs);
        code = await session.getReturnCode();
      }

      if (!ReturnCode.isSuccess(code)) {
        final logs = await session.getAllLogsAsString();
        debugPrint('VideoTrimUtils: failed code=$code logs=$logs');
        try {
          if (await outFile.exists()) await outFile.delete();
        } catch (_) {}
        return null;
      }
      if (!await outFile.exists() || (await outFile.length()) <= 1024) {
        return null;
      }
      return outFile;
    } catch (e) {
      debugPrint('VideoTrimUtils: error: $e');
      return null;
    }
  }

  /// Trims each local path when start/end lists are present and meaningful.
  static Future<List<String>> bakeClipTrims({
    required List<String> paths,
    List<double>? trimStarts,
    List<double>? trimEnds,
    List<double>? trimmedDurations,
  }) async {
    if (paths.isEmpty) return paths;
    final out = <String>[];
    for (var i = 0; i < paths.length; i++) {
      final path = paths[i];
      final start = (trimStarts != null && i < trimStarts.length)
          ? trimStarts[i]
          : 0.0;
      double? end;
      if (trimEnds != null && i < trimEnds.length) {
        end = trimEnds[i];
      } else if (trimmedDurations != null && i < trimmedDurations.length) {
        end = start + trimmedDurations[i];
      }
      if (end == null || end <= start + 0.05 || start < 0.05 && end > 36000) {
        out.add(path);
        continue;
      }
      // Skip bake when start≈0 and we don't know original length — still bake
      // when start > 0 or when end is clearly a short clip of a longer source.
      final needsTrim = start > 0.05 ||
          (trimmedDurations != null &&
              i < trimmedDurations.length &&
              trimmedDurations[i] > 0 &&
              end - start <= trimmedDurations[i] + 0.05);
      if (!needsTrim && start < 0.05) {
        // When start is 0, still trim to end so long tails are removed.
      }
      final trimmed = await trimFile(
        path,
        startSeconds: start,
        endSeconds: end,
      );
      out.add(trimmed?.path ?? path);
      if (trimmed != null) {
        debugPrint('VideoTrimUtils: baked clip $i $path → ${trimmed.path}');
      }
    }
    return out;
  }
}
