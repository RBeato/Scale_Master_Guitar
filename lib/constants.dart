import 'package:flutter/material.dart';

class Constants {
  static const INITIAL_TEMPO = 120.0;
  static const INITIAL_IS_LOOPING = true;
  static const DEFAULT_VELOCITY = 0.75;

  static const ROW_LABELS_DRUMS = ['HH', 'S', 'K', 'CB'];
  static const ROW_PITCHES_DRUMS = [44, 38, 36, 56];

  static const List<String> samplesImages = [
    'assets/images/bass_drum.png',
    'assets/images/snare_drum.png',
    'assets/images/hi_hat.png',
    'assets/images/cowbell.png',
  ];

  static const mainBackgroundColor = Color(0xFF1D1D1D);
  static const Color appBarColorTheme = Color.fromARGB(255, 235, 182, 103);

  static const List<Color> colors = [
    Colors.red,
    Colors.amber,
    Colors.purple,
    Colors.blue,
    Colors.pink,
  ];

  static const Map<String, Map<String, String>> soundPath = {
    'drums': {
      'Electronic': "assets/sounds/sf2/TR-808.sf2",
      'Acoustic': "assets/sounds/sf2/drums_171k_G.sf2"
    },
    'keys': {
      'Piano': "assets/sounds/sf2/kawai_grand_piano.sf2",
      'Rhodes': "assets/sounds/sf2/Toy_Rhodes.sf2"
    },
    'bass': {
      'Double Bass': "assets/sounds/sf2/jazz_bass.sf2",
      'Electric': "assets/sounds/sf2/tek_bass.sf2"
    },
  };

  static const ROW_LABELS_PIANO = [
    'C3',
    'C#3',
    'D3',
    'D#3',
    'E3',
    'F3',
    'F#3',
    'G3',
    'G#3',
    'A3',
    'A#3',
    'B3',
    'C4',
    'C#4',
    'D4',
    'D#4',
    'E4',
    'F4',
    'F#4',
    'G4',
    'G#4',
    'A4',
    'A#4',
    'B4',
    'C5',
    'C#5',
    'D5',
    'D#5',
    'E5',
    'F5',
    'F#5',
    'G5',
    'G#5',
    'A5',
    'A#5',
    'B5',
  ];
  static const ROW_PITCHES_PIANO = [
    48,
    49,
    50,
    51,
    52,
    53,
    54,
    55,
    56,
    57,
    58,
    59,
    60,
    61,
    62,
    63,
    64,
    65,
    66,
    67,
    68,
    69,
    70,
    71,
    72,
    73,
    74,
    75,
    76,
    77,
    78,
    79,
    80,
    81,
    82,
    83,
  ];
}
