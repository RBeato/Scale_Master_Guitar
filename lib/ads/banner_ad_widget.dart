import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../revenue_cat_purchase_flutter/provider/revenue_cat_provider.dart';
import '../services/feature_restriction_service.dart';

class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({super.key});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _bannerAd;

  static String get _bannerAdUnitId {
    if (Platform.isIOS) {
      return dotenv.get('ADMOB_BANNER_IOS_AD_UNIT_ID', fallback: 'ca-app-pub-3940256099942544/6300978111');
    } else {
      return dotenv.get('ADMOB_BANNER_ANDROID_AD_UNIT_ID', fallback: 'ca-app-pub-3940256099942544/6300978111');
    }
  }

  @override
  void initState() {
    super.initState();
    // Load ad on next frame to ensure widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndLoadAd();
    });
  }

  void _checkAndLoadAd() {
    final entitlement = ref.read(revenueCatProvider);
    if (FeatureRestrictionService.shouldShowAds(entitlement)) {
      _loadAd();
    }
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() {}),
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entitlement = ref.watch(revenueCatProvider);
    
    if (!FeatureRestrictionService.shouldShowAds(entitlement) || _bannerAd == null) {
      return const SizedBox.shrink();
    }
    
    return SizedBox(
      height: _bannerAd!.size.height.toDouble(),
      width: _bannerAd!.size.width.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
