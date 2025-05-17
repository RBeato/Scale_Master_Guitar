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

final sequencerManagerProvider = Provider((ref) => SequencerManager());

class SequencerManager {
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
    ref,
    tracks,
    sequence,
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
        ref: ref,
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
    required WidgetRef ref,
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

      var index = ref.read(bassNoteIndexProvider);

      if (i > 0) {
        index = MusicUtils.calculateIndexForBassNote(
          MusicUtils.extractNoteName(selectedChords[i - 1].completeChordName!),
          note,
          index,
        );
        ref.read(bassNoteIndexProvider.notifier).update((state) => index);
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
    final midiValue = MusicConstants.midiValues[MusicUtils.filterNoteNameWithSlash(note)]!;
    final pianoTrack = tracks[1];

    // Add note to active set
    _activeMidiNotes.add(midiValue);

    // Clear only the events, not the state, to avoid duplicate notes
    pianoTrack.events.clear();
    trackStepSequencerStates[pianoTrack.id]!.clear();

    // Add all currently active notes
    for (final midi in _activeMidiNotes) {
      trackStepSequencerStates[pianoTrack.id]!.setVelocity(0, midi, 0.60);
    }

    _syncTrack(pianoTrack);

    // Only start playing if not already playing
    if (!sequence.getIsPlaying()) {
      sequence.play();
    }
  }

  // Call this on key release (you'll need to wire this up in the UI)
  void stopPianoNote(String note, List<Track> tracks, Sequence sequence) {
    final midiValue = MusicConstants.midiValues[MusicUtils.filterNoteNameWithSlash(note)]!;
    final pianoTrack = tracks[1];

    _activeMidiNotes.remove(midiValue);

    pianoTrack.events.clear();
    trackStepSequencerStates[pianoTrack.id]!.clear();

    for (final midi in _activeMidiNotes) {
      trackStepSequencerStates[pianoTrack.id]!.setVelocity(0, midi, 0.60);
    }

    _syncTrack(pianoTrack);

    // If no notes are left, stop the sequence
    if (_activeMidiNotes.isEmpty) {
      sequence.stop();
    }
  }

  handleTogglePlayStop(WidgetRef ref, Sequence sequence) {
    ref.read(isSequencerPlayingProvider.notifier).update((state) => !state);
    bool isPlaying = ref.read(isSequencerPlayingProvider);

    if (!isPlaying) {
      sequence.stop();
      ref.read(isSequencerPlayingProvider.notifier).update((state) => false);
    } else {
      var tracks = sequence.getTracks();
      debugPrint("PlayAllInstruments: $playAllInstruments");
      debugPrint("Playing sequence. Tracks: ${tracks.length}");
      if (tracks.length > 2) {
        debugPrint("Bass track events: ${tracks[2].events.length}");
        // debugPrint("Bass track volume: ${trackVolumes[tracks[2].id]}");
        debugPrint("Bass track volume: ${tracks[2].getVolume()}");
      } else {
        debugPrint("Not enough tracks available");
      }
      sequence.play();
    }
  }

  handleStop(Sequence sequence) {
    sequence.stop();
    // ref.read(isSequencerPlayingProvider.notifier).update((state) => !state);
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

  _handleTempoChange(double nextTempo, Sequence sequence) {
    if (nextTempo <= 0) return;
    sequence.setTempo(nextTempo);
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

  _syncTrack(track) {
    track.clearEvents();
    trackStepSequencerStates[track.id]!
        .iterateEvents((step, noteNumber, velocity) {
      if (step < stepCount) {
        track.addNote(
            noteNumber: noteNumber,
            velocity: velocity,
            startBeat: step.toDouble(),
            durationBeats: 1.0);
      }
    });
    track.syncBuffer();
  }

  loadProjectState(
      ProjectState projectState, List<Track> tracks, Sequence sequence) {
    handleStop(sequence);

    trackStepSequencerStates[tracks[0].id] = projectState.drumState;
    trackStepSequencerStates[tracks[1].id] = projectState.pianoState;
    trackStepSequencerStates[tracks[2].id] = projectState.bassState;

    _handleStepCountChange(projectState.stepCount, tracks, sequence);
    _handleTempoChange(tempo, sequence);
    _handleSetLoop(projectState.isLooping, sequence);

    _syncTrack(tracks[0]);
    _syncTrack(tracks[1]);
    _syncTrack(tracks[2]);
  }

  clearTracks(ref, List<Track> tracks, Sequence sequence) {
    sequence.stop();
    ref.read(isSequencerPlayingProvider.notifier).update((state) => false);
    if (tracks.isNotEmpty) {
      trackStepSequencerStates[tracks[0].id] = StepSequencerState();
      _syncTrack(tracks[0]);
      if (ref != null) {
        ref.read(selectedChordsProvider.notifier).removeAll();
      }
    }
  }

  void clearEverything(List<Track> tracks, Sequence sequence) {
    sequence.stop();
    for (var track in tracks) {
      trackStepSequencerStates[track.id] = StepSequencerState();
      _syncTrack(track);
    }
    tracks.clear(); // Clear all tracks
    _handleStepCountChange(0, tracks, sequence); // Reset the step count to 0
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
