import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sequencer/sequence.dart';
import 'package:flutter_sequencer/track.dart';
import 'package:scalemasterguitar/UI/player_page/provider/is_playing_provider.dart';
import 'package:scalemasterguitar/UI/player_page/provider/selected_chords_provider.dart';
import 'package:scalemasterguitar/constants.dart';

import '../../../models/scale_model.dart';
import '../../../models/settings_model.dart';
import '../../../models/step_sequencer_state.dart';
import '../../../utils/player_utils.dart';
import '../../fretboard/provider/beat_counter_provider.dart';
import '../logic/sequencer_manager.dart';
import '../provider/is_metronome_selected.dart';
import '../provider/metronome_tempo_provider.dart';

class SequencerInitializer extends ConsumerStatefulWidget {
  const SequencerInitializer(this.scaleModel, this.musicPlayer, {super.key});

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
  late SequencerManager sequencerManager;
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
    sequencerManager = ref.read(sequencerManagerProvider);
    initializeSequencer();
  }

  Future<void> initializeSequencer() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });
    isPlaying = ref.read(isSequencerPlayingProvider);
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
    if (!mounted) return;
    ticker = createTicker((Duration elapsed) {
      if (!mounted) return;
      setState(() {
        tempo = 120;
        position = sequence.getBeat();
        isPlaying = sequence.getIsPlaying();
        ref.read(currentBeatProvider.notifier).update((state) => position.toInt());
        for (var track in tracks) {
          trackVolumes[track.id] = track.getVolume();
        }
        isLoading = false;
      });
    });
    ticker.start();
    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    debugPrint('[SequencerInitializer] Disposing: stopping sequencer and cleaning up tracks');
    try {
      if (ticker.isActive) {
        ticker.dispose();
      }
      if (sequence != null) {
        sequencerManager.handleStop(sequence);
      }
      sequencerManager.dispose();
      tracks.clear();
    } catch (e, st) {
      debugPrint('[SequencerInitializer] Error during dispose: $e\n$st');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.musicPlayer;
  }
}
