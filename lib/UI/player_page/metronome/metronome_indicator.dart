import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../../fretboard/provider/beat_counter_provider.dart';

class MetronomeIndicator extends ConsumerWidget {
  const MetronomeIndicator({
    required this.currentStep,
    required this.labelCellSize,
    required this.isBass,
  });
  final int currentStep;
  final double labelCellSize;
  final bool isBass;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: labelCellSize / 6),
      child: SizedBox(
          height: labelCellSize / 6,
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                InkWell(
                  enableFeedback: false,
                  child: Container(
                    width: labelCellSize,
                  ),
                ),
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
              ])),
    );
  }

  Color _getColor(int i, int currentStep) {
    Color color = Colors.white;
    if (i == currentStep) {
      color = Colors.white70.withOpacity(0.2);
    } else {
      color = Colors.transparent;
    }
    return color;
  }
}
