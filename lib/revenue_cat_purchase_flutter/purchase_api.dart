import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/entitlement.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PurchaseApi {
  // New prefixed entitlement/offering IDs for unified RC project
  static const String _premiumOfferingId = 'smg_premium';
  static const String _premiumOneTimeEntitlementId = 'smg_premium';

  // Monthly subscription (in-app)
  static const String _subscriptionOfferingId = 'smg_fingerings';
  static const String _subscriptionEntitlementId = 'smg_fingerings_library';

  // Old entitlement/offering IDs — checked as fallback during migration
  // TODO: Remove these 30+ days after unified RC project migration
  static const String _oldPremiumOfferingId = 'premium';
  static const String _oldPremiumOneTimeEntitlementId = 'premium_lifetime';
  static const String _oldSubscriptionOfferingId = 'fingerings_library';
  static const String _oldSubscriptionEntitlementId = 'fingerings_library';

  static bool _billingUnavailable = false;

  static bool get isBillingUnavailable => _billingUnavailable;

  static Future<void> init(String apiKey) async {
    await Purchases.setLogLevel(LogLevel.debug);
    await Purchases.configure(PurchasesConfiguration(apiKey));

    // One-time migration: restore purchases so RC re-validates receipts
    // and grants new prefixed entitlements (smg_premium_lifetime, smg_fingerings_library)
    try {
      final prefs = await SharedPreferences.getInstance();
      final didMigrate = prefs.getBool('rc_entitlement_migration_v1') ?? false;
      if (!didMigrate) {
        debugPrint('[PurchaseApi] Running one-time entitlement migration restore...');
        await Purchases.restorePurchases();
        await prefs.setBool('rc_entitlement_migration_v1', true);
        debugPrint('[PurchaseApi] Migration restore complete');
      }
    } catch (e) {
      debugPrint('[PurchaseApi] Migration restore failed (non-fatal): $e');
    }
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

      // Check both new prefixed and old entitlement names for migration
      final hasSubscription =
          activeEntitlements.containsKey(_subscriptionEntitlementId) ||
              activeEntitlements.containsKey(_oldSubscriptionEntitlementId) ||
              activeEntitlements.containsKey('all_access');
      final hasLifetime =
          activeEntitlements.containsKey(_premiumOneTimeEntitlementId) ||
              activeEntitlements.containsKey(_oldPremiumOneTimeEntitlementId);

      // Subscriber gets everything (subscription takes precedence over lifetime)
      if (hasSubscription) {
        return Entitlement.premiumSub;
      }

      // Lifetime user: scales, audio, download (no instruments, no cloud library)
      if (hasLifetime) {
        return Entitlement.premiumOneTime;
      }

      return Entitlement.free;
    } catch (e) {
      debugPrint('Error getting user entitlement: $e');
      return Entitlement.free;
    }
  }

  /// Check if user has fingerings library access (either via fingerings sub or premium)
  static Future<bool> hasFingeringsLibraryAccess() async {
    try {
      final entitlement = await getUserEntitlement();
      return entitlement.hasFingeringsLibraryAccess;
    } catch (e) {
      debugPrint('Error checking fingerings library access: $e');
      return false;
    }
  }

  /// Fetch the fingerings library offering for purchase
  static Future<Offering?> fetchFingeringsLibraryOffering() async {
    try {
      final offerings = await Purchases.getOfferings();

      debugPrint('Looking for subscription offering: $_subscriptionOfferingId');

      var fingeringsOffering = offerings.all[_subscriptionOfferingId];

      // Fallback to old offering ID during migration
      if (fingeringsOffering == null) {
        debugPrint('New offering not found, trying old: $_oldSubscriptionOfferingId');
        fingeringsOffering = offerings.all[_oldSubscriptionOfferingId];
      }

      if (fingeringsOffering == null) {
        debugPrint('Fingerings library offering not found');
      }

      return fingeringsOffering;
    } on PlatformException catch (e) {
      debugPrint('Error fetching fingerings library offering: ${e.message}');
      if (e.message?.contains('BILLING_UNAVAILABLE') == true ||
          e.message?.contains('billing API version') == true) {
        _billingUnavailable = true;
      }
      return null;
    }
  }

  static Future<Offering?> fetchPremiumOffering() async {
    try {
      final offerings = await Purchases.getOfferings();
      
      // Debug: Print all available offerings
      debugPrint('Available offerings: ${offerings.all.keys.toList()}');
      debugPrint('Current offering: ${offerings.current?.identifier}');
      
      // Try to get premium offering (new prefixed ID first, then old)
      var premiumOffering = offerings.all[_premiumOfferingId];

      // Fallback to old offering ID during migration
      if (premiumOffering == null) {
        debugPrint('New premium offering not found, trying old: $_oldPremiumOfferingId');
        premiumOffering = offerings.all[_oldPremiumOfferingId];
      }

      // If still not found, try current offering or first available
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
      // Check for any entitlement (new prefixed + old fallback + all_access)
      return purchaserInfo.entitlements.active.containsKey(_premiumOneTimeEntitlementId) ||
             purchaserInfo.entitlements.active.containsKey(_oldPremiumOneTimeEntitlementId) ||
             purchaserInfo.entitlements.active.containsKey(_subscriptionEntitlementId) ||
             purchaserInfo.entitlements.active.containsKey(_oldSubscriptionEntitlementId) ||
             purchaserInfo.entitlements.active.containsKey('all_access');
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
      // Check for any entitlement (new prefixed + old fallback + all_access)
      return restoredInfo.entitlements.active.containsKey(_premiumOneTimeEntitlementId) ||
             restoredInfo.entitlements.active.containsKey(_oldPremiumOneTimeEntitlementId) ||
             restoredInfo.entitlements.active.containsKey(_subscriptionEntitlementId) ||
             restoredInfo.entitlements.active.containsKey(_oldSubscriptionEntitlementId) ||
             restoredInfo.entitlements.active.containsKey('all_access');
    } on PlatformException catch (e) {
      debugPrint('Error restoring purchases: ${e.message}');
      return false;
    }
  }
}
