import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'selection_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final entitlementProviderInstance = ref.watch(entitlementProvider);
    return const SelectionPage();

    //   return FutureBuilder(
    //     future: entitlementProviderInstance.updatePurchaseStatus(),
    //     builder: (context, snapshot) {
    //       if (snapshot.connectionState == ConnectionState.waiting) {
    //         // Show a loading spinner while waiting for the future to complete
    //         return const Center(child: CircularProgressIndicator());
    //       } else if (snapshot.connectionState == ConnectionState.done) {
    //         if (entitlementProviderInstance.entitlement == Entitlement.paid) {
    //           // Redirect to the SelectionPage if the user has the paid entitlement
    //           WidgetsBinding.instance!.addPostFrameCallback((_) {
    //             Navigator.pushReplacement(
    //               context,
    //               MaterialPageRoute(builder: (context) => const SelectionPage()),
    //             );
    //           });
    //           return const SizedBox
    //               .shrink(); // Return an empty widget while redirecting
    //         } else {
    //           // Show the subscription prompt if the user does not have the paid entitlement
    //           return

    //       Scaffold(
    //         appBar: AppBar(
    //           title: Text(title),
    //         ),
    //         body: Center(
    //           child: ElevatedButton(
    //             onPressed: () {
    //               // Navigator.push(
    //               //   context,
    //               //   MaterialPageRoute(
    //               //       builder: (context) => SubscriptionPage()),
    //               // );
    //             },
    //             child: const Text('Subscribe Now'),
    //           ),
    //         ),
    //       );
    //     }
    //   } else {
    //   // Handle the case where the future failed
    //   return Scaffold(
    //     appBar: AppBar(
    //       title: Text(title),
    //     ),
    //     body: const Center(
    //       child: Text('Failed to check entitlement. Please try again later.'),
    //     ),
    //   );
    // }
    //   },
    // );
  }
}
