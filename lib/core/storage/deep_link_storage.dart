import 'package:artable_app/core/storage/local_storage.dart';

/// Persists an inbound share / invite deep link until auth + splash finish.
abstract final class DeepLinkStorage {
  DeepLinkStorage._();

  static const _pendingKey = 'pending_deep_link_uri';

  static Future<void> savePendingUri(String? uri) async {
    final clean = uri?.trim() ?? '';
    if (clean.isEmpty) {
      await LocalStorage.remove(_pendingKey);
      return;
    }
    await LocalStorage.setString(_pendingKey, clean);
  }

  static Future<String?> readPendingUri() async {
    final value = await LocalStorage.getString(_pendingKey);
    final clean = value?.trim() ?? '';
    if (clean.isEmpty) return null;
    return clean;
  }

  static Future<String?> takePendingUri() async {
    final value = await readPendingUri();
    if (value != null) await clearPendingUri();
    return value;
  }

  static Future<void> clearPendingUri() async {
    await LocalStorage.remove(_pendingKey);
  }
}
