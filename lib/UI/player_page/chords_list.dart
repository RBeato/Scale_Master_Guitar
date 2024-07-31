import 'package:flutter/material.dart';

import '../../models/chord_model.dart';
import 'metronome_indicator.dart';

class ChordListWidget extends StatelessWidget {
  const ChordListWidget({
    Key? key,
    required this.chordList,
  }) : super(key: key);
  final List<ChordModel> chordList;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              const MetronomeIndicator(),
              Opacity(
                opacity: 0.9,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final chord in chordList)
                      Expanded(
                        flex: chord.duration,
                        child: Container(
                          color: chord.color,
                          child: Center(
                            child: Text(
                              chord.completeChordName!,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
