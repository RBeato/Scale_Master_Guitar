import 'package:tonic/tonic.dart';

class ChordUtils {
  static String handleCustomPatterns(List<Interval?> intervals) {
    List<String> intervalNames = intervals.map((interval) {
      if (interval == Interval.P1) {
        return 'P1';
      } else if (interval == Interval.m2) {
        return 'm2';
      } else if (interval == Interval.M2) {
        return 'M2';
      } else if (interval == Interval.d3) {
        return 'd3';
      } else if (interval == Interval.m3) {
        return 'm3';
      } else if (interval == Interval.M3) {
        return 'M3';
      } else if (interval == Interval.P4) {
        return 'P4';
      } else if (interval == Interval.A4) {
        return 'A4';
      } else if (interval == Interval.d5) {
        return 'd5';
      } else if (interval == Interval.P5) {
        return 'P5';
      } else if (interval == Interval.A5) {
        return 'A5';
      } else if (interval == Interval.m6) {
        return 'm6';
      } else if (interval == Interval.M6) {
        return 'M6';
      } else if (interval == Interval.m7) {
        return 'm7';
      } else if (interval == Interval.M7) {
        return 'M7';
      } else {
        return '';
      }
    }).toList();

    // Join interval names to form a chord pattern string
    String chordPattern = intervalNames.join(',');

    // Manually handle chord patterns not recognized by the ChordPattern class

    if (chordPattern == 'P1,m3,m6') {
      //*inversion
      return 'M7/5';
    }
    if (chordPattern == 'P1,m3,m7') {
      return 'm7';
    }
    if (chordPattern == 'P1,M3,m7') {
      return '7';
    }
    if (chordPattern == 'P1,d3,m6') {
      return 'aug sus2';
    }
    if (chordPattern == 'P1,m3,M6') {
      return 'dim/3';
    }
    if (chordPattern == 'P1,P4,M6') {
      //*inversion
      return 'M64';
    }
    if (chordPattern == '6sus4') {
      //*inversion
      return 'M64';
    }
    if (chordPattern == 'P1,M3,M6') {
      return 'm6';
    }
    if (chordPattern == 'P1,P4,m6') {
      //*inversion
      return 'm64';
    }
    if (chordPattern == 'P1,P4,m7') {
      //*inversion
      return 'sus4/2';
    }
    if (chordPattern == 'P1,P4,M7') {
      return '1/4/7';
    }
    if (chordPattern == 'P1,A4,M6') {
      //*inversion
      return '7/5/3';
    }
    if (chordPattern == 'P1,A4,m6') {
      //*inversion
      return "7/3";
    }
    if (chordPattern == 'P1,A4,M6') {
      //*inversion
      return 'dim/4';
    }
    if (chordPattern == 'P1,A4,M7') {
      return 'Maj7#11';
    }
    if (chordPattern == 'P1,m3,M7') {
      return 'mMaj7';
    }
    if (chordPattern == 'P1,d5,m7') {
      return 'ø7';
    }
    if (chordPattern == 'P1,A5,M7') {
      return 'aug Maj7';
    } else {
      return 'UNKNOWN';
    }
  }

  static Interval getChordNoteIntervalToScaleDegree(String type) {
    if (type == 'm') {
      return Interval.P1;
    }
    if (type == 'min/maj7') {
      return Interval.P1;
    }
    if (type == 'M') {
      return Interval.P1;
    }
    if (type == '') {
      return Interval.P1;
    }
    if (type == 'M7/5') {
      return Interval.m3;
    }

    if (type == 'm7') {
      return Interval.P1;
    }
    if (type == '7') {
      return Interval.P1;
    }
    if (type == 'P1,d3,m6') {
      //TODO: Double check this
      return Interval.m6;
    }
    if (type == 'dim/3') {
      return Interval.M6;
    }
    if (type == 'M64') {
      return Interval.P4;
    }
    if (type == 'm♭6') {
      return Interval.m6;
    }
    if (type == 'm6') {
      return Interval.M6;
    }
    if (type == '6') {
      //TODO: Double check this
      return Interval.M6;
    }
    if (type == 'm64') {
      return Interval.P4;
    }
    if (type == 'sus4/2') {
      return Interval.P4;
    }
    if (type == '1/4/7') {
      return Interval.P1;
    }

    if (type == '7sus4') {
      return Interval.P1;
    }
    if (type == '6sus4') {
      return Interval.P1;
    }
    if (type == '7/5/3') {
      return Interval.M2;
    }
    if (type == '7/3 #4') {
      return Interval.M2;
    }
    if (type == '7/3') {
      return Interval.A4;
    }
    if (type == 'dim/4') {
      return Interval.A4;
    }
    if (type == 'Maj7#11') {
      return Interval.P1;
    }
    if (type == 'mMaj7') {
      return Interval.P1;
    }
    if (type == 'ø7') {
      return Interval.P1;
    }
    if (type == 'aug Maj7') {
      return Interval.P1;
    }
    if (type == 'aug sus2') {
      return Interval.P1;
    }
    if (type == '°') {
      return Interval.P1;
    }
    if (type == '+') {
      return Interval.P1;
    } else {
      print('Unknown chord type. Chord type is $type');
      throw Exception('Unknown chord type. Chord type is $type');
    }
  }
}
