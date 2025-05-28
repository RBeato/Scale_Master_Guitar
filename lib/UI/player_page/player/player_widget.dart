import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/material.dart';

import 'package:flutter_sequencer/sequence.dart';
import 'package:flutter_sequencer/track.dart';
import 'package:flutter/scheduler.dart';
import 'package:scalemasterguitar/UI/player_page/logic/sequencer_manager.dart';
import 'package:scalemasterguitar/UI/player_page/provider/selected_chords_provider.dart';
import 'package:scalemasterguitar/utils/player_utils.dart';
import 'package:scalemasterguitar/models/chord_model.dart';

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
    with TickerProviderStateMixin {
  Map<int, StepSequencerState> trackStepSequencerStates = {};
  List<Track> tracks = [];
  Map<int, double> trackVolumes = {};
  // Track? selectedTrack;
  Ticker? ticker;
  late SequencerManager sequencerManager;
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
    sequencerManager = ref.read(sequencerManagerProvider);
    // initializeSequencer(); // Defer to first chord or explicit play action
    // Initial setup might not need full sequencer init if no chords are present initially
    // Consider if Ticker should only start when sequence is actually ready and playing.
  }

  Future<void> _initializeAndSetupTicker({required List<ChordModel> chordsToProcess}) async {
    debugPrint('[PlayerWidget] _initializeAndSetupTicker: called with ${chordsToProcess.length} chords');
    if (!mounted) return;

    // Use the passed chordsToProcess directly
    int calculatedStepCount = chordsToProcess.isNotEmpty
        ? chordsToProcess.fold(0, (prev, chord) {
            final endPosition = chord.position + chord.duration;
            return endPosition > prev ? endPosition : prev;
          })
        : ref.read(beatCounterProvider); 

    if (calculatedStepCount == 0 && chordsToProcess.isNotEmpty) {
        calculatedStepCount = chordsToProcess.first.duration;
    }
    if (calculatedStepCount == 0) calculatedStepCount = ref.read(beatCounterProvider);
    if (calculatedStepCount == 0) calculatedStepCount = 4; 

    debugPrint('[PlayerWidget] _initializeAndSetupTicker: Calculated stepCount = $calculatedStepCount for ${chordsToProcess.length} chords');

    tempo = ref.read(metronomeTempoProvider);
    sequence = Sequence(tempo: tempo, endBeat: calculatedStepCount.toDouble());

    debugPrint('[PlayerWidget] _initializeAndSetupTicker: calling sequencerManager.initialize');
    tracks = await sequencerManager.initialize(
      tracks: tracks, 
      sequence: sequence!, 
      playAllInstruments: true, 
      instruments: SoundPlayerUtils.getInstruments(widget.settings),
      isPlaying: ref.read(isSequencerPlayingProvider), 
      stepCount: calculatedStepCount, 
      trackVolumes: trackVolumes,
      trackStepSequencerStates: trackStepSequencerStates,
      selectedChords: chordsToProcess, // Use passed chordsToProcess
      isLoading: isLoading, 
      isMetronomeSelected: ref.read(isMetronomeSelectedProvider),
      isScaleTonicSelected: widget.settings.isTonicUniversalBassNote,
      tempo: tempo, 
    );
    debugPrint('[PlayerWidget] _initializeAndSetupTicker: sequencerManager.initialize complete, tracks.length = ${tracks.length}');

    // Dispose old ticker if exists before creating a new one
    if (ticker != null && ticker!.isActive) {
      debugPrint('[PlayerWidget] Disposing old ticker before creating new one in _initializeAndSetupTicker');
      ticker!.dispose();
    }
    
    if (!mounted) return;
    debugPrint('[PlayerWidget] _initializeAndSetupTicker: creating ticker');
    ticker = createTicker((Duration elapsed) {
      if (!mounted || sequence == null) {
        // If sequence becomes null or widget unmounted, stop ticker implicitly by returning
        // Consider explicitly stopping ticker if sequence is disposed elsewhere.
        return;
      }

      final double currentPluginBeat = sequence!.getBeat();
      final bool currentPluginIsPlaying = sequence!.getIsPlaying();

      final int currentBeatInt = currentPluginBeat.toInt();
      if (ref.read(currentBeatProvider) != currentBeatInt) {
        ref.read(currentBeatProvider.notifier).update((state) => currentBeatInt);
      }
      
      final bool riverpodIsPlaying = ref.read(isSequencerPlayingProvider);
      if (currentPluginIsPlaying != riverpodIsPlaying) {
        ref.read(isSequencerPlayingProvider.notifier).update((state) => currentPluginIsPlaying);
      }

      if (mounted) {
          setState(() {
            this.position = currentPluginBeat;
            // isLoading = false; // isLoading should be managed by the async operations themselves
          });
      }
    });
    ticker!.start();
    debugPrint('[PlayerWidget] _initializeAndSetupTicker: ticker started');
    if (!mounted) return;
    // isLoading is set to false at the end of the calling method (e.g., getSequencer or after listener)
  }

  // Replace initializeSequencer and getSequencer with a single method that does full init
  Future<void> _performFullSequencerReinitialization({required List<ChordModel> newChords}) async {
    debugPrint('[PlayerWidget] _performFullSequencerReinitialization: start with ${newChords.length} chords');
    if (!mounted) return;
    
    // Only show loading state if we're not just adding chords (i.e., initial load)
    final bool isInitializing = sequence == null || tracks.isEmpty;
    
    if (isInitializing) {
      setState(() {
        isLoading = true;
      });
    }

    if (sequence != null) {
      sequencerManager.handleStop(sequence!); 
    }
    if (ticker != null && ticker!.isActive) {
      debugPrint('[PlayerWidget] Disposing ticker in _performFullSequencerReinitialization');
      ticker!.dispose();
      ticker = null;
    }

    await _initializeAndSetupTicker(chordsToProcess: newChords); // Pass newChords

    if (!mounted) return;
    if (isInitializing) {
      setState(() {
        isLoading = false;
      });
    }
    debugPrint('[PlayerWidget] _performFullSequencerReinitialization: end');
  }

  @override
  void dispose() {
    debugPrint('[PlayerWidget] Disposing: stopping sequencer and cleaning up tracks');
    try {
      // Stop the ticker first
      if (ticker != null) {
        if (ticker!.isActive) {
          ticker!.stop();
        }
        ticker!.dispose();
        ticker = null;
      }
      
      // Stop any playing audio and clean up the sequencer
      if (sequence != null) {
        try {
          // Stop the sequence if it's playing
          if (sequence!.getIsPlaying()) {
            sequence!.stop();
          }
          
          // Stop all active notes on all tracks
          for (final track in sequence!.getTracks()) {
            try {
              // Clear any pending events
              track.clearEvents();
              
              // Stop any playing notes
              for (int note = 0; note < 128; note++) {
                try {
                  track.stopNoteNow(noteNumber: note);
                } catch (e) {
                  debugPrint('[PlayerWidget] Error stopping note $note: $e');
                }
              }
            } catch (e) {
              debugPrint('[PlayerWidget] Error cleaning up track: $e');
            }
          }
          
          // Sequence cleanup complete
        } catch (e, st) {
          debugPrint('[PlayerWidget] Error stopping sequence: $e\n$st');
        }
      }
      
      // Clear track references
      tracks.clear();
      trackStepSequencerStates.clear();
      trackVolumes.clear();
      
      debugPrint('[PlayerWidget] Cleanup complete');
    } catch (e, st) {
      debugPrint('[PlayerWidget] Error during dispose: $e\n$st');
    } finally {
      // Always call super.dispose()
      super.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[PlayerWidget] build called. isLoading: $isLoading');
    // Watch essential providers that trigger UI changes or logic
    final isPlayingState = ref.watch(isSequencerPlayingProvider);
    final selectedChordsState = ref.watch(selectedChordsProvider);
    final metronomeTempoState = ref.watch(metronomeTempoProvider);
    final isMetronomeSelectedState = ref.watch(isMetronomeSelectedProvider);
    // currentBeat is watched by specific UI parts if needed, or use this.position

    // Listener for selectedChords changes
    ref.listen<List<ChordModel>>(selectedChordsProvider, (previousChords, nextChords) {
      debugPrint('[PlayerWidget] selectedChordsProvider listener: prev=${previousChords?.length}, next=${nextChords.length}');
      
      // Skip reinitialization if we're just adding a chord (nextChords is one longer than previous)
      final isJustAddingChord = previousChords != null && 
                              nextChords.length == previousChords.length + 1 &&
                              nextChords.sublist(0, previousChords.length).every(
                                (chord) => previousChords.contains(chord)
                              );
      
      if (isJustAddingChord) {
        debugPrint('[PlayerWidget] Just adding a chord, skipping full reinitialization');
        // Just update the sequence with the new chord without showing loading state
        _updateSequenceWithNewChord(nextChords);
      } else if (!isLoading) {
        _performFullSequencerReinitialization(newChords: nextChords);
      } else {
        debugPrint('[PlayerWidget] selectedChordsProvider listener: SKIPPING re-init, isLoading is true.');
      }
    });

    // Listener for metronome selection (might also need re-init if drums are added/removed)
    ref.listen<bool>(isMetronomeSelectedProvider, (previous, next) {
      debugPrint('[PlayerWidget] isMetronomeSelectedProvider listener: $next');
      if (previous != next && !isLoading) {
         // When metronome changes, we need the current set of chords for re-initialization
         final currentChords = ref.read(selectedChordsProvider);
         _performFullSequencerReinitialization(newChords: currentChords); 
      } else {
          debugPrint('[PlayerWidget] isMetronomeSelectedProvider listener: SKIPPING re-init, isLoading is true or value unchanged.');
      }
    });
    
    // Listener for tempo changes (more lightweight update)
    ref.listen<double>(metronomeTempoProvider, (previous, next) {
        debugPrint('[PlayerWidget] metronomeTempoProvider listener: $next');
        if (previous != next && sequence != null) {
            tempo = next; // Update local tempo state if needed by anything else
            sequencerManager.handleTempoChange(next, sequence!); // Tell SM to update plugin
        }
    });

    debugPrint('[PlayerWidget] returning ChordPlayerBar. isPlayingState: $isPlayingState, isLoading: $isLoading');
    return ChordPlayerBar(
      selectedTrack: tracks.isEmpty ? null : tracks[0], // This needs careful review if tracks can be empty
      isLoading: isLoading,
      isPlaying: isPlayingState,
      tempo: metronomeTempoState,
      isLooping: isLooping, // isLooping is a local state field, manage it if user can change it
      clearTracks: () {
        debugPrint('[PlayerWidget] clearTracks UI action');
        if (!isLoading) {
            Debouncer.handleButtonPress(() {
                // setState(() { isLoading = true; }); // isLoading set by _performFullSequencerReinitialization
                ref.read(selectedChordsProvider.notifier).removeAll(); 
                // The listener for selectedChordsProvider will pick up the empty list 
                // and call _performFullSequencerReinitialization.
                // No need to set isLoading false here, it's handled by the re-init method.
            });
        }
      },
      handleTogglePlayStop: () {
        debugPrint('[PlayerWidget] handleTogglePlayStop UI action');
        if (sequence != null && !isLoading) {
            Debouncer.handleButtonPress(() {
                sequencerManager.handleTogglePlayStop(sequence!); 
            });
        }
      },
    );
  }

  // updateSequencer and old initializeSequencer/getSequencer are effectively replaced by 
  // _performFullSequencerReinitialization and the listeners.

  void handlePianoKeyDown(String noteName) {
    final String widgetContext = 'PlayerWidget.handlePianoKeyDown';
    debugPrint('[$widgetContext] Received KEY DOWN for note: $noteName');
    if (sequence != null && tracks.isNotEmpty && !isLoading) {
      sequencerManager.playPianoNote(noteName, tracks, sequence!); 
    } else {
      debugPrint('[$widgetContext] Sequence/tracks issue or isLoading, cannot play note.');
    }
  }

  void handlePianoKeyUp(String noteName) {
    final String widgetContext = 'PlayerWidget.handlePianoKeyUp';
    debugPrint('[$widgetContext] Received KEY UP for note: $noteName');
    if (sequence != null && tracks.isNotEmpty && !isLoading) {
      sequencerManager.stopPianoNote(noteName, tracks, sequence!); 
    } else {
      debugPrint('[$widgetContext] Sequence/tracks issue or isLoading, cannot stop note.');
    }
  }

  // Update sequence with a new chord without showing loading state
  Future<void> _updateSequenceWithNewChord(List<ChordModel> chords) async {
    debugPrint('[PlayerWidget] _updateSequenceWithNewChord: updating with ${chords.length} chords');
    if (sequence == null || tracks.isEmpty) {
      // If we don't have a valid sequence yet, do a full initialization
      await _performFullSequencerReinitialization(newChords: chords);
      return;
    }

    try {
      // Stop any current playback
      final wasPlaying = ref.read(isSequencerPlayingProvider);
      sequencerManager.handleStop(sequence!);
      
      // Clear existing tracks
      sequencerManager.clearEverything(tracks, sequence!);
      
      // Calculate the required step count based on the chords
      final calculatedStepCount = chords.fold(0, (prev, chord) {
        final endPosition = chord.position + chord.duration;
        return endPosition > prev ? endPosition : prev;
      });

      // Create a new sequence with the updated step count
      sequence!.setEndBeat(calculatedStepCount.toDouble());
      
      // Re-initialize tracks with the new chords
      await _initializeAndSetupTicker(chordsToProcess: chords);
      
      // Restart playback if it was playing
      if (wasPlaying) {
        sequence!.play();
        ref.read(isSequencerPlayingProvider.notifier).update((state) => true);
      }
    } catch (e, stackTrace) {
      debugPrint('Error updating sequence with new chord: $e');
      debugPrint(stackTrace.toString());
      // Fall back to full reinitialization if update fails
      await _performFullSequencerReinitialization(newChords: chords);
    }
  }
}
