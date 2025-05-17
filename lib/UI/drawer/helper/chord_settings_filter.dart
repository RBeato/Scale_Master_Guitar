import 'package:flutter/material.dart';

import '../../../constants/guitar_chord_voicings.dart';

List<String> createBottomStringList(String chordVoicing) {
  late List<String> bottomStringOptions;
  try {
    switch (chordVoicing) {
      case 'CAGED':
        bottomStringOptions = GuitarChordVoicings.cagedBottomStrings
            .map((o) => o.toString())
            .toList();
        break;
      case 'Close voicings':
        bottomStringOptions = GuitarChordVoicings.basicFormBottomStrings
            .map((o) => o.toString())
            .toList();
        break;
      case 'Drop':
        bottomStringOptions = GuitarChordVoicings.dropBottomStrings
            .map((o) => o.toString())
            .toList();
        break;
      case 'All chord tones':
        bottomStringOptions = GuitarChordVoicings.allChordTonesBottomStrings
            .map((o) => o.toString())
            .toList();
        break;
      default:
    }
  } catch (e) {
    debugPrint('Voicing not selected: $e');
  }
  return bottomStringOptions;
}
