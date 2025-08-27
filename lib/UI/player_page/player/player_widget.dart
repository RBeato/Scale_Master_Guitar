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
import '../../drawer/provider/settings_state_notifier.dart';
import '../../drawer/models/settings_state.dart';

import '../../utils/debouncing.dart' as debouncing_utils;
import '../../../utils/performance_utils.dart';
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
  
  // Add debouncer for performance optimization
  late Debouncer _chordChangeDebouncer;
  // final Set<String> _uiActivePianoNotes = {}; // No longer needed for sustain logic

  @override
  void initState() {
    super.initState();
    sequencerManager = ref.read(sequencerManagerProvider);
    _chordChangeDebouncer = Debouncer(milliseconds: 300);
    
    // Check if chords already exist when widget is created (e.g., returning from navigation)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final existingChords = ref.read(selectedChordsProvider);
        if (existingChords.isNotEmpty) {
          debugPrint('[PlayerWidget] initState: Found ${existingChords.length} existing chords, initializing sequencer');
          _performFullSequencerReinitialization(newChords: existingChords);
        } else {
          debugPrint('[PlayerWidget] initState: No existing chords found');
        }
      }
    });
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

    // Get current settings from provider instead of using static widget.settings
    final currentSettingsState = ref.read(settingsStateNotifierProvider);
    Settings currentSettings;
    if (currentSettingsState is SettingsLoaded) {
      currentSettings = currentSettingsState.settings;
    } else {
      // Fallback to widget settings if provider isn't loaded yet
      currentSettings = widget.settings;
    }
    
    final instruments = SoundPlayerUtils.getInstruments(currentSettings);
    debugPrint('[PlayerWidget] Available instruments: ${instruments.length}');
    for (int i = 0; i < instruments.length; i++) {
      debugPrint('[PlayerWidget] Instrument $i: ${instruments[i].toString()}');
    }
    
    debugPrint('[PlayerWidget] _initializeAndSetupTicker: calling sequencerManager.initialize');
    // Update the tracks reference to ensure we're using the correct tracks
    final newTracks = await sequencerManager.initialize(
      tracks: tracks, 
      sequence: sequence!, 
      playAllInstruments: true, 
      instruments: instruments,
      isPlaying: ref.read(isSequencerPlayingProvider), 
      stepCount: calculatedStepCount, 
      trackVolumes: trackVolumes,
      trackStepSequencerStates: trackStepSequencerStates,
      selectedChords: chordsToProcess, // Use passed chordsToProcess
      isLoading: isLoading, 
      isMetronomeSelected: ref.read(isMetronomeSelectedProvider),
      isScaleTonicSelected: currentSettings.isTonicUniversalBassNote,
      tempo: tempo, 
    );
    
    // CRITICAL: Update the widget's tracks reference to use the new tracks
    tracks = newTracks;
    debugPrint('[PlayerWidget] _initializeAndSetupTicker: sequencerManager.initialize complete, tracks.length = ${tracks.length}');
    
    // Debug track information
    for (int i = 0; i < tracks.length; i++) {
      final track = tracks[i];
      debugPrint('[PlayerWidget] Track $i: id=${track.id}, events=${track.events.length}');
    }

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

      // Use custom playback system position
      final double currentPluginBeat = sequencerManager.position;
      final bool currentPluginIsPlaying = sequencerManager.isPlaying;

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
            position = currentPluginBeat;
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
    
    // Check if we have valid chords to work with
    if (newChords.isEmpty) {
      debugPrint('[PlayerWidget] No chords to initialize, skipping');
      return;
    }
    
    // Debug chord content and validate
    bool hasValidChords = false;
    for (int i = 0; i < newChords.length; i++) {
      final chord = newChords[i];
      debugPrint('[PlayerWidget] Chord $i: ${chord.completeChordName}');
      debugPrint('[PlayerWidget] Chord $i notes: ${chord.chordNotesInversionWithIndexes}');
      debugPrint('[PlayerWidget] Chord $i position: ${chord.position}, duration: ${chord.duration}');
      
      if (chord.chordNotesInversionWithIndexes != null && chord.chordNotesInversionWithIndexes!.isNotEmpty) {
        hasValidChords = true;
      }
    }
    
    if (!hasValidChords) {
      debugPrint('[PlayerWidget] No valid chord notes found, skipping initialization');
      return;
    }
    
    if (!mounted) return;
    
    // Only show loading state if we're not just adding chords (i.e., initial load)
    final bool isInitializing = sequence == null || tracks.isEmpty;
    debugPrint('[PlayerWidget] isInitializing: $isInitializing, sequence: ${sequence != null}, tracks.length: ${tracks.length}');
    
    if (isInitializing) {
      setState(() {
        isLoading = true;
      });
    }

    if (sequence != null) {
      debugPrint('[PlayerWidget] Stopping existing sequence');
      await sequencerManager.handleStop(sequence!); 
    }
    if (ticker != null && ticker!.isActive) {
      debugPrint('[PlayerWidget] Disposing ticker in _performFullSequencerReinitialization');
      ticker!.dispose();
      ticker = null;
    }

    debugPrint('[PlayerWidget] About to call _initializeAndSetupTicker');
    await _initializeAndSetupTicker(chordsToProcess: newChords); // Pass newChords
    debugPrint('[PlayerWidget] _initializeAndSetupTicker completed');

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
      // Dispose debouncer first
      try {
        _chordChangeDebouncer.dispose();
      } catch (e) {
        debugPrint('[PlayerWidget] Error disposing debouncer: $e');
      }
      
      // Stop the ticker first
      if (ticker != null) {
        try {
          if (ticker!.isActive) {
            ticker!.stop();
          }
          ticker!.dispose();
          ticker = null;
        } catch (e) {
          debugPrint('[PlayerWidget] Error disposing ticker: $e');
        }
      }
      
      // Don't dispose sequencer manager during widget disposal
      // Just stop any active playback synchronously
      if (sequence != null) {
        try {
          // Use synchronous stop to avoid async issues in dispose
          sequence!.stop();
          ref.read(isSequencerPlayingProvider.notifier).update((state) => false);
        } catch (e) {
          debugPrint('[PlayerWidget] Error stopping sequence: $e');
        }
      }
      
      // Clear track references safely
      try {
        tracks.clear();
        trackStepSequencerStates.clear();
        trackVolumes.clear();
      } catch (e) {
        debugPrint('[PlayerWidget] Error clearing collections: $e');
      }
      
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
    // debugPrint('[PlayerWidget] build called. isLoading: $isLoading');
    // Watch essential providers that trigger UI changes or logic
    final isPlayingState = ref.watch(isSequencerPlayingProvider);
    final metronomeTempoState = ref.watch(metronomeTempoProvider);
    // currentBeat is watched by specific UI parts if needed, or use this.position

    // Optimized: Split complex listener into simpler, more specific listeners
    
    // Listen for settings changes - specifically keyboard sound changes
    ref.listen<SettingsState>(settingsStateNotifierProvider, (previous, next) {
      debugPrint('[PlayerWidget] Settings state changed: ${next.runtimeType}');
      
      if (previous is SettingsLoaded && next is SettingsLoaded) {
        final prevKeyboardSound = previous.settings.keyboardSound;
        final nextKeyboardSound = next.settings.keyboardSound;
        
        if (prevKeyboardSound != nextKeyboardSound) {
          debugPrint('[PlayerWidget] Keyboard sound changed: $prevKeyboardSound -> $nextKeyboardSound');
          
          // Only reinitialize if we have a valid sequence and tracks already
          if (!isLoading && sequence != null && tracks.isNotEmpty) {
            final currentChords = ref.read(selectedChordsProvider);
            if (currentChords.isNotEmpty) {
              debugPrint('[PlayerWidget] Reinitializing sequencer due to keyboard sound change');
              _performFullSequencerReinitialization(newChords: currentChords);
            }
          }
        }
      }
    });

    // Listen for chord count changes
    ref.listen<int>(selectedChordsProvider.select((chords) => chords.length), (prevCount, nextCount) {
      debugPrint('[PlayerWidget] Chord count changed: $prevCount -> $nextCount');
      
      // Prevent multiple initializations when already loading
      if (isLoading) {
        debugPrint('[PlayerWidget] Already loading, skipping chord count change');
        return;
      }
      
      final nextChords = ref.read(selectedChordsProvider);
      
      // Handle loading progression (0 -> many chords)
      if (prevCount == 0 && nextCount > 0) {
        debugPrint('[PlayerWidget] Loading progression with $nextCount chords');
        _performFullSequencerReinitialization(newChords: nextChords);
      }
      // Handle adding single chord (increment by 1)
      else if (prevCount != null && nextCount == prevCount + 1) {
        debugPrint('[PlayerWidget] Adding single chord - using full reinitialization for track consistency');
        _performFullSequencerReinitialization(newChords: nextChords);
      }
      // Handle other changes (clearing, removing chords, etc.) - use debouncing
      else if (nextCount != prevCount) {
        debugPrint('[PlayerWidget] Other chord change, using debouncer');
        _chordChangeDebouncer.run(() {
          if (!isLoading) {
            _performFullSequencerReinitialization(newChords: ref.read(selectedChordsProvider));
          }
        });
      }
    });

    // Listener for metronome selection (might also need re-init if drums are added/removed)
    ref.listen<bool>(isMetronomeSelectedProvider, (previous, next) {
      debugPrint('[PlayerWidget] isMetronomeSelectedProvider listener: $next');
      if (previous != next && !isLoading && sequence != null && tracks.isNotEmpty) {
         // When metronome changes, we need the current set of chords for re-initialization
         final currentChords = ref.read(selectedChordsProvider);
         if (currentChords.isNotEmpty) {
           _performFullSequencerReinitialization(newChords: currentChords); 
         }
      } else {
          debugPrint('[PlayerWidget] isMetronomeSelectedProvider listener: SKIPPING re-init, isLoading is true, no sequence/tracks, or value unchanged.');
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

    // debugPrint('[PlayerWidget] returning ChordPlayerBar. isPlayingState: $isPlayingState, isLoading: $isLoading');
    return ChordPlayerBar(
      selectedTrack: tracks.isEmpty ? null : tracks[0], // This needs careful review if tracks can be empty
      isLoading: isLoading,
      isPlaying: isPlayingState,
      tempo: metronomeTempoState,
      isLooping: isLooping, // isLooping is a local state field, manage it if user can change it
      clearTracks: () {
        debugPrint('[PlayerWidget] clearTracks UI action');
        if (!isLoading) {
            debouncing_utils.Debouncer.handleButtonPress(() {
                // Stop playback if sequence is currently playing
                if (sequence != null && sequencerManager.isPlaying) {
                  debugPrint('[PlayerWidget] Stopping playback before clearing tracks');
                  sequencerManager.handleTogglePlayStop(sequence!);
                }
                
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
        debugPrint('[PlayerWidget] sequence != null: ${sequence != null}');
        debugPrint('[PlayerWidget] !isLoading: ${!isLoading}');
        debugPrint('[PlayerWidget] tracks.length: ${tracks.length}');
        
        // Check if tracks have events loaded before allowing playback
        bool hasEventsLoaded = tracks.isNotEmpty && tracks.any((track) => 
          track.events.isNotEmpty);
        
        if (sequence != null && !isLoading && hasEventsLoaded) {
            debugPrint('[PlayerWidget] Calling sequencerManager.handleTogglePlayStop');
            // Remove debouncing to prevent double-press issues
            sequencerManager.handleTogglePlayStop(sequence!);
        } else {
            debugPrint('[PlayerWidget] Cannot play: sequence=${sequence != null}, isLoading=$isLoading, tracks=${tracks.length}, hasEvents=$hasEventsLoaded');
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


}
