import 'package:flutter/material.dart';
import 'package:scalemasterguitar/constants/music_constants.dart';
import '../../constants/accidents_simplifier.dart';
import '../../models/scale_model.dart';
import '../../utils/music_utils.dart';
import 'custom_piano_key.dart';

class CustomPiano extends StatefulWidget {
  const CustomPiano(
    this.scaleInfo, {
    required this.onKeyDown,
    required this.onKeyUp,
    this.keyScale = 1.0,
    super.key
  });

  final ScaleModel? scaleInfo;
  final Function(String) onKeyDown;
  final Function(String) onKeyUp;
  final double keyScale;

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
    final s = widget.keyScale;
    double whiteKeyWidth = 40.0 * s;
    double blackKeyWidth = 25.0 * s;
    double whiteKeyHeight = 150.0 * s;
    double blackKeyHeight = 100.0 * s;
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
        height: whiteKeyHeight,
        width: whiteKeysWidth,
        child: Stack(
          children: [
            Row(children: _buildWhiteKeys(whiteKeyWidth, whiteKeyHeight)),
            ..._buildBlackKeys(whiteKeyWidth, blackKeyWidth, blackKeyHeight),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildWhiteKeys(double whiteKeyWidth, double whiteKeyHeight) {
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
          onKeyDown: (noteName) => widget.onKeyDown(noteName),
          onKeyUp: (noteName) => widget.onKeyUp(noteName),
          keyHeight: whiteKeyHeight,
          keyWidth: whiteKeyWidth,
          isInScale: _isInScale(
            cleanedNoteName,
            notesList,
          ),
        ));
      }
    }
    return whiteKeys;
  }

  List<Widget> _buildBlackKeys(double whiteKeyWidth, double blackKeyWidth, double blackKeyHeight) {
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
            onKeyDown: (noteName) => widget.onKeyDown(noteName),
            onKeyUp: (noteName) => widget.onKeyUp(noteName),
            keyHeight: blackKeyHeight,
            keyWidth: blackKeyWidth,
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
