import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob interstitial shown after Video Detail / Challenge exit
/// (and on the studio "Entry Submitted" screen).
class VideoInterstitialAd {
  VideoInterstitialAd._();

  static final VideoInterstitialAd instance = VideoInterstitialAd._();

  static const String adUnitId = 'ca-app-pub-8377462640468284/2385475747';
  static const String _testAdUnitId = 'ca-app-pub-3940256099942544/1033173712';

  InterstitialAd? _ad;
  bool _loading = false;
  bool _showing = false;
  DateTime? _lastShownAt;
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
        debugPrint('VideoInterstitialAd: production no-fill, retrying test');
        loaded = await _request(_testAdUnitId);
      }
      if (!loaded) {
        debugPrint('VideoInterstitialAd: no ad available');
      }
    } catch (e) {
      debugPrint('VideoInterstitialAd load error: $e');
    } finally {
      _loading = false;
      if (!completer.isCompleted) completer.complete();
    }
    return completer.future;
  }

  Future<bool> _request(String unitId) async {
    final done = Completer<bool>();
    await InterstitialAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('VideoInterstitialAd loaded ($unitId)');
          _ad = ad;
          if (!done.isCompleted) done.complete(true);
        },
        onAdFailedToLoad: (error) {
          debugPrint('VideoInterstitialAd failed ($unitId): $error');
          _ad = null;
          if (!done.isCompleted) done.complete(false);
        },
      ),
    );
    return done.future;
  }

  /// Shows the interstitial if one is ready. Never throws.
  Future<void> show() async {
    if (kIsWeb || _showing) return;
    if (_lastShownAt != null &&
        DateTime.now().difference(_lastShownAt!) < const Duration(seconds: 20)) {
      return;
    }

    if (_ad == null) {
      await load().timeout(const Duration(seconds: 6), onTimeout: () {});
    }

    final ad = _ad;
    if (ad == null) return;

    final dismissed = Completer<void>();
    _showing = true;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) =>
          debugPrint('VideoInterstitialAd shown'),
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('VideoInterstitialAd dismissed');
        _showing = false;
        ad.dispose();
        _ad = null;
        if (!dismissed.isCompleted) dismissed.complete();
        unawaited(load());
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('VideoInterstitialAd failed to show: $error');
        _showing = false;
        ad.dispose();
        _ad = null;
        if (!dismissed.isCompleted) dismissed.complete();
        unawaited(load());
      },
    );

    try {
      _lastShownAt = DateTime.now();
      await ad.show();
    } catch (e) {
      debugPrint('VideoInterstitialAd show error: $e');
      _showing = false;
      ad.dispose();
      _ad = null;
      if (!dismissed.isCompleted) dismissed.complete();
      return;
    }
    return dismissed.future;
  }
}
