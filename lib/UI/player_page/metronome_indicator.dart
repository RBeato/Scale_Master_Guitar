import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../fretboard/provider/beat_counter_provider.dart';

class MetronomeIndicator extends ConsumerWidget {
  const MetronomeIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStep = ref.watch(currentBeatProvider);
    return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(child: Consumer(builder: (context, watch, _) {
            final numberBeats = ref.watch(beatCounterProvider);

            return Container(
              decoration: const BoxDecoration(
                border: Border(
                    right: BorderSide(
                  width: 1.0,
                  color: Colors.transparent,
                )),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List<Widget>.generate(
                  numberBeats,
                  (i) => Expanded(
                    child: SizedBox.expand(
                      child: Container(
                        decoration: BoxDecoration(
                            color: _getColor(i, currentStep),
                            borderRadius: BorderRadius.circular(10.0)),
                      ),
                    ),
                  ),
                ),
              ),
            );
          })),
        ]);
  }

  Color _getColor(int i, int currentStep) {
    Color color = Colors.white;
    if (i == currentStep) {
      color = Colors.white70.withOpacity(0.9);
    } else {
      color = Colors.transparent.withOpacity(0.2); //was transparent
    }
    return color;
  }
}
