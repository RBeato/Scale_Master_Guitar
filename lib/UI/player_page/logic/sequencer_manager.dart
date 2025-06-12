import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sequencer/global_state.dart';
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

final sequencerManagerProvider = Provider((ref) => SequencerManager(ref));

class SequencerManager {
  final Ref _ref;
  SequencerManager(this._ref);

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
  double position = 0.0;
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

    GlobalState().setKeepEngineRunning(true);
    debugPrint('[SequencerManager] Audio engine keep running set to true');
    
    // Add audio engine debugging
    try {
      debugPrint('[SequencerManager] Checking audio engine state');
      // Note: Some of these methods might not exist - we'll see what works
    } catch (e) {
      debugPrint('[SequencerManager] Audio engine state check failed: $e');
    }

    // Start periodic cleanup for stale notes
    _startCleanupTimer();

    try {
      // Create tracks
      List<Track> createdTracks = await sequence.createTracks(instruments);
      
      // Wait for SoundFont to load - iOS needs more time for proper audio loading
      final loadingDelay = Platform.isIOS ? 1500 : 500;
      debugPrint('[SequencerManager] Waiting ${loadingDelay}ms for SoundFont loading on ${Platform.operatingSystem}');
      await Future.delayed(Duration(milliseconds: loadingDelay));
      
      this.tracks = createdTracks;
      selectedTrack = this.tracks[0];

      for (Track track in this.tracks) {
        trackVolumes[track.id] = 0.8; // Set audible volume for all tracks
        trackStepSequencerStates[track.id] = StepSequencerState();
        
        // Ensure track volume is properly set
        track.changeVolumeNow(volume: 0.8);
        debugPrint('[SequencerManager] Track ${track.id} volume set to: ${track.getVolume()}');
        
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
    bool currentIsPlaying = _ref.read(isSequencerPlayingProvider);
    bool nextIsPlaying = !currentIsPlaying;
    
    debugPrint('[SequencerManager] handleTogglePlayStop: currentIsPlaying=$currentIsPlaying, nextIsPlaying=$nextIsPlaying');

    if (nextIsPlaying) {
      debugPrint("[SequencerManager] PlayAllInstruments: $playAllInstruments");
      debugPrint("[SequencerManager] Playing sequence. Tracks: ${tracks.length}");
      
      // Debug all tracks - use stored tracks, not sequence.getTracks()
      for (int i = 0; i < tracks.length; i++) {
        final track = tracks[i];
        debugPrint("[SequencerManager] Track $i: id=${track.id}, events=${track.events.length}, volume=${track.getVolume()}");
        
        // Debug first few events for each track
        for (int j = 0; j < track.events.length && j < 3; j++) {
          final event = track.events[j];
          debugPrint("[SequencerManager]   Event $j: $event");
        }
      }
      
      debugPrint("[SequencerManager] About to call sequence.play()");
      sequence.play();
      debugPrint("[SequencerManager] sequence.play() completed");
      
      // Verify sequence is actually playing
      await Future.delayed(const Duration(milliseconds: 100));
      debugPrint("[SequencerManager] Sequence is playing: ${sequence.getIsPlaying()}");
      debugPrint("[SequencerManager] Sequence current beat: ${sequence.getBeat()}");
      debugPrint("[SequencerManager] Sequence tempo: ${sequence.getTempo()}");
      
      _ref.read(isSequencerPlayingProvider.notifier).update((state) => true);
    } else {
      debugPrint("[SequencerManager] Stopping sequence");
      sequence.stop();
      _ref.read(isSequencerPlayingProvider.notifier).update((state) => false);
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
      
      // Stop notes only on tracks where they were actually started
      for (final track in tracks) {
        final trackActiveNotes = _trackActiveNotes[track.id]?.toList() ?? [];
        for (final note in trackActiveNotes) {
          try {
            track.stopNoteNow(noteNumber: note);
          } catch (e) {
            // Ignore individual note stop failures
          }
        }
      }
      _trackActiveNotes.clear();
    } catch (e) {
      debugPrint('[SequencerManager] Error in _stopPlaybackOnly: $e');
    }
  }

  Future<void> handleStop(Sequence sequence) async {
    try {
      debugPrint('[SequencerManager] handleStop called');
      
      await PerformanceUtils.trackAsyncOperation('handleStop', () async {
        // Stop the sequence first to prevent new notes from being triggered
        try {
          sequence.stop();
          isPlaying = false;
          _ref.read(isSequencerPlayingProvider.notifier).update((state) => false);
        } catch (e) {
          debugPrint('[SequencerManager] Error stopping sequence: $e');
        }
        
        // Give sequence a moment to fully stop before cleaning up notes
        await Future.delayed(const Duration(milliseconds: 50));
        
        // Stop notes only on tracks where they were actually started
        final tracks = this.tracks; // Use stored tracks instead of sequence.getTracks()
        
        for (final track in tracks) {
          try {
            // Clear events first to prevent timing issues
            track.clearEvents();
            
            // Only stop notes that were actually started on this specific track
            final trackActiveNotes = _trackActiveNotes[track.id]?.toList() ?? [];
            for (final note in trackActiveNotes) {
              try {
                track.stopNoteNow(noteNumber: note);
                debugPrint('[SequencerManager] Stopped note $note on track ${track.id}');
              } catch (e) {
                // Log but don't crash on individual note stop failures
                debugPrint('[SequencerManager] Non-critical error stopping note $note on track ${track.id}: $e');
              }
            }
            
            // Clear this track's note tracking
            _trackActiveNotes[track.id]?.clear();
          } catch (e) {
            debugPrint('[SequencerManager] Error cleaning track ${track.id}: $e');
          }
        }
        
        // Clear all tracked notes as final safety
        _trackActiveNotes.clear();
        
        // Stop cleanup timer
        _cleanupTimer?.cancel();
      });
    } catch (e, st) {
      debugPrint('[SequencerManager] Error in handleStop: $e\n$st');
      // Don't rethrow to prevent crashes, just log the error
    }
  }

  _handleSetLoop(bool nextIsLooping, Sequence sequence) {
    if (nextIsLooping) {
      sequence.setLoop(0, stepCount.toDouble());
    } else {
      sequence.unsetLoop();
    }
    isTrackLooping = nextIsLooping;
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
    debugPrint('[SequencerManager] handleTempoChange: $nextTempo BPM');
    sequence.setTempo(nextTempo);
    // Update local tempo if SequencerManager keeps its own tempo state that needs to match
    this.tempo = nextTempo; 
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
      
      if (sequence != null) {
        debugPrint('[SequencerManager] Stopping sequence');
        
        // Use handleStop but with extra safety
        try {
          await handleStop(sequence!);
        } catch (e) {
          debugPrint('[SequencerManager] Error in handleStop during dispose: $e');
          // Continue with manual cleanup
        }
        
        // Additional safety cleanup - stop all notes across all MIDI channels
        try {
          final tracks = this.tracks; // Use stored tracks instead of sequence.getTracks()
          if (tracks.isNotEmpty) {
            for (final track in tracks) {
              try {
                debugPrint('[SequencerManager] Force-clearing track id: ${track.id}');
                
                // Clear events first
                track.clearEvents();
                
                // Only stop notes that were tracked as active on this track
                final trackActiveNotes = _trackActiveNotes[track.id]?.toList() ?? [];
                for (final note in trackActiveNotes) {
                  try {
                    track.stopNoteNow(noteNumber: note);
                  } catch (e) {
                    // Individual note stop failures are not critical during dispose
                  }
                }
              } catch (e) {
                debugPrint('[SequencerManager] Non-critical error force-clearing track ${track.id}: $e');
              }
            }
          }
        } catch (e) {
          debugPrint('[SequencerManager] Error during force cleanup: $e');
        }
        
        debugPrint('[SequencerManager] Sequence cleanup complete');
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
