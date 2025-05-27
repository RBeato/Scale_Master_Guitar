import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/purchase_api.dart';

class PaywallPage extends StatefulWidget {
  const PaywallPage({super.key});

  @override
  _PaywallPageState createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  bool _isLoading = true;
  Offering? _offering;

  @override
  void initState() {
    super.initState();
    _fetchOffering();
  }

  Future<void> _fetchOffering() async {
    setState(() => _isLoading = true);
    final offering = await PurchaseApi.fetchPremiumOffering();
    setState(() {
      _offering = offering;
      _isLoading = false;
    });
  }

  Future<void> _makePurchase(Package package) async {
    setState(() => _isLoading = true);
    final success = await PurchaseApi.purchasePackage(package);
    setState(() => _isLoading = false);
    if (success) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase failed')),
      );
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);
    final restored = await PurchaseApi.restorePurchases();
    setState(() => _isLoading = false);
    if (restored) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No purchases to restore')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Premium Access')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _offering == null
              ? const Center(child: Text('No offerings available'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Upgrade to Premium',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ..._offering!.availablePackages.map(
                      (package) => PackageItem(
                        package: package,
                        onTap: () => _makePurchase(package),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _restorePurchases,
                      child: const Text('Restore Purchases'),
                    ),
                  ],
                ),
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
      child: ListTile(
        title: Text(package.storeProduct.title),
        subtitle: Text(package.storeProduct.description),
        trailing: Text(package.storeProduct.priceString),
        onTap: onTap,
      ),
    );
  }
}
