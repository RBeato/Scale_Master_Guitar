import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:test/revenue_cat_purchase_flutter/entitlement.dart';
import 'package:test/revenue_cat_purchase_flutter/paywall_widget.dart';
import 'package:test/revenue_cat_purchase_flutter/provider/revenue_cat_provider.dart';
import 'package:test/revenue_cat_purchase_flutter/purchase_api.dart';
import 'package:test/revenue_cat_purchase_flutter/utils.dart';

class SubscriptionPage extends ConsumerStatefulWidget {
  const SubscriptionPage({super.key});

  @override
  _SubscriptionsPageState createState() => _SubscriptionsPageState();
}

class _SubscriptionsPageState extends ConsumerState<SubscriptionPage> {
  bool isLoading = false;
  List<Package> packages = [];

  @override
  void initState() {
    super.initState();
    fetchPackages();
  }

  Future<void> fetchPackages() async {
    setState(() {
      isLoading = true;
    });

    final offerings = await PurchaseApi.fetchOffers(all: false);
    if (offerings.isNotEmpty) {
      setState(() {
        packages = offerings[0].availablePackages;
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final entitlement = ref.watch(revenueCatProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Subscribe')),
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildEntitlement(entitlement),
            const SizedBox(height: 32),
            if (isLoading)
              const CircularProgressIndicator()
            else if (packages.isEmpty)
              ElevatedButton(
                onPressed: fetchPackages,
                child: const Text('Load Plans'),
              )
            else
              ...packages.map((pkg) {
                return ElevatedButton(
                  onPressed: () async {
                    final success = await PurchaseApi.purchasePackage(pkg);
                    if (success) {
                      // handle successful purchase
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Purchase successful')),
                      );
                      await ref
                          .read(revenueCatProvider.notifier)
                          .updatePurchaseStatus();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Purchase failed')),
                      );
                    }
                  },
                  child: Text(
                      'Make a one-time purchase for ${pkg.storeProduct.priceString}'),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget buildEntitlement(Entitlement entitlement) {
    switch (entitlement) {
      case Entitlement.paid:
        return buildEntitlementIcon(
            text: 'You are on Paid plan', icon: Icons.paid);
      case Entitlement.free:
      default:
        return buildEntitlementIcon(
            text: 'You are on a 7-day trial', icon: Icons.lock);
    }
  }

  Widget buildEntitlementIcon({required String text, required IconData icon}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 48),
        const SizedBox(width: 16),
        Text(text, style: const TextStyle(fontSize: 24)),
      ],
    );
  }

  Future fetchOffers() async {
    final offerings = await PurchaseApi.fetchOffers();
    if (offerings.isEmpty) {
      Utils.showSnackBar(context, 'No Plans Found');
    } else {
      final packages = offerings
          .map((offer) => offer.availablePackages)
          .expand((pair) => pair)
          .toList();

      Utils.showSheet(
          context,
          (context) => PaywallWidget(
              packages: packages,
              title: 'Upgrade Your Plan',
              description: 'Upgrade to a new plan to enjoy more features.',
              onClickedPackage: (package) async {
                final success = await PurchaseApi.purchasePackage(package);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Purchase successful')),
                  );
                  await ref
                      .read(revenueCatProvider.notifier)
                      .updatePurchaseStatus();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Purchase failed')),
                  );
                }
              }));
    }
  }
}
