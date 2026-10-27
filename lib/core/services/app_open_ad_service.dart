import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Loads and shows the AdMob **App Open** ad.
///
/// Flow: Splash loads the ad → navigate to Home → Home shows it after
/// the route has settled (showing during `go()` fails on Android).
class AppOpenAdService {
  AppOpenAdService._();

  static final AppOpenAdService instance = AppOpenAdService._();

  static const String _androidAdUnitId =
      'ca-app-pub-8377462640468284/8655582654';
  static const String _iosAdUnitId = 'ca-app-pub-8377462640468284/8655582654';

  /// Google official App Open test units — used only when production 403s.
  static const String _androidTestAdUnitId =
      'ca-app-pub-3940256099942544/9257395921';
  static const String _iosTestAdUnitId =
      'ca-app-pub-3940256099942544/5575463023';

  static const Duration _maxCacheDuration = Duration(hours: 4);

  static String get adUnitId =>
      Platform.isIOS ? _iosAdUnitId : _androidAdUnitId;

  static String get _testAdUnitId =>
      Platform.isIOS ? _iosTestAdUnitId : _androidTestAdUnitId;

  AppOpenAd? _ad;
  DateTime? _loadTime;
  bool _isLoading = false;
  bool _isShowing = false;
  bool _pendingHomeShow = false;
  Completer<void>? _loadCompleter;

  bool get isAdAvailable {
    final ad = _ad;
    final loadedAt = _loadTime;
    if (ad == null || loadedAt == null) return false;
    return DateTime.now().difference(loadedAt) < _maxCacheDuration;
  }

  /// Call from Splash right before `go(Home)` so Home can show the ad.
  void markPendingHomeShow() => _pendingHomeShow = true;

  Future<void> load() async {
    if (kIsWeb) return;
    if (isAdAvailable) return;
    if (_isLoading && _loadCompleter != null) return _loadCompleter!.future;

    _isLoading = true;
    final completer = _loadCompleter = Completer<void>();

    try {
      await MobileAds.instance.initialize();
      var loaded = await _request(adUnitId);
      if (!loaded) {
        debugPrint('AppOpenAd: production no-fill, retrying test unit');
        loaded = await _request(_testAdUnitId);
      }
      if (!loaded) {
        debugPrint('AppOpenAd: no ad available');
      }
    } catch (e) {
      debugPrint('AppOpenAd load error: $e');
    } finally {
      _isLoading = false;
      if (!completer.isCompleted) completer.complete();
    }
    return completer.future;
  }

  Future<bool> _request(String unitId) async {
    final done = Completer<bool>();
    await AppOpenAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('AppOpenAd loaded ($unitId)');
          _ad = ad;
          _loadTime = DateTime.now();
          if (!done.isCompleted) done.complete(true);
        },
        onAdFailedToLoad: (error) {
          debugPrint('AppOpenAd failed to load ($unitId): $error');
          if (!done.isCompleted) done.complete(false);
        },
      ),
    );
    return done.future;
  }

  /// Called from Home after the first frame. Shows the splash-loaded ad
  /// once the activity is resumed (not mid-navigation).
  Future<void> showWhenHomeReady() async {
    if (kIsWeb || !_pendingHomeShow || _isShowing) return;
    _pendingHomeShow = false;

    if (!isAdAvailable) {
      await load().timeout(const Duration(seconds: 6), onTimeout: () {});
    }

    // Let the Home route finish opening — showing during go() is dropped.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await _showLoadedAd();
  }

  Future<void> showIfAvailable({
    Duration maxWait = const Duration(seconds: 3),
  }) async {
    if (kIsWeb || _isShowing) return;
    if (!isAdAvailable && _isLoading && _loadCompleter != null) {
      await _loadCompleter!.future.timeout(maxWait, onTimeout: () {});
    }
    await _showLoadedAd();
  }

  Future<void> _showLoadedAd() async {
    if (_isShowing) return;
    final ad = _ad;
    if (ad == null || !isAdAvailable) {
      _disposeAd();
      return;
    }

    final dismissed = Completer<void>();
    _isShowing = true;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => debugPrint('AppOpenAd shown'),
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('AppOpenAd failed to show: $error');
        _isShowing = false;
        ad.dispose();
        _clear();
        if (!dismissed.isCompleted) dismissed.complete();
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('AppOpenAd dismissed');
        _isShowing = false;
        ad.dispose();
        _clear();
        if (!dismissed.isCompleted) dismissed.complete();
      },
    );

    try {
      await ad.show();
    } catch (e) {
      debugPrint('AppOpenAd show error: $e');
      _isShowing = false;
      _disposeAd();
      if (!dismissed.isCompleted) dismissed.complete();
    }
    return dismissed.future;
  }

  void _clear() {
    _ad = null;
    _loadTime = null;
  }

  void _disposeAd() {
    _ad?.dispose();
    _clear();
  }
}
