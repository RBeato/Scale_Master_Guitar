import 'dart:async';
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
/// Includes an optional timer-based metronome click track (hi-hat).
class DroneService {
  static final DroneService _instance = DroneService._internal();
  factory DroneService() => _instance;
  DroneService._internal();

  static const Map<String, String> _soundToSf2 = {
    'Organ': 'assets/sounds/sf2/dance_organ.sf2',
    'Atmospheric Pad': 'assets/sounds/sf2/atmospheric_pad.sf2',
  };

  static const String _drumSf2 = 'assets/sounds/sf2/DrumsSlavo.sf2';
  static const int _hiHatNote = 44; // Pedal Hi-Hat (GM)
  static const double _clickVelocity = 0.53;
  static const Duration _clickDuration = Duration(milliseconds: 80);

  Sequence? _sequence;
  Track? _padTrack;
  Track? _clickTrack;
  bool _isInitialized = false;
  bool _isPlaying = false;
  DroneChord? _currentChord;
  final Set<int> _activeNotes = {};
  double _volume = 0.54;
  String _currentSound = 'Organ';

  // Metronome state
  Timer? _metronomeTimer;
  bool _metronomeRunning = false;
  double _metronomeBpm = 120.0;

  bool get isInitialized => _isInitialized;
  bool get isPlaying => _isPlaying;
  DroneChord? get currentChord => _currentChord;
  String get currentSound => _currentSound;
  bool get isMetronomeRunning => _metronomeRunning;

  /// Initialize the drone audio engine with the given sound name.
  /// Creates its own Sequence + pad Track + click Track.
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

      final padInstrument = Sf2Instrument(
        path: sf2Path,
        isAsset: true,
        presetIndex: 0,
      );

      final drumInstrument = Sf2Instrument(
        path: _drumSf2,
        isAsset: true,
        presetIndex: 0,
      );

      final tracks = await _sequence!.createTracks([padInstrument, drumInstrument]);
      if (tracks.isEmpty) {
        throw Exception('Failed to create drone tracks');
      }

      _padTrack = tracks[0];
      _padTrack!.changeVolumeNow(volume: _volume);

      if (tracks.length >= 2) {
        _clickTrack = tracks[1];
        _clickTrack!.changeVolumeNow(volume: 0.7);
      }

      _isInitialized = true;
      debugPrint('[DroneService] Initialized with $soundName');
    } catch (e, st) {
      debugPrint('[DroneService] Initialization failed: $e\n$st');
      _isInitialized = false;
      _sequence = null;
      _padTrack = null;
      _clickTrack = null;
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

  /// Stop the drone and metronome.
  void stop() {
    debugPrint('[DroneService] Stopping drone');
    stopMetronome();
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

  // --- Metronome ---

  /// Start the metronome click at the given BPM.
  void startMetronome(double bpm) {
    if (_clickTrack == null) return;
    _metronomeBpm = bpm;
    _metronomeTimer?.cancel();

    final intervalMs = (60000.0 / bpm).round();
    debugPrint('[DroneService] Starting metronome at $bpm BPM (${intervalMs}ms)');

    // Fire first click immediately
    _fireClick();

    _metronomeTimer = Timer.periodic(
      Duration(milliseconds: intervalMs),
      (_) => _fireClick(),
    );
    _metronomeRunning = true;
  }

  /// Stop the metronome click.
  void stopMetronome() {
    _metronomeTimer?.cancel();
    _metronomeTimer = null;
    _metronomeRunning = false;
  }

  /// Update the metronome tempo. Restarts the timer if running.
  void updateMetronomeTempo(double bpm) {
    _metronomeBpm = bpm;
    if (_metronomeRunning) {
      startMetronome(bpm);
    }
  }

  void _fireClick() {
    if (_clickTrack == null) return;
    try {
      _clickTrack!.startNoteNow(noteNumber: _hiHatNote, velocity: _clickVelocity);
      // Short note — stop after a brief duration
      Future.delayed(_clickDuration, () {
        try {
          _clickTrack?.stopNoteNow(noteNumber: _hiHatNote);
        } catch (_) {}
      });
    } catch (e) {
      debugPrint('[DroneService] Error firing click: $e');
    }
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
        // Destroy the sequence to properly remove tracks from the native engine.
        // Without this, orphaned AudioUnit tracks accumulate and leak memory.
        _sequence!.destroy();
      } catch (e) {
        debugPrint('[DroneService] Error stopping/destroying sequence: $e');
      }
    }

    _padTrack = null;
    _clickTrack = null;
    _sequence = null;
    _isInitialized = false;
    debugPrint('[DroneService] Disposed');
  }
}
