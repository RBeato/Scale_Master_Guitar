import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PaywallWidget extends StatefulWidget {
  final String title;
  final String description;
  final List<Package> packages;
  final void Function(Package) onClickedPackage;

  const PaywallWidget({
    super.key,
    required this.title,
    required this.description,
    required this.packages,
    required this.onClickedPackage,
  });

  @override
  _PaywallWidgetState createState() => _PaywallWidgetState();
}

class _PaywallWidgetState extends State<PaywallWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            buildPackages(),
          ],
        ),
      ),
    );
  }

  Widget buildPackages() {
    return ListView.builder(
      shrinkWrap: true,
      primary: false,
      itemCount: widget.packages.length,
      itemBuilder: (context, index) {
        final package = widget.packages[index];
        return buildPackage(context, package);
      },
    );
  }

  Widget buildPackage(BuildContext context, Package package) {
    final product = package.storeProduct;
    return Card(
      color: Theme.of(context).colorScheme.secondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Theme(
        data: ThemeData.light(),
        child: ListTile(
          contentPadding: const EdgeInsets.all(8),
          title: Text(
            product.title,
            style: const TextStyle(fontSize: 18),
          ),
          subtitle: Text(
            product.description,
            style: const TextStyle(fontSize: 14),
          ),
          onTap: () => widget.onClickedPackage(package),
        ),
      ),
    );
  }
}
