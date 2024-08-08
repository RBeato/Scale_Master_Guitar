import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/material.dart';

import 'package:flutter_sequencer/sequence.dart';
import 'package:flutter_sequencer/track.dart';
import 'package:flutter/scheduler.dart';
import 'package:test/UI/player_page/logic/sequencer_manager.dart';
import 'package:test/UI/player_page/provider/selected_chords_provider.dart';
import 'package:test/utils/player_utils.dart';

import '../../../constants.dart';
import '../../../models/settings_model.dart';
import '../../../models/step_sequencer_state.dart';
import '../../fretboard/provider/beat_counter_provider.dart';

import '../../utils/debouncing.dart';
import '../provider/is_metronome_selected.dart';
import '../provider/metronome_tempo_provider.dart';
import '../provider/is_playing_provider.dart';
import 'chord_player_bar.dart';

class PlayerWidget extends ConsumerStatefulWidget {
  const PlayerWidget(
    this.settings, {
    super.key,
  });

  final Settings settings;

  @override
  PlayerPageShowcaseState createState() => PlayerPageShowcaseState();
}

class PlayerPageShowcaseState extends ConsumerState<PlayerWidget>
    with SingleTickerProviderStateMixin {
  Map<int, StepSequencerState> trackStepSequencerStates = {};
  List<Track> tracks = [];
  Map<int, double> trackVolumes = {};
  // Track? selectedTrack;
  late Ticker ticker;
  SequencerManager sequencerManager = SequencerManager();
  double tempo = Constants.INITIAL_TEMPO;
  double position = 0.0;
  late bool isPlaying;
  bool isLooping = Constants.INITIAL_IS_LOOPING;
  late Sequence sequence;
  Map<String, dynamic> sequencer = {};
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    initializeSequencer();
  }

  Future<void> initializeSequencer() async {
    setState(() {
      isLoading = true;
    });

    // Initialize sequencer manager
    isPlaying = ref.read(isSequencerPlayingProvider);
    sequencerManager = ref.read(sequencerManagerProvider);
    var stepCount = ref.read(beatCounterProvider).toDouble();

    sequence = Sequence(tempo: tempo, endBeat: stepCount);
    // print("selectedTrack ${selectedTrack.hashCode}");
    // Initialize sequencer and tracks
    tracks = await sequencerManager.initialize(
      ref: ref,
      tracks: tracks,
      sequence: sequence,
      playAllInstruments: true,
      instruments: SoundPlayerUtils.getInstruments(widget.settings),
      isPlaying: ref.read(isSequencerPlayingProvider),
      stepCount: ref.read(beatCounterProvider),
      trackVolumes: trackVolumes,
      trackStepSequencerStates: trackStepSequencerStates,
      selectedChords: ref.read(selectedChordsProvider),
      isLoading: isLoading,
      isMetronomeSelected: ref.read(isMetronomeSelectedProvider),
      isScaleTonicSelected: widget.settings.isTonicUniversalBassNote,
      tempo: ref.read(metronomeTempoProvider),
    );

    // Start ticker
    ticker = createTicker((Duration elapsed) {
      setState(() {
        tempo = ref.read(metronomeTempoProvider); //sequence.getTempo();

        position = sequence.getBeat();
        isPlaying = sequence.getIsPlaying();

        ref
            .read(currentBeatProvider.notifier)
            .update((state) => position.toInt());

        for (var track in tracks) {
          trackVolumes[track.id] = track.getVolume();
        }
        setState(() {
          isLoading = false;
        });
      });
    });
    ticker.start();
  }

  Future<void> getSequencer() async {
    tracks = await sequencerManager.initialize(
      ref: ref,
      tracks: tracks,
      sequence: sequence,
      playAllInstruments: true,
      instruments: SoundPlayerUtils.getInstruments(widget.settings),
      isPlaying: ref.read(isSequencerPlayingProvider),
      stepCount: ref.read(beatCounterProvider),
      trackVolumes: trackVolumes,
      trackStepSequencerStates: trackStepSequencerStates,
      selectedChords: ref.read(selectedChordsProvider),
      // selectedTrack: selectedTrack,
      isLoading: isLoading,
      isMetronomeSelected: ref.read(isMetronomeSelectedProvider),
      isScaleTonicSelected: widget.settings.isTonicUniversalBassNote,
      tempo: ref.read(metronomeTempoProvider),
    );
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    isPlaying = ref.watch(isSequencerPlayingProvider);
    if (!isPlaying) {
      sequencerManager.handleStop(sequence);
    }
    final selectedChords = ref.watch(selectedChordsProvider);
    ref.watch(metronomeTempoProvider);

    final isMetronomeSelected = ref.watch(isMetronomeSelectedProvider);

    updateSequencer(
      selectedChords,
      isMetronomeSelected,
    );

    return ChordPlayerBar(
      selectedTrack: tracks.isEmpty ? null : tracks[0],
      isLoading: isLoading,
      isPlaying: isPlaying,
      tempo: ref.read(metronomeTempoProvider),
      isLooping: isLooping,
      clearTracks: () {
        Debouncer.handleButtonPress(() {
          sequencerManager.clearTracks(ref, tracks, sequence);
        });
      },
      handleTogglePlayStop: () {
        Debouncer.handleButtonPress(() {
          sequencerManager.handleTogglePlayStop(ref, sequence);
        });
      },
    );
  }

  updateSequencer(
    List selectedChords,
    bool isMetronomeSelected,
  ) {
    if (sequencerManager.needToUpdateSequencer(
      sequence,
      selectedChords,
      tempo,
      widget.settings.isTonicUniversalBassNote,
      isMetronomeSelected,
    )) {
      setState(() {
        isLoading = true; // Set loading flag to true when initialization starts
      });

      //add new chords to sequence.
      getSequencer();
      // selectedTrack = tracks[0];
      setState(() {
        isLoading = false;
      });
    }
  }
}
