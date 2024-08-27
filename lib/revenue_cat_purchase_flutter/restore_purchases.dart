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
        onPressed: () async {
          try {
            // Call the restorePurchase method from the provider
            // await ref.read(revenueCatProvider.notifier).restorePurchase();
            // Inform the user that the restore was successful
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Purchases restored successfully!')),
            );
          } catch (error) {
            // Handle errors if the restore process fails
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to restore purchases: $error')),
            );
          }
        },
        child: const Text("Restore Purchases",
            style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
