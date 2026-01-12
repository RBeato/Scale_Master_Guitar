import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sequencer/models/instrument.dart';
import 'package:flutter_sequencer/sequence.dart';
import 'package:flutter_sequencer/track.dart';
import 'package:scalemasterguitar/constants/general_audio_constants.dart';
import 'package:scalemasterguitar/models/project_state.dart';

import '../../../constants/music_constants.dart';
import '../../../models/chord_model.dart';
import '../../../models/step_sequencer_state.dart';
import '../../../utils/music_utils.dart';
import '../provider/bass_note_index_provider.dart';
import '../provider/is_playing_provider.dart';
import '../provider/selected_chords_provider.dart';
import 'package:collection/collection.dart';
import 'dart:async';
import 'dart:io';
import 'audio_service.dart';
// Sequencer imports (based on working examples)
import 'package:flutter_sequencer/models/events.dart';
import 'package:flutter_sequencer/native_bridge.dart';
import 'package:flutter_sequencer/global_state.dart';

final sequencerManagerProvider = Provider((ref) => SequencerManager(ref));

class SequencerManager {
  final Ref _ref;
  SequencerManager(this._ref);
  
  // Use AudioService singleton for proper audio lifecycle management
  AudioService get _audioService => AudioService();

  Map<int, StepSequencerState> trackStepSequencerStates = {};
  List<Track> tracks = [];
  Sequence? sequence;
  List _lastChords = [];
  // final List _lastExtensions = [];
  // Default to false to match Settings model default - plays each chord's root note as bass
  bool _lastTonicAsUniversalBassNote = false;
  bool tonicAsUniversalBassNote = false;
  bool _lastMetronomeSelected = false;
  bool isMetronomeSelected = false;
  Map<int, double> trackVolumes = {};
  Track? selectedTrack;
  double _lastTempo = Constants.INITIAL_TEMPO;
  double tempo = Constants.INITIAL_TEMPO;
  double _position = 0.0;
  double get position => _position;
  set position(double value) => _position = value;
  bool isPlaying = false;
  bool isTrackLooping = true;
  int stepCount = 0;
  bool isLoading = false;
  bool playAllInstruments = true;

  // Track-specific note tracking to prevent voice management issues
  final Map<int, Set<int>> _trackActiveNotes = {};
  Timer? _cleanupTimer;
  
  // Mutex for thread-safe note operations
  bool _noteOperationInProgress = false;

  // Platform scheduling: iOS=Dart; Android=native (from working example)
  bool get _useNativeScheduling => Platform.isIOS
      ? GlobalState().iosNativeSchedulingEnabled
      : true;

  /// Update position from sequence (for ticker updates)
  void updatePosition() {
    if (sequence != null) {
      try {
        final currentBeat = sequence!.getBeat();
        final sequenceIsPlaying = sequence!.getIsPlaying();

        // Update position and playing state
        position = currentBeat;

        if (isPlaying != sequenceIsPlaying) {
          isPlaying = sequenceIsPlaying;
          _ref.read(isSequencerPlayingProvider.notifier).update((state) => sequenceIsPlaying);

          if (sequenceIsPlaying) {
            debugPrint("[SequencerManager] updatePosition: Sequence started playing at beat $currentBeat");
          } else {
            debugPrint("[SequencerManager] updatePosition: Sequence stopped at beat $currentBeat");
          }
        }
      } catch (e) {
        // Ignore position read errors during playback
      }
    }
  }

  // Simple playback system (based on working flutter_sequencer_plus example)
  Timer? _playbackTimer;
  final Set<String> _processedEvents = {};
  bool isPaused = false;
  
  // Loop boundary detection (simplified from working example)
  double? _lastProcessedBeat;
  int _loopCycle = 0;

  Future<List<Track>> initialize({
    required List<Track> tracks,
    Sequence? sequence, // Make optional since AudioService will create it
    playAllInstruments,
    isPlaying,
    stepCount,
    trackVolumes,
    selectedChords,
    trackStepSequencerStates,
    selectedTrack,
    isLoading,
    isScaleTonicSelected,
    isMetronomeSelected,
    beatCounter,
    tempo,
    required List<Instrument> instruments,
    bool forceRecreateTracksForInstrumentChange = false, // Flag to force track recreation when instrument changes
  }) async {
    if (isPlaying && this.sequence != null) {
      handleStop(this.sequence!);
    }

    if (sequence != null) {
      clearEverything(tracks, sequence);
    }

    this.playAllInstruments = playAllInstruments;
    this.tempo = tempo;
    tonicAsUniversalBassNote = isScaleTonicSelected;
    debugPrint('[SequencerManager] isScaleTonicSelected (tonicAsUniversalBassNote): $isScaleTonicSelected');
    this.isMetronomeSelected = isMetronomeSelected;

    // Initialize audio service with proper lifecycle management - based on working guitar_progression_generator
    debugPrint('[SequencerManager] Initializing AudioService...');

    try {
      // Initialize AudioService with sequence parameters
      await _audioService.initialize(
        tempo: tempo,
        endBeat: stepCount.toDouble(),
        forceReinitialize: false,
      );

      // Get the properly initialized sequence from AudioService
      this.sequence = _audioService.sequence!;
      debugPrint('[SequencerManager] AudioService initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('[SequencerManager] AudioService initialization failed: $e');
      debugPrint('[SequencerManager] Stack trace: $stackTrace');
      throw Exception('Failed to initialize audio engine: $e');
    }

    // Start periodic cleanup for stale notes
    _startCleanupTimer();

    try {
      // Check if we need to recreate tracks due to instrument changes
      // We need to recreate tracks when instruments change because tracks retain their SF2 files
      bool needsRecreation = this.tracks.isEmpty ||
                            this.tracks.length != instruments.length ||
                            forceRecreateTracksForInstrumentChange;

      if (!needsRecreation) {
        // Check if instruments have actually changed by comparing SF2 paths
        for (int i = 0; i < this.tracks.length; i++) {
          final currentInstrument = this.tracks[i].instrument;
          final newInstrument = instruments[i];

          if (currentInstrument.idOrPath != newInstrument.idOrPath ||
              currentInstrument.presetIndex != newInstrument.presetIndex) {
            debugPrint('[SequencerManager] Instrument change detected: track $i changed from ${currentInstrument.idOrPath} to ${newInstrument.idOrPath}');
            needsRecreation = true;
            break;
          }
        }
      }

      final shouldReuseExistingTracks = !needsRecreation;

      if (shouldReuseExistingTracks) {
        debugPrint('[SequencerManager] Reusing existing ${this.tracks.length} tracks (preventing native crash)');
        // Stop all notes and clear events from existing tracks
        for (Track track in this.tracks) {
          // Stop all possible notes to prevent sustaining
          for (int note = 0; note <= 127; note++) {
            try {
              track.stopNoteNow(noteNumber: note);
            } catch (_) {
              // Ignore errors - not all notes are active
            }
          }
          track.clearEvents();

          // Reset track state in native layer
          try {
            NativeBridge.resetTrack(track.id);
            debugPrint('[SequencerManager] Reset track ${track.id} in native layer');
          } catch (e) {
            debugPrint('[SequencerManager] Warning: Could not reset track ${track.id}: $e');
          }
        }
      } else {
        // Recreate tracks when instruments have changed
        if (forceRecreateTracksForInstrumentChange) {
          debugPrint('[SequencerManager] 🔄 INSTRUMENT CHANGE DETECTED: Force recreating ${instruments.length} tracks with new instruments...');
        } else {
          debugPrint('[SequencerManager] Creating ${instruments.length} tracks via AudioService...');
        }

        // Stop and clear old tracks before creating new ones
        if (this.tracks.isNotEmpty) {
          debugPrint('[SequencerManager] Stopping old tracks before recreation...');
          for (Track track in this.tracks) {
            try {
              // Stop all notes
              for (int note = 0; note <= 127; note++) {
                try {
                  track.stopNoteNow(noteNumber: note);
                } catch (_) {}
              }
              track.clearEvents();
            } catch (e) {
              debugPrint('[SequencerManager] Warning: Could not clear track ${track.id}: $e');
            }
          }
        }

        List<Track> createdTracks = await _audioService.createTracks(instruments);
        debugPrint('[SequencerManager] AudioService created ${createdTracks.length} tracks successfully');

        this.tracks = createdTracks;
      }
      selectedTrack = this.tracks[0];

      if (kDebugMode) {
        debugPrint('[SequencerManager] 🎼 TRACK ASSIGNMENT DEBUG:');
        debugPrint('[SequencerManager]   Total tracks created: ${this.tracks.length}');
        debugPrint('[SequencerManager]   Expected: 3 tracks (onlyKeys=true: all piano, or Drums/Piano/Bass)');
      }

      for (int i = 0; i < this.tracks.length; i++) {
        Track track = this.tracks[i];
        trackVolumes[track.id] = 0.6; // Reduced from 0.8 to 0.6 to prevent distortion at high phone volumes
        trackStepSequencerStates[track.id] = StepSequencerState();

        // Ensure track volume is properly set
        track.changeVolumeNow(volume: 0.6); // 60% volume to prevent clipping/distortion

        if (kDebugMode) {
          debugPrint('[SequencerManager] 📍 Track $i Details:');
          debugPrint('[SequencerManager]   Track ID: ${track.id}');
          debugPrint('[SequencerManager]   Volume: ${trackVolumes[track.id]}');
          debugPrint('[SequencerManager]   Type: ${track.runtimeType}');

          // Identify which track this is
          if (i == 0) {
            debugPrint('[SequencerManager]   Role: DRUMS (or Piano if onlyKeys=true)');
          } else if (i == 1) {
            debugPrint('[SequencerManager]   Role: 🎹 PIANO/KEYBOARD (THIS IS THE MAIN TRACK!)');
          } else if (i == 2) {
            debugPrint('[SequencerManager]   Role: BASS (or Piano if onlyKeys=true)');
          }

          // Try to get instrument info if available
          try {
            debugPrint('[SequencerManager]   Instrument: ${instruments[i].runtimeType}');
            if (instruments[i] is Sf2Instrument) {
              final sf2 = instruments[i] as Sf2Instrument;
              debugPrint('[SequencerManager]   SF2 Path: ${sf2.idOrPath}');
              debugPrint('[SequencerManager]   SF2 Preset: ${sf2.presetIndex}');
            }
          } catch (e) {
            debugPrint('[SequencerManager]   Could not get instrument info: $e');
          }
        }
      }

      // Create project state
      ProjectState? project = await _createProject(
        selectedChords: selectedChords,
        stepCount: stepCount,
        nBeats: stepCount,
        playAllInstruments: playAllInstruments,
      );

      // Load project state
      debugPrint('[SequencerManager] About to load project state');
      loadProjectState(project!, this.tracks, this.sequence!);
      
      // Debug tracks after loading project state
      debugPrint('[SequencerManager] After loadProjectState - checking track events:');
      for (int i = 0; i < this.tracks.length; i++) {
        final track = this.tracks[i];
        debugPrint('[SequencerManager] Track $i (id=${track.id}): ${track.events.length} events');
      }
    } catch (e, stackTrace) {
      debugPrint('Error during initialization: $e');
      debugPrint(stackTrace.toString());
      // Handle the error as needed
    }
    // Return a copy of tracks to prevent external modifications from affecting internal state
    return List<Track>.from(this.tracks);
  }

  Future<ProjectState>? _createProject({
    required List<ChordModel> selectedChords,
    required int stepCount,
    required int nBeats,
    required playAllInstruments,
  }) async {
    ProjectState project = ProjectState.empty(stepCount);

    debugPrint("Creating project with ${selectedChords.length} chords");

    for (int i = 0; i < selectedChords.length; i++) {
      ChordModel chord = selectedChords[i];
      debugPrint("Chord ${i + 1}: ${chord.completeChordName}");
      debugPrint("  Position: ${chord.position}");
      debugPrint("  Notes with inversions: ${chord.chordNotesInversionWithIndexes}");
      
      if (chord.chordNotesInversionWithIndexes == null || chord.chordNotesInversionWithIndexes!.isEmpty) {
        debugPrint("  WARNING: No chord notes found for piano! This will result in no sound.");
        continue;
      }
      
      for (var note in chord.chordNotesInversionWithIndexes!) {
        final midiValue = MusicConstants.midiValues[note];
        if (midiValue != null) {
          project.pianoState.setVelocity(chord.position, midiValue, 0.75); // Reduced from 0.95 to 0.75 to prevent distortion
          debugPrint("  Added piano note: $note (MIDI: $midiValue)");
        } else {
          debugPrint("  ERROR: No MIDI value found for note: $note");
        }
      }

      var note = tonicAsUniversalBassNote
          ? chord.parentScaleKey
          : MusicUtils.extractNoteName(chord.completeChordName!);
      // debugPrint('Chord: $chord, bass note $note');

      note = MusicUtils.filterNoteNameWithSlash(note);
      note = MusicUtils.flatsAndSharpsToFlats(note);

      var index = _ref.read(bassNoteIndexProvider);

      if (i > 0) {
        index = MusicUtils.calculateIndexForBassNote(
          MusicUtils.extractNoteName(selectedChords[i - 1].completeChordName!),
          note,
          index,
        );
        _ref.read(bassNoteIndexProvider.notifier).update((state) => index);
      }

      var bassMidiValue = MusicConstants.midiValues["$note$index"]!;
      debugPrint("Adding bass note: Chord ${i + 1}/${selectedChords.length}");
      debugPrint("  Position: ${chord.position}");
      debugPrint("  Note: $note");
      debugPrint("  MIDI Value: $bassMidiValue");

      project.bassState.setVelocity(
          chord.position, bassMidiValue, 0.75); // Reduced from 0.99 to 0.75 to prevent distortion

      // Verify if the note was added successfully
      double? addedVelocity =
          project.bassState.getVelocity(chord.position, bassMidiValue);
      debugPrint("  Bass note added successfully. Velocity: $addedVelocity");

      debugPrint(""); //
    }
    
    // Debug the project state before returning
    debugPrint("[SequencerManager] Project state summary:");
    debugPrint("  Step count: ${project.stepCount}");
    
    // Count events in each state
    int pianoEventCount = 0;
    int bassEventCount = 0;
    project.pianoState.iterateEvents((step, noteNumber, velocity) {
      if (velocity > 0) pianoEventCount++;
    });
    project.bassState.iterateEvents((step, noteNumber, velocity) {
      if (velocity > 0) bassEventCount++;
    });
    
    debugPrint("  Piano state events: $pianoEventCount");
    debugPrint("  Bass state events: $bassEventCount");

    if (isMetronomeSelected && playAllInstruments) {
      for (int i = 0; i < nBeats; i++) {
        project.drumState.setVelocity(i, 44, 0.59); // Hi-hat (Pedal Hi-Hat in GM)
      }
    }
    return project;
  }

  Future<void> playPianoNote(String note, List<Track> tracks, Sequence sequence) async {
    final String method = 'SequencerManager.playPianoNote';
    final midiValue = MusicConstants.midiValues[MusicUtils.filterNoteNameWithSlash(note)]!;

    // Prevent concurrent note operations
    if (_noteOperationInProgress) {
      debugPrint('[$method] Note operation already in progress. Skipping $note.');
      return;
    }

    // Ensure tracks list is not empty and has the piano track at the expected index
    if (tracks.length <= 1) {
      debugPrint('[$method] ❌ Tracks list too short or piano track not available (length: ${tracks.length}). Cannot play note $note.');
      return;
    }
    final pianoTrack = tracks[1]; // Assuming piano is always track 1
    final trackId = pianoTrack.id;

    if (kDebugMode) {
      debugPrint('[$method] 🎹 PLAYING NOTE DEBUG:');
      debugPrint('[$method]   Note: $note → MIDI: $midiValue');
      debugPrint('[$method]   Using track index: 1 (Piano track)');
      debugPrint('[$method]   Track ID: $trackId');
      debugPrint('[$method]   Total tracks: ${tracks.length}');
    }

    _noteOperationInProgress = true;
    try {
      // Initialize track note set if needed
      _trackActiveNotes.putIfAbsent(trackId, () => <int>{});
      
      debugPrint('[$method] CALLED - Note: $note, MIDI: $midiValue. Track $trackId active notes: ${_trackActiveNotes[trackId]}');

      if (_trackActiveNotes[trackId]!.contains(midiValue)) {
        debugPrint('[$method] Note $midiValue already active on track $trackId. SKIPPING startNoteNow.');
        return;
      }
      
      final Stopwatch stopwatch = Stopwatch()..start();
      pianoTrack.startNoteNow(noteNumber: midiValue, velocity: 0.7); // Reduced from 0.85 to 0.7 to prevent distortion
      stopwatch.stop();
      
      // Only add to tracking AFTER successful start
      _trackActiveNotes[trackId]!.add(midiValue);
      debugPrint('[$method] COMPLETED - pianoTrack.startNoteNow for $midiValue on track $trackId. Duration: ${stopwatch.elapsedMicroseconds} us.');
      debugPrint('[$method] Track $trackId active notes now: ${_trackActiveNotes[trackId]}');
    } catch (e, stackTrace) {
      debugPrint('[$method] ERROR calling pianoTrack.startNoteNow for $midiValue: $e\n$stackTrace');
      // Don't add to tracking if start failed
    } finally {
      _noteOperationInProgress = false;
    }
  }

  Future<void> stopPianoNote(String note, List<Track> tracks, Sequence sequence) async {
    final String method = 'SequencerManager.stopPianoNote';
    final midiValue = MusicConstants.midiValues[MusicUtils.filterNoteNameWithSlash(note)]!;
    
    // Prevent concurrent note operations
    if (_noteOperationInProgress) {
      debugPrint('[$method] Note operation already in progress. Skipping $note.');
      return;
    }
    
    // Ensure tracks list is not empty and has the piano track at the expected index
    if (tracks.length <= 1) {
      debugPrint('[$method] Tracks list too short or piano track not available (length: ${tracks.length}). Cannot stop note $note.');
      return;
    }
    final pianoTrack = tracks[1]; // Assuming piano is always track 1
    final trackId = pianoTrack.id;

    _noteOperationInProgress = true;
    try {
      // Initialize track note set if needed
      _trackActiveNotes.putIfAbsent(trackId, () => <int>{});
      
      debugPrint('[$method] CALLED - Note: $note, MIDI: $midiValue. Track $trackId active notes: ${_trackActiveNotes[trackId]}');

      if (!_trackActiveNotes[trackId]!.contains(midiValue)) {
        debugPrint('[$method] Note $midiValue was NOT active on track $trackId. SKIPPING stopNoteNow (might have been stopped already or never started on this track).');
        return;
      }
      
      final Stopwatch stopwatch = Stopwatch()..start();
      pianoTrack.stopNoteNow(noteNumber: midiValue);
      stopwatch.stop();
      
      // Only remove from tracking AFTER successful stop
      _trackActiveNotes[trackId]!.remove(midiValue);
      debugPrint('[$method] COMPLETED - pianoTrack.stopNoteNow for $midiValue on track $trackId. Duration: ${stopwatch.elapsedMicroseconds} us.');
      debugPrint('[$method] Track $trackId active notes now: ${_trackActiveNotes[trackId]}');
    } catch (e, stackTrace) {
      debugPrint('[$method] ERROR calling pianoTrack.stopNoteNow for $midiValue: $e\n$stackTrace');
      // Remove from tracking even if stop failed to prevent stale state
      _trackActiveNotes[trackId]?.remove(midiValue);
    } finally {
      _noteOperationInProgress = false;
    }
  }

  Future<void> handleTogglePlayStop(Sequence sequence) async {
    debugPrint("[SequencerManager] Toggle play/stop - current playing: $isPlaying");

    if (isPlaying) {
      // STOP completely (not pause) for immediate audio cutoff
      debugPrint("[SequencerManager] Stopping sequence completely...");
      _stopPlayback(sequence);
    } else {
      // Start fresh playback (always from beginning)
      debugPrint("[SequencerManager] Starting fresh playback...");
      _startPlayback(sequence);
    }
  }

  /// Simple playback system based on working flutter_sequencer_plus example
  void _startPlayback(Sequence sequence) {
    debugPrint("[SequencerManager] Starting playback...");

    // Reset state like working example
    _processedEvents.clear();
    _loopCycle = 0;
    _lastProcessedBeat = null;

    // Update state
    isPlaying = true;
    isPaused = false;
    position = 0.0;
    _ref.read(isSequencerPlayingProvider.notifier).update((state) => true);

    // Set sequence position to 0 and start native playbook
    sequence.setBeat(0.0);
    sequence.play();

    // Start simple timer for iOS Dart scheduling (like working example)
    if (!_useNativeScheduling) {
      _playbackTimer = Timer.periodic(const Duration(milliseconds: 1), (timer) {
        _processPlayback(sequence);
      });
    }

    debugPrint("[SequencerManager] Playback started");
  }

  // Removed pause/resume methods since we use immediate stop/start

  /// Simple playback processing from working example
  void _processPlayback(Sequence sequence) {
    if (!isPlaying) return;

    // Get position from native sequence (like working example)
    final currentBeat = sequence.getBeat();

    // Update position
    position = currentBeat;

    // Simple loop boundary detection (from working example)
    if (isTrackLooping && _lastProcessedBeat != null) {
      // Detect loop wrap (simplified from working example)
      if (_lastProcessedBeat! > 0.1 && currentBeat < (_lastProcessedBeat! - 0.5)) {
        _loopCycle++;
        _processedEvents.clear(); // Allow events to retrigger
        debugPrint("[SequencerManager] Loop wrap detected - cycle $_loopCycle");
      }
    }
    _lastProcessedBeat = currentBeat;

    // Process events for iOS Dart scheduling (from working example)
    if (!_useNativeScheduling) {
      _processEventsAtBeat(currentBeat);
    }

    // Stop if reached end (non-looping)
    if (!isTrackLooping && currentBeat >= stepCount) {
      debugPrint("[SequencerManager] Reached end - stopping");
      _stopPlayback(sequence);
    }
  }
  
  /// Simple event processing from working example (iOS Dart scheduling)
  void _processEventsAtBeat(double currentBeat) {
    for (final track in tracks) {
      for (final event in track.events) {
        if (event is MidiEvent) {
          // Simple timing check (from working example)
          if ((currentBeat - event.beat).abs() < 0.1) {
            final eventKey = '${track.id}-$_loopCycle-${event.beat}-${event.midiData1}';

            if (!_processedEvents.contains(eventKey)) {
              // Send event using NativeBridge (from working example)
              NativeBridge.handleEventsNow(
                track.id,
                [event],
                GlobalState().sampleRate!,
                tempo,
              );
              _processedEvents.add(eventKey);
            }
          }
        }
      }
    }
  }

  /// Immediate stop method for responsive UI
  void _stopPlayback(Sequence sequence) {
    debugPrint("[SequencerManager] Stopping playback immediately...");

    // STEP 1: Stop timers immediately
    _playbackTimer?.cancel();
    _playbackTimer = null;

    // STEP 2: Stop sequence immediately
    sequence.stop();
    sequence.setBeat(0.0); // Reset to beginning

    // STEP 3: Send aggressive note-offs immediately (prevent audio hanging)
    try {
      for (final track in tracks) {
        // Stop all possible notes immediately for complete silence
        for (int note = 21; note <= 108; note++) { // Full piano range
          try {
            track.stopNoteNow(noteNumber: note);
          } catch (_) {
            // Ignore individual failures - not all notes are active
          }
        }
      }
    } catch (e) {
      debugPrint("[SequencerManager] Error stopping notes: $e");
    }

    // STEP 4: Update state immediately
    isPlaying = false;
    isPaused = false;
    position = 0.0;
    _loopCycle = 0;
    _processedEvents.clear();
    _trackActiveNotes.clear();

    // STEP 5: Update UI state
    _ref.read(isSequencerPlayingProvider.notifier).update((state) => false);

    debugPrint("[SequencerManager] Playback stopped immediately");
  }
  
  void _stopAllActiveNotes() {
    debugPrint("🛑 [SequencerManager] Stopping all active notes from both tracking systems");
    
    // ANDROID OPTIMIZATION: Stop all notes aggressively
    // On Android, we need to be more thorough to prevent hanging notes
    debugPrint("🛑 [SequencerManager] Stopping all notes aggressively for Android");
    
    // First, try to stop all possible notes on all tracks
    if (Platform.isAndroid) {
      for (final track in tracks) {
        try {
          // Stop common note ranges that might be playing
          // Piano/Bass range: 24-96 (C1 to C7)
          // Drums: 35-81 (common drum kit range)
          for (int note = 24; note < 97; note++) {
            try {
              track.stopNoteNow(noteNumber: note);
            } catch (_) {
              // Silently continue - not all notes are playing
            }
          }
          debugPrint("🛑 [SequencerManager] Aggressive stop sent to track ${track.id}");
        } catch (e) {
          debugPrint("🛑 [SequencerManager] Error in aggressive stop: $e");
        }
      }
    }
    
    // Then stop individual notes for cleanup
    // 1. Stop notes from custom playback system - simplified
    int customNotesCount = 0; // Not tracked anymore in simplified system
    
    // 2. Stop notes from piano tracking system (_trackActiveNotes) 
    int pianoNotesCount = 0;
    _trackActiveNotes.forEach((trackId, noteSet) {
      pianoNotesCount += noteSet.length;
      final track = tracks.firstWhere((t) => t.id == trackId, orElse: () => tracks.first);
      
      // Convert to list to avoid concurrent modification
      final notesToStop = noteSet.toList();
      for (final noteNumber in notesToStop) {
        try {
          track.stopNoteNow(noteNumber: noteNumber);
          debugPrint("🛑 [SequencerManager] Stopped piano tracked note $noteNumber on track $trackId");
        } catch (e) {
          debugPrint("🛑 [SequencerManager] Error stopping piano tracked note $noteNumber: $e");
        }
      }
      noteSet.clear();
    });
    
    debugPrint("🛑 [SequencerManager] Stopped $customNotesCount custom notes and $pianoNotesCount piano notes");
    
    // 3. Send "All Notes Off" MIDI command (CC 123) to each track as emergency stop
    debugPrint("🛑 [SequencerManager] Sending All Notes Off MIDI command to all tracks");
    for (final track in tracks) {
      try {
        // Send "All Notes Off" control change message (CC 123, value 0)
        // This should stop all sustaining notes immediately at the native level
        final allNotesOffEvent = MidiEvent(
          beat: 0.0,
          midiStatus: 0xB0, // Control Change on channel 0
          midiData1: 123,   // All Notes Off controller
          midiData2: 0      // Value 0
        );
        
        NativeBridge.handleEventsNow(
          track.id, 
          [allNotesOffEvent], 
          GlobalState().sampleRate!, 
          tempo
        );
        debugPrint("🛑 [SequencerManager] Sent All Notes Off to track ${track.id}");
      } catch (e) {
        debugPrint("🛑 [SequencerManager] Error sending All Notes Off to track ${track.id}: $e");
      }
    }
    
    // 4. Fallback: Emergency stop for common sustaining notes if tracking failed
    if (customNotesCount + pianoNotesCount > 5) {
      debugPrint("🛑 [SequencerManager] Emergency stop: many notes were active, doing bulk individual stop");
      for (final track in tracks) {
        try {
          // Stop common piano notes (C3-C6 range) + bass notes (C2-B2)
          for (int noteNumber = 24; noteNumber <= 96; noteNumber++) {
            track.stopNoteNow(noteNumber: noteNumber);
          }
        } catch (e) {
          // Ignore errors for bulk emergency stop
        }
      }
    }
  }

  // Stop playback without clearing track events
  void _stopPlaybackOnly(Sequence sequence) {
    try {
      if (sequence.getIsPlaying()) {
        sequence.stop();
      }
      isPlaying = false;
      _ref.read(isSequencerPlayingProvider.notifier).update((state) => false);
      
      // CRITICAL: Use the same comprehensive stop method
      _stopAllActiveNotes();
      
      // Clear tracking systems
      _trackActiveNotes.clear();
    } catch (e) {
      debugPrint('[SequencerManager] Error in _stopPlaybackOnly: $e');
    }
  }

  Future<void> handleStop(Sequence sequence) async {
    try {
      debugPrint('[SequencerManager] handleStop called');

      // Prevent multiple simultaneous stop calls
      if (!isPlaying && !isPaused) {
        debugPrint('[SequencerManager] Already stopped, skipping');
        return;
      }

      // Use simple stop method
      _stopPlayback(sequence);

      debugPrint('[SequencerManager] Stop completed successfully');
    } catch (e, st) {
      debugPrint('[SequencerManager] Error in handleStop: $e\n$st');
      // Don't rethrow to prevent crashes, just log the error
    }
  }

  void _handleSetLoop(bool nextIsLooping, Sequence sequence) {
    // Set native looping like working examples
    if (nextIsLooping) {
      sequence.setLoop(0, stepCount.toDouble());
      debugPrint('[SequencerManager] Native looping enabled: 0 to $stepCount beats');
    } else {
      sequence.unsetLoop();
      debugPrint('[SequencerManager] Native looping disabled');
    }

    isTrackLooping = nextIsLooping;
    debugPrint('[SequencerManager] Loop set to: $nextIsLooping');
  }

  void handleToggleLoop(bool isLooping, Sequence sequence) {
    final nextIsLooping = !isLooping;

    _handleSetLoop(nextIsLooping, sequence);
  }

  void _handleStepCountChange(
      int nextStepCount, List<Track> tracks, Sequence sequence) {
    if (nextStepCount < 1) return;

    sequence.setEndBeat(nextStepCount.toDouble());

    if (isTrackLooping) {
      final nextLoopEndBeat = nextStepCount.toDouble();

      sequence.setLoop(0.toDouble(), nextLoopEndBeat);
    }

    stepCount = nextStepCount;
    for (var track in tracks) {
      _syncTrack(track);
    }

    // setState(() {
    //   stepCount = nextStepCount;
    //   for (var track in tracks) {
    //     syncTrack(track);
    //   }
    // });
  }

  void handleTempoChange(double nextTempo, Sequence sequence) {
    if (nextTempo <= 0) {
        debugPrint('[SequencerManager] Invalid tempo: $nextTempo. Must be > 0.');
        return;
    }
    if (kDebugMode) {
      debugPrint('[SequencerManager] handleTempoChange: $nextTempo BPM');
    }
    // Custom playback system uses local tempo directly
    tempo = nextTempo; 
  }

  // handleTrackChange(Track nextTrack) {
  //   selectedTrack = nextTrack;
  //   // setState(() {
  //   //   selectedTrack = nextTrack;
  //   // });
  // }

  handleVolumeChange(double nextVolume, Track selectedTrack) {
    selectedTrack.changeVolumeNow(volume: nextVolume);
  }

  handleVelocitiesChange(int trackId, int step, int noteNumber, double velocity,
      List<Track> tracks) {
    final track = tracks.firstWhere((track) => track.id == trackId);

    trackStepSequencerStates[trackId]!.setVelocity(step, noteNumber, velocity);

    _syncTrack(track);
  }

  _syncTrack(Track track) {
    track.clearEvents();
    final List<ChordModel> currentChords = _ref.read(selectedChordsProvider);
    StepSequencerState? stepState = trackStepSequencerStates[track.id];

    if (stepState == null) {
      debugPrint('[SequencerManager._syncTrack] No StepSequencerState for track ID ${track.id}. Skipping sync.');
      return;
    }

    // Determine track purpose based on the track's position in the tracks list
    // Track order: 0=Drums, 1=Piano, 2=Bass (based on how they're created)
    int trackIndex = tracks.indexOf(track);
    if (trackIndex == -1) {
      debugPrint('[SequencerManager._syncTrack] WARNING: Track ${track.id} not found in tracks list!');
      return;
    }

    bool isDrumTrack = trackIndex == 0;
    bool isPianoTrack = trackIndex == 1;
    bool isBassTrack = trackIndex == 2;

    if (isPianoTrack || isBassTrack) {
      Map<int, ChordModel> chordAtPosition = {};
      for (var chord in currentChords) {
        chordAtPosition[chord.position] = chord;
      }

      stepState.iterateEvents((step, noteNumber, velocity) {
        if (velocity > 0) { // Only active notes
          ChordModel? currentEventChord = chordAtPosition[step];
          double durationBeats = 1.0; // Default duration if no specific chord found at this step

          if (currentEventChord != null) {
            durationBeats = currentEventChord.duration.toDouble();
          } else {
            // This situation (a note in stepState at a step that isn't a chord start)
            // should ideally not happen for piano/bass if stepState is built correctly from chords.
            // If it does, it means there are orphaned notes or a mismatch.
            // For safety, we use a default, but it might indicate an issue in _createProject or state management.
            debugPrint('[SequencerManager._syncTrack] Warning: Note (MIDI: $noteNumber) at step $step for track ${track.id} does not align with a chord start. Using default duration 1.0 beat.');
          }

          track.addNote(
            noteNumber: noteNumber,
            velocity: velocity,
            startBeat: step.toDouble(),
            durationBeats: durationBeats,
          );
        }
      });
    } else if (isDrumTrack) {
      stepState.iterateEvents((step, noteNumber, velocity) {
        if (velocity > 0 && step < this.stepCount) {
          track.addNote(
            noteNumber: noteNumber,
            velocity: velocity,
            startBeat: step.toDouble(),
            durationBeats: 0.5, // Drum hits are short
          );
        }
      });
    } else {
      // Fallback for any other unclassified tracks
      stepState.iterateEvents((step, noteNumber, velocity) {
        if (velocity > 0 && step < this.stepCount) {
          track.addNote(
            noteNumber: noteNumber,
            velocity: velocity,
            startBeat: step.toDouble(),
            durationBeats: 1.0, // Default duration
          );
        }
      });
    }
    track.syncBuffer();
    debugPrint('[SequencerManager._syncTrack] Synced track ID ${track.id}. Events in plugin track: ${track.events.length}');
  }

  loadProjectState(
      ProjectState projectState, List<Track> tracks, Sequence sequence) {
    // Don't call handleStop here - it clears the tracks!
    // Just stop playback and notes without clearing events
    _stopPlaybackOnly(sequence);

    trackStepSequencerStates[tracks[0].id] = projectState.drumState;
    trackStepSequencerStates[tracks[1].id] = projectState.pianoState;
    trackStepSequencerStates[tracks[2].id] = projectState.bassState;

    _handleStepCountChange(projectState.stepCount, tracks, sequence);
    handleTempoChange(tempo, sequence);
    _handleSetLoop(projectState.isLooping, sequence);
    
    // CRITICAL: Set sequence end beat to ensure playback duration is correct
    sequence.endBeat = stepCount.toDouble();
    if (kDebugMode) {
      debugPrint('[SequencerManager] Set sequence endBeat to: ${sequence.endBeat}');
    }

    _syncTrack(tracks[0]);
    _syncTrack(tracks[1]);
    _syncTrack(tracks[2]);
  }

  clearTracks(List<Track> tracks, Sequence sequence) {
    sequence.stop();
    _ref.read(isSequencerPlayingProvider.notifier).update((state) => false);
    if (tracks.isNotEmpty) {
      if (trackStepSequencerStates.containsKey(tracks[0].id)) {
        trackStepSequencerStates[tracks[0].id] = StepSequencerState();
        _syncTrack(tracks[0]);
      }
    } else {
      debugPrint("[SequencerManager.clearTracks] Tracks list is empty, nothing to clear from state map.");
    }
  }

  void clearEverything(List<Track> tracksToClear, Sequence sequence) {
    // Simple approach - just stop sequence and clear track events
    sequence.stop();
    
    // Clear events from tracks without destroying them
    for (var track in tracksToClear) {
      track.clearEvents();
      trackStepSequencerStates[track.id] = StepSequencerState();
    }
    
    // Don't clear the tracks list itself to avoid resetTrack crashes
    // tracksToClear.clear(); // REMOVED - this causes crashes
    
    _handleStepCountChange(0, tracksToClear, sequence);
  }

  bool needToUpdateSequencer(
    Sequence sequence,
    List selectedChords,
    double tempo,
    bool tonicAsUniversalBassNote,
    bool isMetronomeSelected,
  ) {
    if (!_listEquals(selectedChords, _lastChords) ||
        tempo != _lastTempo ||
        tonicAsUniversalBassNote != _lastTonicAsUniversalBassNote ||
        isMetronomeSelected != _lastMetronomeSelected) {
      handleStop(sequence);
      _lastTonicAsUniversalBassNote = tonicAsUniversalBassNote;
      _lastMetronomeSelected = isMetronomeSelected;
      _lastChords = selectedChords;
      _lastTempo = tempo;
      return true;
    }
    return false;
  }

  Function eq = const ListEquality().equals;
  bool _listEquals(List list1, List list2) {
    return eq(list1, list2);
  }

  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _cleanupStaleNotes();
    });
  }
  
  void _cleanupStaleNotes() {
    // Debug current state of active notes
    for (final trackId in _trackActiveNotes.keys.toList()) {
      final activeNotes = _trackActiveNotes[trackId] ?? <int>{};
      if (activeNotes.isNotEmpty) {
        debugPrint('[SequencerManager] Track $trackId has ${activeNotes.length} active notes: $activeNotes');
      }
    }
  }

  Future<void> dispose() async {
    debugPrint('[SequencerManager] Disposing: stopping sequence and clearing resources');
    try {
      // Stop cleanup timer first to prevent any interference
      _cleanupTimer?.cancel();
      _cleanupTimer = null;
      
      // Clean up custom playback timer
      _playbackTimer?.cancel();
      _playbackTimer = null;
      _processedEvents.clear();
      
      if (sequence != null) {
        debugPrint('[SequencerManager] Stopping sequence');
        
        // Use handleStop but with extra safety
        try {
          await handleStop(sequence!);
        } catch (e) {
          debugPrint('[SequencerManager] Error in handleStop during dispose: $e');
          // Continue with manual cleanup
        }
      }
      
      // Dispose AudioService properly
      try {
        debugPrint('[SequencerManager] Disposing AudioService');
        await _audioService.dispose();
        debugPrint('[SequencerManager] AudioService disposed successfully');
      } catch (e) {
        debugPrint('[SequencerManager] Error disposing AudioService: $e');
      }
      
      // Clear all state regardless of previous errors
      try {
        trackStepSequencerStates.clear();
        trackVolumes.clear();
        _trackActiveNotes.clear();
        _lastChords.clear();
        _processedEvents.clear();
      } catch (e) {
        debugPrint('[SequencerManager] Error clearing state: $e');
      }
      
      debugPrint('[SequencerManager] State cleared');
    } catch (e, st) {
      debugPrint('[SequencerManager] Error during dispose: $e\n$st');
      // Don't rethrow to prevent app crashes during cleanup
    } finally {
      debugPrint('[SequencerManager] Disposal complete');
    }
  }
}
