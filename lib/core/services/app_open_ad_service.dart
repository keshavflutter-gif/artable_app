import 'dart:async';

/// Loads and shows the AdMob **App Open** ad.
/// Pop-up ad formats are disabled for a clean user experience.
class AppOpenAdService {
  AppOpenAdService._();

  static final AppOpenAdService instance = AppOpenAdService._();

  bool get isAdAvailable => false;

  void markPendingHomeShow() {}

  Future<void> load() async {}

  Future<void> showWhenHomeReady() async {}

  Future<void> showIfAvailable({
    Duration maxWait = const Duration(seconds: 3),
  }) async {}

  void dispose() {}
}
