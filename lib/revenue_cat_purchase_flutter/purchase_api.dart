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
      debugPrint('Error purchasing package: ${e.code} - ${e.message}');

      // Handle specific purchase errors with improved messaging
      switch (e.code) {
        case 'PURCHASE_CANCELLED':
        case 'PURCHASES_ERROR_PURCHASE_CANCELLED':
          debugPrint('Purchase was cancelled by user');
          return false;

        case 'PURCHASE_NOT_ALLOWED':
        case 'PURCHASES_ERROR_PURCHASE_NOT_ALLOWED':
          debugPrint('Purchase not allowed - App Store configuration issue');
          throw PlatformException(
            code: 'PURCHASE_NOT_ALLOWED',
            message: 'Purchases are not allowed on this device. Please check your App Store settings and ensure you have a valid payment method.',
          );

        case 'STORE_PROBLEM':
        case 'PURCHASES_ERROR_STORE_PROBLEM':
          debugPrint('Store problem - StoreKit configuration or connectivity issue');
          throw PlatformException(
            code: 'STORE_PROBLEM',
            message: 'Unable to connect to the App Store. Please check your internet connection and try again later.',
          );

        case 'PURCHASES_ERROR_PAYMENT_PENDING':
          debugPrint('Payment is pending approval');
          throw PlatformException(
            code: 'PAYMENT_PENDING',
            message: 'Your payment is pending approval. You will receive access once the payment is processed.',
          );

        case 'PURCHASES_ERROR_INVALID_CREDENTIALS':
        case 'PURCHASES_ERROR_NETWORK_ERROR':
          debugPrint('Network or authentication error');
          throw PlatformException(
            code: 'NETWORK_ERROR',
            message: 'Network error occurred. Please check your internet connection and try again.',
          );

        case 'PURCHASES_ERROR_RECEIPT_ALREADY_IN_USE':
          debugPrint('Receipt already in use');
          throw PlatformException(
            code: 'RECEIPT_IN_USE',
            message: 'This purchase has already been used. Try restoring your purchases instead.',
          );

        default:
          debugPrint('Unknown purchase error: ${e.code}');
          throw PlatformException(
            code: e.code,
            message: e.message ?? 'An unexpected error occurred during purchase. Please try again.',
          );
      }
    } catch (e) {
      debugPrint('Unexpected error during purchase: $e');
      throw PlatformException(
        code: 'UNKNOWN_ERROR',
        message: 'An unexpected error occurred. Please try again.',
      );
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
