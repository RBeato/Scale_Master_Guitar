import 'package:tonic/tonic.dart';

class MusicConstants {
  get initialListOfScales => completeListOfScales[0]['modeNames'];

  static List<Interval> tonicNotesDegrees = [
    Interval.P1,
    Interval.m2,
    Interval.M2,
    Interval.m3,
    Interval.M3,
    Interval.P4,
    Interval.TT,
    Interval.P5,
    Interval.m6,
    Interval.M6,
    Interval.m7,
    Interval.M7,
  ];

  static const List<String> notesWithFlats = [
    'C',
    'D♭',
    'D',
    'E♭',
    'E',
    'F',
    'G♭',
    'G',
    'A♭',
    'A',
    'B♭',
    'B',
  ];

  static const List<String> notesDegrees = [
    'I',
    '♭II',
    'II',
    '♯II/♭III',
    'III',
    'IV',
    '♯IV/♭V',
    'V',
    '♯V/bVI',
    'VI/♭♭VII',
    '♭VII',
    'VII'
  ];

  static const List<String> notesWithFlatsAndSharps = [
    'C',
    'C♯/D♭',
    'D',
    'D♯/E♭',
    'E',
    'F',
    'F♯/G♭',
    'G',
    'G♯/A♭',
    'A',
    'A♯/B♭',
    'B',
  ];

  static final List<String> notesWithSharps = [
    'C',
    'C♯',
    'D',
    'D♯',
    'E',
    'F',
    'F♯',
    'G',
    'G♯',
    'A',
    'A♯',
    'B',
  ];

  static const List<String> listOfIntervals = [
    'P1',
    'm2',
    'M2',
    'm3',
    'M3',
    'P4',
    'TT',
    'P5',
    'm6',
    'M6',
    'm7',
    'M7',
    'P8'
  ];

  static final List<String> listOfChordsTypes = [
    'M',
    'm',
    'aug',
    'dim',
    'sus2',
    'sus4',
    'dom7',
    '7aug',
    'dim7',
    'maj7',
    'min7',
    '7♭5',
    'm7♭5',
    '°Maj7',
    'min(maj7)',
    'maj6',
    'min6',
  ];

  static final List listOfChordsInversions = [
    {
      'name': 'triads',
      'intervals': [3, 5],
      'inversion': 'root position'
    },
    {
      'name': 'triads',
      'intervals': [3, 6],
      'inversion': '1st inversion'
    },
    {
      'name': 'triads',
      'intervals': [4, 6],
      'inversion': '2nd inversion'
    },
    {
      'name': '7th',
      'intervals': [3, 5, 7],
      'inversion': 'root position'
    },
    {
      'name': '7th',
      'intervals': [3, 5, 6],
      'inversion': '1st inversion'
    },
    {
      'name': '7th',
      'intervals': [3, 4, 6],
      'inversion': '2nd inversion'
    },
    {
      'name': '7th',
      'intervals': [2, 4, 6],
      'inversion': '3rd inversion'
    },
  ];

  static final List completeListOfScales = [
    {
      'name': 'Diatonic Major',
      'intervals': [0, 2, 4, 5, 7, 9, 11],
      'modeNames': [
        'Ionian',
        'Dorian',
        'Phrygian',
        'Lydian',
        'Mixolydian',
        'Aeolian\nNatural Minor',
        'Locrian'
      ]
    },
    {
      'name': 'Major Pentatonic',
      'intervals': [0, 2, 4, 7, 9],
      'modeNames': [
        'Major Pentatonic',
        'Suspended Pentatonic',
        'Man Gong',
        'Ritusen',
        'Minor Pentatonic'
      ],
    },
    {
      'name': 'Melodic Minor',
      'intervals': [0, 2, 3, 5, 7, 9, 11],
      'modeNames': [
        'Jazz Minor',
        'Dorian ♭2',
        'Lydian Augmented',
        'Lydian Dominant',
        'Mixolydian ♭6',
        'Semilocrian',
        'Superlocrian'
      ]
    },
    {
      'name': 'Harmonic Minor',
      'intervals': [0, 2, 3, 5, 7, 8, 11],
      'modeNames': [
        'Harmonic Minor',
        'Locrian ♯6',
        'Ionian Augmented',
        'Romanian',
        'Phrygian Dominant',
        'Lydian ♯2',
        'Ultralocrian'
      ]
    },
    {
      'name': 'Blues',
      'intervals': [0, 3, 5, 6, 7, 10],
      'modeNames': ['Blues']
    },
    {
      'name': 'Freygish',
      'intervals': [0, 1, 4, 5, 7, 8, 10],
      'modeNames': ['Freygish']
    },
    {
      'name': 'Whole Tone',
      'intervals': [0, 2, 4, 6, 8, 10],
      'modeNames': ['Whole Tone']
    },
    {
      // 'Octatonic' is the classical name. It's the jazz 'Diminished' scale.
      'name': 'Octatonic',
      'intervals': [0, 2, 3, 5, 6, 8, 9, 11],
      'modeNames': ['Diminished']
    }
  ];

  static final Map<String, int> intervalsHalfSteps = {
    'unisson': 0,
    'I': 0,
    '♭II': 1,
    '♭ii': 1,
    'II': 2,
    'ii': 2,
    '♭III': 3,
    '♭iii': 3,
    'III': 4,
    'iii': 4,
    'iv': 5,
    'IV': 5,
    '♭v': 6,
    '♭V': 6,
    'v': 7,
    'V': 7,
    '♭VI': 8,
    '♭vi': 8,
    'VI': 9,
    'vi': 9,
    '♭VII': 10,
    '♭vii': 10,
    'VII': 11,
    'vii': 11,
    'VIII': 12,
    'viii': 12,
  };

  static final Map<String, int> midiValues = {
    'C0': 12,
    'D♭0': 13,
    'D0': 14,
    'E♭0': 15,
    'E0': 16,
    'F0': 17,
    'G♭0': 18,
    'G0': 19,
    'A♭0': 20,
    'A0': 21,
    'B♭0': 22,
    'B0': 23,
    'C1': 24,
    'D♭1': 25,
    'D1': 26,
    'E♭1': 27,
    'E1': 28,
    'F1': 29,
    'G♭1': 30,
    'G1': 31,
    'A♭1': 32,
    'A1': 33,
    'B♭1': 34,
    'B1': 35,
    'C2': 36,
    'D♭2': 37,
    'D2': 38,
    'E♭2': 39,
    'E2': 40,
    'F2': 41,
    'G♭2': 42,
    'G2': 43,
    'A♭2': 44,
    'A2': 45,
    'B♭2': 46,
    'B2': 47,
    'C3': 48,
    'D♭3': 49,
    'D3': 50,
    'E♭3': 51,
    'E3': 52,
    'F3': 53,
    'G♭3': 54,
    'G3': 55,
    'A♭3': 56,
    'A3': 57,
    'B♭3': 58,
    'B3': 59,
    'C4': 60,
    'D♭4': 61,
    'D4': 62,
    'E♭4': 63,
    'E4': 64,
    'F4': 65,
    'G♭4': 66,
    'G4': 67,
    'A♭4': 68,
    'A4': 69,
    'B♭4': 70,
    'B4': 71,
    'C5': 72,
    'D♭5': 73,
    'D5': 74,
    'E♭5': 75,
    'E5': 76,
    'F5': 77,
    'G♭5': 78,
    'G5': 79,
    'A♭5': 80,
    'A5': 81,
    'B♭5': 82,
    'B5': 83,
    'C6': 84,
    'D♭6': 85,
    'D6': 86,
    'E♭6': 87,
    'E6': 88,
    'F6': 89,
    'G♭6': 90,
    'G6': 91,
    'A♭6': 92,
    'A6': 93,
    'B♭6': 94,
    'B6': 95,
    'C7': 96,
    'D♭7': 97,
    'D7': 98,
    'E♭7': 99,
    'E7': 100,
    'F7': 101,
    'G♭7': 102,
    'G7': 103,
    'A♭7': 104,
    'A7': 105,
    'B♭7': 106,
    'B7': 107,
    'C8': 108,
  };
}
