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
import '../../../utils/performance_utils.dart';
import 'dart:async';
import 'dart:io';
import 'audio_service.dart';
// Custom playback system imports (based on working guitar_progression_generator)
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
  bool _lastTonicAsUniversalBassNote = true;
  bool tonicAsUniversalBassNote = true;
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
  
  // Android optimization: Track last processed beat to prevent duplicates
  double? _lastProcessedBeat;
  
  // Mutex for thread-safe note operations
  bool _noteOperationInProgress = false;

  // Custom playback system (based on working flutter_sequencer_plus example)
  Timer? _playbackTimer;
  DateTime? _playbackStartTime;
  double _playbackStartBeat = 0.0;
  double _pausedAtBeat = 0.0;
  final Set<String> _processedEvents = {};
  final Map<String, double> _activeNotes = {}; // Track active notes with their end times
  bool isPaused = false;

  // Use native position tracking from flutter_sequencer

  Future<List<Track>> initialize({
    required List<Track> tracks,
    required Sequence sequence,
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
  }) async {
    this.sequence = sequence;
    if (isPlaying) {
      handleStop(sequence);
    }

    clearEverything(tracks, sequence);

    this.playAllInstruments = playAllInstruments;
    this.tempo = tempo;
    tonicAsUniversalBassNote = isScaleTonicSelected;
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
      // CRITICAL: Reuse existing tracks if they exist to prevent native crashes
      if (this.tracks.isNotEmpty && this.tracks.length == instruments.length) {
        debugPrint('[SequencerManager] Reusing existing ${this.tracks.length} tracks (preventing native crash)');
        // Clear events from existing tracks instead of creating new ones
        for (Track track in this.tracks) {
          track.clearEvents();
        }
      } else {
        // Create tracks using AudioService method only if needed
        debugPrint('[SequencerManager] Creating ${instruments.length} tracks via AudioService...');
        List<Track> createdTracks = await _audioService.createTracks(instruments);
        debugPrint('[SequencerManager] AudioService created ${createdTracks.length} tracks successfully');
        
        this.tracks = createdTracks;
      }
      selectedTrack = this.tracks[0];

      for (Track track in this.tracks) {
        trackVolumes[track.id] = 0.8; // Set audible volume for all tracks
        trackStepSequencerStates[track.id] = StepSequencerState();
        
        // Ensure track volume is properly set
        track.changeVolumeNow(volume: 0.8);
        if (kDebugMode) {
          debugPrint('[SequencerManager] Track ${track.id} volume set to: ${trackVolumes[track.id]}');
        }
        
        // Debug instrument info for piano sound quality issues
        debugPrint('[SequencerManager] Track ${track.id} instrument info:');
        try {
          // These are hypothetical methods - actual methods may vary
          debugPrint('[SequencerManager] Track ${track.id} instrument type: ${track.runtimeType}');
        } catch (e) {
          debugPrint('[SequencerManager] Could not get instrument info: $e');
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
      loadProjectState(project!, this.tracks, sequence);
      
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
    return this.tracks;
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
          project.pianoState.setVelocity(chord.position, midiValue, 0.95);
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
          chord.position, bassMidiValue, 0.99); // Increase velocity if needed

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
        project.drumState.setVelocity(i, 44, 0.59);
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
      debugPrint('[$method] Tracks list too short or piano track not available (length: ${tracks.length}). Cannot play note $note.');
      return;
    }
    final pianoTrack = tracks[1]; // Assuming piano is always track 1
    final trackId = pianoTrack.id;

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
      pianoTrack.startNoteNow(noteNumber: midiValue, velocity: 0.85);
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
    debugPrint("[SequencerManager] CUSTOM: Toggle play/stop - current playing: $isPlaying");
    
    if (isPlaying) {
      // Use CUSTOM pause system (flutter_sequencer_plus style)
      debugPrint("[SequencerManager] CUSTOM: Using custom pause system");
      _pauseCustomPlayback();
    } else {
      // Use CUSTOM playback system (flutter_sequencer_plus style)
      debugPrint("[SequencerManager] CUSTOM: Using custom playback system");
      
      if (isPaused && _pausedAtBeat > 0) {
        // Resume from custom pause
        _resumeCustomPlayback();
      } else {
        // Start fresh custom playback
        _startCustomPlayback();
      }
    }
  }

  /// Custom playback system based on working flutter_sequencer_plus example
  void _startCustomPlayback() {
    debugPrint("🎵 [SequencerManager] Starting CUSTOM playback system (flutter_sequencer_plus style)...");
    _playbackStartTime = DateTime.now();
    _playbackStartBeat = 0.0;
    _pausedAtBeat = 0.0;
    _processedEvents.clear();
    
    // Update state directly
    isPlaying = true;
    isPaused = false;
    _ref.read(isSequencerPlayingProvider.notifier).update((state) => true);
    
    // Platform-optimized timer frequency
    // Android needs slightly lower frequency to prevent audio glitches
    final timerInterval = Platform.isAndroid 
        ? const Duration(milliseconds: 15) // Android: 15ms for smoother performance
        : const Duration(milliseconds: 10); // iOS: 10ms for precision
    
    _playbackTimer = Timer.periodic(timerInterval, (timer) {
      _processCustomPlayback();
    });
    
    debugPrint("🎵 [SequencerManager] CUSTOM playback started - should hear events at scheduled beats");
  }
  
  void _pauseCustomPlayback() {
    debugPrint("🎵 [SequencerManager] Pausing CUSTOM playback...");
    _playbackTimer?.cancel();
    _playbackTimer = null;
    _pausedAtBeat = position;
    
    // Update state directly
    isPlaying = false;
    isPaused = true;
    _ref.read(isSequencerPlayingProvider.notifier).update((state) => false);
    
    debugPrint("🎵 [SequencerManager] CUSTOM paused at beat $_pausedAtBeat");
  }
  
  void _resumeCustomPlayback() {
    debugPrint("🎵 [SequencerManager] Resuming CUSTOM playback from beat $_pausedAtBeat...");
    _playbackStartTime = DateTime.now();
    _playbackStartBeat = _pausedAtBeat;
    
    // Update state directly
    isPlaying = true;
    isPaused = false;
    _ref.read(isSequencerPlayingProvider.notifier).update((state) => true);
    
    // Platform-optimized timer frequency for resume
    final timerInterval = Platform.isAndroid 
        ? const Duration(milliseconds: 15) // Android: 15ms for smoother performance
        : const Duration(milliseconds: 10); // iOS: 10ms for precision
    
    _playbackTimer = Timer.periodic(timerInterval, (timer) {
      _processCustomPlayback();
    });
    
    debugPrint("🎵 [SequencerManager] CUSTOM resumed from beat $_pausedAtBeat");
  }
  
  void _processCustomPlayback() {
    if (_playbackStartTime == null) return;
    
    // Calculate current beat based on elapsed time
    final elapsed = DateTime.now().difference(_playbackStartTime!);
    final elapsedBeats = (elapsed.inMicroseconds / 1000000.0) * (tempo / 60.0);
    var currentBeat = _playbackStartBeat + elapsedBeats;
    
    // Android optimization: Skip processing if we're too close to last processed beat
    // This prevents duplicate events on slower Android devices
    if (Platform.isAndroid && _lastProcessedBeat != null) {
      if ((currentBeat - _lastProcessedBeat!).abs() < 0.01) {
        return; // Skip this tick, too close to last processed beat
      }
    }
    _lastProcessedBeat = currentBeat;
    
    // CRITICAL FIX: Seamless loop transition - use modulo instead of time reset
    if (isTrackLooping && currentBeat >= stepCount) {
      // Calculate how far past the end we are for seamless transition
      final overshoot = currentBeat - stepCount;
      
      // IMPORTANT: Stop all active notes before loop restart to prevent hanging notes
      debugPrint("🎵 [SequencerManager] CUSTOM: Loop restart - stopping active notes before transition");
      _stopAllActiveNotes();
      _activeNotes.clear();
      
      // Clear processed events for the new loop cycle
      debugPrint("🎵 [SequencerManager] CUSTOM: Seamless loop transition at beat ${overshoot.toStringAsFixed(3)}");
      _processedEvents.clear();
      
      // Adjust timing reference for next calculations
      _playbackStartBeat = 0.0;
      _playbackStartTime = DateTime.now().subtract(Duration(microseconds: (overshoot * 1000000.0 / (tempo / 60.0)).round()));
      currentBeat = overshoot; // Continue seamlessly from overshoot position
    } else if (!isTrackLooping && currentBeat >= stepCount) {
      debugPrint("🎵 [SequencerManager] CUSTOM: Stopping playback (reached end)...");
      _stopCustomPlayback();
      return;
    }
    
    // Update position directly
    position = currentBeat % stepCount;
    
    // Process note-off events for expired notes (CRITICAL FIX for sustaining)
    _processNoteOffEvents(currentBeat);
    
    // Process note-on events at current beat
    _processEventsAtBeat(currentBeat);
  }
  
  void _processEventsAtBeat(double currentBeat) {
    final effectiveBeat = currentBeat % stepCount; // Handle loop wrapping
    
    for (final track in tracks) {
      for (final event in track.events) {
        if (event is MidiEvent) {
          final eventBeat = event.beat;
          
          // Check if event should trigger now (with timing tolerance)
          if (eventBeat >= effectiveBeat - 0.15 && eventBeat <= effectiveBeat + 0.15) {
            // Use loop-aware key to prevent duplicate events across loops
            final eventKey = '${track.id}-${(eventBeat * 100).round()}-${event.midiData1}-${event.midiData2}';
            final loopAwareKey = 'loop-${(currentBeat / stepCount).floor()}-$eventKey';
            
            if (!_processedEvents.contains(loopAwareKey)) {
              debugPrint("🎵 [SequencerManager] CUSTOM: TRIGGERING EVENT: track=${track.id} beat=$eventBeat note=${event.midiData1} vel=${event.midiData2}");
              
              // Send MIDI event directly using NativeBridge (like working example)
              NativeBridge.handleEventsNow(
                track.id, 
                [event], 
                GlobalState().sampleRate!, 
                tempo
              );
              
              // Track active note-on events for automatic note-off (only if it's a note-on)
              if (event.midiData2 > 0) { // NOTE-ON event
                double noteDuration;
                final trackIndex = tracks.indexOf(track);
                if (trackIndex == 0) {
                  // Drum track - short hits
                  noteDuration = 0.5;
                } else {
                  // Piano/bass tracks - full beat duration
                  noteDuration = 1.0;
                }
                
                final noteEndBeat = currentBeat + noteDuration;
                final noteKey = '${track.id}-${event.midiData1}';
                _activeNotes[noteKey] = noteEndBeat;
                debugPrint("🎵 [SequencerManager] Note scheduled to end at beat ${noteEndBeat.toStringAsFixed(3)}");
              }
              
              _processedEvents.add(loopAwareKey);
            }
          }
        }
      }
    }
  }
  
  void _processNoteOffEvents(double currentBeat) {
    final notesToStop = <String>[];
    
    _activeNotes.forEach((noteKey, endBeat) {
      if (currentBeat >= endBeat) {
        notesToStop.add(noteKey);
      }
    });
    
    for (final noteKey in notesToStop) {
      final parts = noteKey.split('-');
      if (parts.length == 2) {
        final trackId = int.parse(parts[0]);
        final noteNumber = int.parse(parts[1]);
        final track = tracks.firstWhere((t) => t.id == trackId, orElse: () => tracks.first);
        
        try {
          debugPrint("🛑 [SequencerManager] NOTE-OFF: track=$trackId note=$noteNumber at beat=${currentBeat.toStringAsFixed(3)}");
          track.stopNoteNow(noteNumber: noteNumber);
          _activeNotes.remove(noteKey);
        } catch (e) {
          debugPrint("🛑 [SequencerManager] Error stopping note $noteNumber on track $trackId: $e");
        }
      }
    }
  }
  
  void _stopCustomPlayback() {
    debugPrint("🎵 [SequencerManager] Stopping CUSTOM playback...");
    
    // ANDROID FIX: Stop native sequence FIRST to immediately halt audio
    // This prevents the frozen/hanging sound issue on Android
    if (sequence != null) {
      try {
        sequence!.stop();
        debugPrint("🛑 [SequencerManager] Force stopped native sequence FIRST");
      } catch (e) {
        debugPrint("🛑 [SequencerManager] Error force stopping native sequence: $e");
      }
    }
    
    // Cancel timer to prevent new events
    _playbackTimer?.cancel();
    _playbackTimer = null;
    _playbackStartTime = null;
    _processedEvents.clear();
    
    // Update state immediately to prevent race conditions
    isPlaying = false;
    isPaused = false;
    position = 0.0;
    _pausedAtBeat = 0.0;
    _ref.read(isSequencerPlayingProvider.notifier).update((state) => false);
    
    // Stop all active tracked notes immediately
    _stopAllActiveNotes();
    _activeNotes.clear();
    _trackActiveNotes.clear();
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
    // 1. Stop notes from custom playback system (_activeNotes)
    int customNotesCount = _activeNotes.length;
    _activeNotes.forEach((noteKey, endBeat) {
      final parts = noteKey.split('-');
      if (parts.length == 2) {
        final trackId = int.parse(parts[0]);
        final noteNumber = int.parse(parts[1]);
        final track = tracks.firstWhere((t) => t.id == trackId, orElse: () => tracks.first);
        
        try {
          track.stopNoteNow(noteNumber: noteNumber);
        } catch (e) {
          // Silently continue - All Notes Off should have handled it
        }
      }
    });
    
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
      _activeNotes.clear();
      _trackActiveNotes.clear();
    } catch (e) {
      debugPrint('[SequencerManager] Error in _stopPlaybackOnly: $e');
    }
  }

  Future<void> handleStop(Sequence sequence) async {
    try {
      debugPrint('[SequencerManager] handleStop called - using CUSTOM stop system');
      
      // Prevent multiple simultaneous stop calls
      if (!isPlaying && !isPaused) {
        debugPrint('[SequencerManager] Already stopped, skipping');
        return;
      }
      
      // ANDROID FIX: Don't use async operation tracking for stop
      // This needs to be immediate to prevent audio hanging
      _stopCustomPlayback();
      
      // Platform-specific cleanup
      if (Platform.isAndroid) {
        // Android: Give audio engine time to flush buffers
        await Future.delayed(const Duration(milliseconds: 50));
      }
      
      debugPrint('[SequencerManager] CUSTOM stop completed successfully');
    } catch (e, st) {
      debugPrint('[SequencerManager] Error in handleStop: $e\n$st');
      // Don't rethrow to prevent crashes, just log the error
    }
  }


  void _handleSetLoop(bool nextIsLooping, Sequence sequence) {
    // Custom playback system handles looping internally
    isTrackLooping = nextIsLooping;
    debugPrint('[SequencerManager] Loop set to: $nextIsLooping');
  }

  handleToggleLoop(bool isLooping, Sequence sequence) {
    final nextIsLooping = !isLooping;

    _handleSetLoop(nextIsLooping, sequence);
  }

  _handleStepCountChange(
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
      _activeNotes.clear();
      
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
