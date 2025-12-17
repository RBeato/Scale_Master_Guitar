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
  static int _instanceCounter = 0;
  late final int _instanceId;

  Map<int, StepSequencerState> trackStepSequencerStates = {};
  List<Track> tracks = [];
  Map<int, double> trackVolumes = {};
  Track? selectedTrack;
  Ticker? ticker;
  SequencerManager? sequencerManager;
  double tempo = Constants.INITIAL_TEMPO;
  double position = 0.0;
  bool isPlaying = false;
  Sequence? sequence;
  Map<String, dynamic> sequencer = {};
  bool isLoading = true;
  String? _lastKeyboardSound; // Track the last keyboard sound setting
  bool _isInstrumentChange = false; // Flag to indicate if we're reinitializing due to instrument change

  // Use AudioService singleton for proper audio lifecycle management
  AudioService get _audioService => AudioService();

  CustomPianoState() {
    _instanceId = ++_instanceCounter;
  }

  @override
  void initState() {
    super.initState();
    debugPrint('[CustomPianoPlayer#$_instanceId] initState called');
    _lastKeyboardSound = widget.scaleModel?.settings?.keyboardSound;
    // Initialize sequencerManager immediately, but initialize async parts after frame
    sequencerManager = ref.read(sequencerManagerProvider);
    // Schedule async initialization after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        debugPrint('[CustomPianoPlayer#$_instanceId] PostFrameCallback executing, starting initializeSequencer');
        initializeSequencer();
      } else {
        debugPrint('[CustomPianoPlayer#$_instanceId] PostFrameCallback skipped - widget not mounted');
      }
    });
  }

  @override
  void didUpdateWidget(CustomPianoSoundController oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if the keyboard sound has changed between widget updates
    final oldKeyboardSound = oldWidget.scaleModel?.settings?.keyboardSound;
    final newKeyboardSound = widget.scaleModel?.settings?.keyboardSound;

    if (oldKeyboardSound != newKeyboardSound) {
      debugPrint('[CustomPianoPlayer#$_instanceId] 🎵 Keyboard sound changed in didUpdateWidget: $oldKeyboardSound → $newKeyboardSound');
      _lastKeyboardSound = newKeyboardSound;
      _isInstrumentChange = true; // Set flag to force track recreation

      // Reinitialize sequencer with new instrument
      Future.microtask(() {
        if (mounted) {
          initializeSequencer();
        }
      });
    }
  }

  Future<void> initializeSequencer() async {
    debugPrint('[CustomPianoPlayer#$_instanceId] initializeSequencer START - mounted: $mounted, sequencerManager: ${sequencerManager != null}');

    if (!mounted || sequencerManager == null) {
      debugPrint('[CustomPianoPlayer#$_instanceId] initializeSequencer ABORTED - not mounted or no sequencerManager');
      return;
    }

    // Stop and cleanup existing sequencer first to prevent iOS resource conflicts
    try {
      ticker?.stop();
      ticker?.dispose();
      ticker = null;

      if (tracks.isNotEmpty && sequence != null) {
        debugPrint('[CustomPianoPlayer#$_instanceId] Cleaning up ${tracks.length} existing tracks before reinitializing');
        // Stop any active notes and clear tracks
        await sequencerManager!.handleStop(sequence!);
        tracks.clear();
      }
    } catch (e) {
      debugPrint('[CustomPianoPlayer#$_instanceId] Error during cleanup: $e');
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
    
    debugPrint('[CustomPianoPlayer#$_instanceId] Initializing sequencer with keyboard sound: ${widget.scaleModel!.settings!.keyboardSound}');
    if (_isInstrumentChange) {
      debugPrint('[CustomPianoPlayer#$_instanceId] ⚠️  This is an INSTRUMENT CHANGE - will force track recreation');
    }

    final newTracks = await sequencerManager!.initialize(
        tracks: tracks,
        sequence: sequence!,
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
        tempo: ref.read(metronomeTempoProvider),
        forceRecreateTracksForInstrumentChange: _isInstrumentChange); // Pass the flag!

    // Reset the flag after initialization
    _isInstrumentChange = false;

    if (!mounted) {
      debugPrint('[CustomPianoPlayer#$_instanceId] Widget unmounted after sequencerManager.initialize, aborting');
      return;
    }

    debugPrint('[CustomPianoPlayer#$_instanceId] SequencerManager.initialize returned ${newTracks.length} tracks');

    // Update state with new tracks
    setState(() {
      tracks = newTracks;
    });

    debugPrint('[CustomPianoPlayer#$_instanceId] Tracks updated in state: ${tracks.length} tracks available for piano');

    // Verify tracks in state
    if (tracks.isEmpty) {
      debugPrint('[CustomPianoPlayer#$_instanceId] ⚠️ WARNING: tracks list is EMPTY after setState!');
    } else {
      debugPrint('[CustomPianoPlayer#$_instanceId] ✅ SUCCESS: ${tracks.length} tracks now ready for piano playback');
    }

    ticker = createTicker((Duration elapsed) {
      if (!mounted || sequence == null) return;
      setState(() {
        tempo = 120;
        position = sequence!.getBeat();
        isPlaying = sequence!.getIsPlaying();
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

    debugPrint('[CustomPianoPlayer#$_instanceId] initializeSequencer COMPLETE - tracks.length: ${tracks.length}, isLoading: $isLoading');
  }

  @override
  void dispose() {
    debugPrint('[CustomPianoPlayer#$_instanceId] Disposing: stopping sequencer and cleaning up tracks');
    try {
      ticker?.stop();
      ticker?.dispose();
      if (sequence != null && sequencerManager != null) {
        sequencerManager!.handleStop(sequence!);
      }
      tracks.clear();
    } catch (e, st) {
      debugPrint('[CustomPianoPlayer#$_instanceId] Error during dispose: $e\n$st');
    }
    super.dispose();
  }

  void handlePianoKeyDown(String noteName) {
    debugPrint('[CustomPianoPlayer#$_instanceId.handlePianoKeyDown] Received KEY DOWN for note: $noteName');
    // Ensure sequencerManager, sequence and tracks are initialized and not empty
    if (sequencerManager != null && sequence != null && tracks.isNotEmpty) {
      sequencerManager!.playPianoNote(noteName, tracks, sequence!);
    } else {
      debugPrint('[CustomPianoPlayer#$_instanceId.handlePianoKeyDown] NOT READY. Manager: ${sequencerManager != null}, Sequence: ${sequence != null}, Tracks: ${tracks.length}');
    }
  }

  void handlePianoKeyUp(String noteName) {
    debugPrint('[CustomPianoPlayer#$_instanceId.handlePianoKeyUp] Received KEY UP for note: $noteName');
    // Ensure sequencerManager, sequence and tracks are initialized and not empty
    if (sequencerManager != null && sequence != null && tracks.isNotEmpty) {
      sequencerManager!.stopPianoNote(noteName, tracks, sequence!);
    } else {
      debugPrint('[CustomPianoPlayer#$_instanceId.handlePianoKeyUp] NOT READY. Manager: ${sequencerManager != null}, Sequence: ${sequence != null}, Tracks: ${tracks.length}');
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
