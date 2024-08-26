import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test/revenue_cat_purchase_flutter/provider/revenue_cat_provider.dart';

import '../../constants/scales/scales_data_v2.dart';
import '../../revenue_cat_purchase_flutter/entitlement.dart';
import 'provider/mode_dropdown_value_provider.dart';
import 'provider/scale_dropdown_value_provider.dart';

class ScaleSelector extends ConsumerStatefulWidget {
  const ScaleSelector({super.key});

  @override
  _ScaleSelectorState createState() => _ScaleSelectorState();
}

class _ScaleSelectorState extends ConsumerState<ScaleSelector> {
  @override
  Widget build(BuildContext context) {
    final selectedScale = ref.watch(scaleDropdownValueProvider);
    final selectedMode = ref.watch(modeDropdownValueProvider);
    final entitlement =
        ref.watch(revenueCatProvider); // Watch user's entitlement status

    bool hasFullAccess =
        entitlement == Entitlement.paid || entitlement == Entitlement.trial;
    String defaultScale = 'Diatonic Major';

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
                isExpanded: true, // Make the dropdown button expanded
                dropdownColor: Colors.grey[800],
                value: hasFullAccess ? selectedScale : defaultScale,
                onChanged: (newValue) {
                  if (hasFullAccess) {
                    ref.read(scaleDropdownValueProvider.notifier).state =
                        newValue!;
                    ref.read(modeDropdownValueProvider.notifier).state =
                        Scales.data[newValue].keys.first as String;
                  } else {
                    // If the user doesn't have full access, reset to default
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Upgrade required to select this scale. Defaulting to Diatonic Major.'),
                      ),
                    );
                    // ref.read(scaleDropdownValueProvider.notifier).state =
                    //     defaultScale;
                    // ref.read(modeDropdownValueProvider.notifier).state =
                    //     Scales.data[defaultScale].keys.first as String;
                  }
                },
                items: Scales.data.keys
                    .map<DropdownMenuItem<String>>((dynamic value) {
                  String key = value as String;
                  return DropdownMenuItem<String>(
                    value: key,
                    child: Text(key,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70)),
                  );
                }).toList(),
                hint: const Text('Select Scale',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white70)),
              ),
            ),
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
                items: Scales
                    .data[hasFullAccess ? selectedScale : defaultScale].keys
                    .map<DropdownMenuItem<String>>((dynamic value) {
                  String key = value.toString();
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
