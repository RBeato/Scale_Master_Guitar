import 'dart:async';

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
  Timer? _timer;

  @override
  Widget build(BuildContext context) {
    final selectedScale = ref.watch(scaleDropdownValueProvider);
    final selectedMode = ref.watch(modeDropdownValueProvider);
    final entitlement = ref.watch(revenueCatProvider);

    bool hasFullAccess =
        entitlement == Entitlement.paid || entitlement == Entitlement.trial;
    String defaultScale = 'Diatonic Major';

    final scaleToDisplay = hasFullAccess ? selectedScale : defaultScale;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Expanded(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.4,
              ),
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                dropdownColor: Colors.grey[800],
                value: scaleToDisplay,
                onChanged: (newValue) {
                  if (hasFullAccess) {
                    ref.read(scaleDropdownValueProvider.notifier).state =
                        newValue!;
                    ref.read(modeDropdownValueProvider.notifier).state =
                        Scales.data[newValue]!.keys.first;
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Upgrade required to select this scale. Defaulting to Diatonic Major.'),
                      ),
                    );
                    ref.read(scaleDropdownValueProvider.notifier).state =
                        defaultScale;
                    ref.read(modeDropdownValueProvider.notifier).state =
                        Scales.data[defaultScale]!.keys.first;
                  }
                },
                items: Scales.data.keys
                    .map<DropdownMenuItem<String>>((String key) {
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
          const SizedBox(width: 20),
          Expanded(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.4,
              ),
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                dropdownColor: Colors.grey[800],
                value: selectedMode,
                onChanged: (newValue) {
                  ref.read(modeDropdownValueProvider.notifier).state =
                      newValue!;
                },
                items: Scales
                    .data[hasFullAccess ? selectedScale : defaultScale]!.keys
                    .map<DropdownMenuItem<String>>((String key) {
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
