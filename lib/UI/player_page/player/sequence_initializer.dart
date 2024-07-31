import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sequencer/sequence.dart';
import 'package:flutter_sequencer/track.dart';
import 'package:test/UI/player_page/provider/is_playing_provider.dart';
import 'package:test/UI/player_page/provider/selected_chords_provider.dart';
import 'package:test/constants.dart';

import '../../../models/scale_model.dart';
import '../../../models/settings_model.dart';
import '../../../models/step_sequencer_state.dart';
import '../../../utils/player_utils.dart';
import '../../fretboard/provider/beat_counter_provider.dart';
import '../logic/sequencer_manager.dart';
import '../provider/is_metronome_selected.dart';
import '../provider/metronome_tempo_provider.dart';

class SequencerInitializer extends ConsumerStatefulWidget {
  const SequencerInitializer(this.scaleModel, this.musicPlayer, {Key? key})
      : super(key: key);

  final ScaleModel? scaleModel;
  final Widget musicPlayer;

  @override
  SequencerInitializerState createState() => SequencerInitializerState();
}

class SequencerInitializerState extends ConsumerState<SequencerInitializer>
    with SingleTickerProviderStateMixin {
  Map<int, StepSequencerState> trackStepSequencerStates = {};
  List<Track> tracks = [];
  Map<int, double> trackVolumes = {};
  Track? selectedTrack;
  late Ticker ticker;
  SequencerManager sequencerManager = SequencerManager();
  double tempo = Constants.INITIAL_TEMPO;
  double position = 0.0;
  late bool isPlaying;
  late Sequence sequence;
  Map<String, dynamic> sequencer = {};
  late bool isLoading;
  late Settings settings;

  @override
  void initState() {
    super.initState();
    initializeSequencer();
  }

  Future<void> initializeSequencer() async {
    setState(() {
      isLoading = true;
    });

    isPlaying = ref.read(isSequencerPlayingProvider);
    sequencerManager = ref.read(sequencerManagerProvider);
    var stepCount = ref.read(beatCounterProvider).toDouble();

    sequence = Sequence(tempo: tempo, endBeat: stepCount);

    await sequencerManager.initialize(
        tracks: tracks,
        sequence: sequence,
        playAllInstruments: false,
        instruments: SoundPlayerUtils.getInstruments(
            widget.scaleModel!.settings!,
            onlyKeys: true),
        isPlaying: ref.read(isSequencerPlayingProvider),
        stepCount: ref.read(beatCounterProvider),
        trackVolumes: trackVolumes,
        trackStepSequencerStates: trackStepSequencerStates,
        selectedChords: ref.read(selectedChordsProvider),
        selectedTrack: selectedTrack,
        isLoading: isLoading,
        isMetronomeSelected: ref.read(isMetronomeSelectedProvider),
        isScaleTonicSelected:
            widget.scaleModel!.settings!.isTonicUniversalBassNote,
        tempo: ref.read(metronomeTempoProvider));

    // Start ticker
    ticker = createTicker((Duration elapsed) {
      setState(() {
        tempo = 120;
        //sequence.getTempo();
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

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.musicPlayer;
  }
}
