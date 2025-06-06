import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/purchase_api.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/provider/revenue_cat_provider.dart';

class EnhancedPaywallPage extends ConsumerStatefulWidget {
  const EnhancedPaywallPage({super.key});

  @override
  ConsumerState<EnhancedPaywallPage> createState() => _EnhancedPaywallPageState();
}

class _EnhancedPaywallPageState extends ConsumerState<EnhancedPaywallPage> {
  bool isLoading = false;
  Offering? offering;
  Package? monthlyPackage;
  Package? yearlyPackage;
  Package? lifetimePackage;

  @override
  void initState() {
    super.initState();
    _fetchOfferings();
  }

  Future<void> _fetchOfferings() async {
    setState(() => isLoading = true);
    try {
      offering = await PurchaseApi.fetchPremiumOffering();
      if (offering != null) {
        // Find packages by type
        for (final package in offering!.availablePackages) {
          switch (package.packageType) {
            case PackageType.monthly:
              monthlyPackage = package;
              break;
            case PackageType.annual:
              yearlyPackage = package;
              break;
            case PackageType.lifetime:
              lifetimePackage = package;
              break;
            default:
              break;
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching offerings: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _purchasePackage(Package package) async {
    setState(() => isLoading = true);
    try {
      final success = await PurchaseApi.purchasePackage(package);
      if (success) {
        // Update the provider state
        await ref.read(revenueCatProvider.notifier).updatePurchaseStatus();
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        _showError('Purchase failed. Please try again.');
      }
    } catch (e) {
      debugPrint('Error making purchase: $e');
      _showError('An error occurred during purchase');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => isLoading = true);
    try {
      await ref.read(revenueCatProvider.notifier).restorePurchases();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      _showError('No purchases found to restore');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header
                  const Icon(
                    Icons.music_note,
                    size: 80,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Unlock Premium Features',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  // Features list
                  _buildFeatureList(),
                  
                  const SizedBox(height: 32),
                  
                  // Purchase options
                  if (isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    _buildPurchaseOptions(),
                  
                  const Spacer(),
                  
                  // Restore button
                  TextButton(
                    onPressed: _restorePurchases,
                    child: const Text(
                      'Restore Purchases',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  
                  // Terms and privacy
                  const Text(
                    'By purchasing, you agree to our Terms of Service and Privacy Policy',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          
          // Loading overlay
          if (isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureList() {
    const features = [
      'Access to all scales and modes',
      'Audio playback and chord progression player',
      'Download fretboard images',
      'No ads',
      'Priority support',
    ];

    return Column(
      children: features.map((feature) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                feature,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildPurchaseOptions() {
    return Column(
      children: [
        // Monthly subscription
        if (monthlyPackage != null)
          _buildPurchaseCard(
            title: 'Monthly Subscription',
            subtitle: 'Billed monthly, cancel anytime',
            price: monthlyPackage!.storeProduct.priceString,
            package: monthlyPackage!,
            isPopular: false,
          ),
        
        const SizedBox(height: 16),
        
        // Yearly subscription
        if (yearlyPackage != null)
          _buildPurchaseCard(
            title: 'Yearly Subscription',
            subtitle: 'Best value! Save 50%',
            price: yearlyPackage!.storeProduct.priceString,
            package: yearlyPackage!,
            isPopular: true,
          ),
        
        const SizedBox(height: 16),
        
        // Lifetime purchase
        if (lifetimePackage != null)
          _buildPurchaseCard(
            title: 'Lifetime Access',
            subtitle: 'One-time payment, yours forever',
            price: lifetimePackage!.storeProduct.priceString,
            package: lifetimePackage!,
            isPopular: false,
          ),
      ],
    );
  }

  Widget _buildPurchaseCard({
    required String title,
    required String subtitle,
    required String price,
    required Package package,
    required bool isPopular,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: isPopular 
          ? Border.all(color: Colors.orange, width: 2)
          : Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: Stack(
        children: [
          if (isPopular)
            Positioned(
              top: 0,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: const Text(
                  'MOST POPULAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      price,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _purchasePackage(package),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPopular ? Colors.orange : Colors.grey[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Choose ${title.split(' ').first}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}