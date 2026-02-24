import '../models/instrument_tuning.dart';

/// Dynamically generates fretboard note arrays for any tuning.
/// Replaces the hardcoded lookup tables in fretboard_notes.dart.
class FretboardNoteGenerator {
  // Using Unicode sharp/flat characters to match existing codebase conventions
  static const List<String> _chromaticSharps = [
    'C', 'C♯', 'D', 'D♯', 'E', 'F', 'F♯', 'G', 'G♯', 'A', 'A♯', 'B',
  ];

  static const List<String> _chromaticFlats = [
    'C', 'D♭', 'D', 'E♭', 'E', 'F', 'G♭', 'G', 'A♭', 'A', 'B♭', 'B',
  ];

  /// Mapping from various note name formats to chromatic index (0-11).
  /// Handles Unicode sharps/flats, ASCII sharps/flats, and natural notes.
  static final Map<String, int> _noteToIndex = {
    // Naturals
    'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11,
    // Unicode sharps
    'C♯': 1, 'D♯': 3, 'F♯': 6, 'G♯': 8, 'A♯': 10,
    // Unicode flats
    'D♭': 1, 'E♭': 3, 'G♭': 6, 'A♭': 8, 'B♭': 10,
    // ASCII sharps
    'C#': 1, 'D#': 3, 'E#': 5, 'F#': 6, 'G#': 8, 'A#': 10, 'B#': 0,
    // ASCII flats
    'Db': 1, 'Eb': 3, 'Fb': 4, 'Gb': 6, 'Ab': 8, 'Bb': 10, 'Cb': 11,
  };

  /// Generate note names for all strings and frets using sharps.
  /// Returns List<List<String>> where [stringIndex][fretIndex] = note name.
  /// stringIndex 0 = highest pitched string (thinnest).
  static List<List<String>> generateSharps(InstrumentTuning tuning) {
    return _generate(tuning, _chromaticSharps);
  }

  /// Generate note names for all strings and frets using flats.
  static List<List<String>> generateFlats(InstrumentTuning tuning) {
    return _generate(tuning, _chromaticFlats);
  }

  static List<List<String>> _generate(
    InstrumentTuning tuning,
    List<String> chromatic,
  ) {
    return tuning.openNotes.map((openNote) {
      final startIndex = _getNoteIndex(openNote);
      return List<String>.generate(tuning.fretCount + 1, (fret) {
        return chromatic[(startIndex + fret) % 12];
      });
    }).toList();
  }

  /// Get the chromatic index (0-11) for a note name.
  /// Supports all formats: 'C', 'C#', 'C♯', 'Db', 'D♭', etc.
  static int _getNoteIndex(String note) {
    final index = _noteToIndex[note];
    if (index != null) return index;
    throw ArgumentError('Unknown note name: $note');
  }

  /// Public accessor for note index lookup, used by other parts of the app.
  static int getNoteIndex(String note) => _getNoteIndex(note);
}
