// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:in_app_purchase/in_app_purchase.dart';

// enum SubscriptionStatus {
//   active, // User has an active subscription
//   trial, // User is in a free trial period
//   inactive, // User does not have an active subscription or trial
//   error // An error occurred while checking the subscription status
// }

// final subscriptionProvider = FutureProvider<SubscriptionStatus>((ref) async {
//   final InAppPurchase iap = InAppPurchase.instance;
//   const Set<String> _kIds = {'monthly_subscription'};

//   try {
//     final ProductDetailsResponse response =
//         await iap.queryProductDetails(_kIds);
//     debugPrint('Product Details Response: $response');

//     if (response.error != null) {
//       // Handle response error
//       throw SubscriptionException(response.error!.message);
//     }

//     if (response.notFoundIDs.isNotEmpty || response.productDetails.isEmpty) {
//       // Handle missing product details
//       throw SubscriptionException('Product details not found');
//     }

//     final Stream<List<PurchaseDetails>> purchaseStream = iap.purchaseStream;
//     await for (var purchases in purchaseStream) {
//       for (var purchase in purchases) {
//         switch (purchase.status) {
//           case PurchaseStatus.purchased:
//             if (purchase.pendingCompletePurchase) {
//               await iap.completePurchase(purchase);
//             }
//             // Assume the serverVerificationData contains 'FreeTrial' for trial users
//             if (purchase.verificationData.serverVerificationData
//                 .contains('FreeTrial')) {
//               return SubscriptionStatus.trial;
//             } else {
//               return SubscriptionStatus.active;
//             }
//             break;
//           case PurchaseStatus.error:
//             // Handle purchase error
//             throw SubscriptionException(purchase.error!.message);
//             break;
//           case PurchaseStatus.canceled:
//           case PurchaseStatus.restored:
//           default:
//             // Handle other cases as necessary
//             break;
//         }
//       }
//     }
//   } catch (e) {
//     // You may want to log the error or notify the user
//     return SubscriptionStatus.error;
//   }

//   return SubscriptionStatus.inactive;
// });

// class SubscriptionException implements Exception {
//   final String message;

//   SubscriptionException(this.message);
// }
