import 'package:tonic/tonic.dart';

Map octatonics = {
  'Whole-Half': {
    'scaleStepsRoman': ['I', 'II', '♭III', 'IV', 'V', '♭VI', 'VI', 'VII'],
    'intervals': [0, 1, 3, 4, 6, 7, 9, 10],
    'scaleDegrees': [
      Interval.P1,
      null,
      Interval.M2,
      Interval.m3,
      null,
      Interval.P4,
      Interval.d5,
      null,
      Interval.m6,
      Interval.M6,
      null,
      Interval.M7,
    ],
  },
  'Half-Whole': {
    'scaleStepsRoman': ['I', '♭II', '♭III', 'III', '♯IV', 'V', 'VI', '♭VII'],
    'intervals': [0, 1, 3, 4, 6, 7, 9, 10],
    'scaleDegrees': [
      Interval.P1,
      Interval.m2,
      null,
      Interval.m3,
      Interval.M3,
      null,
      Interval.A4,
      Interval.P5,
      null,
      Interval.M6,
      Interval.m7,
      null,
    ],
  },
};
