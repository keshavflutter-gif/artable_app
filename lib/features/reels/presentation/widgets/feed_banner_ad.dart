import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Full-page AdMob banner slot used in the Reels (Challenge Arena) feed.
class FeedBannerAd extends StatefulWidget {
  const FeedBannerAd({super.key, this.fallback});

  final Widget? fallback;

  static const String adUnitId = 'ca-app-pub-8377462640468284/7637802428';
  static const String _testAdUnitId = 'ca-app-pub-3940256099942544/6300978111';

  @override
  State<FeedBannerAd> createState() => _FeedBannerAdState();
}

class _FeedBannerAdState extends State<FeedBannerAd> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    if (kIsWeb || _requested) return;
    _requested = true;

    try {
      await MobileAds.instance.initialize();
      if (!mounted) return;

      final loaded = await _request(FeedBannerAd.adUnitId, AdSize.mediumRectangle);
      if (loaded || !mounted) return;

      final width = MediaQuery.sizeOf(context).width.truncate();
      final adaptive = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
      if (!mounted) return;

      if (adaptive != null) {
        final adaptiveLoaded = await _request(FeedBannerAd.adUnitId, adaptive);
        if (adaptiveLoaded || !mounted) return;
      }

      debugPrint('FeedBannerAd: production no-fill, retrying test banner');
      await _request(FeedBannerAd._testAdUnitId, AdSize.mediumRectangle);
    } catch (e) {
      debugPrint('FeedBannerAd load error: $e');
    }
  }

  Future<bool> _request(String adUnitId, AdSize size) async {
    final done = Completer<bool>();
    final ad = BannerAd(
      adUnitId: adUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('FeedBannerAd loaded ($adUnitId)');
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
          debugPrint('FeedBannerAd failed ($adUnitId): $error');
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
    if (!_loaded || ad == null) {
      return widget.fallback ?? const SizedBox.expand();
    }

    return ColoredBox(
      color: const Color(0xFF0B0714),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: SizedBox(
              width: ad.size.width.toDouble(),
              height: ad.size.height.toDouble(),
              child: AdWidget(ad: ad),
            ),
          ),
          const Positioned(
            top: 68,
            left: 18,
            child: _AdBadge(),
          ),
        ],
      ),
    );
  }
}

class _AdBadge extends StatelessWidget {
  const _AdBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Ad',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Color(0xFF170B33),
        ),
      ),
    );
  }
}
