import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test/revenue_cat_purchase_flutter/provider/revenue_cat_provider.dart';

class RestorePurchases extends ConsumerWidget {
  const RestorePurchases({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextButton(
        onPressed: () {
          ref.read(revenueCatProvider.notifier).restorePurchase();
        },
        child: const Text("Restore Purchases",
            style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
