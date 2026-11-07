import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import 'package:artable_app/app/routes/app_router.dart';
import 'package:artable_app/app/routes/app_routes.dart';
import 'package:artable_app/core/auth/auth_gate.dart';
import 'package:artable_app/core/storage/deep_link_storage.dart';
import 'package:artable_app/features/referral/data/referral_storage.dart';

/// Handles `https://artable.app/...` App Links and `artable://...` custom scheme.
///
/// Supported paths:
/// - `/video/:id` → Full Reel feed for that video
/// - `/invite/:code` → signup / home with referral code (existing)
/// - `/profile/:id` → public profile
abstract final class DeepLinkService {
  DeepLinkService._();

  static final AppLinks _appLinks = AppLinks();
  static StreamSubscription<Uri>? _sub;
  static bool _started = false;
  static String? _lastHandled;

  static Future<void> start() async {
    if (_started) return;
    _started = true;

    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        await handleUri(initial, fromColdStart: true);
      }
    } catch (e) {
      debugPrint('[DeepLink] getInitialLink error: $e');
    }

    _sub?.cancel();
    _sub = _appLinks.uriLinkStream.listen(
      (uri) => unawaited(handleUri(uri, fromColdStart: false)),
      onError: (Object e) => debugPrint('[DeepLink] stream error: $e'),
    );
  }

  static Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    _started = false;
  }

  /// Call after splash / login when the user is ready to land on a target screen.
  static Future<bool> consumePendingIfAny() async {
    final raw = await DeepLinkStorage.takePendingUri();
    if (raw == null || raw.isEmpty) return false;
    try {
      return await handleUri(Uri.parse(raw), fromColdStart: false, forceNavigate: true);
    } catch (e) {
      debugPrint('[DeepLink] consumePending error: $e');
      return false;
    }
  }

  static Future<bool> handleUri(
    Uri uri, {
    required bool fromColdStart,
    bool forceNavigate = false,
  }) async {
    final normalized = _normalize(uri);
    if (normalized == null) return false;

    final key = normalized.toString();
    if (!forceNavigate && _lastHandled == key) return true;
    _lastHandled = key;
    debugPrint('[DeepLink] Handling $normalized');

    final videoId = _extractVideoId(normalized);
    if (videoId != null) {
      return _openVideo(videoId, fromColdStart: fromColdStart, forceNavigate: forceNavigate);
    }

    final inviteCode = _extractInviteCode(normalized);
    if (inviteCode != null) {
      await ReferralStorage.savePendingCode(inviteCode);
      if (!AuthGate.instance.isLoggedIn) {
        if (forceNavigate || !fromColdStart) {
          appRouter.go('${AppRoutes.signup}?ref=${Uri.encodeComponent(inviteCode)}');
        } else {
          await DeepLinkStorage.savePendingUri(normalized.toString());
        }
        return true;
      }
      if (forceNavigate || !fromColdStart) {
        appRouter.go(AppRoutes.home);
      } else {
        await DeepLinkStorage.savePendingUri(normalized.toString());
      }
      return true;
    }

    final profileId = _extractProfileId(normalized);
    if (profileId != null) {
      return _openProfile(profileId, fromColdStart: fromColdStart, forceNavigate: forceNavigate);
    }

    return false;
  }

  static Future<bool> _openVideo(
    String videoId, {
    required bool fromColdStart,
    required bool forceNavigate,
  }) async {
    final target = '${AppRoutes.reelsFeed}?id=${Uri.encodeComponent(videoId)}';
    if (!AuthGate.instance.initialized || !AuthGate.instance.isLoggedIn) {
      await DeepLinkStorage.savePendingUri('https://artable.app/video/$videoId');
      if (forceNavigate && AuthGate.instance.initialized && !AuthGate.instance.isLoggedIn) {
        appRouter.go(AppRoutes.login);
      }
      return true;
    }
    if (forceNavigate || !fromColdStart) {
      appRouter.go(target);
      return true;
    }
    // Cold start while logged in — splash still owns first navigation; keep pending.
    await DeepLinkStorage.savePendingUri('https://artable.app/video/$videoId');
    return true;
  }

  static Future<bool> _openProfile(
    String profileId, {
    required bool fromColdStart,
    required bool forceNavigate,
  }) async {
    final target = '${AppRoutes.publicProfile}?id=${Uri.encodeComponent(profileId)}';
    if (!AuthGate.instance.initialized || !AuthGate.instance.isLoggedIn) {
      await DeepLinkStorage.savePendingUri('https://artable.app/profile/$profileId');
      if (forceNavigate && AuthGate.instance.initialized && !AuthGate.instance.isLoggedIn) {
        appRouter.go(AppRoutes.login);
      }
      return true;
    }
    if (forceNavigate || !fromColdStart) {
      appRouter.go(target);
      return true;
    }
    await DeepLinkStorage.savePendingUri('https://artable.app/profile/$profileId');
    return true;
  }

  static Uri? _normalize(Uri uri) {
    if (uri.scheme == 'artable') {
      // artable://video/ID  or  artable://artable.app/video/ID
      final host = uri.host.toLowerCase();
      if (host == 'video' || host == 'invite' || host == 'profile') {
        final id = uri.pathSegments.isNotEmpty
            ? uri.pathSegments.first
            : (uri.path.startsWith('/') ? uri.path.substring(1) : uri.path);
        if (id.trim().isEmpty && uri.pathSegments.isEmpty) {
          return Uri(scheme: 'https', host: 'artable.app', path: '/$host');
        }
        final cleanId = id.trim().isNotEmpty
            ? id.trim()
            : (uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '');
        return Uri(
          scheme: 'https',
          host: 'artable.app',
          path: '/$host/${cleanId.isNotEmpty ? cleanId : uri.pathSegments.join('/')}',
        );
      }
      if (host == 'artable.app' || host.isEmpty) {
        return Uri(
          scheme: 'https',
          host: 'artable.app',
          path: uri.path.isEmpty ? '/' : uri.path,
          query: uri.hasQuery ? uri.query : null,
        );
      }
    }

    if (uri.scheme == 'https' || uri.scheme == 'http') {
      final host = uri.host.toLowerCase();
      if (host == 'artable.app' || host == 'www.artable.app') {
        return uri;
      }
    }
    return null;
  }

  static String? _extractVideoId(Uri uri) {
    final segments = uri.pathSegments.where((s) => s.trim().isNotEmpty).toList();
    if (segments.length >= 2 && segments[0].toLowerCase() == 'video') {
      final id = segments[1].trim();
      return id.isEmpty ? null : id;
    }
    // /video?id=
    if (segments.length == 1 && segments[0].toLowerCase() == 'video') {
      final id = uri.queryParameters['id']?.trim();
      return (id == null || id.isEmpty) ? null : id;
    }
    return null;
  }

  static String? _extractInviteCode(Uri uri) {
    final segments = uri.pathSegments.where((s) => s.trim().isNotEmpty).toList();
    if (segments.length >= 2 && segments[0].toLowerCase() == 'invite') {
      final code = segments[1].trim();
      return code.isEmpty ? null : code;
    }
    final q = uri.queryParameters['ref'] ?? uri.queryParameters['code'];
    return (q != null && q.trim().isNotEmpty) ? q.trim() : null;
  }

  static String? _extractProfileId(Uri uri) {
    final segments = uri.pathSegments.where((s) => s.trim().isNotEmpty).toList();
    if (segments.length >= 2 && segments[0].toLowerCase() == 'profile') {
      final id = segments[1].trim();
      return id.isEmpty ? null : id;
    }
    return null;
  }
}
