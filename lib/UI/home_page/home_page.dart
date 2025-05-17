import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test/UI/home_page/selection_page.dart';
import 'package:test/revenue_cat_purchase_flutter/entitlement.dart';
import 'package:test/revenue_cat_purchase_flutter/provider/revenue_cat_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
     WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SelectionPage()),
            );
          });
          return const SizedBox.shrink();


//TODO: Use this
    // return FutureBuilder(
    //   future: ref.read(revenueCatProvider.notifier).updatePurchaseStatus(),
    //   builder: (context, snapshot) {
    //     if (snapshot.connectionState == ConnectionState.waiting) {
    //       return const Center(child: CircularProgressIndicator());
    //     } else if (snapshot.connectionState == ConnectionState.done) {
    //       WidgetsBinding.instance.addPostFrameCallback((_) {
    //         Navigator.pushReplacement(
    //           context,
    //           MaterialPageRoute(builder: (context) => const SelectionPage()),
    //         );
    //       });
    //       return const SizedBox.shrink();
    //     } else {
    //       return Scaffold(
    //         appBar: AppBar(
    //           title: Text(title),
    //         ),
    //         body: const Center(
    //           child:
    //               Text('Failed to check entitlement. Please try again later.'),
    //         ),
    //       );
    //     }
    //   },
    // );
  }
}
