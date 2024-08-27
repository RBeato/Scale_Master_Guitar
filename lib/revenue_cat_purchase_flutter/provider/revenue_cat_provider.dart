import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:test/revenue_cat_purchase_flutter/entitlement.dart';
import 'package:test/revenue_cat_purchase_flutter/purchase_api.dart';

// Define a provider for RevenueCatNotifier
// final revenueCatProvider =
//     StateNotifierProvider<RevenueCatNotifier, Entitlement>((ref) {
//   return RevenueCatNotifier();
// });

final revenueCatProvider = Provider<Entitlement>((ref) {
  return Entitlement.paid;
});

// RevenueCatNotifier to manage entitlements state
class RevenueCatNotifier extends StateNotifier<Entitlement> {
  RevenueCatNotifier() : super(Entitlement.free) {
    init();
  }

  // Initialize RevenueCat and set up a listener for customer info updates
  Future<void> init() async {
    try {
      await PurchaseApi.init();
      Purchases.addCustomerInfoUpdateListener((purchaserInfo) async {
        await updatePurchaseStatus();
      });
    } on PlatformException catch (e) {
      debugPrint("Initialization error: ${e.toString()}");
    }
  }

  // Update the purchase status based on the current entitlements
  Future<void> updatePurchaseStatus() async {
    try {
      final purchaserInfo = await Purchases.getCustomerInfo();
      final entitlements = purchaserInfo.entitlements.active.values.toList();

      bool hasPremium = entitlements.any((entitlement) =>
          entitlement.identifier == "premium"); // Check for premium entitlement

      // Check if the premium entitlement has a trial period
      bool isOnTrial = entitlements.any((entitlement) =>
          entitlement.identifier == "premium" &&
          entitlement.willRenew &&
          entitlement.billingIssueDetectedAt == null &&
          (DateTime.now()
                  .difference(DateTime.parse(entitlement.latestPurchaseDate))
                  .inDays <
              7));

      if (isOnTrial) {
        state = Entitlement.trial;
      } else if (hasPremium) {
        state = Entitlement.paid;
      } else {
        state = Entitlement.free;
      }
    } on PlatformException catch (e) {
      debugPrint("Update purchase status error: ${e.toString()}");
      state = Entitlement.free;
    }
  }

  // Restore previous purchases and update the purchase status
  Future<void> restorePurchase() async {
    try {
      await Purchases.restorePurchases();
      await updatePurchaseStatus();
    } on PlatformException catch (e) {
      debugPrint("Restore purchase error: ${e.toString()}");
    }
  }
}
