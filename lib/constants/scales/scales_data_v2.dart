import 'package:scalemasterguitar/constants/scales/scales_modes/diatonic_major_modes.dart';
import 'package:scalemasterguitar/constants/scales/scales_modes/melodic_minor_modes.dart';
import 'scales_modes/harmonic_major_modes.dart';
import 'scales_modes/harmonic_minor_modes.dart';
import 'scales_modes/pentatonics.dart';
import 'scales_modes/octatonics.dart';
import 'scales_modes/hexatonics.dart';

class Scales {
  static Map<String, dynamic> data = {
    'Diatonic Major': diatonicMajorModes,
    'Melodic Minor': melodicMinorModes,
    'Harmonic Minor': harmonicMinorModes,
    'Harmonic Major': harmonicMajorModes,
    'Pentatonics': pentatonics,
    'Hexatonics': hexatonics,
    'Octatonics': octatonics,
  };
}
