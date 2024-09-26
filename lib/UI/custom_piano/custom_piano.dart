import 'package:flutter/material.dart';
import 'package:test/constants/music_constants.dart';
import '../../constants/accidents_simplifier.dart';
import '../../models/scale_model.dart';
import '../../utils/music_utils.dart';
import 'custom_piano_key.dart';

class CustomPiano extends StatefulWidget {
  const CustomPiano(this.scaleInfo, {required this.onKeyPressed, super.key});

  final ScaleModel? scaleInfo;
  final Function(String) onKeyPressed;

  @override
  State<CustomPiano> createState() => _CustomPianoState();
}

class _CustomPianoState extends State<CustomPiano> {
  final int numberOfOctaves = 6;
  final whiteKeyNotes = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
  final blackKeyNotes = ['C♯/D♭', 'D♯/E♭', 'F♯/G♭', 'G♯/A♭', 'A♯/B♭'];
  List notesList = [];

  @override
  Widget build(BuildContext context) {
    double whiteKeyWidth = 40.0;
    double blackKeyWidth = 25.0;
    double whiteKeysWidth = numberOfOctaves * 7 * whiteKeyWidth;

    double initialScrollOffset =
        (whiteKeysWidth - MediaQuery.of(context).size.width) / 2;
    ScrollController scrollController =
        ScrollController(initialScrollOffset: initialScrollOffset);

    notesList = widget.scaleInfo!.scaleNotesNames
        .map((e) => MusicUtils.extractNoteName(simplifyAccidents(e)))
        .toList();

    return SingleChildScrollView(
      controller: scrollController,
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 150,
        width: whiteKeysWidth,
        child: Stack(
          children: [
            Row(children: _buildWhiteKeys(whiteKeyWidth)),
            ..._buildBlackKeys(whiteKeyWidth, blackKeyWidth),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildWhiteKeys(double whiteKeyWidth) {
    List<Widget> whiteKeys = [];
    for (int octave = 0; octave < numberOfOctaves; octave++) {
      for (int i = 0; i < 7; i++) {
        String noteName = '${whiteKeyNotes[i]}${octave + 1}';

        var cleanedNoteName = MusicUtils.extractNoteName(
            MusicUtils.filterNoteNameWithSlash(noteName));

        Color? color = Colors.blue;

        notesList.first == cleanedNoteName
            ? color = Colors.orange
            : color = Colors.blue;

        whiteKeys.add(CustomPianoKey(
          isBlack: false,
          note: noteName,
          containerColor: color,
          onKeyPressed: (noteName) => widget.onKeyPressed(noteName),
          isInScale: _isInScale(
            cleanedNoteName,
            notesList,
          ),
        ));
      }
    }
    return whiteKeys;
  }

  List<Widget> _buildBlackKeys(double whiteKeyWidth, double blackKeyWidth) {
    List<Widget> blackKeys = [];
    List<double> blackKeyOffsets = [
      whiteKeyWidth - blackKeyWidth / 2,
      whiteKeyWidth * 2 - blackKeyWidth / 2,
      whiteKeyWidth * 4 - blackKeyWidth / 2,
      whiteKeyWidth * 5 - blackKeyWidth / 2,
      whiteKeyWidth * 6 - blackKeyWidth / 2,
    ];

    for (int octave = 0; octave < numberOfOctaves; octave++) {
      for (int i = 0; i < blackKeyNotes.length; i++) {
        String noteName = blackKeyNotes[i] + (octave + 1).toString();

        var cleanedNoteName = MusicUtils.extractNoteName(
            MusicUtils.filterNoteNameWithSlash(noteName));

        Color? color = Colors.blue;
        notesList.first == cleanedNoteName
            ? color = Colors.orange
            : color = Colors.blue;

        double leftOffset = octave * 7 * whiteKeyWidth + blackKeyOffsets[i];

        blackKeys.add(Positioned(
          left: leftOffset,
          child: CustomPianoKey(
            isBlack: true,
            note: noteName,
            containerColor: color,
            onKeyPressed: (noteName) => widget.onKeyPressed(noteName),
            isInScale: _isInScale(
                cleanedNoteName, notesList), // Check if note is in scale
          ),
        ));
      }
    }
    return blackKeys;
  }

  bool _isInScale(String cleanedNoteName, List notesList) {
    var listMidiValues = List.from(notesList)
        .map((e) => MusicConstants
            .midiValues["${MusicUtils.flatsAndSharpsToFlats(e)}1"])
        .toList();
    var noteMidiValue = MusicConstants.midiValues["${cleanedNoteName}1"];

    return listMidiValues.contains(noteMidiValue);
  }
}
