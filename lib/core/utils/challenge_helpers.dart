String formatParticipants(int count) {
  if (count >= 1000) {
    final value = count / 1000;
    return value == value.roundToDouble()
        ? '${value.toInt()}K'
        : '${value.toStringAsFixed(1)}K';
  }
  return count.toString();
}

int daysRemaining(String endDateIso) {
  if (endDateIso.isEmpty) return 0;
  try {
    final end = DateTime.parse(endDateIso);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDay = DateTime(end.year, end.month, end.day);
    return endDay.difference(today).inDays;
  } catch (_) {
    return 0;
  }
}

String formatDate(String endDateIso) {
  if (endDateIso.isEmpty) return '';
  try {
    final date = DateTime.parse(endDateIso);
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  } catch (_) {
    return endDateIso;
  }
}

String challengeDateLabel(Map<String, dynamic> challenge) {
  if (challenge['daysLeftLabel'] is String &&
      (challenge['daysLeftLabel'] as String).isNotEmpty) {
    return challenge['daysLeftLabel'] as String;
  }
  final status = (challenge['status'] as String? ?? 'active').toLowerCase();
  final endDate = challenge['endDate'] as String? ?? '';
  if (endDate.isEmpty) return 'Active';
  final remaining = daysRemaining(endDate);
  switch (status) {
    case 'completed':
      return 'Ended ${formatDate(endDate)}';
    case 'upcoming':
      return 'Starts ${formatDate(endDate)}';
    default:
      return remaining > 0 ? '${remaining}d left' : 'Ending today';
  }
}

String challengeCtaLabel(String status) {
  switch (status) {
    case 'completed':
      return 'View Results';
    case 'upcoming':
      return 'View Details';
    default:
      return 'Join Challenge';
  }
}

Map<String, dynamic>? findChallengeById(
  List<Map<String, dynamic>> challenges,
  String? id,
) {
  if (id == null || id.isEmpty) return null;
  for (final challenge in challenges) {
    if (challenge['id'] == id) return challenge;
  }
  return null;
}
