import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Playback-speed helpers for studio edit duration display + export.
abstract final class VideoSpeedUtils {
  VideoSpeedUtils._();

  static double parseMultiplier(String? speedLabel) {
    final clean = (speedLabel ?? '1x').replaceAll('x', '').trim();
    final v = double.tryParse(clean) ?? 1.0;
    return v.clamp(0.4, 4.0);
  }

  /// Playback duration from source duration: `source / speed`.
  /// e.g. 30s @ 0.5x → 60s, 30s @ 2x → 15s.
  static Duration adjustedDuration(Duration source, double speed) {
    final s = speed.clamp(0.4, 4.0);
    if (s <= 0) return source;
    final ms = (source.inMilliseconds / s).round();
    return Duration(milliseconds: ms.clamp(0, 24 * 60 * 60 * 1000));
  }

  static int adjustedMs(int sourceMs, double speed) {
    final s = speed.clamp(0.4, 4.0);
    if (s <= 0) return sourceMs;
    return (sourceMs / s).round().clamp(0, 24 * 60 * 60 * 1000);
  }

  static double adjustedSeconds(double sourceSeconds, double speed) {
    final s = speed.clamp(0.4, 4.0);
    if (s <= 0) return sourceSeconds;
    return sourceSeconds / s;
  }

  static String formatMs(int ms) {
    final sec = (ms / 1000).floor().clamp(0, 360000);
    final m = sec ~/ 60;
    final s = sec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  static String formatDuration(Duration d) => formatMs(d.inMilliseconds);

  /// `atempo` only accepts 0.5–2.0; chain filters for 0.4x / 3x / 4x etc.
  static String atempoFilterChain(double speed) {
    final target = speed.clamp(0.4, 4.0);
    final factors = <double>[];
    var remaining = target;
    while (remaining > 2.0 + 1e-6) {
      factors.add(2.0);
      remaining /= 2.0;
    }
    while (remaining < 0.5 - 1e-6) {
      factors.add(0.5);
      remaining /= 0.5;
    }
    factors.add(double.parse(remaining.toStringAsFixed(4)));
    return factors.map((f) => 'atempo=${f.toStringAsFixed(4)}').join(',');
  }

  /// Returns a new MP4 with video+audio running at [speed] (baked in).
  /// No-op (null) when speed ≈ 1.0 or input is remote/missing.
  static Future<File?> applySpeedToFile(
    String inputPath,
    double speed, {
    bool muteOriginalAudio = false,
  }) async {
    final s = speed.clamp(0.4, 4.0);
    final speedChanged = (s - 1.0).abs() >= 0.01;
    if (!speedChanged && !muteOriginalAudio) return null;

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
    if (!await input.exists() || await input.length() <= 0) {
      return null;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${tempDir.path}/studio_speed');
      if (!cacheDir.existsSync()) {
        cacheDir.createSync(recursive: true);
      }

      final key = md5
          .convert(utf8.encode(
            '${input.absolute.path}|$s|mute=$muteOriginalAudio|v1',
          ))
          .toString();
      final outFile = File('${cacheDir.path}/speed_$key.mp4');
      if (await outFile.exists() && (await outFile.length()) > 1024) {
        return outFile;
      }

      // Faster playback → smaller PTS; slower → larger PTS.
      final setpts = speedChanged ? 'setpts=PTS/$s' : 'setpts=PTS-STARTPTS';
      late final List<String> args;
      if (!speedChanged && muteOriginalAudio) {
        // Mute only — stream-copy video when possible.
        args = <String>[
          '-y',
          '-i',
          input.path,
          '-c:v',
          'copy',
          '-an',
          '-movflags',
          '+faststart',
          outFile.path,
        ];
      } else if (muteOriginalAudio) {
        args = <String>[
          '-y',
          '-i',
          input.path,
          '-filter:v',
          setpts,
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
      } else {
        args = <String>[
          '-y',
          '-i',
          input.path,
          '-filter_complex',
          '[0:v]$setpts[v];[0:a]${atempoFilterChain(s)}[a]',
          '-map',
          '[v]',
          '-map',
          '[a]',
          '-c:a',
          'aac',
          '-b:a',
          '128k',
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
      }

      debugPrint('VideoSpeedUtils: ${args.join(' ')}');
      var session = await FFmpegKit.executeWithArguments(args);
      var code = await session.getReturnCode();

      // Retry without audio if source has no audio stream.
      if (!ReturnCode.isSuccess(code) && !muteOriginalAudio && speedChanged) {
        final retryArgs = <String>[
          '-y',
          '-i',
          input.path,
          '-filter:v',
          setpts,
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
        debugPrint('VideoSpeedUtils: retry video-only');
        session = await FFmpegKit.executeWithArguments(retryArgs);
        code = await session.getReturnCode();
      }

      if (!ReturnCode.isSuccess(code)) {
        final logs = await session.getAllLogsAsString();
        debugPrint('VideoSpeedUtils: failed code=$code logs=$logs');
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
      debugPrint('VideoSpeedUtils: error: $e');
      return null;
    }
  }
}
