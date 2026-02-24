import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/fretboard_note_generator.dart';
import 'tuning_provider.dart';

/// Dynamic fretboard notes using sharps, recalculated when tuning changes.
final fretboardNotesSharpsProvider = Provider<List<List<String>>>((ref) {
  final tuning = ref.watch(tuningProvider);
  return FretboardNoteGenerator.generateSharps(tuning);
});

/// Dynamic fretboard notes using flats, recalculated when tuning changes.
final fretboardNotesFlatsProvider = Provider<List<List<String>>>((ref) {
  final tuning = ref.watch(tuningProvider);
  return FretboardNoteGenerator.generateFlats(tuning);
});
