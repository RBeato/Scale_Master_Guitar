import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tonic/tonic.dart' as tonic;

import '../chromatic_wheel/chromatic_wheel.dart';
import '../custom_piano/custom_piano_player.dart';
import '../fretboard/provider/fingerings_provider.dart';
import '../../revenue_cat_purchase_flutter/provider/revenue_cat_provider.dart';
import '../../revenue_cat_purchase_flutter/entitlement.dart';
import '../../models/scale_model.dart';
import '../../constants/color_constants.dart';
import '../../constants/app_theme.dart';
import 'provider/piano_visibility_provider.dart';

class WheelAndPianoColumn extends ConsumerWidget {
  const WheelAndPianoColumn({super.key});

  String _getIntervalShortName(tonic.Interval interval) {
    // Map interval to short name like "1", "M2", "m3", "P4", etc.
    final Map<tonic.Interval, String> intervalNames = {
      tonic.Interval.P1: '1',
      tonic.Interval.m2: 'm2',
      tonic.Interval.M2: 'M2',
      tonic.Interval.A2: 'A2',
      tonic.Interval.m3: 'm3',
      tonic.Interval.M3: 'M3',
      tonic.Interval.d4: 'd4',
      tonic.Interval.P4: 'P4',
      tonic.Interval.A4: 'A4',
      tonic.Interval.d5: 'd5',
      tonic.Interval.P5: 'P5',
      tonic.Interval.A5: 'A5',
      tonic.Interval.m6: 'm6',
      tonic.Interval.M6: 'M6',
      tonic.Interval.A6: 'A6',
      tonic.Interval.d7: 'd7',
      tonic.Interval.m7: 'm7',
      tonic.Interval.M7: 'M7',
    };
    return intervalNames[interval] ?? interval.toString();
  }

  Color _getIntervalColor(tonic.Interval interval) {
    return ConstantColors.scaleTonicColorMap[interval] ?? Colors.white;
  }

  Widget _buildScaleNotesDisplay(ScaleModel scaleModel) {
    final notes = scaleModel.scaleNotesNames;
    final intervals = scaleModel.notesIntervalsRelativeToTonicForBuildingChordsList ?? [];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(notes.length, (index) {
          final note = notes[index];
          final interval = index < intervals.length ? intervals[index] : null;
          final intervalColor = interval != null
              ? _getIntervalColor(interval)
              : Colors.white70;
          final intervalName = interval != null
              ? _getIntervalShortName(interval)
              : '';

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                note,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                intervalName,
                style: TextStyle(
                  color: intervalColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fingerings = ref.watch(chordModelFretboardFingeringProvider);
    
    return fingerings.when(
      data: (data) {
        return _buildContent(data!);
      },
      loading: () {
        // Try to get the previous data first
        final previousData = ref.read(chordModelFretboardFingeringProvider).valueOrNull;
        if (previousData != null) {
          // Show previous data while loading
          return _buildContent(previousData);
        }
        return const Center(
          child: CircularProgressIndicator(color: Colors.orange),
        );
      },
      error: (error, stackTrace) {
        // Try to show previous data on error too
        final previousData = ref.read(chordModelFretboardFingeringProvider).valueOrNull;
        if (previousData != null) {
          return _buildContent(previousData);
        }
        return const Text('Something went wrong!');
      },
    );
  }

  Widget _buildContent(dynamic data) {
    // Check if user is premium and piano visibility
    return Consumer(
      builder: (context, ref, child) {
        final entitlement = ref.watch(revenueCatProvider);
        final isPremium = entitlement.isPremium;
        final showPiano = ref.watch(pianoVisibilityProvider);

        // If piano is hidden, show wheel and scale notes
        if (!showPiano) {
          return Column(
            children: [
              // Chromatic wheel centered, with bottom padding to account for scale container
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: ChromaticWheel(data.scaleModel!),
                  ),
                ),
              ),
              // Scale notes at the bottom
              Padding(
                padding: EdgeInsets.only(
                  bottom: isPremium ? 20 : 10,
                  left: 16,
                  right: 16,
                ),
                child: _buildScaleNotesDisplay(data.scaleModel!),
              ),
            ],
          );
        }

        // Adjust spacing based on premium status
        // Premium users get more space since no ad is shown
        return Center(
          child: Column(
            mainAxisAlignment: isPremium
                ? MainAxisAlignment.end // Push content down for premium users
                : MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: isPremium ? 12 : 14, // Give wheel more space when premium
                child: Center(child: ChromaticWheel(data.scaleModel!)),
              ),
              SizedBox(height: isPremium ? 40 : 30), // More spacing for premium
              Expanded(
                flex: isPremium ? 5 : 6, // Slightly smaller piano area for premium
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Transform.scale(
                    scale: 1.12, // Keep the same scale
                    child: CustomPianoSoundController(data.scaleModel),
                  ),
                ),
              ),
              if (isPremium)
                const SizedBox(height: 20), // Extra bottom padding for premium users
            ],
          ),
        );
      },
    );
  }
}
