import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/scale_model.dart';
import 'custom_piano_painter.dart';

class CustomPianoTest extends ConsumerStatefulWidget {
  const CustomPianoTest(this.scaleInfo,
      {required this.onKeyPressed, super.key});

  final ScaleModel? scaleInfo;
  final Function(String) onKeyPressed;

  @override
  _CustomPianoState createState() => _CustomPianoState();
}

class _CustomPianoState extends ConsumerState<CustomPianoTest> {
  final int numberOfOctaves = 6;
  final whiteKeyNotes = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
  final blackKeyNotes = ['C♯/D♭', 'D♯/E♭', 'F♯/G♭', 'G♯/A♭', 'A♯/B♭'];
  List<String> pressedKeys = [];

  @override
  Widget build(BuildContext context) {
    double whiteKeyWidth = 40.0;
    double blackKeyWidth = 25.0;
    double whiteKeysWidth = numberOfOctaves * 7 * whiteKeyWidth;

    double initialScrollOffset =
        (whiteKeysWidth - MediaQuery.of(context).size.width) / 2;
    ScrollController scrollController =
        ScrollController(initialScrollOffset: initialScrollOffset);

    List<String> scaleNotes =
        widget.scaleInfo!.scaleNotesNames.map((e) => e).toList();

    return SingleChildScrollView(
      controller: scrollController,
      scrollDirection: Axis.horizontal,
      child: GestureDetector(
        onTapDown: (details) {
          double x = details.localPosition.dx;
          String note = _getNoteAtPosition(x, whiteKeyWidth, blackKeyWidth);
          setState(() {
            pressedKeys.add(note);
          });
          widget.onKeyPressed(note);
        },
        onTapUp: (details) {
          setState(() {
            pressedKeys.clear();
          });
        },
        child: CustomPaint(
          size: Size(whiteKeysWidth, 150),
          painter: CustomPianoPainter(
            numberOfOctaves: numberOfOctaves,
            whiteKeyNotes: whiteKeyNotes,
            blackKeyNotes: blackKeyNotes,
            scaleNotes: scaleNotes,
            whiteKeyWidth: whiteKeyWidth,
            blackKeyWidth: blackKeyWidth,
            pressedKeys: pressedKeys,
            containerColor: Colors.orange,
          ),
        ),
      ),
    );
  }

  String _getNoteAtPosition(
      double x, double whiteKeyWidth, double blackKeyWidth) {
    int octave = (x ~/ (7 * whiteKeyWidth));
    double positionInOctave = x % (7 * whiteKeyWidth);

    // Determine if the click is on a black key
    List<double> blackKeyOffsets = [
      whiteKeyWidth - blackKeyWidth / 2,
      whiteKeyWidth * 2 - blackKeyWidth / 2,
      whiteKeyWidth * 4 - blackKeyWidth / 2,
      whiteKeyWidth * 5 - blackKeyWidth / 2,
      whiteKeyWidth * 6 - blackKeyWidth / 2,
    ];

    for (int i = 0; i < blackKeyOffsets.length; i++) {
      if (positionInOctave >= blackKeyOffsets[i] &&
          positionInOctave < blackKeyOffsets[i] + blackKeyWidth) {
        return blackKeyNotes[i] + (octave + 1).toString();
      }
    }

    // If not, it's on a white key
    int whiteKeyIndex = (positionInOctave ~/ whiteKeyWidth);
    return whiteKeyNotes[whiteKeyIndex] + (octave + 1).toString();
  }
}
