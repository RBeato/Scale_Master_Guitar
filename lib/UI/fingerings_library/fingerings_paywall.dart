import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:scalemasterguitar/constants/app_theme.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/purchase_api.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/provider/revenue_cat_provider.dart';

class FingeringsPaywall extends ConsumerStatefulWidget {
  const FingeringsPaywall({super.key});

  @override
  ConsumerState<FingeringsPaywall> createState() => _FingeringsPaywallState();
}

class _FingeringsPaywallState extends ConsumerState<FingeringsPaywall> {
  Offering? _offering;
  bool _isLoading = true;
  bool _isPurchasing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOffering();
  }

  Future<void> _loadOffering() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final offering = await PurchaseApi.fetchFingeringsLibraryOffering();
      if (mounted) {
        setState(() {
          _offering = offering;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading offering: $e');
      if (mounted) {
        setState(() {
          _error = 'Unable to load subscription options';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _purchase(Package package) async {
    setState(() => _isPurchasing = true);

    try {
      final success = await PurchaseApi.purchasePackage(package);

      if (success) {
        // Refresh subscription status
        await ref.read(revenueCatProvider.notifier).updatePurchaseStatus();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Welcome to Fingerings Library!'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      debugPrint('Purchase error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isPurchasing = true);

    try {
      final restored = await PurchaseApi.restorePurchases();

      if (!mounted) return;

      await ref.read(revenueCatProvider.notifier).updatePurchaseStatus();

      if (!mounted) return;

      if (restored) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchases restored successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No purchases to restore'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Restore error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to restore purchases'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.lightBlueAccent))
            : _error != null
                ? _buildErrorState()
                : _buildContent(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadOffering,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.lightBlueAccent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.library_music,
              size: 64,
              color: Colors.lightBlueAccent,
            ),
          ),
          const SizedBox(height: 24),

          // Title
          const Text(
            'Fingerings Library',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Unlock unlimited fingering patterns',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Features
          _buildFeatureRow(Icons.cloud_upload, 'Save unlimited fingerings to the cloud'),
          _buildFeatureRow(Icons.public, 'Share your fingerings with the community'),
          _buildFeatureRow(Icons.explore, 'Discover fingerings from other guitarists'),
          _buildFeatureRow(Icons.favorite, 'Like and save your favorites'),
          _buildFeatureRow(Icons.sync, 'Sync across all your devices'),

          const SizedBox(height: 32),

          // Packages
          if (_offering != null && _offering!.availablePackages.isNotEmpty)
            ..._offering!.availablePackages.map((package) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildPackageCard(package),
                )),

          if (_offering == null || _offering!.availablePackages.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Subscription options not available',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please check back later or contact support',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Restore purchases
          TextButton(
            onPressed: _isPurchasing ? null : _restorePurchases,
            child: Text(
              'Restore Purchases',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),

          const SizedBox(height: 16),

          // Terms
          Text(
            'Subscriptions will be charged to your payment method through your App Store or Play Store account. '
            'Subscriptions automatically renew unless canceled at least 24 hours before the end of the current period.',
            style: TextStyle(color: Colors.grey[600], fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.greenAccent, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(Package package) {
    final product = package.storeProduct;
    final isMonthly = package.packageType == PackageType.monthly;
    final isYearly = package.packageType == PackageType.annual;

    String periodLabel = '';
    String? savingsLabel;

    if (isMonthly) {
      periodLabel = '/month';
    } else if (isYearly) {
      periodLabel = '/year';
      savingsLabel = 'Save 58%';
    } else {
      periodLabel = '';
    }

    return InkWell(
      onTap: _isPurchasing ? null : () => _purchase(package),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isYearly
              ? Colors.lightBlueAccent.withValues(alpha: 0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isYearly ? Colors.lightBlueAccent : AppColors.border,
            width: isYearly ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          product.title.replaceAll(' (Scale Master Guitar)', ''),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (savingsLabel != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            savingsLabel,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  product.priceString,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  periodLabel,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
