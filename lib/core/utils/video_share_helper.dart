import 'dart:convert';
import 'dart:io';

import 'package:artable_app/core/utils/media_url_utils.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

abstract final class VideoShareHelper {
  VideoShareHelper._();

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

    if (!isRemote && !isLocal) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video is not available to share.')),
        );
      }
      return;
    }

    File? videoFile;
    if (isRemote) {
      videoFile = await _downloadAndCacheVideo(context, resolvedUrl);
      if (videoFile == null) return;
    } else {
      videoFile = File(resolvedUrl);
    }

    if (!await videoFile.exists()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not prepare video file.')),
        );
      }
      return;
    }

    final xFile = XFile(
      videoFile.path,
      mimeType: 'video/mp4',
      name: 'artable_video.mp4',
    );

    final box = context.findRenderObject() as RenderBox?;
    final origin = (box != null && box.hasSize)
        ? box.localToGlobal(Offset.zero) & box.size
        : null;

    // WhatsApp / SMS / Email / Social all open the system share sheet with the
    // actual .mp4 so the user can pick WhatsApp (or another app).
    await SharePlus.instance.share(
      ShareParams(
        files: [xFile],
        text: isRemote ? '$shareText\n$resolvedUrl' : shareText,
        subject: title,
        title: title ?? 'Share video',
        sharePositionOrigin: origin,
      ),
    );
  }

  /// Downloads network video to a local cache file (streamed, not all-in-memory).
  static Future<File?> _downloadAndCacheVideo(
    BuildContext context,
    String url,
  ) async {
    final client = http.Client();
    try {
      final tempDir = await getTemporaryDirectory();
      final urlHash = md5.convert(utf8.encode(url)).toString();
      final file = File('${tempDir.path}/cached_video_$urlHash.mp4');

      if (await file.exists() && (await file.length()) > 0) {
        return file;
      }

      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not download video file.')),
          );
        }
        return null;
      }

      final sink = file.openWrite();
      try {
        await response.stream.pipe(sink);
      } finally {
        await sink.close();
      }

      if (!await file.exists() || (await file.length()) <= 0) {
        if (await file.exists()) {
          await file.delete();
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not download video file.')),
          );
        }
        return null;
      }

      return file;
    } catch (e) {
      debugPrint('Error downloading video for share: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error preparing video: $e')),
        );
      }
      return null;
    } finally {
      client.close();
    }
  }
}
