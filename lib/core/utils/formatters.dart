/// Formatting helpers from doc/js/app.js
abstract final class AppFormatters {
  static const _fixedToday = '2026-07-11';

  static DateTime? tryParseDate(String raw) {
    final str = raw.trim();
    if (str.isEmpty) return null;
    final direct = DateTime.tryParse(str);
    if (direct != null) return direct;
    if (!str.contains('T')) {
      return DateTime.tryParse('${str}T00:00:00');
    }
    return null;
  }

  static String formatDate(String iso) {
    if (iso.isEmpty) return '';
    final d = tryParseDate(iso);
    if (d == null) return iso;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  static int daysRemaining(String iso) {
    if (iso.isEmpty) return 0;
    final end = tryParseDate(iso);
    if (end == null) return 0;
    final today = tryParseDate(_fixedToday) ?? DateTime.now();
    return end.difference(today).inDays;
  }

  static String formatParticipants(int n) {
    if (n >= 1000) {
      final k = n / 1000;
      final s = k.toStringAsFixed(1);
      return s.endsWith('.0') ? '${s.split('.').first}K' : '${s}K';
    }
    return n.toString();
  }

  static String formatDateTime(String iso) {
    if (iso.isEmpty) return '';
    final d = tryParseDate(iso);
    if (d == null) return iso;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final timeStr = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return '${months[d.month - 1]} ${d.day}, ${d.year} · $timeStr';
  }

  static String imgFallbackUrl(String alt, {int w = 400, int h = 400}) {
    final seed = Uri.encodeComponent(alt.isEmpty ? 'artable' : alt);
    return 'https://picsum.photos/seed/$seed/${w > 200 ? w : 200}/${h > 200 ? h : 200}';
  }
}
