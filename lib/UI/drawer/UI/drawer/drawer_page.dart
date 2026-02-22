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
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/purchase_api.dart';
import 'package:scalemasterguitar/UI/paywall/unified_paywall.dart';
import 'package:scalemasterguitar/shared/widgets/other_apps_promo_widget.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scalemasterguitar/services/in_app_review_service.dart';
import 'package:scalemasterguitar/services/riffroutine_api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'chord_options_cards.dart';

const _linkedEmailKey = 'riffroutine_linked_email';
const _anonUserIdKey = 'revenuecat_anon_user_id';

class DrawerPage extends ConsumerStatefulWidget {
  const DrawerPage({super.key});

  @override
  ConsumerState<DrawerPage> createState() => _DrawerPageState();
}

class _DrawerPageState extends ConsumerState<DrawerPage> {
  String _appVersion = '';
  String? _linkedEmail;

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _loadLinkedEmail();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = 'v${packageInfo.version}+${packageInfo.buildNumber}';
      });
    }
  }

  Future<void> _loadLinkedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_linkedEmailKey);
    if (mounted) {
      setState(() {
        _linkedEmail = email;
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
              
              // Restore purchases button - always visible (Apple requirement)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton.icon(
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Restore Purchases'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade400,
                  ),
                  onPressed: () async {
                    try {
                      await ref.read(revenueCatProvider.notifier).restorePurchases();
                      if (!context.mounted) return;
                      final restored = ref.read(revenueCatProvider).isPremium;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(restored
                              ? 'Purchases restored successfully!'
                              : 'No previous purchases found.'),
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Error restoring purchases. Please try again.')),
                      );
                    }
                  },
                ),
              ),

              // Manage Subscription - link to store subscription management
              if (entitlement.isPremium)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: TextButton.icon(
                    icon: const Icon(Icons.manage_accounts, size: 18),
                    label: const Text('Manage Subscription'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade400,
                    ),
                    onPressed: () async {
                      final url = Platform.isIOS
                          ? 'https://apps.apple.com/account/subscriptions'
                          : 'https://play.google.com/store/account/subscriptions';
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                      }
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
                        _linkedEmail != null
                          ? 'RiffRoutine Premium'
                          : entitlement.name == 'premiumSub'
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
              
              const SizedBox(height: 8),

              // Link RiffRoutine Account
              Card(
                color: _linkedEmail != null
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.purple.withValues(alpha: 0.1),
                child: ListTile(
                  leading: Icon(
                    _linkedEmail != null ? Icons.check_circle : Icons.link,
                    color: _linkedEmail != null ? Colors.green : Colors.purple,
                  ),
                  title: Text(
                    _linkedEmail != null ? 'RiffRoutine Linked' : 'Link RiffRoutine Account',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    _linkedEmail != null ? _linkedEmail! : 'Unlock premium with your web subscription',
                  ),
                  onTap: () => _showLinkAccountSheet(context),
                ),
              ),

              const SizedBox(height: 12),

              // Rate the App
              Card(
                color: Colors.orange.withValues(alpha: 0.1),
                child: ListTile(
                  leading: const Icon(Icons.star_rate_rounded, color: Colors.orange),
                  title: const Text(
                    'Rate Scale Master',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text('Enjoying the app? Leave a review!'),
                  onTap: () => InAppReviewService().openStoreListing(),
                ),
              ),

              const SizedBox(height: 8),

              // Suggest improvements via email
              Card(
                color: Colors.amber.withValues(alpha: 0.1),
                child: ListTile(
                  leading: const Icon(Icons.lightbulb_outline, color: Colors.amber),
                  title: const Text(
                    'Suggest Improvements',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text('Tell us what features you want'),
                  onTap: () async {
                    final Uri emailUri = Uri(
                      scheme: 'mailto',
                      path: 'rb.soundz@hotmail.com',
                      queryParameters: {
                        'subject': 'Scale Master Guitar - Feature Suggestion',
                        'body': 'Hi! I\'d love to see this feature in Scale Master:\n\n',
                      },
                    );
                    try {
                      await launchUrl(emailUri);
                    } catch (e) {
                      debugPrint('Could not launch email: $e');
                    }
                  },
                ),
              ),

              const SizedBox(height: 8),

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

  /// Show bottom sheet to link a RiffRoutine web subscription
  Future<void> _showLinkAccountSheet(BuildContext context) async {
    // Check if already linked
    final prefs = await SharedPreferences.getInstance();
    final existingEmail = prefs.getString(_linkedEmailKey);

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return _LinkAccountSheet(
          existingEmail: existingEmail,
          onLinked: (email) async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_linkedEmailKey, email);
            // Refresh entitlement state
            final entitlement = await PurchaseApi.getUserEntitlement();
            ref.read(revenueCatProvider.notifier).state = entitlement;
            if (mounted) setState(() => _linkedEmail = email);
          },
          onUnlinked: () async {
            final prefs = await SharedPreferences.getInstance();
            final savedAnonId = prefs.getString(_anonUserIdKey);
            await prefs.remove(_linkedEmailKey);
            await prefs.remove('riffroutine_tier');
            await prefs.remove('riffroutine_subscription_active');
            await prefs.remove(_anonUserIdKey);
            try {
              // Restore original anonymous identity to reconnect prior purchases
              if (savedAnonId != null) {
                await Purchases.logIn(savedAnonId);
              } else {
                await Purchases.logOut();
              }
            } catch (_) {}
            final entitlement = await PurchaseApi.getUserEntitlement();
            ref.read(revenueCatProvider.notifier).state = entitlement;
            if (mounted) setState(() => _linkedEmail = null);
          },
        );
      },
    );
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

enum _LinkStep { enterEmail, enterCode, result }

/// Bottom sheet widget for linking/unlinking a RiffRoutine account
/// with 6-digit email verification code.
class _LinkAccountSheet extends StatefulWidget {
  final String? existingEmail;
  final Future<void> Function(String email) onLinked;
  final Future<void> Function() onUnlinked;

  const _LinkAccountSheet({
    required this.existingEmail,
    required this.onLinked,
    required this.onUnlinked,
  });

  @override
  State<_LinkAccountSheet> createState() => _LinkAccountSheetState();
}

class _LinkAccountSheetState extends State<_LinkAccountSheet> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _api = RiffRoutineApiService.instance;

  _LinkStep _step = _LinkStep.enterEmail;
  bool _isLoading = false;
  String? _linkedEmail;
  String? _error;
  bool _canResend = false;
  bool _hasSubscription = false;
  String _tier = 'FREE';

  @override
  void initState() {
    super.initState();
    _linkedEmail = widget.existingEmail;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Please enter a valid email');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final success = await _api.sendLinkCode(email);

    if (!mounted) return;
    if (success) {
      setState(() {
        _isLoading = false;
        _step = _LinkStep.enterCode;
        _canResend = false;
      });
      Future.delayed(const Duration(seconds: 60), () {
        if (mounted) setState(() => _canResend = true);
      });
    } else {
      setState(() {
        _isLoading = false;
        _error = 'Failed to send code. Please try again.';
      });
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Please enter the 6-digit code');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final email = _emailController.text.trim();
    final result = await _api.verifyLinkCode(email, code);

    if (!mounted) return;

    if (result == null) {
      setState(() {
        _isLoading = false;
        _error = 'Connection error. Please try again.';
      });
      return;
    }

    if (result['verified'] != true) {
      final errorCode = result['error'] as String?;
      final remaining = result['attemptsRemaining'] as int?;
      String errorMsg;
      if (errorCode == 'code_expired') {
        errorMsg = 'Code expired. Please request a new one.';
      } else if (errorCode == 'too_many_attempts') {
        errorMsg = 'Too many failed attempts. Please request a new code.';
        _codeController.clear();
        _step = _LinkStep.enterEmail;
      } else if (remaining != null && remaining > 0) {
        errorMsg = 'Invalid code. $remaining attempt${remaining == 1 ? '' : 's'} remaining.';
      } else {
        errorMsg = 'Invalid code. Please try again.';
      }
      setState(() {
        _isLoading = false;
        _error = errorMsg;
      });
      return;
    }

    // Verified — now do RevenueCat login with purchase protection
    _hasSubscription = result['hasSubscription'] == true;
    _tier = (result['tier'] as String?) ?? 'FREE';

    // Persist tier for display and subscription-aware logic
    final tierPrefs = await SharedPreferences.getInstance();
    await tierPrefs.setString('riffroutine_tier', _tier);
    await tierPrefs.setBool('riffroutine_subscription_active', _hasSubscription);

    try {
      // 1. Snapshot current entitlements and anonymous ID BEFORE switching identity
      final beforeInfo = await Purchases.getCustomerInfo();
      final previousEntitlements = beforeInfo.entitlements.active.keys.toList();
      final previousAnonId = beforeInfo.originalAppUserId;

      // Save anonymous ID so we can restore it on unlink
      await tierPrefs.setString(_anonUserIdKey, previousAnonId);

      // 2. Switch RevenueCat identity
      final loginResult = await Purchases.logIn(email);

      // 3. Check if existing purchases would be lost
      final lostEntitlements = previousEntitlements.where(
        (id) => !loginResult.customerInfo.entitlements.active.containsKey(id),
      ).toList();

      if (lostEntitlements.isNotEmpty && !_hasSubscription) {
        if (!mounted) return;
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Warning: Existing Purchases'),
            content: Text(
              'Linking this account would disconnect your current in-app purchase '
              '(${lostEntitlements.join(", ")}). '
              'The linked RiffRoutine account has no active subscription.\n\n'
              'Do you want to proceed anyway?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: Colors.orange),
                child: const Text('Link Anyway'),
              ),
            ],
          ),
        );

        if (proceed != true) {
          try { await Purchases.logOut(); } catch (_) {}
          if (!mounted) return;
          setState(() => _isLoading = false);
          return;
        }
      }

      // 4. Success — notify parent
      await widget.onLinked(email);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _linkedEmail = email;
        _step = _LinkStep.result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Failed to link account: $e';
      });
    }
  }

  Future<void> _unlinkAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unlink Account?'),
        content: const Text(
          'If you purchased premium through this app while linked, '
          'unlinking may affect your access. You can re-link anytime to restore it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      await widget.onUnlinked();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _linkedEmail = null;
        _step = _LinkStep.enterEmail;
        _emailController.clear();
        _codeController.clear();
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Row(
            children: [
              Icon(Icons.link, color: Colors.purple, size: 28),
              SizedBox(width: 12),
              Text(
                'Link RiffRoutine Account',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Show linked view
          if (_linkedEmail != null && _step != _LinkStep.result) ...[
            _buildLinkedView(),
          ] else ...[
            // Error message
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Step content
            if (_step == _LinkStep.enterEmail) _buildEmailStep(),
            if (_step == _LinkStep.enterCode) _buildCodeStep(),
            if (_step == _LinkStep.result) _buildResultStep(),
          ],
        ],
      ),
    );
  }

  Widget _buildLinkedView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Account Linked', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(_linkedEmail!, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isLoading ? null : _unlinkAccount,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Unlink Account'),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter the email you used on riffroutine.com',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: InputDecoration(
            hintText: 'your@email.com',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.purple, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "We'll send a 6-digit verification code to this email",
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Send Verification Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Code sent to ${_emailController.text.trim()}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _step = _LinkStep.enterEmail;
                  _codeController.clear();
                  _error = null;
                });
              },
              child: const Text('Change', style: TextStyle(color: Colors.purple)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 8),
          decoration: InputDecoration(
            hintText: '000000',
            counterText: '',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.purple, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Verify & Link', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: _canResend ? _sendCode : null,
            child: Text(
              _canResend ? 'Resend code' : 'Resend code (wait 60s)',
              style: TextStyle(
                color: _canResend ? Colors.purple : Colors.grey.shade400,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultStep() {
    if (_hasSubscription) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 12),
            const Text('Account Linked!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              '${_tier.toUpperCase()} subscription active',
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange, size: 48),
          const SizedBox(height: 12),
          const Text('Email Verified & Linked', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'No active subscription found. Subscribe at riffroutine.com/pricing to unlock premium.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Your subscription will automatically sync to this app.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
