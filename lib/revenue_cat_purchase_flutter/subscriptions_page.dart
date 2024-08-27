import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:test/UI/home_page/selection_page.dart';
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
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SelectionPage()));
            },
            icon: const Icon(Icons.close, color: Colors.white60),
          ),
        ],
      ),
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.only(left: 32, right: 32, bottom: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Adding the splash logo at the top
            Image.asset(
              'assets/images/splash_logo.png', // Update this path according to your project structure
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 32), // Add some space below the logo
            buildEntitlement(entitlement),
            const SizedBox(height: 32),
            if (isLoading)
              const CircularProgressIndicator()
            else if (packages.isEmpty)
              ElevatedButton(
                onPressed: fetchPackages,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange, // Button background color
                ),
                child: const Text('Load Plans'),
              )
            else if (entitlement != Entitlement.paid)
              Column(
                children: packages.map((pkg) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        final success = await PurchaseApi.purchasePackage(pkg);
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Purchase successful')),
                          );
                          //TODO; Uncomment the following line to update the entitlement
                          // await ref
                          //     .read(revenueCatProvider.notifier)
                          //     .updatePurchaseStatus();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Purchase failed')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                            255, 243, 168, 55), // Button background color
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 24),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      child: Text(
                        'Make a one-time purchase for ${pkg.storeProduct.priceString}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                }).toList(),
              )
            else
              Container(),
          ],
        ),
      ),
    );
  }

  Widget buildEntitlement(Entitlement entitlement) {
    final daysLeft = calculateDaysLeft(); // Implement this method

    if (entitlement == Entitlement.trial) {
      return Column(
        children: [
          buildEntitlementIcon(
              text: 'You are on a 7-day trial', icon: Icons.lock),
          const SizedBox(height: 20),
          buildTrialCountdown(daysLeft),
          const SizedBox(height: 20),
          buildBenefitsHighlight(),
        ],
      );
    }
    if (entitlement == Entitlement.free) {
      return Column(
        children: [
          buildEntitlementIcon(text: 'The 7-day trial ended', icon: Icons.lock),
          const SizedBox(height: 20),
          buildBenefitsHighlight(),
        ],
      );
    } else {
      return buildEntitlementIcon(
          text: 'You are on a Paid plan', icon: Icons.paid);
    }
  }

  Widget buildTrialCountdown(int daysLeft) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        border: Border.all(
            color: Colors.orangeAccent, width: 2.0), // Orange accent borders
        borderRadius: BorderRadius.circular(8.0), // Rounded corners
        color: Colors.grey[850], // Background color for the container
      ),
      child: Text(
        'Trial ends in $daysLeft days',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.orangeAccent, // Text color matching the border
        ),
      ),
    );
  }

  Widget buildBenefitsHighlight() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upgrade now to unlock:',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
        ),
        SizedBox(height: 8),
        Text('- Full access to all features',
            style: TextStyle(fontSize: 15, color: Colors.white)),
        Text('- Ad-free experience',
            style: TextStyle(fontSize: 15, color: Colors.white)),
        Text('- Priority customer support',
            style: TextStyle(fontSize: 15, color: Colors.white)),
      ],
    );
  }

  Widget buildEntitlementIcon({required String text, required IconData icon}) {
    return LayoutBuilder(builder: (context, constraints) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 40,
            color: Colors.white, // Changed icon color to match theme
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: constraints.maxWidth *
                0.7, // Ensure the text occupies 70% of the available width
            child: AutoSizeText(
              text,
              style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
              maxLines: 1, // Limit to a single line
              minFontSize: 18, // Set a minimum font size for the text
              stepGranularity:
                  1, // Control the increments of font size decrease
              overflow:
                  TextOverflow.ellipsis, // Handle overflow with an ellipsis
              textAlign: TextAlign.start, // Align the text to the start
            ),
          ),
        ],
      );
    });
  }

  int calculateDaysLeft() {
    // Replace this with your logic to calculate the days left in the trial
    // For now, return a placeholder value
    return 7; // Placeholder value
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
                  //TODO: Uncomment this line if you want to update the purchase status
                  // await ref
                  //     .read(revenueCatProvider.notifier)
                  //     .updatePurchaseStatus();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Purchase failed')),
                  );
                }
              }));
    }
  }
}
