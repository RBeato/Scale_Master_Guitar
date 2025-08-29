import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:scalemasterguitar/UI/drawer/UI/drawer/sounds_dropdown_column.dart';
import 'package:scalemasterguitar/UI/drawer/provider/settings_state_notifier.dart';
import 'package:scalemasterguitar/ads/banner_ad_widget.dart';
import 'package:scalemasterguitar/constants/styles.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/provider/revenue_cat_provider.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/entitlement.dart';
import 'package:scalemasterguitar/UI/paywall/enhanced_paywall.dart';
import 'package:scalemasterguitar/services/feature_restriction_service.dart';
import 'chord_options_cards.dart';

class DrawerPage extends ConsumerStatefulWidget {
  const DrawerPage({super.key});

  @override
  ConsumerState<DrawerPage> createState() => _DrawerPageState();
}

class _DrawerPageState extends ConsumerState<DrawerPage> {
  @override
  Widget build(BuildContext context) {
    final entitlement = ref.watch(revenueCatProvider);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: <Widget>[
              const GeneralOptions(),
              // Testing switch only visible in debug mode
              if (kDebugMode) _buildTestingSection(),
              const SoundsDropdownColumn(),
            ],
          ),
          Column(
            children: [
              // Show upgrade button for free users
              if (!entitlement.isPremium)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.star, color: Colors.white),
                    label: Text(
                      entitlement.name == 'free' 
                        ? 'Unlock Premium Features' 
                        : 'Upgrade to Premium'
                    ),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.orange,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EnhancedPaywallPage(),
                          fullscreenDialog: true,
                        ),
                      );
                    },
                  ),
                ),
              
              // Show premium status for premium users
              if (entitlement.isPremium)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        entitlement.name == 'premiumSub' 
                          ? 'Premium Subscriber' 
                          : 'Premium Lifetime',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 20),
              
              // Ads only show for free users
              if (FeatureRestrictionService.shouldShowAds(entitlement))
                const BannerAdWidget(),
              
              const SizedBox(height: 20),
              InkWell(
                highlightColor: cardColor,
                child: GestureDetector(
                  onTap: () {
                    ref
                        .read(settingsStateNotifierProvider.notifier)
                        .resetValues();
                  },
                  child: Card(
                    color: clearPreferencesButtonColor,
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Clear Preferences',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'v1.0.0+16',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestingSection() {
    final revenueCatNotifier = ref.read(revenueCatProvider.notifier);
    final testingState = ref.watch(testingStateProvider); // Watch for testing state changes
    final isTestingMode = testingState.isEnabled;
    final testingEntitlement = testingState.testEntitlement;

    return Card(
      color: Colors.deepPurple.withValues(alpha: 0.2),
      child: ExpansionTile(
        title: const Row(
          children: [
            Icon(Icons.science, color: Colors.deepPurple, size: 20),
            SizedBox(width: 8),
            Text(
              'Testing Mode',
              style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Override subscription status for testing:',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text(
                    'Enable Testing Mode',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  subtitle: Text(
                    isTestingMode ? 'Testing: ${testingEntitlement.name}' : 'Using real subscription status',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  value: isTestingMode,
                  activeColor: Colors.deepPurple,
                  onChanged: (value) {
                    if (value) {
                      revenueCatNotifier.setTestingMode(true, Entitlement.free);
                    } else {
                      revenueCatNotifier.setTestingMode(false, Entitlement.free);
                    }
                  },
                ),
                if (isTestingMode) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Test as:',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  ...Entitlement.values.map((entitlement) => RadioListTile<Entitlement>(
                    title: Text(
                      _getEntitlementDisplayName(entitlement),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    value: entitlement,
                    groupValue: testingEntitlement,
                    activeColor: Colors.deepPurple,
                    onChanged: (value) {
                      if (value != null) {
                        revenueCatNotifier.setTestingMode(true, value);
                      }
                    },
                  )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getEntitlementDisplayName(Entitlement entitlement) {
    switch (entitlement) {
      case Entitlement.free:
        return 'Free User (with ads, limited scales)';
      case Entitlement.premiumSub:
        return 'Premium Subscriber';
      case Entitlement.premiumOneTime:
        return 'Premium Lifetime';
    }
  }
}
