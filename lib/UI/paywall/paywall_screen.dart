import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/purchase_api.dart';
import 'package:scalemasterguitar/UI/home_page/selection_page.dart';
import 'package:scalemasterguitar/utils/slide_route.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  String _priceText = 'Unlock Premium';

  @override
  void initState() {
    super.initState();
    _loadPricing();
  }

  Future<void> _loadPricing() async {
    try {
      final offering = await PurchaseApi.fetchPremiumOffering();
      if (offering != null && offering.availablePackages.isNotEmpty) {
        final package = offering.availablePackages.first;
        if (mounted) {
          setState(() {
            _priceText = 'Unlock Premium for ${package.storeProduct.priceString}';
          });
        }
      }
    } catch (e) {
      // Keep default text if pricing fails to load
      debugPrint('Failed to load pricing: $e');
    }
  }

  Future<void> _handlePurchase() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final offering = await PurchaseApi.fetchPremiumOffering();
      if (offering == null) {
        // Check if billing is unavailable (testing environment)
        if (PurchaseApi.isBillingUnavailable) {
          setState(() {
            _errorMessage = 'In-app purchases are not available in this testing environment. Premium features work on real devices with Google Play Store.';
          });
        } else {
          setState(() {
            _errorMessage = 'Premium offering not available. Please check your internet connection and try again.';
          });
        }
        return;
      }
      
      if (offering.availablePackages.isEmpty) {
        setState(() {
          _errorMessage = 'No purchase packages available. The premium offering may not be configured correctly.';
        });
        return;
      }

      // Get the first available package and update price display
      final package = offering.availablePackages.first;
      setState(() {
        _priceText = 'Unlock Premium for ${package.storeProduct.priceString}';
      });
      
      final isPurchased = await PurchaseApi.purchasePackage(package);
      
      if (!mounted) return;
      
      if (isPurchased) {
        // Update the UI to show success
        if (mounted) {
          Navigator.of(context).pop(); // Close paywall
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Premium features unlocked!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Purchase was cancelled or could not be completed. Please try again.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Purchase failed: ${e.toString().replaceAll('Exception: ', '')}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRestore() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final restored = await PurchaseApi.restorePurchases();
      if (restored && mounted) {
        Navigator.of(context).pop(); // Close paywall if restored successfully
      } else if (!restored) {
        setState(() {
          _errorMessage = 'No previous purchases found';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to restore purchases: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unlock Premium'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              SlideRoute(page: const SelectionPage(), direction: SlideDirection.fromLeft),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            const Icon(
              Icons.star,
              size: 80,
              color: Colors.amber,
            ),
            const SizedBox(height: 24),
            const Text(
              'Unlock All Premium Features',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              '• Remove all advertisements\n'
              '• Access to all scales and modes\n'
              '• Advanced practice tools\n'
              '• Custom tunings\n'
              '• And much more!',
              style: TextStyle(fontSize: 18, height: 1.6),
              textAlign: TextAlign.start,
            ),
            const Spacer(),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ElevatedButton(
              onPressed: _isLoading ? null : _handlePurchase,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                disabledBackgroundColor: Colors.blue.withValues(alpha: 0.5),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _priceText,
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isLoading ? null : _handleRestore,
              child: const Text('Restore Purchase'),
            ),
            // Show skip button if billing is unavailable (testing environment)
            if (PurchaseApi.isBillingUnavailable) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Premium purchases work on real devices with Google Play Store'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                child: const Text('Skip (Testing Mode)', style: TextStyle(color: Colors.grey)),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
