class DailyBonusCalendarResponse {
  const DailyBonusCalendarResponse({
    this.success = false,
    this.message = '',
    this.currentStreak = 0,
    this.claimedToday = false,
    this.todayCoins = 0,
    this.todayLabel = '',
    this.calendar = const [],
    this.milestones = const [],
    this.raw = const {},
  });

  final bool success;
  final String message;
  final int currentStreak;
  final bool claimedToday;
  final int todayCoins;
  final String todayLabel;
  final List<DailyBonusCalendarDay> calendar;
  final List<DailyBonusMilestone> milestones;
  final Map<String, dynamic> raw;

  DailyBonusMilestone? get nextMilestone {
    for (final m in milestones) {
      if (!m.unlocked) return m;
    }
    return milestones.isEmpty ? null : milestones.last;
  }

  List<DailyBonusCalendarDay> get weekDays {
    final week = calendar.where((d) => d.day >= 1 && d.day <= 7).toList();
    if (week.isNotEmpty) return week;
    return calendar.take(7).toList();
  }

  factory DailyBonusCalendarResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : <String, dynamic>{};

    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    bool asBool(dynamic v) {
      if (v is bool) return v;
      final s = v?.toString().toLowerCase();
      return s == 'true' || s == '1';
    }

    final today = data['todayReward'] is Map
        ? Map<String, dynamic>.from(data['todayReward'] as Map)
        : <String, dynamic>{};

    final calendarRaw = data['calendar'] is List ? data['calendar'] as List : const [];
    final milestonesRaw =
        data['milestones'] is List ? data['milestones'] as List : const [];

    return DailyBonusCalendarResponse(
      success: json['success'] as bool? ?? false,
      message: json['message']?.toString() ?? '',
      currentStreak: asInt(data['currentStreak']),
      claimedToday: asBool(data['claimedToday']),
      todayCoins: asInt(today['coins']),
      todayLabel: today['label']?.toString() ?? '',
      calendar: calendarRaw
          .whereType<Map>()
          .map((e) => DailyBonusCalendarDay.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      milestones: milestonesRaw
          .whereType<Map>()
          .map((e) => DailyBonusMilestone.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      raw: json,
    );
  }
}

class DailyBonusCalendarDay {
  const DailyBonusCalendarDay({
    required this.day,
    required this.claimed,
    required this.coins,
  });

  final int day;
  final bool claimed;
  final int coins;

  factory DailyBonusCalendarDay.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    return DailyBonusCalendarDay(
      day: asInt(json['day']),
      claimed: json['claimed'] == true,
      coins: asInt(json['coins']),
    );
  }
}

class DailyBonusMilestone {
  const DailyBonusMilestone({
    required this.day,
    required this.title,
    required this.reward,
    required this.unlocked,
  });

  final int day;
  final String title;
  final String reward;
  final bool unlocked;

  factory DailyBonusMilestone.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    return DailyBonusMilestone(
      day: asInt(json['day'] ?? json['days']),
      title: (json['title'] ?? '').toString(),
      reward: (json['reward'] ?? '').toString(),
      unlocked: json['unlocked'] == true,
    );
  }
}
