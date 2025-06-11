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
    debugPrint('[PlayerPage] Loading progression: ${progression.name} with ${progression.chords.length} chords');
    
    // Clear existing chords first
    ref.read(selectedChordsProvider.notifier).removeAll();
    
    // Add a small delay to ensure the clear operation completes
    Future.delayed(const Duration(milliseconds: 100), () {
      // Add each chord from the progression
      for (final chord in progression.chords) {
        debugPrint('[PlayerPage] Adding loaded chord: ${chord.completeChordName}');
        debugPrint('[PlayerPage] Chord notes before adding: ${chord.chordNotesInversionWithIndexes}');
        ref.read(selectedChordsProvider.notifier).addChord(chord);
      }
      
      // Force a rebuild to ensure the PlayerWidget initializes with the new chords
      if (mounted) {
        setState(() {});
      }
    });
  }
  
  // Helper method to clean up resources
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
      
      // NOTE: Don't clear chords during navigation cleanup!
      // The chords should persist unless user explicitly clears them
      
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
          debugPrint('[PlayerPage] PopScope triggered - navigation handled');
          // Don't clear user data on navigation
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[900],
        appBar: AppBar(
          backgroundColor: Colors.grey[800],
          title: const PlayerPageTitle(),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () {
              debugPrint('[PlayerPage] Back button pressed');
              // Just navigate - don't clear user data
              Navigator.of(context).pop();
              debugPrint('[PlayerPage] Navigated back');
            },
          ),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProgressionLibraryPage(),
                  ),
                );
              },
              icon: const Icon(Icons.library_music, color: Colors.white),
            ),
            IconButton(
              onPressed: () {
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

                // Navigate without clearing user data
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const FretboardPage()));
                debugPrint('[PlayerPage] Navigated forward to FretboardPage');
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
