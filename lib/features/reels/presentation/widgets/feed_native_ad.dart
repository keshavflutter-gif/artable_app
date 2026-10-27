import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Full-page AdMob native slot used in the Reels (Challenge Arena) feed.
class FeedNativeAd extends StatefulWidget {
  const FeedNativeAd({super.key, this.fallback});

  final Widget? fallback;

  static const String adUnitId = 'ca-app-pub-8377462640468284/6757458882';
  static const String _testAdUnitId = 'ca-app-pub-3940256099942544/2247696110';

  @override
  State<FeedNativeAd> createState() => _FeedNativeAdState();
}

class _FeedNativeAdState extends State<FeedNativeAd> {
  NativeAd? _ad;
  bool _loaded = false;
  bool _requested = false;

  NativeTemplateStyle get _template => NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: const Color(0xFF160C28),
        cornerRadius: 16,
        callToActionTextStyle: NativeTemplateTextStyle(
          size: 14,
          style: NativeTemplateFontStyle.bold,
          textColor: Colors.white,
          backgroundColor: const Color(0xFFFF3D77),
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          size: 16,
          style: NativeTemplateFontStyle.bold,
          textColor: Colors.white,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          size: 13,
          textColor: const Color(0xFFD4CDE3),
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          size: 12,
          textColor: const Color(0xFFA99FBA),
        ),
      );

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

      final loaded = await _request(FeedNativeAd.adUnitId);
      if (loaded || !mounted) return;

      debugPrint('FeedNativeAd: production no-fill, retrying test native');
      await _request(FeedNativeAd._testAdUnitId);
    } catch (e) {
      debugPrint('FeedNativeAd load error: $e');
    }
  }

  Future<bool> _request(String adUnitId) async {
    final done = Completer<bool>();
    final ad = NativeAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      nativeTemplateStyle: _template,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint('FeedNativeAd loaded ($adUnitId)');
          if (!mounted) {
            ad.dispose();
            if (!done.isCompleted) done.complete(false);
            return;
          }
          setState(() {
            _ad = ad as NativeAd;
            _loaded = true;
          });
          if (!done.isCompleted) done.complete(true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('FeedNativeAd failed ($adUnitId): $error');
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
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 96, 18, 96),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
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
