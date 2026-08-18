/// Formatting helpers from doc/js/app.js
abstract final class AppFormatters {
  static const _fixedToday = '2026-07-11';

  static String formatDate(String iso) {
    final d = DateTime.parse('${iso}T00:00:00');
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  static int daysRemaining(String iso) {
    final end = DateTime.parse('${iso}T00:00:00');
    final today = DateTime.parse('${_fixedToday}T00:00:00');
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
    final d = DateTime.parse(iso);
    return '${formatDate(iso.split('T').first)} · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  static String imgFallbackUrl(String alt, {int w = 400, int h = 400}) {
    final seed = Uri.encodeComponent(alt.isEmpty ? 'artable' : alt);
    return 'https://picsum.photos/seed/$seed/${w > 200 ? w : 200}/${h > 200 ? h : 200}';
  }
}
