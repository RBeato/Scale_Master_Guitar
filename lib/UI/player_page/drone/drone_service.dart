import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sequencer/global_state.dart';
import 'package:flutter_sequencer/models/instrument.dart';
import 'package:flutter_sequencer/sequence.dart';
import 'package:flutter_sequencer/track.dart';

import '../../../models/drone_chord.dart';

/// Manages a sustained chord drone using a single pad track.
///
/// Uses SF2 instruments with looped samples and a flat volume envelope —
/// notes sustain at full volume indefinitely while held (no noteOff sent).
/// One attack when the chord starts, infinite sustain, silence on stop.
///
/// Supports multiple drone sounds (Organ, Atmospheric Pad) configurable
/// from drawer settings.
///
/// No retriggering, no crossfading, no timers. The SF2 instrument does
/// the work natively.
class DroneService {
  static final DroneService _instance = DroneService._internal();
  factory DroneService() => _instance;
  DroneService._internal();

  static const Map<String, String> _soundToSf2 = {
    'Organ': 'assets/sounds/sf2/dance_organ.sf2',
    'Atmospheric Pad': 'assets/sounds/sf2/atmospheric_pad.sf2',
  };

  Sequence? _sequence;
  Track? _padTrack;
  bool _isInitialized = false;
  bool _isPlaying = false;
  DroneChord? _currentChord;
  final Set<int> _activeNotes = {};
  double _volume = 0.54;
  String _currentSound = 'Organ';

  bool get isInitialized => _isInitialized;
  bool get isPlaying => _isPlaying;
  DroneChord? get currentChord => _currentChord;
  String get currentSound => _currentSound;

  /// Initialize the drone audio engine with the given sound name.
  /// Creates its own Sequence + single pad Track with the appropriate SF2.
  /// If already initialized with a different sound, disposes and reinitializes.
  Future<void> initialize({String soundName = 'Organ'}) async {
    // If already initialized with the same sound, skip
    if (_isInitialized && _currentSound == soundName) return;

    // If initialized with a different sound, dispose first
    if (_isInitialized) {
      debugPrint('[DroneService] Sound changed from $_currentSound to $soundName, reinitializing...');
      await dispose();
    }

    _currentSound = soundName;
    final sf2Path = _soundToSf2[soundName] ?? _soundToSf2['Organ']!;

    debugPrint('[DroneService] Initializing with $soundName ($sf2Path)...');

    try {
      // Ensure iOS audio session is set up
      if (Platform.isIOS) {
        try {
          await const MethodChannel('flutter_sequencer')
              .invokeMethod('initializeAudioSession');
        } catch (e) {
          debugPrint('[DroneService] iOS audio session already initialized: $e');
        }
      }

      GlobalState().setKeepEngineRunning(true);

      if (Platform.isIOS) {
        GlobalState().setIosNativeSchedulingEnabled(false);
      }

      // Minimal sequence — we only use real-time note control
      _sequence = Sequence(tempo: 120.0, endBeat: 1.0);

      final instrument = Sf2Instrument(
        path: sf2Path,
        isAsset: true,
        presetIndex: 0,
      );

      final tracks = await _sequence!.createTracks([instrument]);
      if (tracks.isEmpty) {
        throw Exception('Failed to create drone track');
      }

      _padTrack = tracks[0];
      _padTrack!.changeVolumeNow(volume: _volume);

      _isInitialized = true;
      debugPrint('[DroneService] Initialized with $soundName');
    } catch (e, st) {
      debugPrint('[DroneService] Initialization failed: $e\n$st');
      _isInitialized = false;
      _sequence = null;
      _padTrack = null;
      rethrow;
    }
  }

  /// Start the drone with the given chord.
  /// Plays a single attack — notes sustain indefinitely until stop() is called.
  /// [soundName] selects which SF2 instrument to use.
  Future<void> play(DroneChord chord, {String soundName = 'Organ'}) async {
    if (!_isInitialized || _currentSound != soundName) {
      await initialize(soundName: soundName);
    }
    if (_padTrack == null) return;

    // Stop current notes if already playing
    if (_isPlaying) {
      _stopAllNotes();
    }

    _currentChord = chord;

    debugPrint('[DroneService] Playing drone: ${chord.displayName} '
        '(notes: ${chord.allMidiNotes})');

    // Single noteOn per MIDI note — organ sustains indefinitely
    for (final midiNote in chord.allMidiNotes) {
      try {
        _padTrack!.startNoteNow(noteNumber: midiNote, velocity: 0.63);
        _activeNotes.add(midiNote);
      } catch (e) {
        debugPrint('[DroneService] Error starting note $midiNote: $e');
      }
    }

    _isPlaying = true;
  }

  /// Stop the drone.
  void stop() {
    debugPrint('[DroneService] Stopping drone');
    _stopAllNotes();
    _isPlaying = false;
  }

  /// Change chord while drone is playing (smooth transition).
  /// Common tones sustain continuously; only changed notes are stopped/started.
  Future<void> changeChord(DroneChord newChord) async {
    if (!_isPlaying) {
      _currentChord = newChord;
      return;
    }

    if (_padTrack == null) return;

    debugPrint('[DroneService] Changing chord: '
        '${_currentChord?.displayName} → ${newChord.displayName}');

    final oldNotes = Set<int>.from(_activeNotes);
    final newNotes = Set<int>.from(newChord.allMidiNotes);

    final toRemove = oldNotes.difference(newNotes);
    final toAdd = newNotes.difference(oldNotes);

    // Stop notes that are leaving
    for (final note in toRemove) {
      try {
        _padTrack!.stopNoteNow(noteNumber: note);
        _activeNotes.remove(note);
      } catch (e) {
        debugPrint('[DroneService] Error stopping note $note: $e');
      }
    }

    // Start notes that are arriving
    for (final note in toAdd) {
      try {
        _padTrack!.startNoteNow(noteNumber: note, velocity: 0.63);
        _activeNotes.add(note);
      } catch (e) {
        debugPrint('[DroneService] Error starting note $note: $e');
      }
    }

    _currentChord = newChord;
  }

  /// Set volume in real-time.
  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    if (_padTrack != null) {
      _padTrack!.changeVolumeNow(volume: _volume);
    }
  }

  double get volume => _volume;

  void _stopAllNotes() {
    if (_padTrack == null) return;
    for (final note in _activeNotes.toList()) {
      try {
        _padTrack!.stopNoteNow(noteNumber: note);
      } catch (e) {
        debugPrint('[DroneService] Error stopping note $note: $e');
      }
    }
    _activeNotes.clear();
  }

  /// Full cleanup - call when leaving the player page.
  Future<void> dispose() async {
    debugPrint('[DroneService] Disposing...');
    stop();

    if (_sequence != null) {
      try {
        _sequence!.stop();
      } catch (e) {
        debugPrint('[DroneService] Error stopping sequence: $e');
      }
    }

    _padTrack = null;
    _sequence = null;
    _isInitialized = false;
    debugPrint('[DroneService] Disposed');
  }
}
