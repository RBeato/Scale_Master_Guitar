import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:test/revenue_cat_purchase_flutter/entitlement.dart';
import 'package:test/revenue_cat_purchase_flutter/purchase_api.dart';

// Define a provider for RevenueCatNotifier
final revenueCatProvider =
    StateNotifierProvider<RevenueCatNotifier, Entitlement>((ref) {
  return RevenueCatNotifier();
});

class RevenueCatNotifier extends StateNotifier<Entitlement> {
  RevenueCatNotifier() : super(Entitlement.free) {
    init();
  }

  // Initialize RevenueCat and set up a listener for customer info updates
  Future<void> init() async {
    await PurchaseApi.init();
    await updatePurchaseStatus();
    Purchases.addCustomerInfoUpdateListener((_) => updatePurchaseStatus());
  }

  Future<void> updatePurchaseStatus() async {
    final isPremium = await PurchaseApi.isPremiumUser();
    state = isPremium ? Entitlement.premium : Entitlement.free;
  }

  Future<void> restorePurchases() async {
    await Purchases.restorePurchases();
    await updatePurchaseStatus();
  }
}
