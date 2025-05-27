import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../chromatic_wheel/chromatic_wheel.dart';
import '../custom_piano/custom_piano_player.dart';
import '../fretboard/provider/fingerings_provider.dart';

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
        return Text('Error: $error');
      },
    );
  }

  Widget _buildContent(dynamic data) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 14, // Adjusted to maintain proportions with 40% piano size increase
            child: Center(child: ChromaticWheel(data.scaleModel!)),
          ),
          const SizedBox(height: 30),
          Expanded(
            flex: 6, // Adjusted for 40% larger piano
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Transform.scale(
                scale: 1.4, // Scale the piano by 40%
                child: CustomPianoSoundController(data.scaleModel),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
