import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sequencer/global_state.dart';
import 'package:flutter_sequencer/models/instrument.dart';
import 'package:flutter_sequencer/sequence.dart';
import 'package:flutter_sequencer/track.dart';
import 'package:test/constants/general_audio_constants.dart';
import 'package:test/models/project_state.dart';

import '../../../constants/music_constants.dart';
import '../../../models/chord_model.dart';
import '../../../models/step_sequencer_state.dart';
import '../../../utils/music_utils.dart';
import '../provider/bass_note_index_provider.dart';
import '../provider/is_playing_provider.dart';
import '../provider/selected_chords_provider.dart';
import 'package:collection/collection.dart';
import '../../../utils/player_utils.dart';
import '../../../constants/gm_programs.dart';

final sequencerManagerProvider = Provider((ref) => SequencerManager(ref));

class SequencerManager {
  final Ref _ref;
  SequencerManager(this._ref);

  Map<int, StepSequencerState> trackStepSequencerStates = {};
  // List<Track> tracks = [];
  late Sequence sequence;
  List _lastChords = [];
  // final List _lastExtensions = [];
  bool _lastTonicAsUniversalBassNote = true;
  bool tonicAsUniversalBassNote = true;
  bool _lastMetronomeSelected = false;
  bool isMetronomeSelected = false;
  Map<int, double> trackVolumes = {};
  // Track? selectedTrack;
  double _lastTempo = Constants.INITIAL_TEMPO;
  double tempo = Constants.INITIAL_TEMPO;
  double position = 0.0;
  bool isPlaying = false;
  bool isTrackLooping = true;
  int stepCount = 0;
  bool isLoading = false;
  bool playAllInstruments = true;

  // Add a set to keep track of currently pressed notes
  final Set<int> _activeMidiNotes = {};

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

    try {
      // Create tracks
      List<Track> createdTracks = await sequence.createTracks(instruments);
      // Wait for SoundFont to load (workaround for plugin race condition)
      await Future.delayed(const Duration(milliseconds: 500));
      tracks = createdTracks;
      selectedTrack = tracks[0];

      for (Track track in tracks) {
        trackVolumes[track.id] =
            1.0; // Set maximum initial volume for all tracks
        trackStepSequencerStates[track.id] = StepSequencerState();
      }

      // Create project state
      ProjectState? project = await _createProject(
        selectedChords: selectedChords,
        stepCount: stepCount,
        nBeats: stepCount,
        playAllInstruments: playAllInstruments,
      );

      // Load project state
      loadProjectState(project!, tracks, sequence);
    } catch (e, stackTrace) {
      debugPrint('Error during initialization: $e');
      debugPrint(stackTrace.toString());
      // Handle the error as needed
    }
    return tracks;
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
      debugPrint("Chord: $chord");
      for (var note in chord.chordNotesInversionWithIndexes!) {
        project.pianoState.setVelocity(
            chord.position, MusicConstants.midiValues[note]!, 0.89);
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

    if (isMetronomeSelected && playAllInstruments) {
      for (int i = 0; i < nBeats; i++) {
        project.drumState.setVelocity(i, 44, 0.59);
      }
    }
    return project;
  }

  void playPianoNote(String note, List<Track> tracks, Sequence sequence) {
    final String method = 'SequencerManager.playPianoNote';
    final midiValue = MusicConstants.midiValues[MusicUtils.filterNoteNameWithSlash(note)]!;
    // Ensure tracks list is not empty and has the piano track at the expected index
    if (tracks.length <= 1) {
      debugPrint('[$method] Tracks list too short or piano track not available (length: \${tracks.length}). Cannot play note $note.');
      return;
    }
    final pianoTrack = tracks[1]; // Assuming piano is always track 1

    debugPrint('[$method] CALLED - Note: $note, MIDI: $midiValue. Current _activeMidiNotes: $_activeMidiNotes');

    if (_activeMidiNotes.contains(midiValue)) {
      debugPrint('[$method] Note $midiValue already in _activeMidiNotes. SKIPPING startNoteNow.');
      return;
    }
    _activeMidiNotes.add(midiValue);
    debugPrint('[$method] Added $midiValue to _activeMidiNotes. Current: $_activeMidiNotes');

    try {
      final Stopwatch stopwatch = Stopwatch()..start();
      pianoTrack.startNoteNow(noteNumber: midiValue, velocity: 0.60);
      stopwatch.stop();
      debugPrint('[$method] COMPLETED - pianoTrack.startNoteNow for $midiValue. Duration: \${stopwatch.elapsedMicroseconds} us.');
    } catch (e, stackTrace) {
      debugPrint('[$method] ERROR calling pianoTrack.startNoteNow for $midiValue: $e\\n$stackTrace');
    }
  }

  void stopPianoNote(String note, List<Track> tracks, Sequence sequence) {
    final String method = 'SequencerManager.stopPianoNote';
    final midiValue = MusicConstants.midiValues[MusicUtils.filterNoteNameWithSlash(note)]!;
    // Ensure tracks list is not empty and has the piano track at the expected index
    if (tracks.length <= 1) {
      debugPrint('[$method] Tracks list too short or piano track not available (length: \${tracks.length}). Cannot stop note $note.');
      return;
    }
    final pianoTrack = tracks[1]; // Assuming piano is always track 1

    debugPrint('[$method] CALLED - Note: $note, MIDI: $midiValue. Current _activeMidiNotes: $_activeMidiNotes');

    if (!_activeMidiNotes.contains(midiValue)) {
      debugPrint('[$method] Note $midiValue was NOT in _activeMidiNotes. SKIPPING stopNoteNow (might have been stopped already or never started).');
      return;
    }
    _activeMidiNotes.remove(midiValue);
    debugPrint('[$method] Removed $midiValue from _activeMidiNotes. Current: $_activeMidiNotes');

    try {
      final Stopwatch stopwatch = Stopwatch()..start();
      pianoTrack.stopNoteNow(noteNumber: midiValue);
      stopwatch.stop();
      debugPrint('[$method] COMPLETED - pianoTrack.stopNoteNow for $midiValue. Duration: \${stopwatch.elapsedMicroseconds} us.');
    } catch (e, stackTrace) {
      debugPrint('[$method] ERROR calling pianoTrack.stopNoteNow for $midiValue: $e\\n$stackTrace');
    }
  }

  handleTogglePlayStop(Sequence sequence) {
    bool currentIsPlaying = _ref.read(isSequencerPlayingProvider);
    bool nextIsPlaying = !currentIsPlaying;

    if (nextIsPlaying) {
      var tracks = sequence.getTracks();
      debugPrint("PlayAllInstruments: $playAllInstruments");
      debugPrint("Playing sequence. Tracks: ${tracks.length}");
      if (tracks.length > 2) {
        debugPrint("Bass track events: ${tracks[2].events.length}");
        debugPrint("Bass track volume: ${tracks[2].getVolume()}");
      } else {
        debugPrint("Not enough tracks available");
      }
      sequence.play();
      _ref.read(isSequencerPlayingProvider.notifier).update((state) => true);
    } else {
      sequence.stop();
      _ref.read(isSequencerPlayingProvider.notifier).update((state) => false);
    }
  }

  handleStop(Sequence sequence) {
    sequence.stop();
    _ref.read(isSequencerPlayingProvider.notifier).update((state) => false);
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

    // Determine track purpose - A more robust mapping should ideally be established during track creation.
    // For now, assuming IDs based on common order: 0=Drums, 1=Piano, 2=Bass.
    // This requires tracks to be created in a consistent order and IDs assigned sequentially by the plugin.
    // These IDs would ideally come from constants or a mapping established in `initialize`.
    const int assumedDrumsTrackId = 0;
    const int assumedPianoTrackId = 1;
    const int assumedBassTrackId = 2;

    bool isDrumTrack = track.id == assumedDrumsTrackId;
    bool isPianoTrack = track.id == assumedPianoTrackId;
    bool isBassTrack = track.id == assumedBassTrackId;

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
    handleStop(sequence);

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
    sequence.stop();
    for (var track in tracksToClear) {
      trackStepSequencerStates[track.id] = StepSequencerState();
      _syncTrack(track);
    }
    tracksToClear.clear(); // Clear all tracks
    _handleStepCountChange(0, tracksToClear, sequence); // Reset the step count to 0
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

  void dispose() {
    debugPrint('[SequencerManager] Disposing: stopping sequence and clearing resources');
    try {
      if (sequence != null) {
        debugPrint('[SequencerManager] Stopping sequence');
        handleStop(sequence);
        if (sequence.getTracks().isNotEmpty) {
          for (final track in sequence.getTracks()) {
            try {
              debugPrint('[SequencerManager] Would dispose track id: \\${track.id} (no dispose method available)');
            } catch (e) {
              debugPrint('[SequencerManager] Error disposing track: $e');
            }
          }
        }
        debugPrint('[SequencerManager] Would dispose sequence (no dispose method available)');
      }
      trackStepSequencerStates.clear();
      trackVolumes.clear();
      // Optionally clear other state if needed
    } catch (e, st) {
      debugPrint('[SequencerManager] Error during dispose: $e\n$st');
    }
  }
}
