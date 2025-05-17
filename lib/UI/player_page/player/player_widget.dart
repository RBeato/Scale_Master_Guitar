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
  Ticker? ticker;
  SequencerManager sequencerManager = SequencerManager();
  double tempo = Constants.INITIAL_TEMPO;
  double position = 0.0;
  late bool isPlaying;
  bool isLooping = Constants.INITIAL_IS_LOOPING;
  Sequence? sequence;
  Map<String, dynamic> sequencer = {};
  bool isLoading = false;
  // final Set<String> _uiActivePianoNotes = {}; // No longer needed for sustain logic

  @override
  void initState() {
    super.initState();
    initializeSequencer();
  }

  Future<void> initializeSequencer() async {
    debugPrint('[PlayerWidget] initializeSequencer: called');
    // Dispose old ticker if exists
    if (ticker != null && ticker!.isActive) {
      debugPrint('[PlayerWidget] Disposing old ticker before re-initializing');
      ticker!.dispose();
      ticker = null;
    }
    if (!mounted) return;
    debugPrint('[PlayerWidget] initializeSequencer: start');
    setState(() {
      isLoading = true;
    });
    isPlaying = ref.read(isSequencerPlayingProvider);
    sequencerManager = ref.read(sequencerManagerProvider);
    var stepCount = ref.read(beatCounterProvider).toDouble();
    final selectedChords = ref.read(selectedChordsProvider);
    debugPrint('[PlayerWidget] initializeSequencer: selectedChords.length = \${selectedChords.length}');
    if (selectedChords.isEmpty) {
      debugPrint('[PlayerWidget] initializeSequencer: selectedChords is empty, skipping sequencer initialization');
      setState(() {
        isLoading = false;
      });
      return;
    }
    sequence = Sequence(tempo: tempo, endBeat: stepCount);
    debugPrint('[PlayerWidget] initializeSequencer: calling sequencerManager.initialize');
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
      selectedChords: selectedChords,
      isLoading: isLoading,
      isMetronomeSelected: ref.read(isMetronomeSelectedProvider),
      isScaleTonicSelected: widget.settings.isTonicUniversalBassNote,
      tempo: ref.read(metronomeTempoProvider),
    );
    debugPrint('[PlayerWidget] initializeSequencer: sequencerManager.initialize complete, tracks.length = \${tracks.length}');
    if (!mounted) return;
    debugPrint('[PlayerWidget] initializeSequencer: creating ticker');
    int tickCount = 0;
    ticker = createTicker((Duration elapsed) {
      if (!mounted) return;
      final String tickerContext = 'SequencerInitializer.Ticker';
      final Stopwatch fullTickStopwatch = Stopwatch()..start();

      final Stopwatch beatStopwatch = Stopwatch()..start();
      position = sequence!.getBeat(); // Potentially expensive call
      beatStopwatch.stop();

      isPlaying = sequence!.getIsPlaying(); // Potentially expensive call

      ref.read(currentBeatProvider.notifier).update((state) => position.toInt());

      if (tracks.isNotEmpty) { // Ensure tracks list is not empty before iterating
        final Stopwatch volumesStopwatch = Stopwatch()..start();
        for (var track in tracks) {
          trackVolumes[track.id] = track.getVolume(); // Potentially expensive call
        }
        volumesStopwatch.stop();
      }

      setState(() {
        tempo = ref.read(metronomeTempoProvider);
        position = sequence!.getBeat();
        isPlaying = sequence!.getIsPlaying();
        ref.read(currentBeatProvider.notifier).update((state) => position.toInt());
        for (var track in tracks) {
          trackVolumes[track.id] = track.getVolume();
        }
        isLoading = false;
      });

      fullTickStopwatch.stop();
    });
    ticker!.start();
    debugPrint('[PlayerWidget] initializeSequencer: ticker started');
    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
    debugPrint('[PlayerWidget] initializeSequencer: end');
  }

  Future<void> getSequencer() async {
    debugPrint('[PlayerWidget] getSequencer: start');
    final selectedChords = ref.read(selectedChordsProvider);
    debugPrint('[PlayerWidget] getSequencer: selectedChords.length = \${selectedChords.length}');
    if (selectedChords.isEmpty) {
      debugPrint('[PlayerWidget] getSequencer: selectedChords is empty, skipping sequencer initialization');
      setState(() {
        isLoading = false;
      });
      return;
    }
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
      selectedChords: selectedChords,
      // selectedTrack: selectedTrack,
      isLoading: isLoading,
      isMetronomeSelected: ref.read(isMetronomeSelectedProvider),
      isScaleTonicSelected: widget.settings.isTonicUniversalBassNote,
      tempo: ref.read(metronomeTempoProvider),
    );
    debugPrint('[PlayerWidget] getSequencer: sequencerManager.initialize complete, tracks.length = \${tracks.length}');
    debugPrint('[PlayerWidget] getSequencer: end');
  }

  @override
  void dispose() {
    debugPrint('[PlayerWidget] Disposing: stopping sequencer and cleaning up tracks');
    try {
      if (ticker != null && ticker!.isActive) {
        ticker!.dispose();
        ticker = null;
      }
      if (sequence != null) {
        sequencerManager.handleStop(sequence!);
        // If the plugin exposes a dispose method for sequence or tracks, call it here
        // sequence!.dispose(); // Uncomment if available
      }
      // Optionally clear tracks list for GC
      tracks.clear();
    } catch (e, st) {
      debugPrint('[PlayerWidget] Error during dispose: $e\n$st');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[PlayerWidget] build called');
    isPlaying = ref.watch(isSequencerPlayingProvider);
    if (!isPlaying && sequence != null) {
      debugPrint('[PlayerWidget] Not playing, stopping sequencer');
      sequencerManager.handleStop(sequence!);
    }
    final selectedChords = ref.watch(selectedChordsProvider);
    ref.watch(metronomeTempoProvider);
    final isMetronomeSelected = ref.watch(isMetronomeSelectedProvider);

    ref.listen<List>(selectedChordsProvider, (previous, next) {
      debugPrint('[PlayerWidget] selectedChordsProvider changed: ' + next.toString());
      final isMetronomeSelected = ref.read(isMetronomeSelectedProvider);
      if ((previous == null || previous.isEmpty) && next.isNotEmpty) {
        debugPrint('[PlayerWidget] selectedChordsProvider: chords added to empty list, initializing sequencer');
        initializeSequencer();
      } else {
        updateSequencer(next, isMetronomeSelected);
      }
    });
    ref.listen<bool>(isMetronomeSelectedProvider, (previous, next) {
      debugPrint('[PlayerWidget] isMetronomeSelectedProvider changed: ' + next.toString());
      final selectedChords = ref.read(selectedChordsProvider);
      updateSequencer(selectedChords, next);
    });

    debugPrint('[PlayerWidget] returning ChordPlayerBar');
    return ChordPlayerBar(
      selectedTrack: tracks.isEmpty ? null : tracks[0],
      isLoading: isLoading,
      isPlaying: isPlaying,
      tempo: ref.read(metronomeTempoProvider),
      isLooping: isLooping,
      clearTracks: () {
        debugPrint('[PlayerWidget] clearTracks called');
        Debouncer.handleButtonPress(() {
          if (sequence != null) {
            sequencerManager.clearTracks(ref, tracks, sequence!);
          }
        });
      },
      handleTogglePlayStop: () {
        debugPrint('[PlayerWidget] handleTogglePlayStop called');
        Debouncer.handleButtonPress(() {
          if (sequence != null) {
            sequencerManager.handleTogglePlayStop(ref, sequence!);
          }
        });
      },
    );
  }

  updateSequencer(
    List selectedChords,
    bool isMetronomeSelected,
  ) {
    // Ensure sequence is not null before calling needToUpdateSequencer
    if (sequence == null) {
      debugPrint('[PlayerWidget.updateSequencer] Sequence is null. Skipping update.');
      return;
    }
    if (sequencerManager.needToUpdateSequencer(
      sequence!, // Now safe to use !
      selectedChords,
      tempo,
      widget.settings.isTonicUniversalBassNote,
      isMetronomeSelected,
    )) {
      if (!mounted) return;
      setState(() {
        isLoading = true;
      });
      getSequencer().then((_) {
        if (!mounted) return;
        setState(() {
          isLoading = false;
        });
      });
    }
  }

  void handlePianoKeyDown(String noteName) {
    final String widgetContext = 'PlayerWidget.handlePianoKeyDown';
    debugPrint('[$widgetContext] Received KEY DOWN for note: $noteName');
    if (sequence != null && tracks.isNotEmpty) {
      sequencerManager.playPianoNote(noteName, tracks, sequence!); 
    } else {
      debugPrint('[$widgetContext] Sequence is null or tracks are empty, cannot play note.');
    }
  }

  void handlePianoKeyUp(String noteName) {
    final String widgetContext = 'PlayerWidget.handlePianoKeyUp';
    debugPrint('[$widgetContext] Received KEY UP for note: $noteName');
    if (sequence != null && tracks.isNotEmpty) {
      sequencerManager.stopPianoNote(noteName, tracks, sequence!); 
    } else {
      debugPrint('[$widgetContext] Sequence is null or tracks are empty, cannot stop note.');
    }
  }
}
