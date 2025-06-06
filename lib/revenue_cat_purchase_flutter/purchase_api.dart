import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/entitlement.dart';

class PurchaseApi {
  static const String _premiumOfferingId = 'premium';
  static const String _premiumSubEntitlementId = 'premium_subscription';
  static const String _premiumOneTimeEntitlementId = 'premium_lifetime';

  static Future<void> init(String apiKey) async {
    await Purchases.setLogLevel(LogLevel.debug);
    await Purchases.configure(PurchasesConfiguration(apiKey));
  }

  static Future<CustomerInfo> getCustomerInfo() async {
    try {
      return await Purchases.getCustomerInfo();
    } on PlatformException catch (e) {
      debugPrint('Error fetching customer info: ${e.message}');
      rethrow;
    }
  }

  static Future<bool> isPremiumUser() async {
    try {
      final entitlement = await getUserEntitlement();
      return entitlement.isPremium;
    } catch (e) {
      debugPrint('Error checking premium status: $e');
      return false;
    }
  }

  static Future<Entitlement> getUserEntitlement() async {
    try {
      final customerInfo = await getCustomerInfo();
      final activeEntitlements = customerInfo.entitlements.active;
      
      // Check for one-time purchase first
      if (activeEntitlements.containsKey(_premiumOneTimeEntitlementId)) {
        return Entitlement.premiumOneTime;
      }
      
      // Check for subscription
      if (activeEntitlements.containsKey(_premiumSubEntitlementId)) {
        return Entitlement.premiumSub;
      }
      
      // Fallback to old premium check for backward compatibility
      if (activeEntitlements.containsKey(_premiumOfferingId)) {
        return Entitlement.premiumSub;
      }
      
      return Entitlement.free;
    } catch (e) {
      debugPrint('Error getting user entitlement: $e');
      return Entitlement.free;
    }
  }

  static Future<Offering?> fetchPremiumOffering() async {
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.all[_premiumOfferingId];
    } on PlatformException catch (e) {
      debugPrint('Error fetching premium offering: ${e.message}');
      return null;
    }
  }

  static Future<bool> purchasePackage(Package package) async {
    try {
      final purchaserInfo = await Purchases.purchasePackage(package);
      return purchaserInfo.entitlements.active.containsKey(_premiumOfferingId);
    } on PlatformException catch (e) {
      debugPrint('Error purchasing package: ${e.message}');
      return false;
    }
  }

  static Future<bool> restorePurchases() async {
    try {
      final restoredInfo = await Purchases.restorePurchases();
      return restoredInfo.entitlements.active.containsKey(_premiumOfferingId);
    } on PlatformException catch (e) {
      debugPrint('Error restoring purchases: ${e.message}');
      return false;
    }
  }
}
