import 'package:flutter/material.dart';

class Constants {
  static const INITIAL_TEMPO = 120.0;
  static const INITIAL_IS_LOOPING = true;
  static const DEFAULT_VELOCITY = 0.68;

  static const ROW_LABELS_DRUMS = ['HH', 'S', 'K', 'CB'];
  static const ROW_PITCHES_DRUMS = [44, 38, 36, 56];

  static const List<String> samplesImages = [
    'assets/images/bass_drum.png',
    'assets/images/snare_drum.png',
    'assets/images/hi_hat.png',
    'assets/images/cowbell.png',
  ];

  static const mainBackgroundColor = Color(0xFF1C2128);
  static const appBarBackgroundColor = Color(0xFF1C2128); // Same as body
  static const Color appBarColorTheme = Color.fromARGB(255, 235, 182, 103);

  static const List<Color> colors = [
    Colors.red,
    Colors.amber,
    Colors.purple,
    Colors.blue,
    Colors.pink,
  ];

  static const Map<String, Map<String, String>> soundPath = {
    // Updated to use working SF2 files from guitar_progression_generator pattern
    'drums': {
      'Electronic': "assets/sounds/sf2/808-Drums.sf2",
      'Acoustic': "assets/sounds/sf2/DrumsSlavo.sf2"
    },
    'keys': {
      'Piano': "assets/sounds/sf2/korg.sf2",           // Korg Triton - better quality (6.9MB)
      'Rhodes': "assets/sounds/sf2/rhodes.sf2",         // Dedicated Rhodes SF2
      'Organ': "assets/sounds/sf2/korg.sf2",           // Dedicated Korg SF2
      'Pad': "assets/sounds/sf2/korg.sf2"              // Use Korg for pad sounds
    },
    'bass': {
      'Double Bass': "assets/sounds/sf2/acoustic_bass.sf2",    // Dedicated acoustic bass
      'Electric': "assets/sounds/sf2/BassGuitars.sf2",         // Proven electric bass SF2
      'Synth': "assets/sounds/sf2/BassGuitars.sf2"             // Use electric bass for synth
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
