import 'package:flutter/material.dart';

import '../models/chord_model.dart';
import '../models/chord_scale_model.dart';
import '../utils/music_utils.dart';

/// Generates a default chord progression when a scale/mode is selected.
///
/// For 7-note scales: uses 2nd and 3rd degree triads (each 4 beats).
/// For other scales: uses a curated lookup table of chord indices.
class DefaultProgressionGenerator {
  /// Main entry point. Returns 1-2 ChordModels for the default progression.
  static List<ChordModel> generate(ChordScaleFingeringsModel scaleFingerings) {
    final scaleModel = scaleFingerings.scaleModel;
    if (scaleModel == null) return [];

    final scale = scaleModel.scale;
    final mode = scaleModel.mode;
    if (scale == null || mode == null) return [];

    if (_isSevenNoteScale(scale)) {
      return _generateSevenNoteProgression(scaleFingerings);
    } else if (scale == 'Octatonics') {
      return _generateOctatonicProgression(scaleFingerings);
    } else if (scale == 'Hexatonics') {
      return _generateHexatonicProgression(scaleFingerings, mode);
    } else if (scale == 'Pentatonics') {
      return _generatePentatonicProgression(scaleFingerings, mode);
    }

    return [];
  }

  static bool _isSevenNoteScale(String scale) {
    return const [
      'Diatonic Major',
      'Melodic Minor',
      'Harmonic Minor',
      'Harmonic Major',
    ].contains(scale);
  }

  // ---------------------------------------------------------------------------
  // 7-note scales: 2nd degree (index 1) + 3rd degree (index 2)
  // ---------------------------------------------------------------------------
  static List<ChordModel> _generateSevenNoteProgression(
      ChordScaleFingeringsModel scaleFingerings) {
    final chords = <ChordModel>[];

    final chord1 =
        _buildChordAtIndex(scaleFingerings, 1, position: 0, duration: 4);
    if (chord1 != null) chords.add(chord1);

    final chord2 =
        _buildChordAtIndex(scaleFingerings, 2, position: 4, duration: 4);
    if (chord2 != null) chords.add(chord2);

    return chords;
  }

  // ---------------------------------------------------------------------------
  // Pentatonics: curated index pairs per mode
  // ---------------------------------------------------------------------------
  static const Map<String, List<int>> _pentatonicIndices = {
    'Major Pentatonic': [0, 4], // I + vi
    'Minor Pentatonic': [0, 2], // i + iv
    'Blues': [0, 3], // i + v
    'Major Blues': [1, 2], // ii + iii (7-note-like)
    'Egyptian': [0, 3], // suspended, open
    'Hirajoshi': [0, 2], // dark Japanese
    'In-Sen': [0, 3], // dark quartal
    'Iwato': [0, 3], // same intervals as In-Sen
    'Kumoi': [0, 2], // gentle Japanese
    'Pelog': [0, 3], // Balinese gamelan
    'Prometheus': [0, 3], // Scriabin-like
    'Prometheus Neapolitan': [0, 3], // dark Prometheus
    'Prometheus Spanish': [0, 2], // Spanish variant
    'Ritusen': [0, 2], // same as Hirajoshi
    'Ryukyu': [0, 3], // Okinawan
    'Yo': [0, 2], // Japanese folk
    'Yo-Kumoi': [0, 2], // major-dominant blend
    'Zhi': [0, 2], // Chinese pentatonic
    'Zhi-Yu': [0, 2], // similar to Yo-Kumoi
    'Zhi-Yu-Kumoi': [0, 3], // same as Major Pentatonic
  };

  static List<ChordModel> _generatePentatonicProgression(
      ChordScaleFingeringsModel scaleFingerings, String mode) {
    final indices = _pentatonicIndices[mode] ?? [0];
    return _buildChordsFromIndices(scaleFingerings, indices);
  }

  // ---------------------------------------------------------------------------
  // Hexatonics: curated index pairs per mode
  // ---------------------------------------------------------------------------
  static const Map<String, List<int>> _hexatonicIndices = {
    'Whole Tone': [0], // symmetrical — one augmented chord suffices
    'Major Hexatonic': [1, 2], // near-diatonic ii-iii
    'Minor Hexatonic': [1, 2], // near-diatonic minor
    'Ritsu Onkai': [0], // Japanese ceremonial, ambiguous
    'Raga Kumud': [1, 2], // near-major ii-iii
    'Mixolydian Hexatonic': [0, 3], // dominant feel
    'Phrygian Hexatonic': [0, 3], // Phrygian darkness
  };

  static List<ChordModel> _generateHexatonicProgression(
      ChordScaleFingeringsModel scaleFingerings, String mode) {
    final indices = _hexatonicIndices[mode] ?? [0];
    return _buildChordsFromIndices(scaleFingerings, indices);
  }

  // ---------------------------------------------------------------------------
  // Octatonics: two distinct triad types from the diminished symmetry
  // ---------------------------------------------------------------------------
  static List<ChordModel> _generateOctatonicProgression(
      ChordScaleFingeringsModel scaleFingerings) {
    return _buildChordsFromIndices(scaleFingerings, [0, 1]);
  }

  // ---------------------------------------------------------------------------
  // Shared helpers
  // ---------------------------------------------------------------------------

  /// Builds a list of ChordModels from the given indices, each 4 beats,
  /// with sequential positions.
  static List<ChordModel> _buildChordsFromIndices(
      ChordScaleFingeringsModel scaleFingerings, List<int> indices) {
    final chords = <ChordModel>[];
    int position = 0;

    for (final index in indices) {
      final chord = _buildChordAtIndex(scaleFingerings, index,
          position: position, duration: 4);
      if (chord != null) {
        chords.add(chord);
        position += 4;
      }
    }

    return chords;
  }

  /// Builds a single ChordModel at the given scale degree index.
  /// Returns null if the index is out of bounds.
  /// Mirrors the logic in Chords.addChordModel() (chords.dart:157).
  static ChordModel? _buildChordAtIndex(
    ChordScaleFingeringsModel scaleFingerings,
    int index, {
    required int position,
    required int duration,
  }) {
    final scaleModel = scaleFingerings.scaleModel!;

    // Bounds check
    if (index >= scaleModel.completeChordNames.length ||
        index >= scaleModel.chordTypes.length ||
        index >= scaleModel.degreeFunction.length ||
        index >= scaleModel.modesScalarTonicIntervals.length) {
      debugPrint(
          '[DefaultProgressionGenerator] Index $index out of bounds for '
          '${scaleModel.scale} ${scaleModel.mode} '
          '(${scaleModel.completeChordNames.length} chords available)');
      return null;
    }

    final chordNotes = MusicUtils.getChordInfo(scaleFingerings, index);

    return ChordModel(
      id: position,
      noteName: scaleModel.completeChordNames[index],
      duration: duration,
      mode: scaleModel.mode!,
      position: position,
      chordNotesWithIndexesRaw: chordNotes,
      chordFunction: scaleModel.chordTypes[index],
      chordDegree: scaleModel.degreeFunction[index],
      completeChordName: scaleModel.completeChordNames[index],
      scale: scaleModel.scale!,
      originalScaleType: scaleModel.scale!,
      parentScaleKey: scaleModel.parentScaleKey,
      selectedChordPitches: MusicUtils.cleanNotesIndexes(chordNotes)
          .map((n) => MusicUtils.flatsAndSharpsToFlats(n) as String)
          .toList(),
      chordNotesInversionWithIndexes: [],
    );
  }
}
