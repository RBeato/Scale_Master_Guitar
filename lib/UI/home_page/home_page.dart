import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scalemasterguitar/UI/home_page/selection_page.dart';
import 'package:scalemasterguitar/UI/paywall/unified_paywall.dart';
import 'package:scalemasterguitar/constants/app_theme.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/entitlement.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/provider/revenue_cat_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    if (entitlement.isPremium) {
      return const SelectionPage();
    } else {
      return const UnifiedPaywall();
    }
  }
}
