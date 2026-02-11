import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:scalemasterguitar/constants/app_theme.dart';
import 'package:scalemasterguitar/utils/slide_route.dart';
import 'package:scalemasterguitar/UI/drawer/UI/drawer/sounds_dropdown_column.dart';
import 'package:scalemasterguitar/UI/drawer/provider/settings_state_notifier.dart';
import 'package:scalemasterguitar/constants/styles.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/provider/revenue_cat_provider.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/entitlement.dart';
import 'package:scalemasterguitar/UI/paywall/unified_paywall.dart';
import 'package:scalemasterguitar/shared/widgets/other_apps_promo_widget.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';
import 'chord_options_cards.dart';

class DrawerPage extends ConsumerStatefulWidget {
  const DrawerPage({super.key});

  @override
  ConsumerState<DrawerPage> createState() => _DrawerPageState();
}

class _DrawerPageState extends ConsumerState<DrawerPage> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = 'v${packageInfo.version}+${packageInfo.buildNumber}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final entitlement = ref.watch(revenueCatProvider);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  const GeneralOptions(),
                  // Testing switch only visible in debug mode
                  if (kDebugMode) _buildTestingSection(),
                  const SoundsDropdownColumn(),

                  const SizedBox(height: 20),

                  // Cross-promotion section
                  const OtherAppsPromoWidget(
                    currentAppId: 'scale_master_guitar',
                    accentColor: Color(0xFF4CAF50),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
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
                        SlideRoute(
                          page: const UnifiedPaywall(),
                          direction: SlideDirection.fromBottom,
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
              
              // Contact & Feedback button with User ID sharing
              Card(
                color: Colors.green.withValues(alpha: 0.1),
                child: ListTile(
                  leading: const Icon(Icons.support_agent, color: Colors.green),
                  title: const Text(
                    'Get Support',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text('Share User ID for support or premium access'),
                  onTap: () => _showSupportDialog(context),
                ),
              ),

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
              Text(
                _appVersion,
                style: const TextStyle(
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
    final testingState = ref.watch(testingStateProvider);
    final isTestingMode = testingState.isEnabled;
    final testingEntitlement = testingState.testEntitlement;

    return Card(
      color: Colors.deepPurple.withValues(alpha: 0.2),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.science, color: Colors.deepPurple, size: 18),
            const SizedBox(width: 8),
            Switch(
              value: isTestingMode,
              activeTrackColor: Colors.deepPurple,
              onChanged: (value) {
                revenueCatNotifier.setTestingMode(value, testingEntitlement);
              },
            ),
            const SizedBox(width: 4),
            Expanded(
              child: DropdownButton<Entitlement>(
                value: testingEntitlement,
                isExpanded: true,
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                underline: const SizedBox(),
                items: Entitlement.values.map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(_getEntitlementDisplayName(e)),
                )).toList(),
                onChanged: isTestingMode ? (value) {
                  if (value != null) {
                    revenueCatNotifier.setTestingMode(true, value);
                  }
                } : null,
              ),
            ),
          ],
        ),
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
      case Entitlement.premiumOneTimeWithLibrary:
        return 'Premium Lifetime + Library';
      case Entitlement.fingeringsLibrary:
        return 'Fingerings Library Subscriber';
    }
  }

  /// Show support dialog with User ID sharing
  Future<void> _showSupportDialog(BuildContext context) async {
    try {
      // Get RevenueCat User ID
      final customerInfo = await Purchases.getCustomerInfo();
      final userId = customerInfo.originalAppUserId;

      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.support_agent, color: Colors.green),
                SizedBox(width: 8),
                Text('Get Support'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Need help or want premium access?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Share your User ID with us to get support or request premium features.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your User ID:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          userId,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'How to use:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '1. Tap "Share User ID" below\n'
                          '2. Send via email/WhatsApp\n'
                          '3. We\'ll grant you access',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.email, color: Colors.grey.shade600, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'rb.soundz@hotmail.com',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Close'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final packageInfo = await PackageInfo.fromPlatform();
                  final deviceInfo = Platform.isIOS ? 'iOS' : 'Android';

                  await Share.share(
                    'Hi! I need support for SMGuitar.\n\n'
                    'My User ID: $userId\n'
                    'Device: $deviceInfo\n'
                    'App Version: ${packageInfo.version}\n\n'
                    'Please contact me at: rb.soundz@hotmail.com',
                    subject: 'SMGuitar - Support Request',
                  );
                },
                icon: const Icon(Icons.share),
                label: const Text('Share User ID'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to get User ID: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
