class FormatUtils {
  FormatUtils._();

  static String formatDate(String iso) {
    final parts = iso.split('-');
    if (parts.length != 3) return iso;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final month = int.tryParse(parts[1]) ?? 1;
    return '${months[month - 1]} ${int.parse(parts[2])}, ${parts[0]}';
  }

  static String formatDateTime(String iso) {
    final d = DateTime.parse(iso);
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
    final end = DateTime.parse('${iso}T00:00:00');
    final today = DateTime(2026, 7, 11);
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
