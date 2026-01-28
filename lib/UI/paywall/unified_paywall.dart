import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:scalemasterguitar/constants/app_theme.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/purchase_api.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/provider/revenue_cat_provider.dart';
import 'package:scalemasterguitar/UI/home_page/selection_page.dart';
import 'package:scalemasterguitar/utils/slide_route.dart';

class UnifiedPaywall extends ConsumerStatefulWidget {
  /// Which tab to show initially: 0 = Premium, 1 = Fingerings Library
  final int initialTab;

  const UnifiedPaywall({super.key, this.initialTab = 0});

  @override
  ConsumerState<UnifiedPaywall> createState() => _UnifiedPaywallState();
}

class _UnifiedPaywallState extends ConsumerState<UnifiedPaywall>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Premium tab state
  bool _isPremiumLoading = false;
  String? _premiumError;
  String _premiumPriceText = 'Unlock Premium';
  Offering? _premiumOffering;

  // Fingerings Library tab state
  bool _isFingeringsLoading = true;
  String? _fingeringsError;
  Offering? _fingeringsOffering;
  Package? _selectedPackage;

  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _loadOfferings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Extract a user-friendly error message from an exception
  String _getErrorMessage(dynamic error) {
    if (error is PlatformException) {
      // PlatformException from RevenueCat has user-friendly messages
      return error.message ?? 'An error occurred. Please try again.';
    }

    final errorString = error.toString();

    // Remove common exception prefixes for cleaner messages
    if (errorString.contains('PlatformException')) {
      // Extract message from PlatformException string format
      final match = RegExp(r'message: ([^,\)]+)').firstMatch(errorString);
      if (match != null) {
        return match.group(1) ?? 'An error occurred. Please try again.';
      }
    }

    // Remove "Exception: " prefix if present
    if (errorString.startsWith('Exception: ')) {
      return errorString.substring(11);
    }

    // For other errors, provide a generic message
    return 'An error occurred. Please try again.';
  }

  Future<void> _loadOfferings() async {
    await Future.wait([
      _loadPremiumOffering(),
      _loadFingeringsOffering(),
    ]);
  }

  Future<void> _loadPremiumOffering() async {
    try {
      final offering = await PurchaseApi.fetchPremiumOffering();
      if (mounted) {
        setState(() {
          _premiumOffering = offering;
          if (offering != null && offering.availablePackages.isNotEmpty) {
            final package = offering.availablePackages.first;
            _premiumPriceText =
                'Unlock Premium for ${package.storeProduct.priceString}';
          }
        });
      }
    } catch (e) {
      debugPrint('Failed to load premium pricing: $e');
    }
  }

  Future<void> _loadFingeringsOffering() async {
    setState(() {
      _isFingeringsLoading = true;
      _fingeringsError = null;
    });

    try {
      final offering = await PurchaseApi.fetchFingeringsLibraryOffering();
      if (mounted) {
        setState(() {
          _fingeringsOffering = offering;
          _isFingeringsLoading = false;
          // Select yearly by default, or first available
          if (offering != null && offering.availablePackages.isNotEmpty) {
            _selectedPackage = offering.availablePackages.firstWhere(
              (p) => p.packageType == PackageType.annual,
              orElse: () => offering.availablePackages.first,
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading fingerings offering: $e');
      if (mounted) {
        setState(() {
          _fingeringsError = 'Unable to load subscription options';
          _isFingeringsLoading = false;
        });
      }
    }
  }

  Future<void> _handlePremiumPurchase() async {
    setState(() {
      _isPremiumLoading = true;
      _premiumError = null;
    });

    try {
      final offering = _premiumOffering ?? await PurchaseApi.fetchPremiumOffering();
      if (offering == null) {
        if (PurchaseApi.isBillingUnavailable) {
          setState(() {
            _premiumError =
                'In-app purchases are not available in this testing environment.';
          });
        } else {
          setState(() {
            _premiumError = 'Premium offering not available. Please try again.';
          });
        }
        return;
      }

      if (offering.availablePackages.isEmpty) {
        setState(() {
          _premiumError = 'No purchase packages available.';
        });
        return;
      }

      final package = offering.availablePackages.first;
      final isPurchased = await PurchaseApi.purchasePackage(package);

      if (!mounted) return;

      if (isPurchased) {
        await ref.read(revenueCatProvider.notifier).updatePurchaseStatus();
        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Premium features unlocked!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _premiumError = 'Purchase was cancelled. Please try again.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _premiumError = _getErrorMessage(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPremiumLoading = false;
        });
      }
    }
  }

  Future<void> _handleFingeringsPurchase(Package package) async {
    setState(() => _isPurchasing = true);

    try {
      final success = await PurchaseApi.purchasePackage(package);

      if (success) {
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
            content: Text(_getErrorMessage(e)),
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

  Future<void> _handleRestore() async {
    setState(() {
      _isPremiumLoading = true;
      _isPurchasing = true;
    });

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
        setState(() {
          _isPremiumLoading = false;
          _isPurchasing = false;
        });
      }
    }
  }

  void _closePaywall() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      // If we can't pop (paywall is root), navigate to selection page
      Navigator.of(context).pushReplacement(
        SlideRoute(page: const SelectionPage(), direction: SlideDirection.fromLeft),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: Icon(canPop ? Icons.arrow_back : Icons.close),
          onPressed: _closePaywall,
        ),
        title: const Text(
          'Upgrade',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          if (!canPop)
            TextButton(
              onPressed: _closePaywall,
              child: const Text(
                'Skip',
                style: TextStyle(color: Colors.white70),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'Lifetime Premium'),
            Tab(text: 'Fingerings Library'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPremiumTab(),
          _buildFingeringsTab(),
        ],
      ),
    );
  }

  Widget _buildPremiumTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.star,
              size: 64,
              color: Colors.amber,
            ),
          ),
          const SizedBox(height: 24),

          // Title
          const Text(
            'Lifetime Premium',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'One-time purchase, forever yours',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Features
          _buildFeatureRow(Icons.block, 'Remove all advertisements'),
          _buildFeatureRow(Icons.music_note, 'Access to all scales and modes'),
          _buildFeatureRow(Icons.tune, 'Advanced practice tools'),
          _buildFeatureRow(Icons.settings, 'Custom tunings'),
          _buildFeatureRow(Icons.download, 'Download fretboard images'),

          const SizedBox(height: 16),

          // Important note about Fingerings Library and storage
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Important: Lifetime Premium stores progressions locally on this device only. They will not sync across devices.',
                        style: TextStyle(
                          color: Colors.orange[200],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 32),
                    Expanded(
                      child: Text(
                        'For cloud sync of progressions and fingerings, subscribe to Fingerings Library.',
                        style: TextStyle(
                          color: Colors.orange[200],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Error message
          if (_premiumError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _premiumError!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),

          // Purchase button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isPremiumLoading ? null : _handlePremiumPurchase,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isPremiumLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : Text(
                      _premiumPriceText,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // Restore purchases
          TextButton(
            onPressed: (_isPremiumLoading || _isPurchasing)
                ? null
                : _handleRestore,
            child: Text(
              'Restore Purchases',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),

          // Skip button for testing
          if (PurchaseApi.isBillingUnavailable) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Premium purchases work on real devices'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              child: const Text(
                'Skip (Testing Mode)',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFingeringsTab() {
    if (_isFingeringsLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.lightBlueAccent),
      );
    }

    if (_fingeringsError != null) {
      return _buildFingeringsErrorState();
    }

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
          _buildFeatureRow(
              Icons.cloud_upload, 'Save unlimited fingerings to the cloud'),
          _buildFeatureRow(
              Icons.queue_music, 'Save progressions to the cloud'),
          _buildFeatureRow(
              Icons.public, 'Share your fingerings with the community'),
          _buildFeatureRow(
              Icons.explore, 'Discover fingerings from other guitarists'),
          _buildFeatureRow(Icons.favorite, 'Like and save your favorites'),
          _buildFeatureRow(Icons.sync, 'Sync across all your devices'),

          const SizedBox(height: 32),

          // Packages - selectable options
          if (_fingeringsOffering != null &&
              _fingeringsOffering!.availablePackages.isNotEmpty)
            ..._fingeringsOffering!.availablePackages.map(
              (package) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildPackageCard(package),
              ),
            ),

          if (_fingeringsOffering == null ||
              _fingeringsOffering!.availablePackages.isEmpty)
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

          // Subscribe button
          if (_selectedPackage != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isPurchasing
                    ? null
                    : () => _handleFingeringsPurchase(_selectedPackage!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlueAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isPurchasing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                    : Text(
                        'Subscribe for ${_selectedPackage!.storeProduct.priceString}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

          const SizedBox(height: 16),

          // Restore purchases
          TextButton(
            onPressed: _isPurchasing ? null : _handleRestore,
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

  Widget _buildFingeringsErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            _fingeringsError!,
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadFingeringsOffering,
            child: const Text('Try Again'),
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
    final isSelected = _selectedPackage == package;

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
      onTap: _isPurchasing
          ? null
          : () {
              setState(() {
                _selectedPackage = package;
              });
            },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.lightBlueAccent.withValues(alpha: 0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.lightBlueAccent : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Selection indicator
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.lightBlueAccent : Colors.grey,
                  width: 2,
                ),
                color: isSelected ? Colors.lightBlueAccent : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.black)
                  : null,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        product.title.replaceAll(' (Scale Master Guitar)', ''),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[300],
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[300],
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
