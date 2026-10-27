import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob banner for the Home Dashboard "Home Banner" slot.
class HomeBannerAd extends StatefulWidget {
  const HomeBannerAd({super.key, this.fallback});

  /// Shown while the ad is loading, and if every request fails to fill.
  final Widget? fallback;

  static const String adUnitId = 'ca-app-pub-8377462640468284/1511148864';

  /// Google's official standard-banner test unit.
  static const String _testAdUnitId = 'ca-app-pub-3940256099942544/6300978111';

  @override
  State<HomeBannerAd> createState() => _HomeBannerAdState();
}

class _HomeBannerAdState extends State<HomeBannerAd> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAd();
  }

  Future<void> _loadAd() async {
    if (kIsWeb || _requested) return;
    _requested = true;

    try {
      await MobileAds.instance.initialize();
      if (!mounted) return;

      // Standard 320x50 first — matches a normal AdMob "Banner" unit.
      // Large adaptive can 403 on units that are not large-adaptive.
      var loaded = await _requestBanner(HomeBannerAd.adUnitId, AdSize.banner);
      if (loaded || !mounted) return;

      final width = MediaQuery.sizeOf(context).width.truncate();
      final adaptive = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
      if (!mounted) return;
      if (adaptive != null) {
        loaded = await _requestBanner(HomeBannerAd.adUnitId, adaptive);
        if (loaded || !mounted) return;
      }

      debugPrint(
        'HomeBannerAd: production 403/no-fill. '
        'AdMob rejected this app+unit (check package com.artable '
        'and that the unit is Banner). Retrying Google test banner.',
      );
      await _requestBanner(HomeBannerAd._testAdUnitId, AdSize.banner);
    } catch (e) {
      debugPrint('HomeBannerAd load error: $e');
    }
  }

  Future<bool> _requestBanner(String adUnitId, AdSize size) async {
    final done = Completer<bool>();

    final ad = BannerAd(
      adUnitId: adUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('HomeBannerAd loaded ($adUnitId, ${size.width}x${size.height})');
          if (!mounted) {
            ad.dispose();
            if (!done.isCompleted) done.complete(false);
            return;
          }
          setState(() {
            _ad = ad as BannerAd;
            _loaded = true;
          });
          if (!done.isCompleted) done.complete(true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('HomeBannerAd failed ($adUnitId, ${size.width}x${size.height}): $error');
          ad.dispose();
          if (!done.isCompleted) done.complete(false);
        },
      ),
    );

    await ad.load();
    return done.future;
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (_loaded && ad != null) {
      return ColoredBox(
        color: Colors.white,
        child: SizedBox(
          width: double.infinity,
          height: ad.size.height.toDouble(),
          child: AdWidget(ad: ad),
        ),
      );
    }
    return widget.fallback ?? const SizedBox.shrink();
  }
}
