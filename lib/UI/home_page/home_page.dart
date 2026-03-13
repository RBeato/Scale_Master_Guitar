import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scalemasterguitar/UI/home_page/selection_page.dart';
import 'package:scalemasterguitar/UI/paywall/unified_paywall.dart';
import 'package:scalemasterguitar/constants/app_theme.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/entitlement.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/provider/revenue_cat_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    // Fallback: if entitlement check hasn't completed in 15s, force-show app in free mode
    _fallbackTimer = Timer(const Duration(seconds: 15), () {
      if (mounted && !ref.read(entitlementLoadedProvider)) {
        debugPrint('[SMG] Entitlement check timed out — showing app in free mode');
        ref.read(entitlementLoadedProvider.notifier).state = true;
      }
    });
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasLoaded = ref.watch(entitlementLoadedProvider);
    final entitlement = ref.watch(revenueCatProvider);

    // Show loading screen until entitlement is resolved
    if (!hasLoaded) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.orangeAccent),
        ),
      );
    }

    // Cancel fallback timer once loaded
    _fallbackTimer?.cancel();

    if (entitlement.isPremium) {
      return const SelectionPage();
    } else {
      return const UnifiedPaywall();
    }
  }
}
