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

      final hasSubscription =
          activeEntitlements.containsKey(_subscriptionEntitlementId) ||
              activeEntitlements.containsKey('all_access');
      final hasLifetime =
          activeEntitlements.containsKey(_premiumOneTimeEntitlementId);

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

      // IMPORTANT: Do NOT fall back to offerings.current or first available.
      // This is a unified Hub project with GPG/SMG/ENP offerings — the default
      // offering is likely a GPG product, not an SMG product.
      if (premiumOffering == null) {
        debugPrint('WARNING: SMG premium offering not found. Available: ${offerings.all.keys.toList()}');
        debugPrint('Current/default offering: ${offerings.current?.identifier} — NOT using it (may be GPG)');
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

  /// Check if user already has the entitlement that a package would grant.
  /// Returns a message string if already purchased, or null if safe to proceed.
  static Future<String?> checkAlreadyPurchased(Package package) async {
    try {
      final productId = package.storeProduct.identifier;

      // Check if this is a lifetime/premium product
      final isLifetimeProduct = productId == 'premium' ||
          productId == 'com.rbsoundz.scalemasterguitar.premium' ||
          package.packageType == PackageType.lifetime;

      // Check if this is a subscription product
      final isSubscriptionProduct = productId.contains('smg_fingerings') ||
          productId.contains('fingerings') ||
          package.packageType == PackageType.monthly ||
          package.packageType == PackageType.annual;

      // Check raw RC entitlements directly (not derived enum) because
      // getUserEntitlement() returns subscription when user has BOTH lifetime
      // + subscription, which would miss the lifetime check.
      final customerInfo = await getCustomerInfo();
      final active = customerInfo.entitlements.active;

      if (isLifetimeProduct) {
        if (active.containsKey(_premiumOneTimeEntitlementId)) {
          return 'You already have Lifetime access! No need to purchase again.';
        }
      }

      if (isSubscriptionProduct) {
        if (active.containsKey(_subscriptionEntitlementId)) {
          return 'You already have an active Pro subscription!';
        }
      }

      // If user has all_access (RiffRoutine ELITE), they already have everything
      if (active.containsKey('all_access')) {
        return 'All features are included with your RiffRoutine ELITE subscription!';
      }

      return null; // Safe to proceed with purchase
    } catch (e) {
      debugPrint('Error checking existing entitlement: $e');
      return null; // Allow purchase attempt if check fails
    }
  }

  static Future<bool> purchasePackage(Package package) async {
    try {
      // Guard: prevent duplicate purchases
      final alreadyPurchased = await checkAlreadyPurchased(package);
      if (alreadyPurchased != null) {
        debugPrint('Purchase blocked: $alreadyPurchased');
        throw PlatformException(
          code: 'ALREADY_PURCHASED',
          message: alreadyPurchased,
        );
      }

      final purchaserInfo = await Purchases.purchasePackage(package);
      return purchaserInfo.entitlements.active.containsKey(_premiumOneTimeEntitlementId) ||
             purchaserInfo.entitlements.active.containsKey(_subscriptionEntitlementId) ||
             purchaserInfo.entitlements.active.containsKey('all_access');
    } on PlatformException catch (e) {
      debugPrint('Error purchasing package: ${e.code} - ${e.message}');

      // Handle specific purchase errors with improved messaging
      switch (e.code) {
        case 'ALREADY_PURCHASED':
          // Re-throw with the descriptive message from checkAlreadyPurchased
          rethrow;

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
      return restoredInfo.entitlements.active.containsKey(_premiumOneTimeEntitlementId) ||
             restoredInfo.entitlements.active.containsKey(_subscriptionEntitlementId) ||
             restoredInfo.entitlements.active.containsKey('all_access');
    } on PlatformException catch (e) {
      debugPrint('Error restoring purchases: ${e.message}');
      return false;
    }
  }
}
