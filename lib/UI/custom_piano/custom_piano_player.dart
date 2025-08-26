import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sequencer/sequence.dart';
import 'package:flutter_sequencer/track.dart';
import 'package:scalemasterguitar/UI/player_page/provider/selected_chords_provider.dart';
import 'package:scalemasterguitar/constants.dart';

import '../../models/scale_model.dart';
import '../../models/step_sequencer_state.dart';
import '../../utils/player_utils.dart';
import '../fretboard/provider/beat_counter_provider.dart';
import '../player_page/logic/sequencer_manager.dart';
import '../player_page/logic/audio_service.dart';
import '../player_page/provider/is_metronome_selected.dart';
import '../player_page/provider/is_playing_provider.dart';
import '../player_page/provider/metronome_tempo_provider.dart';
import 'custom_piano.dart';

class CustomPianoSoundController extends ConsumerStatefulWidget {
  const CustomPianoSoundController(this.scaleModel, {super.key});

  final ScaleModel? scaleModel;

  @override
  CustomPianoState createState() => CustomPianoState();
}

class CustomPianoState extends ConsumerState<CustomPianoSoundController>
    with TickerProviderStateMixin {
  Map<int, StepSequencerState> trackStepSequencerStates = {};
  List<Track> tracks = [];
  Map<int, double> trackVolumes = {};
  Track? selectedTrack;
  Ticker? ticker;
  late SequencerManager sequencerManager;
  double tempo = Constants.INITIAL_TEMPO;
  double position = 0.0;
  late bool isPlaying;
  late Sequence sequence;
  Map<String, dynamic> sequencer = {};
  late bool isLoading;
  String? _lastKeyboardSound; // Track the last keyboard sound setting
  
  // Use AudioService singleton for proper audio lifecycle management
  AudioService get _audioService => AudioService();

  @override
  void initState() {
    super.initState();
    sequencerManager = ref.read(sequencerManagerProvider);
    _lastKeyboardSound = widget.scaleModel?.settings?.keyboardSound;
    initializeSequencer();
  }

  @override
  void didUpdateWidget(CustomPianoSoundController oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if the keyboard sound has changed between widget updates
    final oldKeyboardSound = oldWidget.scaleModel?.settings?.keyboardSound;
    final newKeyboardSound = widget.scaleModel?.settings?.keyboardSound;
    
    if (oldKeyboardSound != newKeyboardSound) {
      debugPrint('[CustomPianoPlayer] Keyboard sound changed in didUpdateWidget: $oldKeyboardSound → $newKeyboardSound');
      _lastKeyboardSound = newKeyboardSound;
      
      // Reinitialize sequencer with new instrument
      Future.microtask(() {
        if (mounted) {
          initializeSequencer();
        }
      });
    }
  }

  Future<void> initializeSequencer() async {
    if (!mounted) return;
    
    // Stop and cleanup existing sequencer first to prevent iOS resource conflicts
    try {
      ticker?.stop();
      ticker?.dispose();
      ticker = null;
      
      if (tracks.isNotEmpty) {
        debugPrint('[CustomPianoPlayer] Cleaning up ${tracks.length} existing tracks before reinitializing');
        // Stop any active notes and clear tracks
        await sequencerManager.handleStop(sequence);
        tracks.clear();
      }
    } catch (e) {
      debugPrint('[CustomPianoPlayer] Error during cleanup: $e');
    }
    
    setState(() {
      isLoading = true;
    });
    
    isPlaying = ref.read(isSequencerPlayingProvider);
    var stepCount = ref.read(beatCounterProvider).toDouble();
    
    // Initialize AudioService and get properly initialized sequence
    try {
      await _audioService.initialize(
        tempo: tempo, 
        endBeat: stepCount,
        forceReinitialize: true, // Force reinit for piano controller changes
      );
      sequence = _audioService.sequence!;
      debugPrint('[CustomPianoPlayer] AudioService initialized for piano');
    } catch (e) {
      debugPrint('[CustomPianoPlayer] AudioService initialization failed: $e');
      // Fallback to direct sequence creation if AudioService fails
      sequence = Sequence(tempo: tempo, endBeat: stepCount);
    }
    
    debugPrint('[CustomPianoPlayer] Initializing sequencer with keyboard sound: ${widget.scaleModel!.settings!.keyboardSound}');
    
    tracks = await sequencerManager.initialize(
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
        // Removed excessive volume polling - volumes are set once and don't change frequently
        isLoading = false;
      });
    });
    ticker?.start();
    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    debugPrint('[CustomPianoPlayer] Disposing: stopping sequencer and cleaning up tracks');
    try {
      ticker?.stop();
      ticker?.dispose();
      if (sequence != null) {
        sequencerManager.handleStop(sequence);
      }
      tracks.clear();
    } catch (e, st) {
      debugPrint('[CustomPianoPlayer] Error during dispose: $e\n$st');
    }
    super.dispose();
  }

  void handlePianoKeyDown(String noteName) {
    final String widgetContext = 'CustomPianoState.handlePianoKeyDown';
    debugPrint('[$widgetContext] Received KEY DOWN for note: $noteName');
    // Ensure sequence and tracks are initialized and not empty
    if (sequence != null && tracks.isNotEmpty) {
      sequencerManager.playPianoNote(noteName, tracks, sequence);
    } else {
      debugPrint('[$widgetContext] Sequence is null or tracks are empty, cannot play note.');
    }
  }

  void handlePianoKeyUp(String noteName) {
    final String widgetContext = 'CustomPianoState.handlePianoKeyUp';
    debugPrint('[$widgetContext] Received KEY UP for note: $noteName');
    // Ensure sequence and tracks are initialized and not empty
    if (sequence != null && tracks.isNotEmpty) {
      sequencerManager.stopPianoNote(noteName, tracks, sequence);
    } else {
      debugPrint('[$widgetContext] Sequence is null or tracks are empty, cannot stop note.');
    }
  }

  @override
  Widget build(BuildContext context) {
    
    // debugPrint("tracks: \${tracks[0]}");
    // return CustomPianoTest(
    //   widget.scaleModel,
    //   onKeyPressed: (note) =>
    //       sequencerManager.playPianoNote(note, tracks, sequence),
    // );
    return CustomPiano(
      widget.scaleModel,
      // onKeyPressed: (note) => Debouncer.handleButtonPress(() { // Old
      //   sequencerManager.playPianoNote(note, tracks, sequence);
      // }),
      onKeyDown: handlePianoKeyDown, // New
      onKeyUp: handlePianoKeyUp,     // New
    );
  }
}
