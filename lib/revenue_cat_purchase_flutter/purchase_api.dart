import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/entitlement.dart';

class PurchaseApi {
  static const String _premiumOfferingId = 'premium';
  static const String _premiumSubEntitlementId = 'premium_subscription';
  static const String _premiumOneTimeEntitlementId = 'premium_lifetime';
  
  static bool _billingUnavailable = false;

  static bool get isBillingUnavailable => _billingUnavailable;

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
      
      // Debug: Print all available offerings
      debugPrint('Available offerings: ${offerings.all.keys.toList()}');
      debugPrint('Current offering: ${offerings.current?.identifier}');
      
      // Try to get premium offering
      var premiumOffering = offerings.all[_premiumOfferingId];
      
      // If premium not found, try current offering or first available
      if (premiumOffering == null && offerings.current != null) {
        debugPrint('Premium offering not found, using current offering: ${offerings.current!.identifier}');
        premiumOffering = offerings.current;
      }
      
      // If still null, try the first available offering
      if (premiumOffering == null && offerings.all.isNotEmpty) {
        final firstKey = offerings.all.keys.first;
        debugPrint('Using first available offering: $firstKey');
        premiumOffering = offerings.all[firstKey];
      }
      
      return premiumOffering;
    } on PlatformException catch (e) {
      debugPrint('Error fetching premium offering: ${e.message}');
      // Check if this is a billing unavailable error (common in Google Play testing)
      if (e.message?.contains('BILLING_UNAVAILABLE') == true || 
          e.message?.contains('billing API version') == true) {
        _billingUnavailable = true;
        debugPrint('Billing unavailable - this may be a testing environment');
      }
      return null;
    }
  }

  static Future<bool> purchasePackage(Package package) async {
    try {
      final purchaserInfo = await Purchases.purchasePackage(package);
      // Check for any premium entitlement
      return purchaserInfo.entitlements.active.containsKey(_premiumOneTimeEntitlementId) ||
             purchaserInfo.entitlements.active.containsKey(_premiumSubEntitlementId) ||
             purchaserInfo.entitlements.active.containsKey(_premiumOfferingId);
    } on PlatformException catch (e) {
      debugPrint('Error purchasing package: ${e.message}');
      return false;
    }
  }

  static Future<bool> restorePurchases() async {
    try {
      final restoredInfo = await Purchases.restorePurchases();
      // Check for any premium entitlement
      return restoredInfo.entitlements.active.containsKey(_premiumOneTimeEntitlementId) ||
             restoredInfo.entitlements.active.containsKey(_premiumSubEntitlementId) ||
             restoredInfo.entitlements.active.containsKey(_premiumOfferingId);
    } on PlatformException catch (e) {
      debugPrint('Error restoring purchases: ${e.message}');
      return false;
    }
  }
}
