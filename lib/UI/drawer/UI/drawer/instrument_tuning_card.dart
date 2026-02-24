import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scalemasterguitar/constants/app_theme.dart';
import 'package:scalemasterguitar/constants/instrument_presets.dart';
import 'package:scalemasterguitar/models/instrument_tuning.dart';
import 'package:scalemasterguitar/providers/custom_tunings_provider.dart';
import 'package:scalemasterguitar/providers/tuning_provider.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/entitlement.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/provider/revenue_cat_provider.dart';

import 'custom_tuning_creator.dart';

class InstrumentTuningCard extends ConsumerWidget {
  const InstrumentTuningCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlement = ref.watch(revenueCatProvider);
    final isPremiumUser = entitlement.isPremium;
    final isRestricted = !isPremiumUser;
    final currentTuning = ref.watch(tuningProvider);
    final customTunings = ref.watch(customTuningsProvider);

    // Build combined list: presets + custom tunings
    final allTunings = [
      ...InstrumentPresets.allPresets,
      ...customTunings,
    ];

    // Ensure current tuning is in the list
    final currentId = currentTuning.id;
    final isInList = allTunings.any((t) => t.id == currentId);
    if (!isInList) {
      allTunings.add(currentTuning);
    }

    return Card(
      color: AppColors.surface,
      child: ExpansionTile(
        backgroundColor: AppColors.surface,
        initiallyExpanded: false,
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Instrument / Tuning',
                style: TextStyle(
                  color: isRestricted
                      ? Colors.white.withValues(alpha: 0.5)
                      : Colors.white,
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
        trailing: Text(
          currentTuning.name,
          style: TextStyle(
            fontSize: 13.0,
            color: isRestricted ? Colors.grey : Colors.orange,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current tuning: ${currentTuning.openNotes.reversed.join(" - ")}',
                  style: const TextStyle(fontSize: 11.0, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  '${currentTuning.stringCount} strings, ${currentTuning.fretCount} frets',
                  style: const TextStyle(fontSize: 11.0, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                // Preset tunings list
                ...allTunings.map((tuning) => _buildTuningTile(
                      context,
                      ref,
                      tuning,
                      isSelected: tuning.id == currentId,
                      isRestricted: isRestricted,
                      isCustom: customTunings.any((t) => t.id == tuning.id),
                    )),
                const SizedBox(height: 8),
                // Custom tuning button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Create Custom Tuning'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          isRestricted ? Colors.grey : Colors.orange,
                      side: BorderSide(
                        color: isRestricted
                            ? Colors.grey.withValues(alpha: 0.3)
                            : Colors.orange.withValues(alpha: 0.5),
                      ),
                    ),
                    onPressed: isRestricted
                        ? null
                        : () => _showCustomTuningCreator(context),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTuningTile(
    BuildContext context,
    WidgetRef ref,
    InstrumentTuning tuning, {
    required bool isSelected,
    required bool isRestricted,
    required bool isCustom,
  }) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
      leading: Icon(
        _getInstrumentIcon(tuning.type),
        size: 20,
        color: isSelected ? Colors.orange : Colors.grey,
      ),
      title: Text(
        tuning.name,
        style: TextStyle(
          fontSize: 13,
          color: isRestricted
              ? Colors.grey
              : isSelected
                  ? Colors.orange
                  : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        tuning.openNotes.reversed.join(" - "),
        style: TextStyle(
          fontSize: 10,
          color: Colors.grey.withValues(alpha: 0.7),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isCustom)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              color: Colors.grey,
              onPressed: isRestricted
                  ? null
                  : () {
                      ref
                          .read(customTuningsProvider.notifier)
                          .removeTuning(tuning.id);
                      // If we deleted the active tuning, reset to default
                      if (ref.read(tuningProvider).id == tuning.id) {
                        ref
                            .read(tuningProvider.notifier)
                            .setTuning(InstrumentPresets.defaultTuning);
                      }
                    },
            ),
          if (isSelected)
            const Icon(Icons.check_circle, size: 18, color: Colors.orange),
        ],
      ),
      onTap: isRestricted
          ? null
          : () {
              ref.read(tuningProvider.notifier).setTuning(tuning);
            },
    );
  }

  IconData _getInstrumentIcon(InstrumentType type) {
    switch (type) {
      case InstrumentType.guitar:
        return Icons.music_note;
      case InstrumentType.bass:
        return Icons.graphic_eq;
      case InstrumentType.sevenString:
        return Icons.music_note;
      case InstrumentType.ukulele:
        return Icons.music_note_outlined;
      case InstrumentType.custom:
        return Icons.tune;
    }
  }

  void _showCustomTuningCreator(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const CustomTuningCreator(),
    );
  }
}
