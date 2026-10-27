class ClaimDailyBonusResponse {
  const ClaimDailyBonusResponse({
    this.success = false,
    this.message = '',
    this.id = '',
    this.userId = '',
    this.coins = 0,
    this.points = 0,
    this.streakDay = 0,
    this.claimedAt = '',
    this.raw = const {},
  });

  final bool success;
  final String message;
  final String id;
  final String userId;
  final int coins;
  final int points;
  final int streakDay;
  final String claimedAt;
  final Map<String, dynamic> raw;

  bool get alreadyClaimed =>
      message.toLowerCase().contains('already claimed');

  bool get claimedToday => success || alreadyClaimed || claimedAt.isNotEmpty;

  factory ClaimDailyBonusResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : <String, dynamic>{};

    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    return ClaimDailyBonusResponse(
      success: json['success'] as bool? ?? false,
      message: json['message']?.toString() ?? '',
      id: data['id']?.toString() ?? '',
      userId: data['userId']?.toString() ?? '',
      coins: asInt(data['coins'] ?? json['coins']),
      points: asInt(data['points'] ?? json['points']),
      streakDay: asInt(data['streakDay'] ?? json['streakDay']),
      claimedAt: data['claimedAt']?.toString() ?? '',
      raw: json,
    );
  }
}
