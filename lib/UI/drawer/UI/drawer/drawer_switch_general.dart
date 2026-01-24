import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:scalemasterguitar/UI/drawer/UI/drawer/settings_enum.dart';
import 'package:scalemasterguitar/UI/drawer/provider/settings_state_notifier.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/provider/revenue_cat_provider.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/entitlement.dart';
import 'package:scalemasterguitar/constants/app_theme.dart';

class DrawerGeneralSwitch extends ConsumerWidget {
  const DrawerGeneralSwitch({
    super.key,
    required this.title,
    required this.subtitle,
    required this.settingSelection,
    required this.switchValue,
    this.isPremiumFeature = false,
  });

  final String title;
  final String subtitle;
  final SettingsSelection settingSelection;
  final bool switchValue;
  final bool isPremiumFeature;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlement = ref.watch(revenueCatProvider);
    final isPremiumUser = entitlement.hasFullScaleAccess; // Using existing premium check
    final isFeatureRestricted = isPremiumFeature && !isPremiumUser;
    
    return Card(
      color: AppColors.surface,
      child: ExpansionTile(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isFeatureRestricted ? Colors.white.withValues(alpha: 0.5) : Colors.white,
                ),
              ),
            ),
            if (isFeatureRestricted)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star,
                  size: 12,
                  color: Colors.white,
                ),
              ),
          ],
        ),
        trailing: Switch(
          value: switchValue,
          onChanged: isFeatureRestricted
              ? null // Disable the switch for restricted features
              : (value) async {
                  await ref
                      .read(settingsStateNotifierProvider.notifier)
                      .changeValue(settingSelection, value);
                },
          activeTrackColor: isFeatureRestricted 
              ? Colors.grey 
              : Colors.lightGreenAccent,
          activeColor: isFeatureRestricted 
              ? Colors.grey 
              : Colors.green,
        ),
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
              ),
              child: Text(
                subtitle,
                textAlign: TextAlign.left,
                style: const TextStyle(fontSize: 11.0, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
