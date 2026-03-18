import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:scalemasterguitar/constants/app_theme.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/entitlement.dart';
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

  // Current entitlement
  Entitlement _currentEntitlement = Entitlement.free;

  // Premium tab state
  bool _isPremiumLoading = false;
  String? _premiumError;
  String _premiumPriceText = 'Get Lifetime Access';
  Offering? _premiumOffering;

  // Fingerings Library tab state
  bool _isFingeringsLoading = true;
  String? _fingeringsError;
  Offering? _fingeringsOffering;
  Package? _selectedPackage;

  // Trial state
  bool _hasTrialAvailable = false;
  String _trialDurationText = '';

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
    // Check current entitlement first to show "Already Purchased" states
    try {
      _currentEntitlement = await PurchaseApi.getUserEntitlement();
    } catch (e) {
      debugPrint('Error checking entitlement: $e');
    }

    // If lifetime user arrived at the generic paywall (tab 0),
    // redirect to Pro tab since that's the only meaningful upgrade.
    if (_currentEntitlement.isLifetime && widget.initialTab == 0 && _tabController.index == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _tabController.animateTo(1);
        }
      });
    }

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
                'Get Lifetime Essentials for ${package.storeProduct.priceString}';
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

            // Detect free trial on any available package
            for (final pkg in offering.availablePackages) {
              final intro = pkg.storeProduct.introductoryPrice;
              if (intro != null && intro.price == 0) {
                _hasTrialAvailable = true;
                final days = intro.periodNumberOfUnits;
                _trialDurationText = '$days-Day Free Trial';
                break;
              }
            }
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
            _premiumError = 'Offering not available. Please try again.';
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
              content: Text('Lifetime features unlocked!'),
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
              content: Text('Welcome to Pro! All features unlocked.'),
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
            Tab(text: 'Essentials'),
            Tab(text: 'Pro Subscription'),
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
            'Lifetime Essentials',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Core features, one-time payment',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Prominent "not everything" callout — shown BEFORE features
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Does not include all features',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Drone Mode, multi-instrument, and cloud features require a Pro Subscription.',
                  style: TextStyle(
                    color: Colors.orange[200],
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    _tabController.animateTo(1);
                  },
                  child: const Text(
                    'See Pro Subscription for everything ›',
                    style: TextStyle(
                      color: Colors.lightBlueAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.lightBlueAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Included features
          _buildSectionLabel('Included with Lifetime:'),
          const SizedBox(height: 8),
          _buildFeatureRow(Icons.block, 'Remove all advertisements'),
          _buildFeatureRow(Icons.music_note, 'Access to all scales and modes'),
          _buildFeatureRow(Icons.volume_up, 'Audio playback & chord progressions'),
          _buildFeatureRow(Icons.download, 'Download fretboard images'),
          _buildFeatureRow(Icons.save, 'Save progressions locally'),

          const SizedBox(height: 20),

          // Subscriber-only features (NOT included)
          _buildSectionLabel('Not included — requires Pro Subscription:', color: Colors.orange),
          const SizedBox(height: 8),
          _buildExcludedFeatureRow(Icons.music_note, 'Drone Mode'),
          _buildExcludedFeatureRow(Icons.piano, 'Multi-instrument & custom tunings'),
          _buildExcludedFeatureRow(Icons.cloud_upload, 'Cloud Fingerings Library'),
          _buildExcludedFeatureRow(Icons.sync, 'Cross-device sync'),

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

          // Purchase button or Already Purchased state
          if (_currentEntitlement.isLifetime) ...[
            // Already has lifetime — show confirmation
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'Lifetime Access Active',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'You already own this! All lifetime features are unlocked.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ] else ...[
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
          ],

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
                    content: Text('In-app purchases work on real devices'),
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

    // Personalized view for lifetime users
    if (_currentEntitlement.isLifetime) {
      return _buildLifetimeUpgradeTab();
    }

    return _buildDefaultFingeringsTab();
  }

  Widget _buildDefaultFingeringsTab() {
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
            'Pro Subscription',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (_hasTrialAvailable) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5)),
              ),
              child: Text(
                _trialDurationText,
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Unlock all features',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Features - everything unlocked
          _buildFeatureRow(
              Icons.music_note, 'Drone Mode - sustained chord practice'),
          _buildFeatureRow(
              Icons.piano, 'Multi-instrument & custom tunings'),
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
          _buildFeatureRow(
              Icons.star, 'All premium features included'),

          const SizedBox(height: 32),

          ..._buildPackageCards(),

          const SizedBox(height: 24),

          ..._buildSubscribeButton(),

          const SizedBox(height: 16),

          ..._buildRestoreAndTerms(),
        ],
      ),
    );
  }

  Widget _buildLifetimeUpgradeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Acknowledgment banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You have Lifetime Essentials',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Your lifetime features remain active regardless.',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.lightBlueAccent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.rocket_launch,
              size: 56,
              color: Colors.lightBlueAccent,
            ),
          ),
          const SizedBox(height: 20),

          // Title
          const Text(
            'Unlock Pro Features',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Add these features to your Lifetime plan:',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),

          if (_hasTrialAvailable) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5)),
              ),
              child: Text(
                _trialDurationText,
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          const SizedBox(height: 28),

          // Only the ADDITIONAL features (not what they already have)
          _buildFeatureRow(Icons.music_note, 'Drone Mode — sustained chord practice'),
          _buildFeatureRow(Icons.piano, 'Multi-instrument & custom tunings'),
          _buildFeatureRow(Icons.cloud_upload, 'Cloud Fingerings Library'),
          _buildFeatureRow(Icons.public, 'Share fingerings with the community'),
          _buildFeatureRow(Icons.explore, 'Discover fingerings from other guitarists'),
          _buildFeatureRow(Icons.sync, 'Sync across all your devices'),

          const SizedBox(height: 32),

          ..._buildPackageCards(),

          const SizedBox(height: 24),

          // Subscribe button — with "Add Pro" framing
          if (_selectedPackage != null) ...[
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
                        _hasTrialAvailable
                            ? 'Start $_trialDurationText'
                            : 'Add Pro for ${_selectedPackage!.storeProduct.priceString}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            if (_hasTrialAvailable) ...[
              const SizedBox(height: 8),
              Text(
                'Then ${_selectedPackage!.storeProduct.priceString} per ${_selectedPackage!.packageType == PackageType.annual ? 'year' : 'month'}',
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ],

          const SizedBox(height: 16),

          ..._buildRestoreAndTerms(),
        ],
      ),
    );
  }

  /// Shared package cards used by both default and lifetime upgrade tabs
  List<Widget> _buildPackageCards() {
    return [
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
    ];
  }

  /// Shared subscribe button used by the default fingerings tab
  List<Widget> _buildSubscribeButton() {
    return [
      if (_currentEntitlement.isSubscriber) ...[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: const Column(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              SizedBox(height: 8),
              Text(
                'Pro Subscription Active',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'You already have an active subscription! All Pro features are unlocked.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ] else if (_selectedPackage != null) ...[
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
                    _hasTrialAvailable
                        ? 'Start $_trialDurationText'
                        : 'Subscribe for ${_selectedPackage!.storeProduct.priceString}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        if (_hasTrialAvailable) ...[
          const SizedBox(height: 8),
          Text(
            'Then ${_selectedPackage!.storeProduct.priceString} per ${_selectedPackage!.packageType == PackageType.annual ? 'year' : 'month'}',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    ];
  }

  /// Shared restore button and terms text
  List<Widget> _buildRestoreAndTerms() {
    return [
      TextButton(
        onPressed: _isPurchasing ? null : _handleRestore,
        child: Text(
          'Restore Purchases',
          style: TextStyle(color: Colors.grey[400]),
        ),
      ),
      const SizedBox(height: 16),
      Text(
        _hasTrialAvailable
            ? 'Free trial automatically converts to a paid subscription unless canceled at least 24 hours before the trial ends. '
              'Subscriptions will be charged to your payment method through your App Store or Play Store account. '
              'Subscriptions automatically renew unless canceled at least 24 hours before the end of the current period.'
            : 'Subscriptions will be charged to your payment method through your App Store or Play Store account. '
              'Subscriptions automatically renew unless canceled at least 24 hours before the end of the current period.',
        style: TextStyle(color: Colors.grey[600], fontSize: 11),
        textAlign: TextAlign.center,
      ),
    ];
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

  Widget _buildExcludedFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 15,
                decoration: TextDecoration.lineThrough,
                decorationColor: Colors.grey[600],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.lightBlueAccent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.lightBlueAccent.withValues(alpha: 0.4)),
            ),
            child: const Text(
              'PRO',
              style: TextStyle(
                color: Colors.lightBlueAccent,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text, {Color? color}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          color: color ?? Colors.greenAccent,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
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
    final intro = product.introductoryPrice;
    final hasFreeTrial = intro != null && intro.price == 0;

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
                      Flexible(
                        child: Text(
                          product.title.replaceAll(' (Scale Master Guitar)', ''),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[300],
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
                  if (hasFreeTrial) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${intro.periodNumberOfUnits}-day free trial',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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
