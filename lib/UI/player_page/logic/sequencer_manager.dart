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
    this.isMetronomeSelected = isMetronomeSelected;

    try {
      // Initialize AudioService with sequence parameters
      await _audioService.initialize(
        tempo: tempo,
        endBeat: stepCount.toDouble(),
        forceReinitialize: false,
      );

      this.sequence = _audioService.sequence!;
    } catch (e, stackTrace) {
      debugPrint('[SequencerManager] AudioService init failed: $e\n$stackTrace');
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
        for (int i = 0; i < this.tracks.length; i++) {
          final currentInstrument = this.tracks[i].instrument;
          final newInstrument = instruments[i];

          if (currentInstrument.idOrPath != newInstrument.idOrPath ||
              currentInstrument.presetIndex != newInstrument.presetIndex) {
            needsRecreation = true;
            break;
          }
        }
      }

      final shouldReuseExistingTracks = !needsRecreation;

      if (shouldReuseExistingTracks) {
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
          // Note: we intentionally do NOT call NativeBridge.resetTrack() here.
          // AudioUnitReset races with the audio render thread processing the
          // noteOff events we just sent, causing a crash in the AUSampler's
          // memory deallocator. Sending 128 noteOffs + clearEvents is sufficient
          // to reset the track state without the dangerous native reset.
        }
      } else {
        // Stop and clear old tracks before creating new ones
        if (this.tracks.isNotEmpty) {
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
        this.tracks = createdTracks;
      }
      selectedTrack = this.tracks[0];

      for (int i = 0; i < this.tracks.length; i++) {
        Track track = this.tracks[i];
        trackVolumes[track.id] = 0.54;
        trackStepSequencerStates[track.id] = StepSequencerState();
        track.changeVolumeNow(volume: 0.54);
      }

      // Create project state
      ProjectState? project = await _createProject(
        selectedChords: selectedChords,
        stepCount: stepCount,
        nBeats: stepCount,
        playAllInstruments: playAllInstruments,
      );

      loadProjectState(project!, this.tracks, this.sequence!);
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

    for (int i = 0; i < selectedChords.length; i++) {
      ChordModel chord = selectedChords[i];

      if (chord.chordNotesInversionWithIndexes == null || chord.chordNotesInversionWithIndexes!.isEmpty) {
        continue;
      }

      for (var note in chord.chordNotesInversionWithIndexes!) {
        final midiValue = MusicConstants.midiValues[note];
        if (midiValue != null) {
          project.pianoState.setVelocity(chord.position, midiValue, 0.68);
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
      project.bassState.setVelocity(chord.position, bassMidiValue, 0.68);
    }

    if (isMetronomeSelected && playAllInstruments) {
      for (int i = 0; i < nBeats; i++) {
        project.drumState.setVelocity(i, 44, 0.53); // Hi-hat (Pedal Hi-Hat in GM)
      }
    }
    return project;
  }

  Future<void> playPianoNote(String note, List<Track> tracks, Sequence sequence) async {
    final midiValue = MusicConstants.midiValues[MusicUtils.filterNoteNameWithSlash(note)]!;

    if (_noteOperationInProgress) return;
    if (tracks.length <= 1) return;

    final pianoTrack = tracks[1];
    final trackId = pianoTrack.id;

    _noteOperationInProgress = true;
    try {
      _trackActiveNotes.putIfAbsent(trackId, () => <int>{});
      if (_trackActiveNotes[trackId]!.contains(midiValue)) return;

      pianoTrack.startNoteNow(noteNumber: midiValue, velocity: 0.63);
      _trackActiveNotes[trackId]!.add(midiValue);
    } catch (e) {
      debugPrint('[SequencerManager] Error starting note $midiValue: $e');
    } finally {
      _noteOperationInProgress = false;
    }
  }

  Future<void> stopPianoNote(String note, List<Track> tracks, Sequence sequence) async {
    final midiValue = MusicConstants.midiValues[MusicUtils.filterNoteNameWithSlash(note)]!;

    if (_noteOperationInProgress) return;
    if (tracks.length <= 1) return;

    final pianoTrack = tracks[1];
    final trackId = pianoTrack.id;

    _noteOperationInProgress = true;
    try {
      _trackActiveNotes.putIfAbsent(trackId, () => <int>{});
      if (!_trackActiveNotes[trackId]!.contains(midiValue)) return;

      pianoTrack.stopNoteNow(noteNumber: midiValue);
      _trackActiveNotes[trackId]!.remove(midiValue);
    } catch (e) {
      debugPrint('[SequencerManager] Error stopping note $midiValue: $e');
      _trackActiveNotes[trackId]?.remove(midiValue);
    } finally {
      _noteOperationInProgress = false;
    }
  }

  Future<void> handleTogglePlayStop(Sequence sequence) async {
    if (isPlaying) {
      _stopPlayback(sequence);
    } else {
      _startPlayback(sequence);
    }
  }

  void _startPlayback(Sequence sequence) {

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

    if (!_useNativeScheduling) {
      _playbackTimer = Timer.periodic(const Duration(milliseconds: 1), (timer) {
        _processPlayback(sequence);
      });
    }
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
        _processedEvents.clear();
      }
    }
    _lastProcessedBeat = currentBeat;

    // Process events for iOS Dart scheduling (from working example)
    if (!_useNativeScheduling) {
      _processEventsAtBeat(currentBeat);
    }

    if (!isTrackLooping && currentBeat >= stepCount) {
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
            // CRITICAL: Include midiStatus to distinguish note-on (0x90) from
            // note-off (0x80). Without this, when consecutive chords share a
            // note at their boundary, the note-off and note-on at the same
            // beat get the same key, causing the note-on to be skipped.
            final eventKey = '${track.id}-$_loopCycle-${event.beat}-${event.midiStatus}-${event.midiData1}';

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

  void _stopPlayback(Sequence sequence) {
    _playbackTimer?.cancel();
    _playbackTimer = null;

    sequence.stop();
    sequence.setBeat(0.0);

    try {
      for (final track in tracks) {
        for (int note = 21; note <= 108; note++) {
          try {
            track.stopNoteNow(noteNumber: note);
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint("[SequencerManager] Error stopping notes: $e");
    }

    isPlaying = false;
    isPaused = false;
    position = 0.0;
    _loopCycle = 0;
    _processedEvents.clear();
    _trackActiveNotes.clear();

    _ref.read(isSequencerPlayingProvider.notifier).update((state) => false);
  }

  void _stopAllActiveNotes() {
    // Android: aggressive bulk stop
    if (Platform.isAndroid) {
      for (final track in tracks) {
        try {
          for (int note = 24; note < 97; note++) {
            try { track.stopNoteNow(noteNumber: note); } catch (_) {}
          }
        } catch (_) {}
      }
    }

    // Stop tracked notes
    _trackActiveNotes.forEach((trackId, noteSet) {
      final track = tracks.firstWhere((t) => t.id == trackId, orElse: () => tracks.first);
      for (final noteNumber in noteSet.toList()) {
        try { track.stopNoteNow(noteNumber: noteNumber); } catch (_) {}
      }
      noteSet.clear();
    });

    // Send "All Notes Off" MIDI CC 123 to each track
    for (final track in tracks) {
      try {
        final allNotesOffEvent = MidiEvent(
          beat: 0.0,
          midiStatus: 0xB0,
          midiData1: 123,
          midiData2: 0,
        );
        NativeBridge.handleEventsNow(
          track.id, [allNotesOffEvent], GlobalState().sampleRate!, tempo,
        );
      } catch (_) {}
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

    } catch (e, st) {
      debugPrint('[SequencerManager] Error in handleStop: $e\n$st');
      // Don't rethrow to prevent crashes, just log the error
    }
  }

  void _handleSetLoop(bool nextIsLooping, Sequence sequence) {
    if (nextIsLooping) {
      sequence.setLoop(0, stepCount.toDouble());
    } else {
      sequence.unsetLoop();
    }
    isTrackLooping = nextIsLooping;
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
    if (nextTempo <= 0) return;
    tempo = nextTempo;

    if (isPlaying) {
      final currentBeat = sequence.getBeat();

      // Update tempo (adjusts engineStartFrame and frame calculations)
      sequence.setTempo(nextTempo);

      // Force clear ALL native buffers so stale events at old tempo are removed
      for (var track in tracks) {
        track.clearBuffer();
      }

      // Re-sync from current beat position — this re-schedules all events
      // using the new tempo via beatToFrames()
      sequence.setBeat(currentBeat);

      // Clear processed events so Dart-dispatch (iOS) can retrigger correctly
      _processedEvents.clear();
    } else {
      sequence.setTempo(nextTempo);
    }
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
    // Periodic check — no-op unless stale notes need clearing
  }

  Future<void> dispose() async {
    try {
      _cleanupTimer?.cancel();
      _cleanupTimer = null;
      _playbackTimer?.cancel();
      _playbackTimer = null;
      _processedEvents.clear();

      if (sequence != null) {
        try { await handleStop(sequence!); } catch (_) {}
      }

      try { await _audioService.dispose(); } catch (_) {}

      trackStepSequencerStates.clear();
      trackVolumes.clear();
      _trackActiveNotes.clear();
      _lastChords.clear();
      _processedEvents.clear();
    } catch (e) {
      debugPrint('[SequencerManager] Error during dispose: $e');
    }
  }
}
