/// Body for `POST /app/daily-bonus/claim`.
///
/// ```json
/// { "coins": 10, "points": 10, "streakDay": 1 }
/// ```
class ClaimDailyBonusRequest {
  const ClaimDailyBonusRequest({
    required this.coins,
    required this.points,
    required this.streakDay,
  });

  final int coins;
  final int points;
  final int streakDay;

  Map<String, dynamic> toJson() => {
        'coins': coins,
        'points': points,
        'streakDay': streakDay,
      };
}
