import 'package:flutter/material.dart';
import 'package:scalemasterguitar/UI/paywall/unified_paywall.dart';
import 'package:scalemasterguitar/constants/app_theme.dart';
import 'package:scalemasterguitar/utils/slide_route.dart';

void _showUpgradeDialog(BuildContext context, String featureName) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Premium Feature', style: TextStyle(color: Colors.white)),
        content: Text(
            '$featureName is only available for premium users. Would you like to upgrade?',
            style: const TextStyle(color: Colors.white70)),
        actions: <Widget>[
          TextButton(
            child: const Text('No, thanks'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Upgrade'),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                SlideRoute(page: const UnifiedPaywall(), direction: SlideDirection.fromBottom),
              );
            },
          ),
        ],
      );
    },
  );
}
