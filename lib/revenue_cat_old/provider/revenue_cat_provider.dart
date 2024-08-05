// import 'package:flutter/material.dart';
// import 'package:purchases_flutter/purchases_flutter.dart';
// import '../revenue_cat/purchase_api.dart';

// class SubscriptionPage extends StatefulWidget {
//   @override
//   _SubscriptionPageState createState() => _SubscriptionPageState();
// }

// class _SubscriptionPageState extends State<SubscriptionPage> {
//   List<Package> packages = [];

//   @override
//   void initState() {
//     super.initState();
//     fetchPackages();
//   }

//   Future<void> fetchPackages() async {
//     final offers = await PurchaseApi.fetchOffers();
//     if (offers.isNotEmpty) {
//       setState(() {
//         packages = offers[0].availablePackages;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Subscribe')),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Text('Your trial period has ended.',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 20),
//             const Text('Subscribe now to continue using our service.',
//                 style: TextStyle(fontSize: 16)),
//             const SizedBox(height: 40),
//             packages.isNotEmpty
//                 ? Column(
//                     children: packages.map((pkg) {
//                       return ElevatedButton(
//                         onPressed: () async {
//                           final success =
//                               await PurchaseApi.purchasePackage(pkg);
//                           if (success) {
//                             // handle successful purchase
//                           }
//                         },
//                         child: Text('Subscribe for ${pkg.product.priceString}'),
//                       );
//                     }).toList(),
//                   )
//                 : const CircularProgressIndicator(),
//           ],
//         ),
//       ),
//     );
//   }
// }
