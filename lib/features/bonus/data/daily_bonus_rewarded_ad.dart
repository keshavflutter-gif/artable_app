/// AdMob Rewarded ad for the Daily Bonus claim flow.
/// Pop-up ad formats are disabled for a clean user experience.
class DailyBonusRewardedAd {
  DailyBonusRewardedAd._();

  static final DailyBonusRewardedAd instance = DailyBonusRewardedAd._();

  Future<void> load() async {}

  /// Always succeeds so bonus can be claimed without a pop-up ad.
  Future<bool> show() async => true;

  void dispose() {}
}
