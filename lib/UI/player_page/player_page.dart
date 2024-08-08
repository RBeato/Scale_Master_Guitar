import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test/UI/fretboard/provider/fingerings_provider.dart';
import 'package:test/UI/fretboard_page/provider/sharp_flat_selection_provider.dart';
import 'package:test/UI/player_page/logic/sequencer_manager.dart';
import 'package:test/UI/player_page/player/player_widget.dart';
import 'package:test/UI/player_page/provider/is_playing_provider.dart';
import 'package:test/UI/player_page/provider/player_page_title.dart';
import 'package:test/UI/player_page/provider/selected_chords_provider.dart';

import '../../models/chord_scale_model.dart';
import '../chords/chords.dart';
import '../fretboard/UI/fretboard_neck.dart';
import '../fretboard_page/fretboard_page.dart';
import '../fretboard_page/provider/fretboard_page_fingerings_provider.dart';

class PlayerPage extends ConsumerWidget {
  PlayerPage({super.key});

  ChordScaleFingeringsModel? f;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fingerings = ref.watch(chordModelFretboardFingeringProvider);
    final sequencerManager = ref.read(sequencerManagerProvider);

    return WillPopScope(
      onWillPop: () async {
        // Stop the sequencer
        sequencerManager.handleStop(
            sequencerManager.sequence); // Make sure sequence is accessible
        ref.read(selectedChordsProvider.notifier).removeAll();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[900],
        appBar: AppBar(
          backgroundColor: Colors.grey[800],
          title: const PlayerPageTitle(),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () {
              // Stop the sequencer and navigate back
              bool isPlaying = ref.read(isSequencerPlayingProvider);
              if (isPlaying) {
                sequencerManager.handleStop(sequencerManager
                    .sequence); // Make sure sequence is accessible
                ref.read(isSequencerPlayingProvider.notifier).state =
                    !isPlaying;
              }
              Navigator.of(context).pop();
            },
          ),
          actions: [
            IconButton(
              onPressed: () {
                if (fingerings.value!.scaleModel!.scaleNotesNames
                    .take(5)
                    .any((s) => s.contains('♭'))) {
                  ref
                      .read(sharpFlatSelectionProvider.notifier)
                      .update((state) => FretboardSharpFlat.flats);
                }
                if (f != null) {
                  ref.read(fretboardPageFingeringsProvider.notifier).update(f!);
                }

                bool isPlaying = ref.read(isSequencerPlayingProvider);
                if (isPlaying) {
                  // Stop the sequencer and navigate back
                  sequencerManager.handleStop(sequencerManager
                      .sequence); // Make sure sequence is accessible
                  ref.read(isSequencerPlayingProvider.notifier).state =
                      !isPlaying;
                }
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const FretboardPage()));
              },
              icon: const Icon(Icons.arrow_forward_ios,
                  color: Colors.orangeAccent),
            ),
          ],
        ),
        body: SafeArea(
            child: fingerings.when(
                data: (data) {
                  f = data;
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
                              child: PlayerWidget(data!.scaleModel!.settings!)),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ],
                  );
                },
                loading: () =>
                    const CircularProgressIndicator(color: Colors.orange),
                error: (error, stackTrace) => Text('Error: $error'))),
      ),
    );
  }
}
