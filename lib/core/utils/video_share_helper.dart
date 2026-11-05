import 'dart:io';

import 'package:artable_app/core/utils/media_url_utils.dart';
import 'package:artable_app/core/utils/reel_helpers.dart';
import 'package:artable_app/features/trending/data/repositories/videos_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shares Artable videos as **links** (no local download / file attach).
abstract final class VideoShareHelper {
  VideoShareHelper._();

  static const String appHost = 'https://artable.app';

  /// Public watch link for a video id.
  static String videoShareLink(String? videoId) {
    final id = videoId?.trim() ?? '';
    if (id.isEmpty) return appHost;
    return '$appHost/video/$id';
  }

  /// True when [url] looks like a playable media file, not a watch page.
  static bool isDirectMediaUrl(String? url) {
    final clean = MediaUrlUtils.resolve(url ?? '').trim().toLowerCase();
    if (clean.isEmpty) return false;
    return clean.contains('.mp4') ||
        clean.contains('.mov') ||
        clean.contains('.webm') ||
        clean.contains('.3gp') ||
        clean.contains('/videos/') ||
        clean.contains('.r2.dev/');
  }

  /// Prefer API `shareUrl` / watch page; never use a raw CDN mp4 as the share link.
  static String resolveShareLink({
    String? videoId,
    String? shareUrl,
    String? videoUrl,
    Map<String, dynamic>? apiData,
  }) {
    final fromApi = (apiData?['shareUrl'] ??
            apiData?['share_url'] ??
            apiData?['link'] ??
            apiData?['url'] ??
            shareUrl)
        ?.toString()
        .trim();
    if (fromApi != null &&
        fromApi.isNotEmpty &&
        fromApi != 'null' &&
        !isDirectMediaUrl(fromApi)) {
      return MediaUrlUtils.resolve(fromApi);
    }

    final id = (videoId ?? apiData?['id']?.toString() ?? '').trim();
    if (id.isNotEmpty) return videoShareLink(id);

    final fallback = (shareUrl ?? videoUrl)?.trim() ?? '';
    if (fallback.isNotEmpty &&
        fallback != 'null' &&
        !isDirectMediaUrl(fallback)) {
      return MediaUrlUtils.resolve(fallback);
    }

    return appHost;
  }

  /// Pre-cache is a no-op for link sharing (kept for call-site compatibility).
  static Future<File?> precacheVideo(String? videoUrl, {String? videoId}) async {
    return null;
  }

  /// Share a watch **link** for [optionId]: copy / whatsapp / sms / email / social.
  static Future<bool> shareVideo({
    required BuildContext context,
    required String optionId,
    required String videoUrl,
    String? videoId,
    String? title,
    String? caption,
    bool isApiAlreadyRecorded = false,
    String? musicUrl,
    double? musicStartSeconds,
    double? musicCropDuration,
    String? shareUrl,
    Map<String, dynamic>? shareApiData,
  }) async {
    final cleanVideoId = videoId?.trim();
    String? resolvedTitle = title?.trim();
    String? resolvedCaption = ReelHelpers.cleanDescription(caption).trim();
    if (resolvedCaption.isEmpty) resolvedCaption = null;

    Map<String, dynamic>? apiData = shareApiData;

    if (!isApiAlreadyRecorded &&
        cleanVideoId != null &&
        cleanVideoId.isNotEmpty) {
      try {
        final repo = VideosRepository();
        final shareRes = await repo.shareVideo(videoId: cleanVideoId);
        debugPrint('VideoShareHelper: /share API response: $shareRes');
        if (shareRes['success'] == true && shareRes['data'] is Map) {
          apiData = Map<String, dynamic>.from(shareRes['data'] as Map);
          if (resolvedTitle == null || resolvedTitle.isEmpty) {
            resolvedTitle = apiData['title']?.toString().trim();
          }
          if (resolvedCaption == null || resolvedCaption.isEmpty) {
            final cleaned = ReelHelpers.cleanDescription(
              apiData['description']?.toString(),
            ).trim();
            resolvedCaption = cleaned.isEmpty ? null : cleaned;
          }
        }
      } catch (e) {
        debugPrint('VideoShareHelper: shareVideo API error: $e');
      }
    }

    final link = resolveShareLink(
      videoId: cleanVideoId,
      shareUrl: shareUrl,
      videoUrl: videoUrl,
      apiData: apiData,
    );

    final blurb = (resolvedCaption != null && resolvedCaption.isNotEmpty)
        ? resolvedCaption
        : (resolvedTitle != null && resolvedTitle.isNotEmpty)
            ? resolvedTitle
            : 'Check out this video on Artable!';
    final shareText = '$blurb\n$link';

    if (optionId == 'copy') {
      await Clipboard.setData(ClipboardData(text: link));
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

    if (optionId == 'sms') {
      final smsUri = Uri(scheme: 'sms', queryParameters: {'body': shareText});
      try {
        if (await canLaunchUrl(smsUri)) {
          return await launchUrl(smsUri);
        }
      } catch (e) {
        debugPrint('VideoShareHelper: SMS launch error: $e');
      }
      return await _shareTextSheet(context, shareText, resolvedTitle);
    }

    if (optionId == 'email') {
      final emailSubject = resolvedTitle ?? 'Check out this video on Artable';
      final emailUri = Uri(
        scheme: 'mailto',
        queryParameters: {
          'subject': emailSubject,
          'body': '$blurb\n\nWatch here: $link',
        },
      );
      try {
        if (await canLaunchUrl(emailUri)) {
          return await launchUrl(emailUri);
        }
      } catch (e) {
        debugPrint('VideoShareHelper: Email launch error: $e');
      }
      return await _shareTextSheet(context, shareText, resolvedTitle);
    }

    if (optionId == 'whatsapp') {
      final waUri = Uri.parse(
        'https://wa.me/?text=${Uri.encodeComponent(shareText)}',
      );
      try {
        if (await canLaunchUrl(waUri)) {
          final ok = await launchUrl(
            waUri,
            mode: LaunchMode.externalApplication,
          );
          if (ok) return true;
        }
      } catch (e) {
        debugPrint('VideoShareHelper: WhatsApp link launch error: $e');
      }
      return await _shareTextSheet(context, shareText, resolvedTitle);
    }

    // social / default — system share sheet with text + link only (no file)
    return await _shareTextSheet(context, shareText, resolvedTitle);
  }

  static Future<bool> _shareTextSheet(
    BuildContext context,
    String text,
    String? title,
  ) async {
    try {
      if (!context.mounted) return false;
      final box = context.findRenderObject() as RenderBox?;
      final origin =
          (box != null && box.hasSize && box.size.width > 0 && box.size.height > 0)
              ? box.localToGlobal(Offset.zero) & box.size
              : null;

      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: title,
          title: title ?? 'Share video',
          sharePositionOrigin: origin,
        ),
      );
      return true;
    } catch (e) {
      debugPrint('VideoShareHelper: text share error: $e');
      return false;
    }
  }
}
