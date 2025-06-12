import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scalemasterguitar/UI/fretboard/provider/fingerings_provider.dart';
import 'package:scalemasterguitar/UI/fretboard_page/provider/sharp_flat_selection_provider.dart';
import 'package:scalemasterguitar/UI/player_page/logic/sequencer_manager.dart';
import 'package:scalemasterguitar/UI/player_page/player/player_widget.dart';
import 'package:scalemasterguitar/UI/player_page/provider/is_playing_provider.dart';
import 'package:scalemasterguitar/UI/player_page/provider/player_page_title.dart';
import 'package:scalemasterguitar/UI/player_page/provider/selected_chords_provider.dart';  

import '../../models/chord_scale_model.dart';
import '../../models/progression_model.dart';
import '../progression_library/progression_library_page.dart';
import '../chords/chords.dart';
import '../fretboard/UI/fretboard_neck.dart';
import '../fretboard_page/fretboard_page.dart';
import '../fretboard_page/provider/fretboard_page_fingerings_provider.dart';
import '../chromatic_wheel/provider/top_note_provider.dart';
import '../scale_selection_dropdowns/provider/scale_dropdown_value_provider.dart';
import '../scale_selection_dropdowns/provider/mode_dropdown_value_provider.dart';
import '../fretboard/provider/beat_counter_provider.dart';
import '../home_page/selection_page.dart';
import '../../services/feature_restriction_service.dart';
import '../../UI/common/upgrade_prompt.dart';

class PlayerPage extends ConsumerWidget {
  final ProgressionModel? initialProgression;
  
  const PlayerPage({super.key, this.initialProgression});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _PlayerPageContent(initialProgression: initialProgression);
  }
}

class _PlayerPageContent extends ConsumerStatefulWidget {
  final ProgressionModel? initialProgression;
  
  const _PlayerPageContent({super.key, this.initialProgression});
  
  @override
  _PlayerPageContentState createState() => _PlayerPageContentState();
}

class _PlayerPageContentState extends ConsumerState<_PlayerPageContent> {
  bool _isDisposed = false;
  
  @override
  void initState() {
    super.initState();
    // Load initial progression if provided
    if (widget.initialProgression != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadProgression(widget.initialProgression!);
      });
    }
  }
  
  void _loadProgression(ProgressionModel progression) {
    try {
      debugPrint('[PlayerPage] Loading progression: ${progression.name} with ${progression.chords.length} chords');
      
      // Validate progression data
      if (progression.chords.isEmpty) {
        debugPrint('[PlayerPage] ERROR: Progression has no chords');
        return;
      }
      
      // Validate each chord has required data
      for (int i = 0; i < progression.chords.length; i++) {
        final chord = progression.chords[i];
        if (chord.completeChordName?.isEmpty ?? true) {
          debugPrint('[PlayerPage] ERROR: Chord $i has invalid name: ${chord.completeChordName}');
          return;
        }
        if (chord.selectedChordPitches?.isEmpty ?? true) {
          debugPrint('[PlayerPage] ERROR: Chord $i has no pitches: ${chord.selectedChordPitches}');
          return;
        }
      }
      
      // Check if widget is still mounted before proceeding
      if (!mounted) {
        debugPrint('[PlayerPage] Widget not mounted, aborting progression load');
        return;
      }
      
      // Clear existing chords first
      ref.read(selectedChordsProvider.notifier).removeAll();
      
      // Update scale context based on the first chord
      final firstChord = progression.chords.first;
      debugPrint('[PlayerPage] Setting scale context from first chord: ${firstChord.parentScaleKey} ${firstChord.scale} ${firstChord.mode}');
      
      // Update scale providers to match the progression
      ref.read(topNoteProvider.notifier).update((state) => firstChord.parentScaleKey);
      ref.read(scaleDropdownValueProvider.notifier).update((state) => firstChord.scale);
      ref.read(modeDropdownValueProvider.notifier).update((state) => firstChord.mode);
      
      // Update beat counter to match progression total beats
      final totalBeats = progression.totalBeats;
      debugPrint('[PlayerPage] Setting beat counter to: $totalBeats');
      ref.read(beatCounterProvider.notifier).update((state) => totalBeats);
      
      // Add a small delay to ensure the clear operation and scale updates complete
      Future.delayed(const Duration(milliseconds: 150), () {
        // Double-check widget is still mounted before proceeding with async operation  
        if (!mounted) {
          debugPrint('[PlayerPage] Widget unmounted during async load, aborting');
          return;
        }
        
        try {
          // Log progression details with null safety
          for (final chord in progression.chords) {
            debugPrint('[PlayerPage] Loaded chord: ${chord.completeChordName ?? "Unknown"}');
            debugPrint('[PlayerPage] Chord notes: ${chord.chordNotesInversionWithIndexes}');
          }
          
          // Add all chords at once using updateProgression to avoid multiple reinitializations
          ref.read(selectedChordsProvider.notifier).updateProgression(progression.chords);
          
          // Force a rebuild to ensure the PlayerWidget initializes with the new chords
          if (mounted) {
            setState(() {});
          }
        } catch (e, stackTrace) {
          debugPrint('[PlayerPage] ERROR during delayed progression loading: $e');
          debugPrint('[PlayerPage] Stack trace: $stackTrace');
        }
      });
    } catch (e, stackTrace) {
      debugPrint('[PlayerPage] ERROR loading progression: $e');
      debugPrint('[PlayerPage] Stack trace: $stackTrace');
    }
  }
  
  // Helper method to clean up resources - but preserve user data
  Future<void> _cleanupResources() async {
    debugPrint('[PlayerPage] Cleaning up resources...');
    final sequencerManager = ref.read(sequencerManagerProvider);
    
    try {
      // Stop the sequencer if it's playing
      final isPlaying = ref.read(isSequencerPlayingProvider);
      if (isPlaying && sequencerManager.sequence != null) {
        debugPrint('[PlayerPage] Stopping sequencer during cleanup');
        await sequencerManager.handleStop(sequencerManager.sequence!);
        ref.read(isSequencerPlayingProvider.notifier).state = false;
      }
      
      // IMPORTANT: Don't clear chords! User data should persist across navigation
      // ref.read(selectedChordsProvider.notifier).removeAll(); // REMOVED - this was the bug!
      
      debugPrint('[PlayerPage] Cleanup completed');
    } catch (e, st) {
      debugPrint('[PlayerPage] Error during cleanup: $e\n$st');
    }
  }

  @override
  void dispose() {
    if (!_isDisposed) {
      debugPrint('[PlayerPage] dispose called');
      _isDisposed = true;
      // _cleanupResources() REMOVED: Do not use ref after dispose
    }
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    debugPrint('[PlayerPage] build called');
    final fingerings = ref.watch(chordModelFretboardFingeringProvider);
    final sequencerManager = ref.read(sequencerManagerProvider);
    debugPrint('[PlayerPage] sequencerManager.sequence: \\${sequencerManager.sequence}');
    // debugPrint('[PlayerPage] fingerings state: \\${fingerings}');

    // PopScope for back button handling
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          debugPrint('[PlayerPage] PopScope triggered');
          // Cleanup sequencer but preserve user chords
          _cleanupResources();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[900],
        appBar: AppBar(
          backgroundColor: Colors.grey[800],
          title: const PlayerPageTitle(),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () async {
              debugPrint('[PlayerPage] Back button pressed');
              // Cleanup sequencer but preserve user chords
              await _cleanupResources();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SelectionPage()),
                );
                debugPrint('[PlayerPage] Navigated back to selection page');
              }
            },
          ),
          actions: [
            Consumer(
              builder: (context, ref, child) {
                final canSaveProgressions = ref.watch(featureRestrictionProvider('save_progressions'));
                
                return IconButton(
                  onPressed: () {
                    if (!canSaveProgressions) {
                      UpgradePrompt.showUpgradeAlert(
                        context,
                        title: 'Premium Feature',
                        message: FeatureRestrictionService.getProgressionSaveRestrictionMessage(),
                      );
                      return;
                    }
                    
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProgressionLibraryPage(),
                      ),
                    );
                  },
                  icon: Stack(
                    children: [
                      Icon(
                        Icons.library_music, 
                        color: canSaveProgressions ? Colors.white : Colors.grey[600]
                      ),
                      if (!canSaveProgressions)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 8,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            IconButton(
              onPressed: () async {
                debugPrint('[PlayerPage] Forward button pressed');
                
                // Update fingerings if available - do this immediately
                final fingeringsValue = fingerings.value;
                if (fingeringsValue != null && fingeringsValue.scaleModel != null) {
                  if (fingeringsValue.scaleModel!.scaleNotesNames.take(5).any((s) => s.contains('♭'))) {
                    ref.read(sharpFlatSelectionProvider.notifier).update((state) => FretboardSharpFlat.flats);
                  }
                  // Update fretboardPageFingeringsProvider safely
                  ref.read(fretboardPageFingeringsProvider.notifier).update(fingeringsValue);
                }

                // Cleanup sequencer but preserve user chords
                await _cleanupResources();
                
                if (context.mounted) {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const FretboardPage()));
                  debugPrint('[PlayerPage] Navigated forward to FretboardPage');
                }
              },
              icon: const Icon(Icons.arrow_forward_ios,
                  color: Colors.orangeAccent),
            ),
          ],
        ),
        body: SafeArea(
            child: fingerings.when(
                data: (data) {
                  debugPrint('[PlayerPage] fingerings.when: data received');
                  // Defensive: Check for nulls in data, scaleModel, and settings
                  if (data == null || data.scaleModel == null || data.scaleModel!.settings == null) {
                    debugPrint('[PlayerPage] Error: Missing data, scaleModel, or settings.');
                    return const Center(child: Text('Missing player data. Please check your selection.'));
                  }
                  // Defensive: Only update provider if data is present in navigation
                  final ChordScaleFingeringsModel safeFingerings = data;
                  return Stack(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          const SizedBox(height: 30),
                          Fretboard(),
                          const Expanded(
                              flex: 6, child: Center(child: Chords())),
                          Expanded(
                              flex: 8,
                              child: Builder(
                                builder: (context) {
                                  debugPrint('[PlayerPage] Building PlayerWidget');
                                  // Defensive: Only pass non-null settings to PlayerWidget
                                  if (data.scaleModel != null && data.scaleModel!.settings != null) {
                                    return PlayerWidget(data.scaleModel!.settings!);
                                  } else {
                                    return const Center(child: Text('Error: Missing settings.'));
                                  }
                                },
                              )),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ],
                  );
                },
                loading: () {
                  debugPrint('[PlayerPage] fingerings.when: loading');
                  return const CircularProgressIndicator(color: Colors.orange);
                },
                error: (error, stackTrace) {
                  debugPrint('[PlayerPage] fingerings.when: error: $error');
                  return Text('Error: $error');
                })),
      ),
    );
  }
}
