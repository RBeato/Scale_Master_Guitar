import 'package:tonic/tonic.dart';

Map barryHarrisModes = {
  'Major 6th Diminished': {
    // C D E F G Ab A B — Major scale + chromatic passing tone (b6) between 5 and 6
    // Harmonization: alternating Major 6th and dim7 chords
    'scaleStepsRoman': ['I', 'II', 'III', 'IV', 'V', '♭VI', 'VI', 'VII'],
    'intervals': [0, 2, 4, 5, 7, 8, 9, 11],
    'scaleDegrees': [
      Interval.P1, // 0  - I
      null, // 1
      Interval.M2, // 2  - II
      null, // 3
      Interval.M3, // 4  - III
      Interval.P4, // 5  - IV
      null, // 6
      Interval.P5, // 7  - V
      Interval.m6, // 8  - ♭VI (passing tone)
      Interval.M6, // 9  - VI
      null, // 10
      Interval.M7, // 11 - VII
    ],
  },
  'Minor 6th Diminished': {
    // C D Eb F G Ab A B — Melodic minor + chromatic passing tone (b6) between 5 and 6
    // Harmonization: alternating minor 6th and dim7 chords
    'scaleStepsRoman': ['I', 'II', '♭III', 'IV', 'V', '♭VI', 'VI', 'VII'],
    'intervals': [0, 2, 3, 5, 7, 8, 9, 11],
    'scaleDegrees': [
      Interval.P1, // 0  - I
      null, // 1
      Interval.M2, // 2  - II
      Interval.m3, // 3  - ♭III
      null, // 4
      Interval.P4, // 5  - IV
      null, // 6
      Interval.P5, // 7  - V
      Interval.m6, // 8  - ♭VI (passing tone)
      Interval.M6, // 9  - VI
      null, // 10
      Interval.M7, // 11 - VII
    ],
  },
  'Dominant 7th Diminished': {
    // C D E F G Ab Bb B — Mixolydian + b6 passing tone between 5 and b7
    // Harmonization: alternating dominant 7th and dim7 chords
    'scaleStepsRoman': ['I', 'II', 'III', 'IV', 'V', '♭VI', '♭VII', 'VII'],
    'intervals': [0, 2, 4, 5, 7, 8, 10, 11],
    'scaleDegrees': [
      Interval.P1, // 0  - I
      null, // 1
      Interval.M2, // 2  - II
      null, // 3
      Interval.M3, // 4  - III
      Interval.P4, // 5  - IV
      null, // 6
      Interval.P5, // 7  - V
      Interval.m6, // 8  - ♭VI (passing tone)
      null, // 9
      Interval.m7, // 10 - ♭VII
      Interval.M7, // 11 - VII
    ],
  },
};
