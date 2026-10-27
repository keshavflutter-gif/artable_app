import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob Rewarded ad for the Daily Bonus claim flow.
class DailyBonusRewardedAd {
  DailyBonusRewardedAd._();

  static final DailyBonusRewardedAd instance = DailyBonusRewardedAd._();

  static const String adUnitId = 'ca-app-pub-8377462640468284/9824982069';
  static const String _testAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

  RewardedAd? _ad;
  bool _loading = false;
  Completer<void>? _loadCompleter;

  Future<void> load() async {
    if (kIsWeb) return;
    if (_ad != null) return;
    if (_loading && _loadCompleter != null) return _loadCompleter!.future;

    _loading = true;
    final completer = _loadCompleter = Completer<void>();

    try {
      await MobileAds.instance.initialize();
      var loaded = await _request(adUnitId);
      if (!loaded) {
        debugPrint('DailyBonusRewardedAd: production no-fill, retrying test');
        loaded = await _request(_testAdUnitId);
      }
      if (!loaded) {
        debugPrint('DailyBonusRewardedAd: no ad available');
      }
    } catch (e) {
      debugPrint('DailyBonusRewardedAd load error: $e');
    } finally {
      _loading = false;
      if (!completer.isCompleted) completer.complete();
    }
    return completer.future;
  }

  Future<bool> _request(String unitId) async {
    final done = Completer<bool>();
    await RewardedAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('DailyBonusRewardedAd loaded ($unitId)');
          _ad = ad;
          if (!done.isCompleted) done.complete(true);
        },
        onAdFailedToLoad: (error) {
          debugPrint('DailyBonusRewardedAd failed ($unitId): $error');
          _ad = null;
          if (!done.isCompleted) done.complete(false);
        },
      ),
    );
    return done.future;
  }

  /// Shows the rewarded ad. Returns `true` only if the user earned the reward.
  Future<bool> show() async {
    if (kIsWeb) return false;

    if (_ad == null) {
      await load().timeout(const Duration(seconds: 8), onTimeout: () {});
    }

    final ad = _ad;
    if (ad == null) return false;

    final result = Completer<bool>();
    var earned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) =>
          debugPrint('DailyBonusRewardedAd shown'),
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('DailyBonusRewardedAd dismissed');
        ad.dispose();
        _ad = null;
        if (!result.isCompleted) result.complete(earned);
        unawaited(load());
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('DailyBonusRewardedAd failed to show: $error');
        ad.dispose();
        _ad = null;
        if (!result.isCompleted) result.complete(false);
        unawaited(load());
      },
    );

    try {
      await ad.show(
        onUserEarnedReward: (ad, reward) {
          debugPrint(
            'DailyBonusRewardedAd earned ${reward.amount} ${reward.type}',
          );
          earned = true;
        },
      );
    } catch (e) {
      debugPrint('DailyBonusRewardedAd show error: $e');
      ad.dispose();
      _ad = null;
      if (!result.isCompleted) result.complete(false);
      return false;
    }

    return result.future;
  }

  void dispose() {
    _ad?.dispose();
    _ad = null;
  }
}
