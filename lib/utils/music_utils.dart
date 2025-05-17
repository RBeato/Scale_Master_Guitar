import 'dart:math';

import 'package:tonic/tonic.dart';

import '../constants/flats_only_nomenclature_converter.dart';
import '../constants/music_constants.dart';
import '../constants/scales/scales_data_v2.dart';
import '../models/chord_scale_model.dart';
import '../models/scale_model.dart';
import '../models/settings_model.dart';
import 'chord_utils.dart';
import 'package:flutter/material.dart' as material;
class MusicUtils {
  static List<String> createChords(
      Settings settings, String key, String scale, String mode) {
    return MusicUtils.cleanNotesIndexes(Scales.data[scale][mode]['scaleDegrees']
        .where((n) => n != null)
        .toList()
        .map((interval) => Pitch.parse(key) + interval)
        .toList());
  }

  static List<String> getChordInfo(
      ChordScaleFingeringsModel fingeringsModel, int chordIndex) {
    Map<String, int> chordIntervals = _getNotesScaleNotes(
        fingeringsModel.scaleModel!.modesScalarTonicIntervals[chordIndex]);

    String baseNote = extractNoteName(
        fingeringsModel.scaleModel!.scaleNotesNames[chordIndex]);

    var chordNotes = createNoteList(baseNote, chordIntervals.values.toList());

    return [chordNotes[0], chordNotes[2], chordNotes[4]];
  }

  static Map<String, int> _getNotesScaleNotes(List<Interval> intervals) {
    Map<String, int> chordScaleNotes = {};
    for (var i in intervals) {
      String note = _mapIntervalToChordTone(i);
      chordScaleNotes[note] = i.semitones;
    }
    return chordScaleNotes;
  }

  static List<int> convertToSemiTones(List<Interval> intervals) {
    List<int> semiTones = [];
    for (var interval in intervals) {
      semiTones.add(interval.semitones);
    }
    return semiTones;
  }

  static List<Interval> getScaleDegreesTonicIntervals(
          ChordScaleFingeringsModel fingeringsModel) =>
      (Scales.data[fingeringsModel.scaleModel!.scale]
                  [fingeringsModel.scaleModel!.mode]['scaleDegrees']
              as List<Interval?>)
          .where((n) => n != null)
          .map((e) => e!)
          .toList();

  static List<int> calculateIntervalsForChord(
      int selectedChordIndex, List initialIntervals) {
    List<int> appendingIntervals = [];
    List<int> intervals = [];
    for (int i = 0; i < initialIntervals.length; i++) {
      if (i < selectedChordIndex) {
        var interval = (initialIntervals[i] + 12);
        interval = interval - selectedChordIndex - 1;
        appendingIntervals.add(interval);
      } else {
        var interval = initialIntervals[i] - selectedChordIndex - 1;
        intervals.add(interval);
      }
    }

    intervals.addAll(appendingIntervals);

    return intervals;
  }

  static String filterNoteNameWithSlash(String note) {
    if (note.contains('♯') && note.contains('/')) {
      List<String> parts = note.split('/');
      return parts.length > 1 ? parts[1] : note;
    } else {
      return note;
    }
  }

  static getTriadsNames(ScaleModel item, List modesIntervals) {
    List<String> triadsNames = [];
    List<String> chordNotes = [];
    for (var i = 0; i < modesIntervals.length; i++) {
      var chordType = getTonicTriadType(modesIntervals[i]);
      var chordNote =
          Pitch.parse('${filterNoteNameWithSlash(item.parentScaleKey)}3') +
              item.notesIntervalsRelativeToTonicForBuildingChordsList![i] +
              ChordUtils.getChordNoteIntervalToScaleDegree(chordType);
      var chordNoteNoIndex = cleanNotesIndexes([chordNote]).first;
      triadsNames.add(chordType);
      chordNotes.add("$chordNoteNoIndex$chordType");
    }
    item.chordTypes = triadsNames;
    item.completeChordNames = chordNotes;
  }

  static getTonicTriadType(List<Interval?> scaleDegrees) {
    bool hasSecond = scaleDegrees.contains(Interval.m2) ||
        scaleDegrees.contains(Interval.M2) ||
        scaleDegrees.contains(Interval.A2);
    // Check if the fourth interval is present
    bool hasThird = scaleDegrees.contains(Interval.m3) ||
        scaleDegrees.contains(Interval.M3);
    // Check if the fourth interval is present
    bool hasFourth = scaleDegrees.contains(Interval.d4) ||
        scaleDegrees.contains(Interval.P4) ||
        scaleDegrees.contains(Interval.A4);
    // Check if the fifth interval is present
    bool hasFifth = scaleDegrees.contains(Interval.d5) ||
        scaleDegrees.contains(Interval.P5) ||
        scaleDegrees.contains(Interval.A5);
    // Check if the sixth interval is present
    bool hasSixth = scaleDegrees.contains(Interval.m6) ||
        scaleDegrees.contains(Interval.M6) ||
        scaleDegrees.contains(Interval.A6);
    bool hasSeventh = scaleDegrees.contains(Interval.d7) ||
        scaleDegrees.contains(Interval.m7) ||
        scaleDegrees.contains(Interval.M7);

    List<Interval> intervals = [];
    // debugPrint("scaleDegrees: $scaleDegrees");

    if (scaleDegrees.length == 8) {
      intervals.addAll([
        scaleDegrees[0]!,
        scaleDegrees[2]!,
        scaleDegrees[4]!,
      ]);
      // if (scaleDegrees.contains(Interval.M3) &&
      //     scaleDegrees.contains(Interval.m3)) {
      //   intervals.addAll([
      //     scaleDegrees[0]!,
      //     scaleDegrees[3]!,
      //     scaleDegrees[5]!,
      //   ]);
      // } else {
      //   intervals.addAll([
      //     scaleDegrees[0]!,
      //     scaleDegrees[2]!,
      //     scaleDegrees[4]!,
      //   ]);
      // }
    }

    if (scaleDegrees.length == 7) {
      if (hasSecond &&
          hasThird &&
          hasFourth &&
          hasFifth &&
          hasSixth &&
          hasSeventh) {
        if (scaleDegrees.contains(Interval.M3) &&
            scaleDegrees.contains(Interval.m3)) {
          intervals
              .addAll([scaleDegrees[0]!, scaleDegrees[3]!, scaleDegrees[5]!]);
        } else {
          intervals
              .addAll([scaleDegrees[0]!, scaleDegrees[2]!, scaleDegrees[4]!]);
        }
      } else {
        material.debugPrint("Something wrong with the scale degrees");
      }
    }
    if (scaleDegrees.length == 6) {
      // if (hasSecond && hasThird && hasFourth && hasFifth && hasSixth) {
      if (scaleDegrees.contains(Interval.M3) &&
          scaleDegrees.contains(Interval.m3)) {
        intervals
            .addAll([scaleDegrees[0]!, scaleDegrees[2]!, scaleDegrees[4]!]);
      }
      if (scaleDegrees.contains(Interval.P5) &&
          scaleDegrees.contains(Interval.d5)) {
        intervals
            .addAll([scaleDegrees[0]!, scaleDegrees[1]!, scaleDegrees[3]!]);
      } else {
        intervals
            .addAll([scaleDegrees[0]!, scaleDegrees[2]!, scaleDegrees[4]!]);
      }
      // }
    }
    if (scaleDegrees.length == 5) {
      if (scaleDegrees.contains(Interval.M3) &&
          scaleDegrees.contains(Interval.m3)) {
        intervals
            .addAll([scaleDegrees[0]!, scaleDegrees[3]!, scaleDegrees[5]!]);
      } else {
        intervals
            .addAll([scaleDegrees[0]!, scaleDegrees[2]!, scaleDegrees[4]!]);
      }
    }

    String chordType = "unknown";

    try {
      chordType = ChordPattern.fromIntervals(intervals).abbrs.first;
    } catch (e) {
      chordType = ChordUtils.handleCustomPatterns(intervals);
    }

    return chordType;
  }

  static List<List<Interval>> getOtherScaleModesIntervalsLists(
      ScaleModel scaleModel) {
    List<List<Interval>> orderedScaleDegrees = [];

    final scaleModes = Scales.data[scaleModel.scale];

    var scaleDegrees =
        (scaleModes[scaleModel.mode]!['scaleDegrees'] as List<Interval?>)
            .where((n) => n != null)
            .map((e) => e!)
            .toList();

    if (scaleModel.scale == 'Pentatonics' && scaleDegrees.length == 6) {
      if (scaleModel.mode == 'Major Blues') {
        scaleDegrees = [
          Interval.P1,
          Interval.M2,
          Interval.M3,
          Interval.P5,
          Interval.M6
        ];
      }
      if (scaleModel.mode == 'Blues') {
        scaleDegrees = [
          Interval.P1,
          Interval.m3,
          Interval.P4,
          Interval.P5,
          Interval.m7
        ];
      }
      // scaleDegrees = removePassingTones(scaleDegrees);
    }

    if (scaleModel.scale == 'Octatonics' && scaleDegrees.length == 8) {
      for (int i = 0; i < 2; i++) {
        List<Interval> modeIntervals = [];
        for (int j = 0; j < scaleDegrees.length; j++) {
          var interval =
              scaleDegrees[(j + i) % scaleDegrees.length] - scaleDegrees[(i)];
          //Hardcoded fix for strange intervals
          if (interval == Interval.d4) {
            interval = Interval.M3;
          }
          //Hardcoded fix for strange intervals
          if (interval == Interval.d5 && modeIntervals[3] == Interval.M3) {
            interval = Interval.A4;
          }
          modeIntervals.add(interval);
        }
        orderedScaleDegrees.add(modeIntervals);
      }
      //Repeat pattern 4 times
      orderedScaleDegrees
          .addAll([orderedScaleDegrees[0], orderedScaleDegrees[1]]);
      orderedScaleDegrees
          .addAll([orderedScaleDegrees[0], orderedScaleDegrees[1]]);
      orderedScaleDegrees
          .addAll([orderedScaleDegrees[0], orderedScaleDegrees[1]]);
    } else {
      orderedScaleDegrees.add(scaleDegrees);

      for (int i = 1; i < scaleDegrees.length; i++) {
        List<Interval> modeIntervals = [];
        for (int j = 0; j < scaleDegrees.length; j++) {
          modeIntervals.add(
              scaleDegrees[(j + i) % scaleDegrees.length] - scaleDegrees[(i)]);
        }
        orderedScaleDegrees.add(modeIntervals);
      }
    }

    List fixedOrderedScaleDegrees = [];
    for (var orderedScale in orderedScaleDegrees) {
      fixedOrderedScaleDegrees.add(fixIntervals(orderedScale));
    }

    // for (int i = 0; i < fixedOrderedScaleDegrees.length; i++) {
    //   debugPrint(
    //       "${orderedScaleDegrees[i]} fixed orderedScaleDegrees $i: ${fixedOrderedScaleDegrees[i]}");
    // }
    scaleModel.notesIntervalsRelativeToTonicForBuildingChordsList =
        scaleDegrees;

    return orderedScaleDegrees; //! or return fixedOrderedScaleDegrees????
  }

  List<Interval> removeMiddleNotes(List<Interval> scaleDegrees) {
    List<Interval> cleanedScale = [];

    // Iterate through the scale degrees
    for (int i = 0; i < scaleDegrees.length; i += 2) {
      cleanedScale.add(scaleDegrees[i]);
    }

    return cleanedScale;
  }

  static List<Interval> fixIntervals(List<Interval> intervals) {
    List<Interval> fixedIntervals = [];
    Map<Interval, int> intervalCount = {};

    for (var interval in intervals) {
      intervalCount.update(interval, (count) => count + 1, ifAbsent: () => 1);
    }

    for (var interval in intervals) {
      Interval newInterval = interval;

      if (interval == Interval.d2) {
        newInterval = Interval.M2;
      } else if (interval == Interval.d3) {
        newInterval = Interval.m3;
      } else if (interval == Interval.d4) {
        newInterval = Interval.P4;
      } else if (interval == Interval.d6) {
        newInterval = Interval.m6;
      } else if (interval == Interval.A2) {
        if (intervalCount.containsKey(Interval.M2) ||
            intervalCount.containsKey(Interval.m3)) {
          newInterval = Interval.M2;
        }
      } else if (interval == Interval.A3) {
        if (intervalCount.containsKey(Interval.m3) ||
            intervalCount.containsKey(Interval.P4)) {
          newInterval = Interval.m3;
        }
      } else if (interval == Interval.A4) {
        if (intervalCount.containsKey(Interval.P4) ||
            intervalCount.containsKey(Interval.A5)) {
          newInterval = Interval.P4;
        }
      } else if (interval == Interval.A6) {
        if (intervalCount.containsKey(Interval.m6) ||
            intervalCount.containsKey(Interval.M6)) {
          newInterval = Interval.m6;
        }
      }

      fixedIntervals.add(newInterval);
      intervalCount.update(newInterval, (count) => count + 1,
          ifAbsent: () => 1);
    }

    return fixedIntervals;
  }

  static List<List<Interval>> getSevenNoteScalesModesIntervalsLists(
      ScaleModel scaleModel) {
    List<List<Interval>> orderedScaleDegrees = [];

    bool foundSelectedMode = false;
    final scaleModes = Scales.data[scaleModel.scale];

    // Iterate from the selected mode to the end
    for (var mode in scaleModes.keys) {
      // debugPrint(mode);
      if (foundSelectedMode) {
        final scaleDegrees =
            (scaleModes[mode]!['scaleDegrees'] as List<Interval?>)
                .where((n) => n != null)
                .map((e) => e!)
                .toList();
        orderedScaleDegrees.add(scaleDegrees);
      } else if (mode == scaleModel.mode) {
        foundSelectedMode = true;
        final scaleDegrees =
            (scaleModes[mode]!['scaleDegrees'] as List<Interval?>)
                .where((n) => n != null)
                .map((e) => e!)
                .toList();
        orderedScaleDegrees
            .add(scaleDegrees); // Add the selected mode's scale degrees
      }
    }

    // Iterate from the beginning to the selected mode (excluding selected mode)
    for (var mode in scaleModes.keys) {
      if (mode == scaleModel.mode) break;
      // debugPrint(mode);

      final scaleDegrees =
          (scaleModes[mode]!['scaleDegrees'] as List<Interval?>)
              .where((n) => n != null)
              .map((e) => e!)
              .toList();
      orderedScaleDegrees.add(scaleDegrees);
    }
    scaleModel.notesIntervalsRelativeToTonicForBuildingChordsList =
        (scaleModes[scaleModel.mode]!['scaleDegrees'] as List<Interval?>)
            .where((n) => n != null)
            .map((e) => e!)
            .toList();

    return orderedScaleDegrees;
  }

  static List<String> createNoteList(String baseNote, List<int> intervals) {
    List<String> notes = [];

    String noteToFlats = flatsOnlyNoteNomenclature(baseNote);

    // Parse the base note
    var basePitch = Pitch.parse("${noteToFlats}3");

    // Calculate notes for each interval
    for (int interval in intervals) {
      // Calculate the MIDI number by adding the interval to the base note's MIDI number
      int midiNumber = basePitch.midiNumber + interval;

      // Create a new pitch object from the MIDI number and octave
      var pitch = Pitch.fromMidiNumber(midiNumber);

      // Add the pitch representation to the list of notes
      notes.add(pitch.toString());
    }

    return notes;
  }

  static List<String> cleanNotesNames(List<String> listOfNotes) {
    //conversion from Pitch to String with octave manipulation 'F#5' ->'Gb'+'5'
    List<String> octaveValueList = listOfNotes
        .map((n) => n
            .toString()
            .substring(n.toString().length - 1, n.toString().length))
        .toList();
    var testFlatsList = listOfNotes
        .map((note) => flatsOnlyNoteNomenclature(
            note.toString().substring(0, note.toString().length - 1)))
        .toList();
    int i = 0;
    List<String> newListOfNotes = testFlatsList
        .map((n) => (n + octaveValueList[i++]).toString())
        .toList();
    return newListOfNotes;
  }

  static List<String> cleanNotesIndexes(List<dynamic> listOfNotes) {
    List<String> testFlatsList = listOfNotes
        .map((note) {
          String noteAsString = note.toString();
          String processedNote =
              // flatsOnlyNoteNomenclature(//TODO: Fix this string
              noteAsString.substring(0, noteAsString.length - 1);
          // );
          return processedNote;
        })
        .cast<String>()
        .toList(); // This cast is safe only if we're sure about the transformation result
    return testFlatsList;
  }

  static String extractNoteName(String chordType) {
    // Define a regular expression pattern to match note names and symbols
    RegExp regex = RegExp(r'([A-Ga-g][♭♯]?)');

    // Extract all note names and symbols from the chord type
    Iterable<Match> matches = regex.allMatches(chordType);

    // Return the first match found (which represents the note name)
    return matches.isNotEmpty ? matches.first.group(0)! : chordType;
  }

  static int getHighestNoteIndex(List<String> notes) {
    int highestIndex = 0;
    for (String note in notes) {
      int noteIndex = MusicConstants.notesWithFlats.indexOf(note);
      if (noteIndex > highestIndex) {
        highestIndex = noteIndex;
      }
    }
    return highestIndex;
  }

  static int getNoteIndex(String note) {
    return MusicConstants.notesWithFlats.indexOf(note);
  }

  static String _mapIntervalToChordTone(Interval interval) {
    if (interval == Interval.P1 || interval == Interval.A1) {
      return '1';
    } else if (interval == Interval.m2 ||
        interval == Interval.M2 ||
        interval == Interval.A2) {
      return '9';
    } else if (interval == Interval.d3 ||
        interval == Interval.m3 ||
        interval == Interval.M3 ||
        interval == Interval.A3) {
      return '3';
    } else if (interval == Interval.d4 ||
        interval == Interval.P4 ||
        interval == Interval.A4) {
      return '11';
    } else if (interval == Interval.d5 ||
        interval == Interval.P5 ||
        interval == Interval.A5) {
      return '5';
    } else if (interval == Interval.m6 ||
        interval == Interval.M6 ||
        interval == Interval.A6) {
      return '13';
    } else if (interval == Interval.d7 ||
        interval == Interval.m7 ||
        interval == Interval.M7) {
      return '7';
    } else {
      throw ArgumentError('Invalid interval: $interval');
    }
  }

  static int selectRandomItem(List itemList) {
    final Random random = Random();

    int index = random.nextInt(itemList.length);
    return index;
  }

  static flatsAndSharpsToFlats(String noteSubString) {
    // debugPrint('Called flatsOnlyNoteNomenclature');
    switch (noteSubString) {
      case 'C':
        noteSubString = 'C';
        break;
      case 'C♯/D♭':
        noteSubString = 'D♭';
        break;
      case 'C♯':
        noteSubString = 'D♭';
        break;
      case 'D':
        noteSubString = 'D';
        break;
      case 'D♯/E♭':
        noteSubString = 'E♭';
        break;
      case 'D♯':
        noteSubString = 'E♭';
        break;
      case 'E':
        noteSubString = 'E';
        break;
      case 'F':
        noteSubString = 'F';
        break;
      case 'F♯/G♭':
        noteSubString = 'G♭';
        break;
      case 'F♯':
        noteSubString = 'G♭';
        break;
      case 'G':
        noteSubString = 'G';
        break;
      case 'G♯/A♭':
        noteSubString = 'A♭';
        break;
      case 'G♯':
        noteSubString = 'A♭';
        break;
      case 'A':
        noteSubString = 'A';
        break;
      case 'A♯/B♭':
        noteSubString = 'B♭';
        break;
      case 'A♯':
        noteSubString = 'B♭';
        break;
      case 'B':
        noteSubString = 'B';
        break;
    }

    return noteSubString;
  }

  static int calculateIndexForBassNote(
      String previousChordNote, String currentNote, int currentIndex) {
    // Get the index of the notes
    int index1 = MusicConstants.notesWithFlats.indexOf(previousChordNote);
    int index2 = MusicConstants.notesWithFlats.indexOf(currentNote);

    // Calculate the distance between the notes
    int distance = index2 - index1;

    // Check for octave change
    bool octaveChange = (distance.abs() < 4);
    if (octaveChange) {
      if (currentIndex == 2) {
        currentIndex = currentIndex + 1;
      }
      if (currentIndex == 3) {
        currentIndex = currentIndex - 1;
      }
    }

    return currentIndex;
  }

  // static int calculateIndexForBassNote(
  //     String previousChordNote, String currentNote, int currentIndex) {
  //   int index = currentIndex;

  //   int index1 = MusicConstants.notesWithFlats.indexOf(previousChordNote);
  //   int index2 = MusicConstants.notesWithFlats.indexOf(currentNote);

  //   int distance1 = index2 - index1;
  //   int distance2 = index1 - index2;

  //   if (distance1 > 4 || distance2 > 4) {
  //     if (index == 2) {
  //       index = index + 1;
  //     }
  //   }
  //   if (distance2 <= 4 || distance2 <= 4) {
  //     if (index == 3) {
  //       index = index - 1;
  //     }
  //   }
  //   return index;
  // }
}
