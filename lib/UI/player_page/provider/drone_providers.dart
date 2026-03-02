import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/drone_chord.dart';

/// Player page mode: chord progression or drone
enum PlayerMode { chords, drone }

/// Current mode - defaults to chord progression (existing behavior)
final playerModeProvider = StateProvider<PlayerMode>((ref) => PlayerMode.chords);

/// The chord currently set for the drone (null until first set)
final droneChordProvider = StateProvider<DroneChord?>((ref) => null);

/// Whether the drone is currently playing
final isDronePlayingProvider = StateProvider<bool>((ref) => false);
