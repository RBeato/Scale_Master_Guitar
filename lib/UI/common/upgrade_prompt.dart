import 'package:flutter/material.dart';
import 'package:scalemasterguitar/UI/paywall/enhanced_paywall.dart';

class UpgradePrompt {
  /// Shows a snackbar with upgrade message and optional action to open paywall
  static void showUpgradeSnackbar(
    BuildContext context,
    String message, {
    bool showPaywallAction = true,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: showPaywallAction
            ? SnackBarAction(
                label: 'Upgrade',
                onPressed: () => showUpgradeDialog(context),
              )
            : null,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Shows the enhanced paywall dialog
  static Future<bool?> showUpgradeDialog(BuildContext context) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const EnhancedPaywallPage(),
        fullscreenDialog: true,
      ),
    );
  }

  /// Shows a modal bottom sheet with upgrade options
  static Future<bool?> showUpgradeBottomSheet(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: const EnhancedPaywallPage(),
      ),
    );
  }

  /// Shows a simple alert dialog with upgrade information
  static Future<bool?> showUpgradeAlert(
    BuildContext context, {
    required String title,
    required String message,
    String upgradeButtonText = 'Upgrade Now',
    String cancelButtonText = 'Not Now',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              cancelButtonText,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              showUpgradeDialog(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text(upgradeButtonText),
          ),
        ],
      ),
    );
  }
}