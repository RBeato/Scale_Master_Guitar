import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PaywallWidget extends StatelessWidget {
  final Offering offering;
  final Function(Package) onPurchase;

  const PaywallWidget({
    super.key,
    required this.offering,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            offering.serverDescription ?? 'Choose your plan',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ),
        ...offering.availablePackages.map(
          (package) =>
              PackageItem(package: package, onTap: () => onPurchase(package)),
        ),
      ],
    );
  }
}

class PackageItem extends StatelessWidget {
  final Package package;
  final VoidCallback onTap;

  const PackageItem({super.key, required this.package, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text(package.storeProduct.title),
        subtitle: Text(package.storeProduct.description),
        trailing: Text(package.storeProduct.priceString),
        onTap: onTap,
      ),
    );
  }
}
