// import 'package:flutter/services.dart';
// import 'package:purchases_flutter/purchases_flutter.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';

// class PurchaseApi {
//   static final String _apiKey = dotenv.env['REVENUE_CAT_API_KEY']!;

//   static Future init() async {
//     await Purchases.setDebugLogsEnabled(true);
//     await Purchases.setup(_apiKey);
//   }

//   static Future<List<Offering>> fetchOffers() async {
//     try {
//       final offerings = await Purchases.getOfferings();
//       final current = offerings.current;

//       return current == null ? [] : [current];
//     } on PlatformException {
//       return [];
//     }
//   }

//   static Future<bool> purchasePackage(Package package) async {
//     try {
//       await Purchases.purchasePackage(package);
//       return true;
//     } on PlatformException {
//       return false;
//     }
//   }
// }
