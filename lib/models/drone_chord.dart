import 'package:flutter/material.dart';
import '../constants/music_constants.dart';
import '../utils/music_utils.dart';
import 'chord_model.dart';

class DroneChord {
  final String displayName;
  final List<int> midiNotes; // Chord tones (e.g. [60, 64, 67])
  final int bassMidiNote; // Bass note in low octave
  final Color? color;

  const DroneChord({
    required this.displayName,
    required this.midiNotes,
    required this.bassMidiNote,
    this.color,
  });

  /// All notes to play (bass + chord tones)
  List<int> get allMidiNotes => [bassMidiNote, ...midiNotes];

  /// Build from an existing ChordModel (diatonic chord button tap).
  /// Uses spread voicing: the lowest chord tone is dropped an octave
  /// for a wider, more resonant drone sound.
  factory DroneChord.fromChordModel(ChordModel chord) {
    // Extract MIDI notes from chord's inversion notes
    final List<int> chordMidi = [];
    if (chord.chordNotesInversionWithIndexes != null) {
      for (final note in chord.chordNotesInversionWithIndexes!) {
        final midi = MusicConstants.midiValues[note];
        if (midi != null) {
          chordMidi.add(midi);
        }
      }
    }

    // Compute bass note: root in octave 2
    var rootName = MusicUtils.extractNoteName(chord.completeChordName ?? chord.noteName);
    rootName = MusicUtils.filterNoteNameWithSlash(rootName);
    rootName = MusicUtils.flatsAndSharpsToFlats(rootName);
    final bassMidi = MusicConstants.midiValues['${rootName}2'] ?? 36;

    // Apply spread voicing: drop the lowest chord tone by one octave
    // to create wider spacing between bass and upper voices
    final spreadMidi = _applySpreadVoicing(chordMidi);

    return DroneChord(
      displayName: chord.completeChordName ?? chord.noteName,
      midiNotes: spreadMidi,
      bassMidiNote: bassMidi,
      color: chord.color,
    );
  }

  /// Build from root note name + chord quality + octave.
  /// Uses spread voicing: root at octave 3, upper voices at octave 4,
  /// creating a wider, more resonant drone sound.
  factory DroneChord.fromRootAndQuality(
    String root,
    String quality, {
    int octave = 4,
    Color? color,
  }) {
    final intervals = _qualityIntervals[quality] ?? [0, 4, 7];

    // Get root MIDI value at the given octave
    final rootFlat = MusicUtils.flatsAndSharpsToFlats(root);
    final rootMidi = MusicConstants.midiValues['$rootFlat$octave'];
    if (rootMidi == null) {
      // Fallback: spread C chord
      return DroneChord(
        displayName: '$root$quality',
        midiNotes: [48, 64, 67], // C3, E4, G4
        bassMidiNote: 36,
        color: color,
      );
    }

    // Spread voicing: root dropped to octave 3, upper voices at octave 4
    final chordMidi = <int>[];
    for (int i = 0; i < intervals.length; i++) {
      if (i == 0) {
        // Root: one octave below the default
        chordMidi.add(rootMidi - 12 + intervals[i]);
      } else {
        // Upper voices: at the default octave
        chordMidi.add(rootMidi + intervals[i]);
      }
    }

    final bassMidi = MusicConstants.midiValues['${rootFlat}2'] ?? (rootMidi - 24);

    // Build display name
    final qualityDisplay = _qualityDisplayNames[quality] ?? quality;

    return DroneChord(
      displayName: '$root$qualityDisplay',
      midiNotes: chordMidi,
      bassMidiNote: bassMidi,
      color: color,
    );
  }

  /// Interval formulas for chord qualities (semitones from root)
  static const Map<String, List<int>> _qualityIntervals = {
    'Major': [0, 4, 7],
    'Minor': [0, 3, 7],
    'Dom7': [0, 4, 7, 10],
    'Maj7': [0, 4, 7, 11],
    'Min7': [0, 3, 7, 10],
    'Dim': [0, 3, 6],
    'Aug': [0, 4, 8],
    'Sus2': [0, 2, 7],
    'Sus4': [0, 5, 7],
    'Dim7': [0, 3, 6, 9],
    'Min6': [0, 3, 7, 9],
    'Maj6': [0, 4, 7, 9],
  };

  static const Map<String, String> _qualityDisplayNames = {
    'Major': '',
    'Minor': 'm',
    'Dom7': '7',
    'Maj7': 'maj7',
    'Min7': 'm7',
    'Dim': 'dim',
    'Aug': 'aug',
    'Sus2': 'sus2',
    'Sus4': 'sus4',
    'Dim7': 'dim7',
    'Min6': 'm6',
    'Maj6': '6',
  };

  /// Spread voicing: drop the lowest chord tone by one octave to widen
  /// the spacing between bass and upper voices. Only drops if the lowest
  /// note is at octave 4 or above (MIDI >= 60) to avoid going too low.
  static List<int> _applySpreadVoicing(List<int> midiNotes) {
    if (midiNotes.length < 2) return List.of(midiNotes);

    final sorted = List<int>.of(midiNotes)..sort();
    final lowest = sorted.first;

    // Only drop if the lowest note is at octave 4+ (MIDI 60+)
    if (lowest >= 60) {
      sorted[0] = lowest - 12;
    }

    return sorted;
  }

  static List<String> get availableQualities => _qualityIntervals.keys.toList();

  @override
  String toString() => 'DroneChord($displayName, midi: $midiNotes, bass: $bassMidiNote)';
}
