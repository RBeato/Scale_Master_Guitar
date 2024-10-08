import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PurchaseApi {
  static final _apiKey = dotenv.env['GOOGLE_API_KEY']!;

  static Future<void> init() async {
    PurchasesConfiguration configuration = PurchasesConfiguration(_apiKey)
      ..purchasesAreCompletedBy = const PurchasesAreCompletedByRevenueCat();

    await Purchases.configure(configuration);

    // Set the log level
    Purchases.setLogLevel(LogLevel.debug);
  }

  static Future<CustomerInfo> getCustomerInfo() async {
    try {
      return await Purchases.getCustomerInfo();
    } on PlatformException catch (e) {
      print('Error fetching customer info: ${e.message}');
      rethrow;
    }
  }

  static Future<bool> isPremiumUser() async {
    try {
      final customerInfo = await getCustomerInfo();
      return customerInfo.entitlements.active.containsKey('premium');
    } catch (e) {
      print('Error checking premium status: $e');
      return false;
    }
  }

  static Future<List<Offering>> fetchOffersByIds(List<String> ids) async {
    final offers = await fetchOffers();

    return offers.where((offer) => ids.contains(offer.identifier)).toList();
  }

  static Future<List<Offering>> fetchOffers({bool all = true}) async {
    try {
      final offerings = await Purchases.getOfferings();

      if (!all) {
        final current = offerings.current;
        return current == null ? List.empty() : [current];
      } else {
        return offerings.all.values.toList();
      }
    } on PlatformException catch (e) {
      print(e);
      return List.empty();
    }
  }

  static Future<bool> purchasePackage(Package package) async {
    try {
      await Purchases.purchasePackage(package);
      return true;
    } on PlatformException {
      return false;
    }
  }
}
