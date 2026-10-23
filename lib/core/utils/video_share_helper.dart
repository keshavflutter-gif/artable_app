import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:artable_app/core/utils/media_url_utils.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:artable_app/features/trending/data/repositories/videos_repository.dart';

class DownloadCancellation {
  bool isCancelled = false;
  VoidCallback? onCancel;

  void cancel() {
    isCancelled = true;
    onCancel?.call();
  }
}

abstract final class VideoShareHelper {
  VideoShareHelper._();

  static final Map<String, Future<File?>> _inFlightDownloads = {};
  static final Map<String, ValueNotifier<double>> _downloadProgress = {};

  /// Pre-caches a remote video in the background silently without showing any UI or dialog.
  /// Note: Only downloads if a direct media link is already known. Never triggers the /share API.
  static Future<File?> precacheVideo(String? videoUrl, {String? videoId}) async {
    final cleanUrl = MediaUrlUtils.resolve(videoUrl ?? '').trim();
    if (cleanUrl.isEmpty || (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://'))) {
      return null;
    }

    final lowerUrl = cleanUrl.toLowerCase();
    final isDirectMedia = lowerUrl.contains('.mp4') ||
        lowerUrl.contains('.mov') ||
        lowerUrl.contains('.webm') ||
        lowerUrl.contains('.3gp') ||
        lowerUrl.contains('/videos/') ||
        lowerUrl.contains('.r2.dev/');

    if (!isDirectMedia) {
      return null;
    }

    return _downloadAndCacheVideo(null, cleanUrl);
  }

  /// Share video file according to option ('copy', 'whatsapp', 'sms', 'email', 'social')
  /// Returns true if the share action was successfully launched.
  static Future<bool> shareVideo({
    required BuildContext context,
    required String optionId,
    required String videoUrl,
    String? videoId,
    String? title,
    String? caption,
    bool isApiAlreadyRecorded = false,
  }) async {
    final cleanVideoId = videoId?.trim();
    String resolvedUrl = MediaUrlUtils.resolve(videoUrl);
    String? resolvedTitle = title?.trim();
    String? resolvedCaption = caption?.trim();

    // 1. If API was not already called and URL is not a direct media link, call /share API
    final isNotDirect = resolvedUrl.isEmpty ||
        (!resolvedUrl.toLowerCase().contains('.mp4') &&
         !resolvedUrl.toLowerCase().contains('.mov') &&
         !resolvedUrl.toLowerCase().contains('.webm') &&
         !resolvedUrl.toLowerCase().contains('.3gp') &&
         !resolvedUrl.contains('/videos/') &&
         !resolvedUrl.contains('.r2.dev/'));

    if (!isApiAlreadyRecorded && isNotDirect && cleanVideoId != null && cleanVideoId.isNotEmpty) {
      try {
        final repo = VideosRepository();
        final shareRes = await repo.shareVideo(videoId: cleanVideoId);
        debugPrint('VideoShareHelper: /share API response: $shareRes');
        if (shareRes['success'] == true && shareRes['data'] is Map<String, dynamic>) {
          final data = shareRes['data'] as Map<String, dynamic>;
          final returnedUrl = data['videoUrl']?.toString();
          if (returnedUrl != null && returnedUrl.trim().isNotEmpty) {
            resolvedUrl = MediaUrlUtils.resolve(returnedUrl.trim());
          }
          if (resolvedTitle == null || resolvedTitle.isEmpty) {
            resolvedTitle = data['title']?.toString().trim();
          }
          if (resolvedCaption == null || resolvedCaption.isEmpty) {
            resolvedCaption = data['description']?.toString().trim();
          }
        }
      } catch (e) {
        debugPrint('VideoShareHelper: shareVideo API error: $e');
      }
    }

    final shareText = (resolvedCaption != null && resolvedCaption.isNotEmpty)
        ? resolvedCaption
        : (resolvedTitle != null && resolvedTitle.isNotEmpty)
            ? resolvedTitle
            : 'Check out this video on Artable!';

    // Direct Copy Link Handling
    if (optionId == 'copy') {
      final copyText = resolvedUrl.isNotEmpty
          ? resolvedUrl
          : (cleanVideoId != null && cleanVideoId.isNotEmpty
              ? 'https://artable.app/video/$cleanVideoId'
              : 'https://artable.app');
      await Clipboard.setData(ClipboardData(text: copyText));
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Link copied to clipboard!'),
              ],
            ),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFF8B3DFF),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return true;
    }

    final isRemote = resolvedUrl.startsWith('http://') || resolvedUrl.startsWith('https://');
    final isLocal = resolvedUrl.isNotEmpty && File(resolvedUrl).existsSync();

    // Direct SMS Handling
    if (optionId == 'sms') {
      final smsBody = isRemote ? '$shareText\n$resolvedUrl' : shareText;
      final smsUri = Uri(scheme: 'sms', queryParameters: {'body': smsBody});
      try {
        if (await canLaunchUrl(smsUri)) {
          return await launchUrl(smsUri);
        }
      } catch (e) {
        debugPrint('VideoShareHelper: SMS launch error: $e');
      }
      return false;
    }

    // Direct Email Handling
    if (optionId == 'email') {
      final emailSubject = resolvedTitle ?? 'Check out this video on Artable';
      final emailBody = isRemote ? '$shareText\n\nWatch here: $resolvedUrl' : shareText;
      final emailUri = Uri(
        scheme: 'mailto',
        queryParameters: {
          'subject': emailSubject,
          'body': emailBody,
        },
      );
      try {
        if (await canLaunchUrl(emailUri)) {
          return await launchUrl(emailUri);
        }
      } catch (e) {
        debugPrint('VideoShareHelper: Email launch error: $e');
      }
      return false;
    }

    // File-based Video Sharing (WhatsApp & Social Share)
    if (!isRemote && !isLocal) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video is not available to share.')),
        );
      }
      return false;
    }

    if (!context.mounted) return false;

    // Get or download video file into local cache with cancellation support
    final cancellation = DownloadCancellation();
    File? videoFile;
    if (isRemote) {
      videoFile = await _downloadAndCacheVideo(context, resolvedUrl, cancellation: cancellation);
      if (cancellation.isCancelled || videoFile == null) {
        debugPrint('VideoShareHelper: User cancelled or videoFile is null. Share aborted.');
        return false;
      }
    } else {
      videoFile = File(resolvedUrl);
    }

    if (cancellation.isCancelled) {
      return false;
    }

    final fileExists = await videoFile.exists();
    final fileLen = fileExists ? await videoFile.length() : 0;
    if (!fileExists || fileLen <= 0) {
      if (!cancellation.isCancelled && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not prepare video file.')),
        );
      }
      return false;
    }

    if (cancellation.isCancelled) {
      return false;
    }

    // Detect proper mime-type and file name
    String mimeType = 'video/mp4';
    String fileName = 'artable_video.mp4';
    final lowerPath = videoFile.path.toLowerCase();
    if (lowerPath.endsWith('.mov')) {
      mimeType = 'video/quicktime';
      fileName = 'artable_video.mov';
    } else if (lowerPath.endsWith('.webm')) {
      mimeType = 'video/webm';
      fileName = 'artable_video.webm';
    } else if (lowerPath.endsWith('.3gp')) {
      mimeType = 'video/3gpp';
      fileName = 'artable_video.3gp';
    }

    final xFile = XFile(
      videoFile.path,
      mimeType: mimeType,
      name: fileName,
    );

    final rawCaption = (caption != null && caption.trim().isNotEmpty)
        ? caption.trim()
        : (title != null && title.trim().isNotEmpty)
            ? title.trim()
            : null;

    // Strictly ensure no URLs are in caption for WhatsApp video sharing
    final videoCaption = (rawCaption != null &&
            !rawCaption.contains('http://') &&
            !rawCaption.contains('https://') &&
            !rawCaption.contains('artable.app') &&
            !rawCaption.contains('.r2.dev'))
        ? rawCaption
        : null;

    // 1. Direct WhatsApp Sharing with video file
    if (optionId == 'whatsapp') {
      if (Platform.isAndroid) {
        try {
          const channel = MethodChannel('com.artable/whatsapp_share');
          final bool? launchedDirectly = await channel.invokeMethod<bool>(
            'shareVideoToWhatsApp',
            {
              'filePath': videoFile.path,
              'text': videoCaption,
            },
          );
          if (launchedDirectly == true) {
            return true;
          }
        } catch (e) {
          debugPrint('VideoShareHelper: Direct WhatsApp intent error: $e');
        }
      }

      // Fallback: share video file via SharePlus
      try {
        if (!context.mounted) return false;
        final box = context.findRenderObject() as RenderBox?;
        final origin = (box != null && box.hasSize && box.size.width > 0 && box.size.height > 0)
            ? box.localToGlobal(Offset.zero) & box.size
            : null;

        await SharePlus.instance.share(
          ShareParams(
            files: [xFile],
            text: videoCaption,
            subject: title,
            title: title ?? 'Share video',
            sharePositionOrigin: origin,
          ),
        );
        return true;
      } catch (e) {
        debugPrint('VideoShareHelper: Fallback share error: $e');
        return false;
      }
    }

    // 2. Social Share / System Sheet
    try {
      if (!context.mounted) return false;
      final box = context.findRenderObject() as RenderBox?;
      final origin = (box != null && box.hasSize && box.size.width > 0 && box.size.height > 0)
          ? box.localToGlobal(Offset.zero) & box.size
          : null;

      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          text: videoCaption,
          subject: title,
          title: title ?? 'Share video',
          sharePositionOrigin: origin,
        ),
      );
      return true;
    } catch (e) {
      debugPrint('VideoShareHelper: Social share error: $e');
      return false;
    }
  }

  /// Downloads network video to a local cache file (streamed, safe atomic write, timeout).
  static Future<File?> _downloadAndCacheVideo(
    BuildContext? context,
    String url, {
    DownloadCancellation? cancellation,
  }) async {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) return null;

    final urlHash = md5.convert(utf8.encode(cleanUrl)).toString();

    // 1. Check if download is already in progress
    if (_inFlightDownloads.containsKey(urlHash)) {
      if (context != null && context.mounted) {
        final existingNotifier = _downloadProgress[urlHash];
        if (existingNotifier != null) {
          _showProgressDialog(context, existingNotifier, () {
            cancellation?.cancel();
          });
        }
      }
      final file = await _inFlightDownloads[urlHash]!;
      if (cancellation?.isCancelled == true) {
        return null;
      }
      return file;
    }

    // 2. Check if complete cached file already exists in shared_videos directory (> 1 KB)
    final tempDir = await getTemporaryDirectory();
    final videoCacheDir = Directory('${tempDir.path}/shared_videos');
    if (!videoCacheDir.existsSync()) {
      try {
        videoCacheDir.createSync(recursive: true);
      } catch (_) {}
    }

    final targetFile = File('${videoCacheDir.path}/cached_video_$urlHash.mp4');
    if (await targetFile.exists() && (await targetFile.length()) > 1024) {
      return targetFile;
    }

    // 3. Check alternative cache paths
    final altPaths = [
      File('${tempDir.path}/share_plus/cached_video_$urlHash.mp4'),
      File('${tempDir.path}/cached_video_$urlHash.mp4'),
      File('${tempDir.path}/vclip_$urlHash.mp4'),
      File('${tempDir.path}/vdl_${cleanUrl.hashCode.abs()}.mp4'),
      File('${tempDir.parent.path}/cache/vdl_${cleanUrl.hashCode.abs()}.mp4'),
    ];
    for (final alt in altPaths) {
      if (await alt.exists() && (await alt.length()) > 1024) {
        try {
          await alt.copy(targetFile.path);
          return targetFile;
        } catch (_) {
          return alt;
        }
      }
    }

    if (context != null && !context.mounted) return null;
    final progressNotifier = ValueNotifier<double>(0.0);
    _downloadProgress[urlHash] = progressNotifier;

    final downloadFuture = _executeDownload(
      context,
      cleanUrl,
      urlHash,
      progressNotifier,
      cancellation: cancellation,
    );
    _inFlightDownloads[urlHash] = downloadFuture;

    try {
      final file = await downloadFuture;
      if (cancellation?.isCancelled == true) {
        return null;
      }
      return file;
    } finally {
      _inFlightDownloads.remove(urlHash);
      _downloadProgress.remove(urlHash);
    }
  }

  static void _showProgressDialog(
    BuildContext context,
    ValueNotifier<double> progressNotifier,
    VoidCallback onCancel,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (dCtx) {
        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) onCancel();
          },
          child: Dialog(
            backgroundColor: const Color(0xFF1E1E24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ValueListenableBuilder<double>(
                valueListenable: progressNotifier,
                builder: (context, progress, _) {
                  final percent = (progress * 100).clamp(0, 100).toInt();
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                        'Preparing Video',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        percent > 0 ? '$percent% ready for WhatsApp' : 'Connecting to download...',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                      ),
                      const SizedBox(height: 18),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress > 0 ? progress : null,
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B3DFF)),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          onCancel();
                          Navigator.of(dCtx).pop();
                        },
                        child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<File?> _executeDownload(
    BuildContext? context,
    String url,
    String urlHash,
    ValueNotifier<double> progressNotifier, {
    DownloadCancellation? cancellation,
  }) async {
    File? tmpFile;
    HttpClient? client;
    BuildContext? dialogContext;

    cancellation?.onCancel = () {
      client?.close(force: true);
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!).pop();
      }
    };

    try {
      final tempDir = await getTemporaryDirectory();
      final videoCacheDir = Directory('${tempDir.path}/shared_videos');
      if (!videoCacheDir.existsSync()) {
        try {
          videoCacheDir.createSync(recursive: true);
        } catch (_) {}
      }

      final targetFile = File('${videoCacheDir.path}/cached_video_$urlHash.mp4');

      final parsedUri = Uri.tryParse(url) ?? Uri.tryParse(Uri.encodeFull(url));
      if (parsedUri == null) {
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid video URL format.')),
          );
        }
        return null;
      }

      if (context != null && context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: true,
          barrierColor: Colors.black54,
          builder: (dCtx) {
            dialogContext = dCtx;
            return PopScope(
              canPop: true,
              onPopInvokedWithResult: (didPop, _) {
                if (didPop) {
                  cancellation?.cancel();
                  client?.close(force: true);
                }
              },
              child: Dialog(
                backgroundColor: const Color(0xFF1E1E24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: ValueListenableBuilder<double>(
                    valueListenable: progressNotifier,
                    builder: (context, progress, _) {
                      final percent = (progress * 100).clamp(0, 100).toInt();
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 8),
                          const Text(
                            'Preparing Video',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            percent > 0 ? '$percent% ready for WhatsApp' : 'Connecting to download...',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                          ),
                          const SizedBox(height: 18),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progress > 0 ? progress : null,
                              backgroundColor: Colors.white12,
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B3DFF)),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              cancellation?.cancel();
                              client?.close(force: true);
                              Navigator.of(dCtx).pop();
                            },
                            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      }

      if (cancellation?.isCancelled == true) {
        return null;
      }

      // Fast streaming download
      client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 25)
        ..idleTimeout = const Duration(seconds: 25)
        ..badCertificateCallback = ((cert, host, port) => true);

      final request = await client.getUrl(parsedUri);
      request.headers.set(HttpHeaders.userAgentHeader,
          'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36');
      request.headers.set(HttpHeaders.acceptHeader, '*/*');

      final response = await request.close().timeout(const Duration(seconds: 40));

      if (cancellation?.isCancelled == true) {
        return null;
      }

      if (response.statusCode != 200) {
        if (dialogContext != null && dialogContext!.mounted) {
          Navigator.of(dialogContext!).pop();
        }
        if (cancellation?.isCancelled != true && context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not download video file.')),
          );
        }
        return null;
      }

      tmpFile = File('${videoCacheDir.path}/temp_${urlHash}_${DateTime.now().millisecondsSinceEpoch}.tmp');
      final sink = tmpFile.openWrite(mode: FileMode.writeOnly);
      final totalBytes = response.contentLength;
      int receivedBytes = 0;
      int lastReportedPercent = -1;

      try {
        await for (final chunk in response.timeout(const Duration(minutes: 3))) {
          if (cancellation?.isCancelled == true) {
            break;
          }
          sink.add(chunk);
          receivedBytes += chunk.length;
          if (totalBytes > 0) {
            final pct = ((receivedBytes / totalBytes) * 100).toInt();
            if (pct != lastReportedPercent && pct % 2 == 0) {
              lastReportedPercent = pct;
              progressNotifier.value = receivedBytes / totalBytes;
            }
          }
        }
      } finally {
        await sink.flush();
        await sink.close();
      }

      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!).pop();
      }

      if (cancellation?.isCancelled == true) {
        if (await tmpFile.exists()) {
          try {
            await tmpFile.delete();
          } catch (_) {}
        }
        return null;
      }

      if (!await tmpFile.exists() || (await tmpFile.length()) <= 0) {
        if (await tmpFile.exists()) {
          try {
            await tmpFile.delete();
          } catch (_) {}
        }
        if (cancellation?.isCancelled != true && context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not download video file.')),
          );
        }
        return null;
      }

      // Successfully downloaded: atomically rename to final target file
      if (await targetFile.exists()) {
        try {
          await targetFile.delete();
        } catch (_) {}
      }
      await tmpFile.rename(targetFile.path);
      return targetFile;
    } catch (e) {
      debugPrint('VideoShareHelper: Error downloading video ($url): $e');
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!).pop();
      }
      if (tmpFile != null && await tmpFile.exists()) {
        try {
          await tmpFile.delete();
        } catch (_) {}
      }
      if (cancellation?.isCancelled != true && context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not download video. Please check your internet connection.')),
        );
      }
      return null;
    } finally {
      client?.close(force: true);
    }
  }
}
