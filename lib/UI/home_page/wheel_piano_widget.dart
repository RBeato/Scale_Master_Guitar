import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../chromatic_wheel/chromatic_wheel.dart';
import '../custom_piano/custom_piano_player.dart';
import '../fretboard/provider/fingerings_provider.dart';

class WheelAndPianoColumn extends ConsumerWidget {
  const WheelAndPianoColumn({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fingerings = ref.watch(chordModelFretboardFingeringProvider);
    return fingerings.when(
      data: (data) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 20),
              Expanded(
                flex: 2,
                child: Center(child: ChromaticWheel(data!.scaleModel!)),
              ),
              const SizedBox(height: 30),
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: CustomPianoSoundController(data.scaleModel),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      ),
      error: (error, stackTrace) => Text('Error: $error'),
    );
  }
}
