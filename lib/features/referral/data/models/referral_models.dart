Map<String, dynamic>? _asMap(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return null;
}

String _str(dynamic value) => value?.toString().trim() ?? '';

String _firstNonEmpty(List<dynamic> values) {
  for (final value in values) {
    final text = _str(value);
    if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
  }
  return '';
}

int _asInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(_str(value).replaceAll(',', '')) ?? 0;
}

String _formatAmount(dynamic value) {
  final raw = _str(value);
  if (raw.isEmpty || raw == '-' || raw == '—') return '—';
  final cleaned = raw.replaceAll('₹', '').replaceAll(r'$', '').trim();
  if (cleaned.isEmpty || cleaned == '0' || cleaned == '0.0') return '—';
  final numVal = num.tryParse(cleaned.replaceAll(',', ''));
  if (numVal == null) {
    return raw.contains('₹') ? raw : '₹$cleaned';
  }
  if (numVal == 0) return '—';
  final abs = numVal.abs();
  final formatted = abs.truncateToDouble() == abs
      ? abs.toStringAsFixed(0)
      : abs.toStringAsFixed(2);
  return numVal < 0 ? '-₹$formatted' : '₹$formatted';
}

class ReferralInviteResponse {
  const ReferralInviteResponse({
    required this.success,
    this.message,
    this.data,
  });

  final bool success;
  final String? message;
  final ReferralInviteData? data;

  factory ReferralInviteResponse.fromJson(Map<String, dynamic> json) {
    final dataRaw = json['data'];
    // Some backends return the code as a bare string under data.
    if (dataRaw is String && dataRaw.trim().isNotEmpty) {
      final code = dataRaw.trim();
      return ReferralInviteResponse(
        success: json['success'] != false,
        message: json['message']?.toString(),
        data: ReferralInviteData(
          code: code,
          inviteLink: ReferralInviteData.buildInviteLink(code),
        ),
      );
    }
    final map = _asMap(dataRaw) ?? json;
    return ReferralInviteResponse(
      success: json['success'] != false ||
          ReferralInviteData.fromJson(map).code.isNotEmpty,
      message: json['message']?.toString(),
      data: ReferralInviteData.fromJson(map),
    );
  }
}

class ReferralInviteData {
  const ReferralInviteData({
    required this.code,
    this.inviteLink = '',
    this.shareMessage = '',
    this.totalInvites = 0,
    this.joinedUsers = 0,
    this.rewardsEarned = '—',
    this.pendingRewards = '—',
  });

  static const String inviteHost = 'https://artable.app';

  final String code;
  final String inviteLink;
  final String shareMessage;
  final int totalInvites;
  final int joinedUsers;
  final String rewardsEarned;
  final String pendingRewards;

  static String buildInviteLink(String code) {
    final clean = code.trim();
    if (clean.isEmpty) return inviteHost;
    return '$inviteHost/invite/${Uri.encodeComponent(clean)}';
  }

  /// Ensures a usable watch/share link even when the API omits inviteLink.
  ReferralInviteData withFallbackLink() {
    if (inviteLink.trim().isNotEmpty || code.trim().isEmpty) return this;
    return ReferralInviteData(
      code: code,
      inviteLink: buildInviteLink(code),
      shareMessage: shareMessage,
      totalInvites: totalInvites,
      joinedUsers: joinedUsers,
      rewardsEarned: rewardsEarned,
      pendingRewards: pendingRewards,
    );
  }

  factory ReferralInviteData.fromJson(Map<String, dynamic> json) {
    final nested = _asMap(json['invite']) ??
        _asMap(json['referral']) ??
        _asMap(json['referralInfo']) ??
        _asMap(json['referral_info']) ??
        _asMap(json['user']) ??
        json;
    final code = _firstNonEmpty([
      nested['referralCode'],
      nested['referral_code'],
      nested['inviteCode'],
      nested['invite_code'],
      nested['myReferralCode'],
      nested['my_referral_code'],
      nested['code'],
      json['referralCode'],
      json['referral_code'],
      json['inviteCode'],
      json['code'],
    ]);
    final link = _firstNonEmpty([
      nested['inviteLink'],
      nested['invite_link'],
      nested['shareUrl'],
      nested['share_url'],
      nested['shareLink'],
      nested['share_link'],
      nested['url'],
      nested['link'],
      json['inviteLink'],
      json['invite_link'],
      json['shareUrl'],
    ]);
    return ReferralInviteData(
      code: code,
      inviteLink: link.isNotEmpty ? link : (code.isNotEmpty ? buildInviteLink(code) : ''),
      shareMessage: _firstNonEmpty([
        nested['shareMessage'],
        nested['share_message'],
        nested['caption'],
        nested['message'],
        json['shareMessage'],
      ]),
      totalInvites: _asInt(nested['totalInvites'] ?? nested['total_invites']),
      joinedUsers: _asInt(nested['joinedUsers'] ?? nested['joined_users']),
      rewardsEarned: _formatAmount(
        nested['rewardsEarned'] ?? nested['rewards_earned'],
      ),
      pendingRewards: _formatAmount(
        nested['pendingRewards'] ?? nested['pending_rewards'],
      ),
    );
  }
}

class ReferralTrackingResponse {
  const ReferralTrackingResponse({
    required this.success,
    this.message,
    this.data,
  });

  final bool success;
  final String? message;
  final ReferralTrackingData? data;

  factory ReferralTrackingResponse.fromJson(Map<String, dynamic> json) {
    final dataRaw = _asMap(json['data']) ?? json;
    return ReferralTrackingResponse(
      success: json['success'] == true,
      message: json['message']?.toString(),
      data: ReferralTrackingData.fromJson(dataRaw),
    );
  }
}

class ReferralTrackingData {
  const ReferralTrackingData({
    this.totalInvites = 0,
    this.joinedUsers = 0,
    this.rewardsEarned = '—',
    this.pendingRewards = '—',
    this.referrals = const [],
  });

  final int totalInvites;
  final int joinedUsers;
  final String rewardsEarned;
  final String pendingRewards;
  final List<ReferralTrackingItem> referrals;

  factory ReferralTrackingData.fromJson(Map<String, dynamic> json) {
    final summary = _asMap(json['summary']) ?? json;
    final listRaw = json['referrals'] ??
        json['list'] ??
        json['items'] ??
        json['history'] ??
        json['tracking'] ??
        json['inviteHistory'] ??
        json['invite_history'];
    final items = <ReferralTrackingItem>[];
    if (listRaw is List) {
      for (final raw in listRaw) {
        final map = _asMap(raw);
        if (map != null) items.add(ReferralTrackingItem.fromJson(map));
      }
    }
    return ReferralTrackingData(
      totalInvites: _asInt(
        summary['totalInvites'] ?? summary['total_invites'] ?? json['totalInvites'],
      ),
      joinedUsers: _asInt(
        summary['joinedUsers'] ?? summary['joined_users'] ?? json['joinedUsers'],
      ),
      rewardsEarned: _formatAmount(
        summary['rewardsEarned'] ?? summary['rewards_earned'] ?? json['rewardsEarned'],
      ),
      pendingRewards: _formatAmount(
        summary['pendingRewards'] ?? summary['pending_rewards'] ?? json['pendingRewards'],
      ),
      referrals: items,
    );
  }
}

class ReferralTrackingItem {
  const ReferralTrackingItem({
    required this.id,
    required this.name,
    this.avatarUrl = '',
    this.status = '',
    this.date = '',
    this.amount = '—',
  });

  final String id;
  final String name;
  final String avatarUrl;
  final String status;
  final String date;
  final String amount;

  factory ReferralTrackingItem.fromJson(Map<String, dynamic> json) {
    final user = _asMap(json['user']) ??
        _asMap(json['referredUser']) ??
        _asMap(json['referred_user']) ??
        json;
    return ReferralTrackingItem(
      id: _firstNonEmpty([
        json['id'],
        json['referralId'],
        json['userId'],
        user['id'],
      ]),
      name: _firstNonEmpty([
        user['fullName'],
        user['name'],
        user['username'],
        json['fullName'],
        json['name'],
        json['username'],
      ]),
      avatarUrl: _firstNonEmpty([
        user['profilePhotoUrl'],
        user['avatarUrl'],
        user['profile_photo_url'],
        json['avatarUrl'],
        json['profilePhotoUrl'],
      ]),
      status: _firstNonEmpty([json['status'], json['state']]),
      date: _firstNonEmpty([
        json['date'],
        json['createdAt'],
        json['created_at'],
        json['joinedAt'],
        json['joined_at'],
      ]),
      amount: _formatAmount(
        json['amount'] ?? json['rewardAmount'] ?? json['reward'] ?? json['reward_amount'],
      ),
    );
  }
}

class ApplyReferralResponse {
  const ApplyReferralResponse({
    required this.success,
    this.message,
    this.data,
  });

  final bool success;
  final String? message;
  final Map<String, dynamic>? data;

  factory ApplyReferralResponse.fromJson(Map<String, dynamic> json) {
    return ApplyReferralResponse(
      success: json['success'] == true,
      message: json['message']?.toString(),
      data: _asMap(json['data']),
    );
  }
}
