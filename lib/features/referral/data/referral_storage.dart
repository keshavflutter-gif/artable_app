import 'package:artable_app/core/storage/local_storage.dart';

/// Persists a pending referral code until the invited user finishes signup.
abstract final class ReferralStorage {
  ReferralStorage._();

  static const _pendingKey = 'pending_referral_code';

  static Future<void> savePendingCode(String? code) async {
    final clean = code?.trim() ?? '';
    if (clean.isEmpty) {
      await LocalStorage.remove(_pendingKey);
      return;
    }
    await LocalStorage.setString(_pendingKey, clean.toUpperCase());
  }

  static Future<String?> readPendingCode() async {
    final value = await LocalStorage.getString(_pendingKey);
    final clean = value?.trim() ?? '';
    if (clean.isEmpty) return null;
    return clean;
  }

  static Future<void> clearPendingCode() async {
    await LocalStorage.remove(_pendingKey);
  }
}
