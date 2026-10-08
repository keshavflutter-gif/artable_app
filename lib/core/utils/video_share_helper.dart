import 'dart:convert';
import 'dart:io';

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
    final cleanUrl = videoUrl.trim();
    final shareText = (caption != null && caption.trim().isNotEmpty)
        ? caption.trim()
        : (title != null && title.trim().isNotEmpty)
            ? title.trim()
            : 'Check out this video on Artable!';

    if (optionId == 'copy') {
      final copyText = cleanUrl.isNotEmpty ? cleanUrl : 'https://artable.app/video';
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

    const defaultSampleUrl = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4';
    final targetUrl = (cleanUrl.isNotEmpty && (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://') || File(cleanUrl).existsSync()))
        ? cleanUrl
        : defaultSampleUrl;

    // For WhatsApp, SMS, Email, Social Share: share actual .mp4 video file
    File? videoFile;
    if (targetUrl.startsWith('http://') || targetUrl.startsWith('https://')) {
      videoFile = await _downloadAndCacheVideo(context, targetUrl);
      if (videoFile == null) {
        // Download was cancelled or failed
        return;
      }
    } else if (File(targetUrl).existsSync()) {
      videoFile = File(targetUrl);
    }

    if (videoFile != null && videoFile.existsSync()) {
      final xFile = XFile(videoFile.path, mimeType: 'video/mp4', name: 'artable_video.mp4');
      
      switch (optionId) {
        case 'whatsapp':
        case 'sms':
        case 'email':
        case 'social':
        default:
          // ignore: deprecated_member_use
          await Share.shareXFiles([xFile]);
          break;
      }
    } else {
      // Fallback if file system error occurred
      // ignore: deprecated_member_use
      await Share.share(
        '$shareText\n$targetUrl',
        subject: title,
      );
    }
  }

  /// Downloads network video silently in background and caches it locally
  static Future<File?> _downloadAndCacheVideo(BuildContext context, String url) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final urlHash = md5.convert(utf8.encode(url)).toString();
      final file = File('${tempDir.path}/cached_video_$urlHash.mp4');

      // Check if already cached & valid size
      if (await file.exists() && (await file.length()) > 0) {
        return file;
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        await file.writeAsBytes(response.bodyBytes);
        return file;
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not download video file.')),
          );
        }
        return null;
      }
    } catch (e) {
      debugPrint('Error downloading video for share: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error preparing video: ${e.toString()}')),
        );
      }
      return null;
    }
  }
}
