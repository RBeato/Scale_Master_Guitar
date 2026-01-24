import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/purchase_api.dart'; 

class PaywallPage extends StatefulWidget {
  const PaywallPage({super.key});

  @override
  _PaywallPageState createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  bool isLoading = false;
  Package? package;

  @override
  void initState() {
    super.initState();
    fetchOffers();
  }

  Future<void> fetchOffers() async {
    // setState(() => isLoading = true);
    // try {
    //   final offers = await PurchaseApi.fetchOffers(all: false);
    //   if (offers.isNotEmpty && offers.first.availablePackages.isNotEmpty) {
    //     setState(() => package = offers.first.availablePackages.first);
    //   }
    // } catch (e) {
    //   debugPrint('Error fetching offers: $e');
    // } finally {
    //   setState(() => isLoading = false);
    // }
  }

  Future<void> makePurchase() async {
//Test code
//     final offering = await PurchaseApi.fetchSpecificOffering('premium');
//     if (offering != null) {
//       debugPrint('Fetched offering: ${offering.identifier}');
//       debugPrint(
//           'Available packages: ${offering.availablePackages.map((p) => p.identifier)}');
//     } else {
//       debugPrint('Failed to fetch specific offering');
//     }
// //
//     final package = await PurchaseApi.fetchPremiumPackage();
//     debugPrint("second test: PremiumPackage function result: $package");

//     if (package == null) return;
//     setState(() => isLoading = true);
//     try {
//       final success = await PurchaseApi.purchasePackage(package);
//       if (success) {
//         Navigator.of(context).pop(true);
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Purchase failed')),
//         );
//       }
    // } catch (e) {
    //   debugPrint('Error making purchase: $e');
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('An error occurred during purchase')),
    //   );
    // } finally {
    //   setState(() => isLoading = false);
    // }
  }

  Future<void> restorePurchases() async {
    setState(() => isLoading = true);
    try {
      final customerInfo = await PurchaseApi.getCustomerInfo();
      if (customerInfo.entitlements.active.isNotEmpty) {
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No purchases to restore')),
        );
      }
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred during restore')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C2128),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Image.asset(
                    'assets/images/splash_logo.png',
                    height: 80,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Scale Master Guitar',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF262C36),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lock, color: Colors.yellow),
                            SizedBox(width: 8),
                            Text(
                              'Premium',
                              style: TextStyle(
                                color: Colors.yellow,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Get full access to all Scale Master Guitar features',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (package != null)
                    Text(
                      'For a single lifetime payment of ${package!.storeProduct.priceString}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    )
                  else
                    const Text(
                      'Unable to load offer details',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isLoading ? null : makePurchase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: isLoading ? null : restorePurchases,
                        child: const Text('Restore',
                            style: TextStyle(color: Colors.white70)),
                      ),
                      const Text('•', style: TextStyle(color: Colors.white70)),
                      TextButton(
                        onPressed: () {
                          // Show privacy policy
                        },
                        child: const Text('Privacy',
                            style: TextStyle(color: Colors.white70)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
