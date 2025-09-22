import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      if (kDebugMode) {
        debugPrint('[Paywall] Fetching offerings...');
      }
      offering = await PurchaseApi.fetchPremiumOffering();
      if (kDebugMode) {
        debugPrint('[Paywall] Offering received: ${offering != null}');
      }
      
      if (offering != null) {
        if (kDebugMode) {
          debugPrint('[Paywall] Available packages count: ${offering!.availablePackages.length}');
        }
        
        // Find packages by type
        for (final package in offering!.availablePackages) {
          if (kDebugMode) {
            debugPrint('[Paywall] Package: ${package.identifier} - ${package.packageType} - ${package.storeProduct.priceString}');
          }
          
          switch (package.packageType) {
            case PackageType.monthly:
              monthlyPackage = package;
              if (kDebugMode) {
                debugPrint('[Paywall] Found monthly package: ${package.identifier}');
              }
              break;
            case PackageType.annual:
              yearlyPackage = package;
              if (kDebugMode) {
                debugPrint('[Paywall] Found yearly package: ${package.identifier}');
              }
              break;
            case PackageType.lifetime:
              lifetimePackage = package;
              if (kDebugMode) {
                debugPrint('[Paywall] Found lifetime package: ${package.identifier}');
              }
              break;
            default:
              if (kDebugMode) {
                debugPrint('[Paywall] Unknown package type: ${package.packageType}');
              }
              break;
          }
        }
        
        if (kDebugMode) {
          debugPrint('[Paywall] Package summary - Monthly: ${monthlyPackage != null}, Yearly: ${yearlyPackage != null}, Lifetime: ${lifetimePackage != null}');
        }
      } else {
        if (kDebugMode) {
          debugPrint('[Paywall] No offering found! This might be a RevenueCat configuration issue.');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Paywall] Error fetching offerings: $e');
      }
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
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('PlatformException during purchase: ${e.code} - ${e.message}');
      }

      // Handle specific error codes with user-friendly messages
      switch (e.code) {
        case 'PURCHASE_CANCELLED':
        case 'PURCHASES_ERROR_PURCHASE_CANCELLED':
          // User cancelled, no error message needed
          break;

        case 'PURCHASE_NOT_ALLOWED':
        case 'PURCHASES_ERROR_PURCHASE_NOT_ALLOWED':
          _showError('Purchases are not allowed on this device. Please check your App Store settings.');
          break;

        case 'STORE_PROBLEM':
        case 'PURCHASES_ERROR_STORE_PROBLEM':
          _showError('Unable to connect to the App Store. Please check your internet connection and try again.');
          break;

        case 'PAYMENT_PENDING':
          _showError('Your payment is pending approval. You will receive access once processed.');
          break;

        case 'NETWORK_ERROR':
          _showError('Network error. Please check your internet connection and try again.');
          break;

        case 'RECEIPT_IN_USE':
          _showError('This purchase has already been used. Try restoring your purchases instead.');
          break;

        default:
          _showError(e.message ?? 'Purchase failed. Please try again.');
          break;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error making purchase: $e');
      }
      _showError('An unexpected error occurred during purchase. Please try again.');
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
      if (kDebugMode) {
        debugPrint('Error restoring purchases: $e');
      }
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
              child: SingleChildScrollView(
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
                    else if (offering == null)
                      _buildNoOfferingsMessage()
                    else
                      _buildPurchaseOptions(),
                    
                    const SizedBox(height: 32),
                    
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

  Widget _buildNoOfferingsMessage() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red, width: 1),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Unable to Load Subscription Options',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'This usually happens on simulators or when there\'s no internet connection. Please try on a physical device or check your connection.',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchOfferings,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
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