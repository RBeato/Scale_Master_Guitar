import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  static String get _bannerAdUnitId {
    if (Platform.isIOS) {
      return dotenv.get('ADMOB_BANNER_IOS_AD_UNIT_ID', fallback: 'ca-app-pub-3940256099942544/6300978111');
    } else {
      return dotenv.get('ADMOB_BANNER_ANDROID_AD_UNIT_ID', fallback: 'ca-app-pub-3940256099942544/6300978111');
    }
  }
  BannerAd? _bannerAd;
  bool _isInitialized = false;
  bool _isProUser = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await MobileAds.instance.initialize();
    _isInitialized = true;
    
    // Check if user has pro
    await _checkProStatus();
  }

  Future<void> _checkProStatus() async {
    try {
      final purchaserInfo = await Purchases.getCustomerInfo();
      _isProUser = purchaserInfo.entitlements.active.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking pro status: $e');
    }
  }

  BannerAd? getBannerAd() {
    if (_isProUser || !_isInitialized) return null;
    
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) => debugPrint('Ad loaded'),
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint('Ad failed to load: $error');
          ad.dispose();
        },
        onAdOpened: (Ad ad) => debugPrint('Ad opened'),
        onAdClosed: (Ad ad) => debugPrint('Ad closed'),
      ),
    )..load();
    
    return _bannerAd;
  }

  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
  }

  // Call this when user upgrades to pro
  Future<void> onProStatusChanged() async {
    await _checkProStatus();
    if (_isProUser) {
      disposeBannerAd();
    }
  }
}

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  final AdService _adService = AdService();

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = _adService.getBannerAd();
    setState(() {});
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_bannerAd == null) {
      return const SizedBox.shrink();
    }
    
    return Container(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      alignment: Alignment.center,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
