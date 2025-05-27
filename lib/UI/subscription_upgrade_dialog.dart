import 'package:flutter/material.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/paywall_page.dart';

void _showUpgradeDialog(BuildContext context, String featureName) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Premium Feature'),
        content: Text(
            '$featureName is only available for premium users. Would you like to upgrade?'),
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
                MaterialPageRoute(builder: (context) => const PaywallPage()),
              );
            },
          ),
        ],
      );
    },
  );
}
