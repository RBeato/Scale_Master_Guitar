import 'dart:math';

import 'package:scalemasterguitar/constants/music_constants.dart';
import 'package:scalemasterguitar/models/chord_model.dart';
import 'package:scalemasterguitar/utils/music_utils.dart';

/// A candidate note with pitch class, octave, and MIDI value.
class _NoteCandidate {
  final String pitchClass;
  final int octave;
  final int midi;

  _NoteCandidate(this.pitchClass, this.octave, this.midi);

  factory _NoteCandidate.empty() => _NoteCandidate('', 0, 0);
}

class VoiceLeadingCreator {
  // Comfortable voicing range
  static const int _midiFloor = 48; // C3
  static const int _midiCeiling = 72; // C5
  static const int _midiCenter = 60; // C4
  static const int _candidateOctaveLow = 2;
  static const int _candidateOctaveHigh = 5;

  static List<ChordModel> buildProgression(List<ChordModel> selectedChords) {
    if (selectedChords.isEmpty) {
      return selectedChords;
    }

    try {
      // Voice the first chord in a comfortable mid-range
      _voiceFirstChord(selectedChords.first);

      // Apply proximity-based voice leading for subsequent chords
      for (int i = 1; i < selectedChords.length; i++) {
        _voiceNextChord(selectedChords[i], selectedChords[i - 1]);
      }
    } catch (e) {
      print('[VoiceLeadingCreator] ERROR in buildProgression: $e');
    }

    return selectedChords;
  }

  /// Voices only a single new chord relative to the existing progression.
  /// This avoids re-voicing all existing chords (which changes their random
  /// inversion and destabilizes the entire progression each time).
  static void voiceNewChord(
      List<ChordModel> existingChords, ChordModel newChord) {
    try {
      if (existingChords.isEmpty) {
        _voiceFirstChord(newChord);
      } else {
        final lastChord = existingChords.last;
        if (lastChord.chordNotesInversionWithIndexes != null &&
            lastChord.chordNotesInversionWithIndexes!.isNotEmpty) {
          _voiceNextChord(newChord, lastChord);
        } else {
          _voiceFirstChord(newChord);
        }
      }
    } catch (e) {
      print('[VoiceLeadingCreator] ERROR in voiceNewChord: $e');
      // Fallback: assign ascending octaves from octave 3
      if (newChord.selectedChordPitches != null) {
        newChord.chordNotesInversionWithIndexes =
            _assignAscendingOctaves(List.from(newChord.selectedChordPitches!), 3);
      }
    }
  }

  /// Voices the first chord with a random inversion, clamped to C3-C5.
  static void _voiceFirstChord(ChordModel chordModel) {
    if (chordModel.selectedChordPitches == null ||
        chordModel.selectedChordPitches!.isEmpty) {
      print('[VoiceLeadingCreator] ERROR: First chord has no pitches');
      return;
    }

    try {
      List<String> pitchClasses = List.from(chordModel.selectedChordPitches!);

      // Random rotation for inversion variety
      int randomInt = MusicUtils.selectRandomItem(pitchClasses);
      for (int i = 0; i < randomInt; i++) {
        pitchClasses.add(pitchClasses.first);
        pitchClasses.removeAt(0);
      }

      // Assign ascending octaves starting from octave 3 (lower than before)
      List<String> voiced = _assignAscendingOctaves(pitchClasses, 3);

      // Clamp into comfortable range
      voiced = _clampToRange(pitchClasses, voiced);

      chordModel.chordNotesInversionWithIndexes = voiced;
    } catch (e) {
      print('[VoiceLeadingCreator] ERROR in _voiceFirstChord: $e');
      if (chordModel.selectedChordPitches != null) {
        chordModel.chordNotesInversionWithIndexes =
            _assignAscendingOctaves(List.from(chordModel.selectedChordPitches!), 3);
      }
    }
  }

  /// Voices the next chord by minimizing voice movement from the previous chord.
  static void _voiceNextChord(
      ChordModel currentChord, ChordModel previousChord) {
    if (currentChord.selectedChordPitches == null ||
        currentChord.selectedChordPitches!.isEmpty) {
      return;
    }

    // Get previous chord's MIDI values
    List<int> prevMidiValues =
        _getMidiValues(previousChord.chordNotesInversionWithIndexes ?? []);
    if (prevMidiValues.isEmpty) {
      // Fallback: treat as first chord
      _voiceFirstChord(currentChord);
      return;
    }

    double prevCenter =
        prevMidiValues.reduce((a, b) => a + b) / prevMidiValues.length;

    // Generate candidates for each pitch class at multiple octaves
    List<String> newPitchClasses =
        List.from(currentChord.selectedChordPitches!);
    List<List<_NoteCandidate>> allCandidates = [];

    for (String pc in newPitchClasses) {
      List<_NoteCandidate> candidates = [];
      for (int oct = _candidateOctaveLow; oct <= _candidateOctaveHigh; oct++) {
        int? midi = _pitchClassToMidi(pc, oct);
        if (midi != null &&
            midi >= _midiFloor - 6 &&
            midi <= _midiCeiling + 6) {
          candidates.add(_NoteCandidate(pc, oct, midi));
        }
      }
      if (candidates.isEmpty) {
        // Fallback: use octave 3
        int? midi = _pitchClassToMidi(pc, 3);
        if (midi != null) {
          candidates.add(_NoteCandidate(pc, 3, midi));
        }
      }
      allCandidates.add(candidates);
    }

    // Nearest-voice assignment
    List<_NoteCandidate> assigned =
        _assignVoices(prevMidiValues, allCandidates, prevCenter);

    // Sort by MIDI value ascending
    assigned.sort((a, b) => a.midi.compareTo(b.midi));

    // Apply drift correction
    assigned = _correctDrift(assigned);

    // Convert to note strings
    currentChord.chordNotesInversionWithIndexes =
        assigned.map((c) => '${c.pitchClass}${c.octave}').toList();
  }

  /// Assigns each new chord's pitch class to an octave that minimizes
  /// total movement from the previous chord's voices.
  static List<_NoteCandidate> _assignVoices(
    List<int> prevMidi,
    List<List<_NoteCandidate>> allCandidates,
    double prevCenter,
  ) {
    int prevSize = prevMidi.length;
    int newSize = allCandidates.length;

    List<int> sortedPrevMidi = List.from(prevMidi)..sort();
    List<_NoteCandidate> result =
        List.filled(newSize, _NoteCandidate.empty());
    List<bool> assigned = List.filled(newSize, false);

    if (newSize <= prevSize) {
      // Same size or fewer notes: use middle N previous voices for matching
      int offset = (prevSize - newSize) ~/ 2;
      List<int> matchPrevMidi =
          sortedPrevMidi.sublist(offset, offset + newSize);
      _greedyMatch(matchPrevMidi, allCandidates, result, assigned);
    } else {
      // More new notes than previous: match previous voices first
      _greedyMatch(sortedPrevMidi, allCandidates, result, assigned);

      // Place remaining unassigned near the previous center
      for (int i = 0; i < newSize; i++) {
        if (!assigned[i]) {
          result[i] =
              _nearestToTarget(allCandidates[i], prevCenter.round());
          assigned[i] = true;
        }
      }
    }

    return result;
  }

  /// For each target MIDI value, find the closest unassigned candidate
  /// across all candidate lists and assign it.
  static void _greedyMatch(
    List<int> targetMidi,
    List<List<_NoteCandidate>> allCandidates,
    List<_NoteCandidate> result,
    List<bool> assigned,
  ) {
    for (int targetMidiValue in targetMidi) {
      int bestCandIdx = -1;
      _NoteCandidate? bestCandidate;
      int bestDistance = 999;

      for (int i = 0; i < allCandidates.length; i++) {
        if (assigned[i]) continue;

        for (_NoteCandidate cand in allCandidates[i]) {
          int dist = (cand.midi - targetMidiValue).abs();
          if (dist < bestDistance) {
            bestDistance = dist;
            bestCandIdx = i;
            bestCandidate = cand;
          }
        }
      }

      if (bestCandIdx >= 0 && bestCandidate != null) {
        result[bestCandIdx] = bestCandidate;
        assigned[bestCandIdx] = true;
      }
    }
  }

  /// Prevents voicings from gradually drifting away from the center range.
  static List<_NoteCandidate> _correctDrift(List<_NoteCandidate> assigned) {
    if (assigned.isEmpty) return assigned;

    double avg =
        assigned.map((c) => c.midi).reduce((a, b) => a + b) / assigned.length;

    // If average is more than 8 semitones above center, try shifting down
    if (avg > _midiCenter + 8) {
      List<_NoteCandidate> shifted = assigned
          .map((c) => _NoteCandidate(c.pitchClass, c.octave - 1, c.midi - 12))
          .toList();
      if (shifted.every((c) => c.midi >= _midiFloor)) {
        return shifted;
      }
    }

    // If average is more than 8 semitones below center, try shifting up
    if (avg < _midiCenter - 8) {
      List<_NoteCandidate> shifted = assigned
          .map((c) => _NoteCandidate(c.pitchClass, c.octave + 1, c.midi + 12))
          .toList();
      if (shifted.every((c) => c.midi <= _midiCeiling)) {
        return shifted;
      }
    }

    return assigned;
  }

  // --- Utility helpers ---

  /// Converts a pitch class and octave to a MIDI value.
  static int? _pitchClassToMidi(String pitchClass, int octave) {
    return MusicConstants.midiValues['$pitchClass$octave'];
  }

  /// Extracts MIDI values from note strings like ['C4', 'E4', 'G4'].
  static List<int> _getMidiValues(List<String> noteStrings) {
    List<int> result = [];
    for (String ns in noteStrings) {
      int? midi = MusicConstants.midiValues[ns];
      if (midi != null) {
        result.add(midi);
      }
    }
    return result;
  }

  /// Assigns ascending octaves to pitch classes, starting from [startOctave].
  /// Increments the octave when the pitch class index wraps around.
  static List<String> _assignAscendingOctaves(
      List<String> pitchClasses, int startOctave) {
    int octave = startOctave;
    int prevNoteIndex = -1;
    List<String> result = [];

    for (int i = 0; i < pitchClasses.length; i++) {
      int noteIndex = MusicUtils.getNoteIndex(pitchClasses[i]);
      if (i > 0 && noteIndex <= prevNoteIndex) {
        octave++;
      }
      result.add('${pitchClasses[i]}$octave');
      prevNoteIndex = noteIndex;
    }

    return result;
  }

  /// Shifts an entire voicing up or down by octave to fit within C3-C5.
  static List<String> _clampToRange(
      List<String> pitchClasses, List<String> voiced) {
    List<int> midiValues = _getMidiValues(voiced);
    if (midiValues.isEmpty) return voiced;

    int highest = midiValues.reduce(max);
    int lowest = midiValues.reduce(min);

    int startOctave = _getOctaveFromNoteString(voiced.first);

    // Shift down if too high
    if (highest > _midiCeiling) {
      return _assignAscendingOctaves(pitchClasses, startOctave - 1);
    }

    // Shift up if too low
    if (lowest < _midiFloor) {
      return _assignAscendingOctaves(pitchClasses, startOctave + 1);
    }

    return voiced;
  }

  /// Finds the candidate whose MIDI value is closest to [target].
  static _NoteCandidate _nearestToTarget(
      List<_NoteCandidate> candidates, int target) {
    _NoteCandidate best = candidates.first;
    int bestDist = (best.midi - target).abs();

    for (var c in candidates) {
      int dist = (c.midi - target).abs();
      if (dist < bestDist) {
        bestDist = dist;
        best = c;
      }
    }

    return best;
  }

  /// Extracts the octave number from a note string like 'C4' or 'E♭3'.
  static int _getOctaveFromNoteString(String noteString) {
    return int.parse(noteString[noteString.length - 1]);
  }

  /// @deprecated Use [_assignAscendingOctaves] instead. Kept for backward compatibility.
  static List<String> addOctaveIndexes(List<String> reorderedNotes) {
    return _assignAscendingOctaves(reorderedNotes, 4);
  }
}
