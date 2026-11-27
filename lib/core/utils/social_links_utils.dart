/// Helpers for reading/writing profile social links across API shapes.
abstract final class SocialLinksUtils {
  SocialLinksUtils._();

  static const _urlKeys = [
    'url',
    'websiteUrl',
    'website',
    'instagramUrl',
    'instagram',
    'youtubeUrl',
    'youtube',
    'link',
    'href',
    'socialUrl',
  ];

  static const _ignoredKeys = {
    'email',
    'provider',
    'providerid',
    'provider_id',
    'providerdata',
    'uid',
    'id',
    'userid',
    'user_id',
    'displayName',
    'displayname',
    'photoURL',
    'photourl',
    'phoneNumber',
    'phonenumber',
    'provi',
  };

  /// Best single display URL for Edit Profile / profile chip.
  static String extractUrl(dynamic source) {
    if (source == null) return '';

    if (source is String) {
      return _sanitizeUrl(source);
    }

    if (source is List) {
      for (final item in source) {
        final url = extractUrl(item);
        if (url.isNotEmpty) return url;
      }
      return '';
    }

    if (source is Map) {
      for (final key in _urlKeys) {
        final value = source[key];
        if (value is Map || value is List) continue;
        final url = _sanitizeUrl(value?.toString());
        if (url.isNotEmpty) return url;
      }

      for (final entry in source.entries) {
        final key = entry.key.toString().trim().toLowerCase();
        if (_ignoredKeys.contains(key)) continue;
        if (key.contains('email') || key.contains('provider')) continue;

        final value = entry.value;
        if (value == null || value is Map || value is List) continue;

        final url = _sanitizeUrl(value.toString());
        if (url.isNotEmpty) return url;
      }
    }

    return '';
  }

  /// Label for profile chip from a URL / platform name.
  static String labelFor({String? url, String? platform}) {
    final p = (platform ?? '').trim().toLowerCase();
    if (p.contains('instagram')) return 'Instagram';
    if (p.contains('youtube')) return 'YouTube';
    if (p.contains('website') || p.contains('web')) return 'Website';

    final u = (url ?? '').toLowerCase();
    if (u.contains('instagram')) return 'Instagram';
    if (u.contains('youtube') || u.contains('youtu.be')) return 'YouTube';
    return 'Website';
  }

  static String _sanitizeUrl(String? raw) {
    final s = (raw ?? '').trim();
    if (s.isEmpty ||
        s == '#' ||
        s == 'https://' ||
        s == 'http://' ||
        s.toLowerCase() == 'null' ||
        s.toLowerCase() == 'undefined') {
      return '';
    }

    // Reject Dart/JSON map dumps and auth provider blobs.
    if (s.startsWith('{') || s.startsWith('[')) return '';
    if (s.contains('providerId') ||
        s.contains('provider:') ||
        s.contains('email:')) {
      return '';
    }

    // Reject bare emails (common pollution from social-login payloads).
    if (_looksLikeEmail(s)) return '';

    if (s.startsWith('http://') || s.startsWith('https://')) return s;
    if (s.startsWith('instagram.com') ||
        s.startsWith('www.instagram.com') ||
        s.startsWith('youtube.com') ||
        s.startsWith('www.youtube.com') ||
        s.startsWith('youtu.be')) {
      return 'https://$s';
    }
    if (s.startsWith('@') && s.length > 1 && !s.contains(' ')) {
      return 'https://instagram.com/${s.substring(1)}';
    }

    // Plain domain (example.com / example.com/path)
    final domain = RegExp(
      r'^[a-zA-Z0-9][a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(/[^\s]*)?$',
    );
    if (domain.hasMatch(s)) return 'https://$s';

    return '';
  }

  static bool _looksLikeEmail(String s) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
  }
}
