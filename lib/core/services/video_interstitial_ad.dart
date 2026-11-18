import 'dart:async';

/// AdMob interstitial shown after Video Detail / Challenge exit.
/// Pop-up ad formats are disabled for a clean user experience.
class VideoInterstitialAd {
  VideoInterstitialAd._();

  static final VideoInterstitialAd instance = VideoInterstitialAd._();

  Future<void> load() async {}

  Future<void> show() async {}

  void dispose() {}
}
