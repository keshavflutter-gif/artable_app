class FormatUtils {
  FormatUtils._();

  static DateTime? _tryParse(String iso) {
    final str = iso.trim();
    if (str.isEmpty) return null;
    final direct = DateTime.tryParse(str);
    if (direct != null) return direct;
    if (!str.contains('T')) {
      return DateTime.tryParse('${str}T00:00:00');
    }
    return null;
  }

  static String formatDate(String iso) {
    if (iso.isEmpty) return iso;
    final d = _tryParse(iso);
    if (d == null) return iso;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  static String formatDateTime(String iso) {
    if (iso.isEmpty) return iso;
    final d = _tryParse(iso);
    if (d == null) return iso;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    final minute = d.minute.toString().padLeft(2, '0');
    return '${months[d.month - 1]} ${d.day} · $hour:$minute $ampm';
  }

  static int daysRemaining(String iso) {
    if (iso.isEmpty) return 0;
    final end = _tryParse(iso);
    if (end == null) return 0;
    final today = DateTime.now();
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
}
