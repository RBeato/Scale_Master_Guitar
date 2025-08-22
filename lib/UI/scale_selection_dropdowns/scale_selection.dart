import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/scales/scales_data_v2.dart';
import '../../revenue_cat_purchase_flutter/provider/revenue_cat_provider.dart';
import '../../services/feature_restriction_service.dart';
import '../common/upgrade_prompt.dart';
import 'provider/mode_dropdown_value_provider.dart';
import 'provider/scale_dropdown_value_provider.dart';

class ScaleSelector extends ConsumerStatefulWidget {
  const ScaleSelector({super.key});

  @override
  _ScaleSelectorState createState() => _ScaleSelectorState();
}

class _ScaleSelectorState extends ConsumerState<ScaleSelector> {
  String? selectedMode;
  String? selectedChordType;

  @override
  Widget build(BuildContext context) {
    final selectedScale = ref.watch(scaleDropdownValueProvider);
    final selectedMode = ref.watch(modeDropdownValueProvider);
    final entitlement = ref.watch(revenueCatProvider);
    
    // Get scales available to current user
    final allScales = Scales.data.keys.toList();
    final availableScales = ref.watch(availableScalesProvider(allScales));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Expanded(
            child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width *
                      0.4, // Adjust the max width as needed
                ),
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  dropdownColor: Colors.grey[800],
                  value: selectedScale,
                  onChanged: (newValue) {
                    // Check if user can access this scale
                    if (!FeatureRestrictionService.canAccessScale(newValue!, entitlement)) {
                      UpgradePrompt.showUpgradeAlert(
                        context,
                        title: 'Premium Feature',
                        message: FeatureRestrictionService.getScaleRestrictionMessage(),
                      );
                      return;
                    }
                    
                    ref.read(scaleDropdownValueProvider.notifier).state = newValue;
                    ref.read(modeDropdownValueProvider.notifier).state =
                        Scales.data[newValue].keys.first as String;
                  },
                  items: availableScales
                      .map<DropdownMenuItem<String>>((String value) {
                    final isRestricted = !FeatureRestrictionService.canAccessScale(value, entitlement);
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              value,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isRestricted ? Colors.white70.withValues(alpha: 0.5) : Colors.white70,
                              ),
                            ),
                          ),
                          if (isRestricted)
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
                    );
                  }).toList(),
                  hint: const Text('Select Scale',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white70)),
                )),
          ),
          const SizedBox(width: 20), // Adjust the width as needed
          Expanded(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width *
                    0.4, // Adjust the max width as needed
              ),
              child: DropdownButtonFormField<String>(
                isExpanded: true, // Make the dropdown button expanded
                dropdownColor: Colors.grey[800],
                value: selectedMode,
                onChanged: (newValue) {
                  ref
                      .read(modeDropdownValueProvider.notifier)
                      .update((state) => newValue!);
                },
                items: Scales.data[selectedScale].keys
                    .map<DropdownMenuItem<String>>((dynamic value) {
                  String key = value.toString();
                  // debugPrint(key);
                  return DropdownMenuItem<String>(
                    value: key,
                    child: Text(key,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70)),
                  );
                }).toList(),
                hint: const Text('Select Mode',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white70)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
