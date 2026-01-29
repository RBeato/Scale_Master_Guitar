import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scalemasterguitar/models/saved_fingering.dart';

/// Provider to hold a fingering that was loaded from the library
/// When set, the fretboard should apply this fingering and then clear it
final loadedFingeringProvider = StateProvider<SavedFingering?>((ref) => null);
