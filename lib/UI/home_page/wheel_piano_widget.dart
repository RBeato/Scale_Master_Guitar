import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../chromatic_wheel/chromatic_wheel.dart';
import '../custom_piano/custom_piano_player.dart';
import '../fretboard/provider/fingerings_provider.dart';
import '../../revenue_cat_purchase_flutter/provider/revenue_cat_provider.dart';
import '../../revenue_cat_purchase_flutter/entitlement.dart';

class WheelAndPianoColumn extends ConsumerWidget {
  const WheelAndPianoColumn({super.key});

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
    // Check if user is premium
    return Consumer(
      builder: (context, ref, child) {
        final entitlement = ref.watch(revenueCatProvider);
        final isPremium = entitlement.isPremium;
        
        // Adjust spacing based on premium status
        // Premium users get more space since no ad is shown
        return Center(
          child: Column(
            mainAxisAlignment: isPremium 
                ? MainAxisAlignment.end  // Push content down for premium users
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
