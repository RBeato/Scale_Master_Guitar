import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tonic/tonic.dart' as tonic;

import '../../../constants/color_constants.dart';
import '../../../constants/flats_only_nomenclature_converter.dart';
import '../../../constants/fretboard_notes.dart';
import '../../../constants/scales/scales_data_v2.dart';
import '../../../models/scale_model.dart';
import '../../../models/chord_scale_model.dart';
import '../../../models/settings_model.dart';
import '../../../utils/music_utils.dart';

class FingeringsCreator {
  String? _modeOption;
  int? _numberOfChordNotes;
  String? _chordVoicings;

  late String _key;
  // late String _key;

  List? _voicingIntervalsNumbers;
  List? _lowerStringList;
  List? _stringDistribution;

  List? _modeIntervals;
  List? _modeNotes;
  List<tonic.Interval>? _voicingTonicIntervalList;
  List _chordNotesPositions = [];
  List _scaleNotesPositions = [];
  Map<String, Color> _scaleColorfulMap = {};
  Map<String, String> _scaleDegreesPositionsMap = {};

  int scaleDegree = 0;

  ChordScaleFingeringsModel _scaleChordPositions = ChordScaleFingeringsModel();
  ChordScaleFingeringsModel get scaleChordPositions => _scaleChordPositions;
  static late Map chordsAndTrackPositions;

  resetScaleChords() {
    _scaleChordPositions = ChordScaleFingeringsModel();
  }

  // settingsChanged(Settings settings) {
  //   _key = MusicConstants.notesWithFlats[settings.musicKey.toInt()];
  // }

  ChordScaleFingeringsModel createChordsScales(
      ScaleModel chordModel, Settings settings) {
    // settingsChanged(settings);

    _key = chordModel.parentScaleKey;
    _modeOption = chordModel.mode;

    return createFretboardPositions(chordModel);
  }

  createFretboardPositions(ScaleModel scaleModel) {
    _key = MusicUtils.flatsAndSharpsToFlats(scaleModel.parentScaleKey);
    addChordsTypes(scaleModel);
    setModeDegrees(scaleModel);
    filterSettings();
    buildVoicingIntervalsList();
    chordsStringFretPositions();
    scalesStringFretPositions();
    // print(_scaleChordPositions);

    _scaleChordPositions = ChordScaleFingeringsModel(
      scaleModel: scaleModel,
      chordVoicingNotesPositions: _chordNotesPositions,
      scaleNotesPositions: _scaleNotesPositions,
      scaleColorfulMap: _scaleColorfulMap,
      scaleDegreesPositionsMap: _scaleDegreesPositionsMap,
    );

    _chordNotesPositions = [];
    _scaleNotesPositions = [];
    _scaleColorfulMap = {};
    _scaleDegreesPositionsMap = {};

    return _scaleChordPositions;
  }

  addChordsTypes(ScaleModel scaleModel) {
    List<String> aux = [];
    for (int i = 0; i < scaleModel.chordTypes.length; i++) {
      aux.add(
          '${scaleModel.scaleNotesNames[i]}${scaleModel.chordTypes[i] == 'M' ? '' : scaleModel.chordTypes[i]}');
    }
    // scaleModel.scaleNotesNames = aux;
    scaleModel.completeChordNames = aux;
    //TODO: Check if is correct
  }

  setModeDegrees(scaleModel) {
    _modeIntervals = (Scales.data[scaleModel.scale]
            [scaleModel.mode]!['scaleDegrees'])
        .where((n) => n != null)
        .map((e) => e!)
        .toList();
  }

  filterSettings() {
    int randomChoice = Random().nextInt(2);

    if (_numberOfChordNotes == 3) {
      switch (_chordVoicings) {
        case 'All chord tones':
          _voicingIntervalsNumbers = [1, 3, 5];

          /// _stringDistriuitions is in all strings
          break;
        case 'Close voicings':
          _voicingIntervalsNumbers = [1, 3, 5];
          _stringDistribution = [0, -1, -2];
          break;
        case 'CAGED':
          _voicingIntervalsNumbers = [1, 3, 5]; //not used
          _stringDistribution = []; //not used
          break;
        case 'Drop':
          _voicingIntervalsNumbers = [1, 5, 3];
          _stringDistribution = [0, -1, -3];
          break;
        default:
      }
    }
    if (_numberOfChordNotes == 4) {
      switch (_chordVoicings) {
        case 'All chord tones':
          _voicingIntervalsNumbers = [1, 3, 5, 7];
          // _stringDistriuitions is in all strings
          break;
        case 'Close voicings':
          _voicingIntervalsNumbers = [1, 3, 5, 7];
          _stringDistribution = [0, -1, -2, -3];
          break;
        case 'Drop':
          if (randomChoice == 1) {
            //Drop2
            // print('RANDOM  CHOICE: DROP2');
            _voicingIntervalsNumbers = [1, 5, 7, 3];
            _stringDistribution = [0, -1, -2, -3];
          } else {
            // 'Drop 3'
            // print('RANDOM  CHOICE: DROP3');
            _stringDistribution = [0, -2, -3, -4];
            _voicingIntervalsNumbers = [1, 7, 3, 5];
          }
          break;
        case 'CAGED':
          //* Special case
          _voicingIntervalsNumbers = [1, 3, 5, 7]; //not used
          _stringDistribution = []; //not used
          break;
        default:
      }
    }
  }

  buildVoicingIntervalsList() {
    _voicingTonicIntervalList = [];
    if (_voicingIntervalsNumbers == null) {
      return;
    } //TODO: Review if this is needed
    for (var element in _voicingIntervalsNumbers!) {
      _voicingTonicIntervalList!.add(_modeIntervals![element - 1]);
    }
  }

  chordsStringFretPositions() {
    _chordNotesPositions = [];
    late int auxValue;
    int string;
    String noteName;
    String noteNameWithoutIndex;
    int fret;
    //CHORD VOICINGS == 'ALL CHORD TONES'
    if (_chordVoicings == 'All chord tones') {
      List<int> noteRepetitionsInOneString = [0, 2];
      for (int i = 0; i < _lowerStringList!.length; i++) {
        for (int j = 0; j < _voicingTonicIntervalList!.length; j++) {
          noteName = (tonic.Pitch.parse(_key) + _voicingTonicIntervalList![j])
              .toString();
          noteNameWithoutIndex =
              noteName.substring(0, noteName.toString().length - 1);
          noteNameWithoutIndex =
              flatsOnlyNoteNomenclature(noteNameWithoutIndex);
          string = _lowerStringList![i]; //strings between 0-5

          for (int n = 0; n < noteRepetitionsInOneString.length; n++) {
            fret = fretboardNotesNamesFlats[string - 1]
                .indexOf(noteNameWithoutIndex, noteRepetitionsInOneString[n]);
            if (n == 1 && fret == auxValue) {
              continue;
            }
            auxValue = fret;
            _chordNotesPositions.add([string, fret]);
          }
        }
      }
      // print('\"All chord tones\" chordNotesPositions: $_chordNotesPositions');
    }
    if (_chordVoicings == 'CAGED') {
      //CAGED NOTES POSITIONS
      //!!ADD CAGED TYPE TO 7TH CHORDS.?
      final chordType =
          tonic.ChordPattern.fromIntervals(_voicingTonicIntervalList!);

      final chord = tonic.Chord.parse('$_key $chordType');
      final instrument = tonic.Instrument.guitar;
      final fretting = tonic.bestFrettingFor(chord, instrument).toString();
      // print('Fretting : $fretting');
      try {
        int stringNumber = 6;
        for (int i = 0; i < 6; i++) {
          var fret = fretting.substring(i, i + 1);
          if (fret != 'x') {
            _chordNotesPositions.add([stringNumber, int.parse(fret)]);
            stringNumber--;
          } else {
            stringNumber--;
          }
        }
        // print('_chordNotesPositions $_chordNotesPositions');
      } catch (e) {
        print('Parsing error: $e');
      }
    }
    //CHORD VOICINGS == 'drop2' || ChordVoicings == 'drop3'|| ChordVoicings == 'close voicing'
    if (_chordVoicings == 'Close voicings' || _chordVoicings == 'Drop') {
      List<int> proximityList = [];
      List<int> notesRepetitionsInOneString = [0, 2];

      for (int i = 0; i < _voicingTonicIntervalList!.length; i++) {
        for (int j = 0; j < _lowerStringList!.length; j++) {
          for (int k = 0; k < notesRepetitionsInOneString.length; k++) {
            string = _lowerStringList![j] +
                _stringDistribution![i]; //strings indexes between 0-5
            noteName = (tonic.Pitch.parse(_key) + _voicingTonicIntervalList![i])
                .toString();
            noteNameWithoutIndex =
                noteName.substring(0, noteName.toString().length - 1);
            noteNameWithoutIndex =
                flatsOnlyNoteNomenclature(noteNameWithoutIndex);
            if (string == 0) {
              print("STRING == 0");
            }
            fret = fretboardNotesNamesFlats[string - 1]
                .indexOf(noteNameWithoutIndex, notesRepetitionsInOneString[k]);
            if (k > 0 && fret == auxValue) {
              continue;
            }
            auxValue = fret;
            proximityList.add(fret);
            _chordNotesPositions.add([string, fret]);
            // print('_proximityList : $_proximityList');
            // print('_chordNotesPositions: $_chordNotesPositions');
          }
        }
        //Calculate the average value fret for the chord and correct the position
        var averageFretPosition =
            proximityList.map((m) => m).reduce((a, b) => a + b) /
                proximityList.length;
        print('Average result: $averageFretPosition');

        for (int frt = 0; frt < _chordNotesPositions.length; frt++) {
          _chordNotesPositions.removeWhere((item) =>
              item[1] < averageFretPosition - 6.5 ||
              item[1] > averageFretPosition + 6.5);
        }
      }
    }
  }

  scalesStringFretPositions() {
    //!Add scale degree here
    _modeNotes = _modeIntervals!
        .map((interval) => tonic.Pitch.parse(_key) + interval)
        .toList();
    _modeNotes = _modeNotes!
        .map((e) => e.toString().substring(0, e.toString().length - 1))
        .toList();
    _modeNotes = _modeNotes!.map((e) => flatsOnlyNoteNomenclature(e)).toList();
    // print('ModeNotes: ${_modeNotes}');

    // var notesRepetitionsInOneString = [0, 2, 3];
    for (int string = 0; string < 6; string++) {
      for (int i = 0; i < _modeNotes!.length; i++) {
        int noteIndex = 0;
        while (noteIndex != -1) {
          int fret = fretboardNotesNamesFlats[string].indexOf(
            _modeNotes![i],
            noteIndex,
          );

          if (fret == -1) {
            // Add this check to break out of the loop if note is not found
            break; // Exit the while loop
          }

          _scaleNotesPositions.add([string + 1, fret]);
          _scaleColorfulMap["${string + 1},$fret"] =
              ConstantColors.scaleTonicColorMap[_modeIntervals![i]]!;
          _scaleDegreesPositionsMap["${string + 1},$fret"] =
              _modeIntervals![i].toString();

          noteIndex = fret + 1; // Prepare for the next iteration
        }
      }
    }

    // var notesRepetitionsInOneString = [0, 2, 3];
    // for (int string = 0; string < 6; string++) {
    //   for (int i = 0; i < _modeNotes!.length; i++) {
    //     for (int n = 0; n < notesRepetitionsInOneString.length; n++) {
    //       print(
    //           " _modeNotes![i], ${_modeNotes![i]} notesRepetitionsInOneString[n]${notesRepetitionsInOneString[n]}");
    //       int fret = fretboardNotesNamesFlats[string].indexOf(
    //         _modeNotes![i],
    //         notesRepetitionsInOneString[n],
    //       );
    //       print("Fret: $fret");
    //       bool contains = false;
    //       for (var k in _scaleNotesPositions) {
    //         if (k[0] == string + 1 && k[1] == fret) contains = true;
    //       }
    //       if (contains == false) {
    //         _scaleNotesPositions.add([string + 1, fret]);
    //         _scaleColorfulMap["${string + 1},$fret"] =
    //             scaleTonicColorMap[_modeIntervals![i]]!;
    //         print("_scaleNotesPositions $_scaleNotesPositions");
    //         print("_scaleColorfulMap $_scaleColorfulMap");
    //       }
    //     }
    //   }
    // }
    //! IF 'scalesOnly' is selected and IF brainin colors are selected show colorful fretboard
    // print('_scaleNotesPositions $_scaleNotesPositions');
  }

  Map cagedVoicings = {
    'C': {'5': 1, '4': 3, '3': 5, '2': 1, '1': 3},
    'A': {'5': 1, '4': 5, '3': 1, '2': 3, '1': 5},
    'G': {'6': 1, '5': 3, '4': 5, '3': 1, '2': 3, '1': 1},
    'E': {'6': 1, '5': 5, '4': 1, '3': 3, '2': 5, '1': 1},
    'D': {'4': 1, '3': 5, '2': 1, '1': 3},
  };
}
