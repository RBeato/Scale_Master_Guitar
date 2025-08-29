import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:scalemasterguitar/UI/drawer/UI/drawer/settings_enum.dart';
import 'package:scalemasterguitar/UI/drawer/provider/settings_state_notifier.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/provider/revenue_cat_provider.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/entitlement.dart';

class DrawerCard extends ConsumerWidget {
  final String title;
  final String subtitle;
  final String savedValue;
  final List dropdownList;
  final SettingsSelection settingsSelection;
  final bool isPremiumFeature;

  const DrawerCard(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.dropdownList,
      required this.savedValue,
      required this.settingsSelection,
      this.isPremiumFeature = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlement = ref.watch(revenueCatProvider);
    final isPremiumUser = entitlement.hasFullScaleAccess;
    final isFeatureRestricted = isPremiumFeature && !isPremiumUser;
    
    return Card(
      color: Colors.black12,
      child: ExpansionTile(
        backgroundColor: Colors.black87,
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
        trailing: DropdownButton<String>(
              dropdownColor: Colors.grey[900],
              value: savedValue,
              style: TextStyle(
                fontSize: 14.0,
                color: isFeatureRestricted ? Colors.grey : Colors.white,
              ),
              icon: Icon(
                Icons.arrow_downward,
                color: isFeatureRestricted ? Colors.grey : Colors.white,
              ),
              iconSize: 15,
              elevation: 10,
              disabledHint: const Text('Disabled'),
              underline:
                  Container(height: 2, color: Colors.black.withValues(alpha: 0.5)),
              onChanged: isFeatureRestricted 
                  ? null 
                  : (String? newValue) {
                      if (newValue != null) {
                        ref
                            .read(settingsStateNotifierProvider.notifier)
                            .changeValue(settingsSelection, newValue);
                      }
                    },
              items: dropdownList.map((item) {
                return DropdownMenuItem(
                  value: item.toString(),
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 14.0, 
                      color: isFeatureRestricted ? Colors.grey : Colors.white,
                    ),
                  ),
                );
              }).toList(),
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
                style: const TextStyle(fontSize: 11.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
