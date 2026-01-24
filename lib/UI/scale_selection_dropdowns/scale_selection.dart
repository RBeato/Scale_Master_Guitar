import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/scales/scales_data_v2.dart';
import '../../constants/app_theme.dart';
import '../../services/feature_restriction_service.dart';
import '../../revenue_cat_purchase_flutter/provider/revenue_cat_provider.dart';
import '../../UI/common/upgrade_prompt.dart';
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
    
    // Show all scales but indicate which ones require premium
    final allScales = Scales.data.keys.toList();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Premium feature indication for scales  
          if (!FeatureRestrictionService.canAccessScale('Harmonic Minor', entitlement)) // Check if restricted scales exist
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.star,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Premium scales available - Upgrade to unlock all scales',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width *
                      0.4, // Adjust the max width as needed
                ),
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  dropdownColor: AppColors.surface,
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
                  items: allScales
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
                                color: isRestricted ? Colors.white70.withValues(alpha: 0.7) : Colors.white70,
                              ),
                            ),
                          ),
                          if (isRestricted)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
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
                    dropdownColor: AppColors.surface,
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
          ],
        ),
      ),
    );
  }
}
