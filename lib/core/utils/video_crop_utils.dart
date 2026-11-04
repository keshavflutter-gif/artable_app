import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Center-crop helpers for studio edit preview + export.
abstract final class VideoCropUtils {
  VideoCropUtils._();

  static const supportedRatios = ['9:16', '1:1', '4:5', '16:9'];

  /// Width / height for the selected crop id.
  static double aspectRatioValue(String? cropId) {
    switch (normalize(cropId)) {
      case '1:1':
        return 1.0;
      case '4:5':
        return 4 / 5;
      case '16:9':
        return 16 / 9;
      case '9:16':
      default:
        return 9 / 16;
    }
  }

  static String normalize(String? cropId) {
    final v = (cropId ?? '').trim();
    if (supportedRatios.contains(v)) return v;
    return '9:16';
  }

  static (int tw, int th) ratioParts(String? cropId) {
    switch (normalize(cropId)) {
      case '1:1':
        return (1, 1);
      case '4:5':
        return (4, 5);
      case '16:9':
        return (16, 9);
      case '9:16':
      default:
        return (9, 16);
    }
  }

  /// Returns a new MP4 center-cropped to [cropAspectRatio] (no stretch).
  /// Skips work when [inputPath] is remote/missing; returns null on failure.
  static Future<File?> centerCropToAspect(
    String inputPath,
    String? cropAspectRatio,
  ) async {
    final ratioId = normalize(cropAspectRatio);
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
      final cacheDir = Directory('${tempDir.path}/studio_cropped');
      if (!cacheDir.existsSync()) {
        cacheDir.createSync(recursive: true);
      }

      final key = md5
          .convert(utf8.encode('${input.absolute.path}|$ratioId|v1'))
          .toString();
      final outFile = File('${cacheDir.path}/crop_$key.mp4');
      if (await outFile.exists() && (await outFile.length()) > 1024) {
        return outFile;
      }

      final (tw, th) = ratioParts(ratioId);
      // Center crop to target aspect, then force even H.264 dimensions.
      final vf =
          'crop=min(iw\\,ih*$tw/$th):min(ih\\,iw*$th/$tw):(iw-ow)/2:(ih-oh)/2,'
          'scale=trunc(iw/2)*2:trunc(ih/2)*2';

      final args = <String>[
        '-y',
        '-i',
        input.path,
        '-vf',
        vf,
        '-c:v',
        'libx264',
        '-preset',
        'veryfast',
        '-crf',
        '23',
        '-pix_fmt',
        'yuv420p',
        '-c:a',
        'copy',
        '-movflags',
        '+faststart',
        outFile.path,
      ];

      debugPrint('VideoCropUtils: ${args.join(' ')}');
      final session = await FFmpegKit.executeWithArguments(args);
      final code = await session.getReturnCode();
      if (!ReturnCode.isSuccess(code)) {
        // Some clips have no audio → retry without stream copy.
        final argsNoAudio = <String>[
          '-y',
          '-i',
          input.path,
          '-vf',
          vf,
          '-c:v',
          'libx264',
          '-preset',
          'veryfast',
          '-crf',
          '23',
          '-pix_fmt',
          'yuv420p',
          '-an',
          '-movflags',
          '+faststart',
          outFile.path,
        ];
        debugPrint('VideoCropUtils: retry without audio');
        final retry = await FFmpegKit.executeWithArguments(argsNoAudio);
        final retryCode = await retry.getReturnCode();
        if (!ReturnCode.isSuccess(retryCode)) {
          final logs = await retry.getAllLogsAsString();
          debugPrint('VideoCropUtils: crop failed code=$retryCode logs=$logs');
          try {
            if (await outFile.exists()) await outFile.delete();
          } catch (_) {}
          return null;
        }
      }

      if (!await outFile.exists() || (await outFile.length()) <= 1024) {
        return null;
      }
      return outFile;
    } catch (e) {
      debugPrint('VideoCropUtils: crop error: $e');
      return null;
    }
  }
}
