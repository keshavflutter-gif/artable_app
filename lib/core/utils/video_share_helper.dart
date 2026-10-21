import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:artable_app/core/utils/media_url_utils.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

abstract final class VideoShareHelper {
  VideoShareHelper._();

  static final Map<String, Future<File?>> _inFlightDownloads = {};

  /// Share video file according to option ('copy', 'whatsapp', 'sms', 'email', 'social')
  static Future<void> shareVideo({
    required BuildContext context,
    required String optionId,
    required String videoUrl,
    String? title,
    String? caption,
  }) async {
    final resolvedUrl = MediaUrlUtils.resolve(videoUrl);
    final shareText = (caption != null && caption.trim().isNotEmpty)
        ? caption.trim()
        : (title != null && title.trim().isNotEmpty)
            ? title.trim()
            : 'Check out this video on Artable!';

    if (optionId == 'copy') {
      final copyText = resolvedUrl.isNotEmpty
          ? resolvedUrl
          : 'https://artable.app/video';
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
      return;
    }

    final isRemote = resolvedUrl.startsWith('http://') ||
        resolvedUrl.startsWith('https://');
    final isLocal = resolvedUrl.isNotEmpty && File(resolvedUrl).existsSync();

    // 1. WhatsApp Direct Sharing Handling
    if (optionId == 'whatsapp') {
      final messageWithUrl = isRemote
          ? (resolvedUrl.isNotEmpty ? '$shareText\n$resolvedUrl' : shareText)
          : shareText;

      // If remote or no local file yet, launch WhatsApp directly via URL scheme
      if (isRemote || !isLocal) {
        final encoded = Uri.encodeComponent(messageWithUrl);
        final whatsappNativeUri = Uri.parse('whatsapp://send?text=$encoded');
        final whatsappWebUri = Uri.parse('https://api.whatsapp.com/send?text=$encoded');

        bool launched = false;
        try {
          if (await canLaunchUrl(whatsappNativeUri)) {
            launched = await launchUrl(whatsappNativeUri, mode: LaunchMode.externalApplication);
          } else if (await canLaunchUrl(whatsappWebUri)) {
            launched = await launchUrl(whatsappWebUri, mode: LaunchMode.externalApplication);
          }
        } catch (e) {
          debugPrint('VideoShareHelper: Direct WhatsApp launch error: $e');
        }

        if (launched) return;
        // If not launched directly, continue below to file sharing fallback
      }
    }

    // 2. SMS Direct Handling
    if (optionId == 'sms') {
      final smsBody = isRemote ? '$shareText\n$resolvedUrl' : shareText;
      final smsUri = Uri(scheme: 'sms', queryParameters: {'body': smsBody});
      try {
        if (await canLaunchUrl(smsUri)) {
          final launched = await launchUrl(smsUri);
          if (launched) return;
        }
      } catch (e) {
        debugPrint('VideoShareHelper: SMS launch error: $e');
      }
    }

    // 3. Email Direct Handling
    if (optionId == 'email') {
      final emailSubject = title ?? 'Check out this video on Artable';
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
          final launched = await launchUrl(emailUri);
          if (launched) return;
        }
      } catch (e) {
        debugPrint('VideoShareHelper: Email launch error: $e');
      }
    }

    // 4. File-based Sharing (Social, Local WhatsApp, or System Sheet fallback)
    if (!isRemote && !isLocal) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video is not available to share.')),
        );
      }
      return;
    }

    if (!context.mounted) return;

    File? videoFile;
    if (isRemote) {
      videoFile = await _downloadAndCacheVideo(context, resolvedUrl);
      if (videoFile == null) return;
    } else {
      videoFile = File(resolvedUrl);
    }

    if (!await videoFile.exists() || (await videoFile.length()) <= 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not prepare video file.')),
        );
      }
      return;
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

    if (!context.mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    final origin = (box != null && box.hasSize && box.size.width > 0 && box.size.height > 0)
        ? box.localToGlobal(Offset.zero) & box.size
        : null;

    final shareCaption = isRemote && resolvedUrl.isNotEmpty
        ? '$shareText\n$resolvedUrl'
        : shareText;

    await SharePlus.instance.share(
      ShareParams(
        files: [xFile],
        text: shareCaption,
        subject: title,
        title: title ?? 'Share video',
        sharePositionOrigin: origin,
      ),
    );
  }

  /// Downloads network video to a local cache file (streamed, safe atomic write, timeout).
  static Future<File?> _downloadAndCacheVideo(
    BuildContext context,
    String url,
  ) async {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) return null;

    final urlHash = md5.convert(utf8.encode(cleanUrl)).toString();

    // Check if download is already in progress for this URL
    if (_inFlightDownloads.containsKey(urlHash)) {
      return _inFlightDownloads[urlHash]!;
    }

    final downloadFuture = _executeDownload(context, cleanUrl, urlHash);
    _inFlightDownloads[urlHash] = downloadFuture;

    try {
      return await downloadFuture;
    } finally {
      _inFlightDownloads.remove(urlHash);
    }
  }

  static Future<File?> _executeDownload(
    BuildContext context,
    String url,
    String urlHash,
  ) async {
    final client = http.Client();
    File? tmpFile;
    try {
      final tempDir = await getTemporaryDirectory();
      final targetFile = File('${tempDir.path}/cached_video_$urlHash.mp4');

      // Check if complete cached file already exists (> 1 KB)
      if (await targetFile.exists() && (await targetFile.length()) > 1024) {
        return targetFile;
      }

      // Safe URL parsing
      final parsedUri = Uri.tryParse(url) ?? Uri.tryParse(Uri.encodeFull(url));
      if (parsedUri == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid video URL format.')),
          );
        }
        return null;
      }

      final request = http.Request('GET', parsedUri);
      final response = await client.send(request).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not download video file.')),
          );
        }
        return null;
      }

      // Write to a temporary file first to prevent corrupted cache
      tmpFile = File('${tempDir.path}/temp_${urlHash}_${DateTime.now().millisecondsSinceEpoch}.tmp');
      final sink = tmpFile.openWrite();
      try {
        await response.stream.pipe(sink).timeout(const Duration(seconds: 60));
      } finally {
        await sink.close();
      }

      if (!await tmpFile.exists() || (await tmpFile.length()) <= 0) {
        if (await tmpFile.exists()) {
          await tmpFile.delete();
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not download video file.')),
          );
        }
        return null;
      }

      // Successfully downloaded: atomically rename to final target file
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await tmpFile.rename(targetFile.path);
      return targetFile;
    } catch (e) {
      debugPrint('VideoShareHelper: Error downloading video for share: $e');
      if (tmpFile != null && await tmpFile.exists()) {
        try {
          await tmpFile.delete();
        } catch (_) {}
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not download video. Please check your internet connection.')),
        );
      }
      return null;
    } finally {
      client.close();
    }
  }
}
