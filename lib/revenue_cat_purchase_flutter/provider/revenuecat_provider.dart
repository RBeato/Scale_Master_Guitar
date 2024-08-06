import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:test/revenue_cat_purchase_flutter/entitlement.dart';
import 'package:test/revenue_cat_purchase_flutter/purchase_api.dart';

final revenuecatProvider =
    StateNotifierProvider<RevenuecatNotifier, Entitlement>((ref) {
  return RevenuecatNotifier();
});

class RevenuecatNotifier extends StateNotifier<Entitlement> {
  RevenuecatNotifier() : super(Entitlement.free) {
    init();
  }

  Future<void> init() async {
    await PurchaseApi.init();
    Purchases.addCustomerInfoUpdateListener((purchaserInfo) async {
      updatePurchaseStatus();
    });
    updatePurchaseStatus();
  }

  Future<void> updatePurchaseStatus() async {
    final purchaserInfo = await Purchases.getCustomerInfo();
    final entitlements = purchaserInfo.entitlements.active.values.toList();
    state = entitlements.isEmpty ? Entitlement.free : Entitlement.allCourses;
  }
}
