import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scalemasterguitar/UI/player_page/provider/selected_chords_provider.dart'; 

import '../../constants/color_constants.dart';
import '../../constants/scales/scales_data_v2.dart';
import '../../models/chord_model.dart';
import '../../models/chord_scale_model.dart';
import '../../utils/music_utils.dart';
import '../fretboard/provider/beat_counter_provider.dart';
import '../fretboard/provider/fingerings_provider.dart';
import '../player_page/provider/is_playing_provider.dart';
import '../utils/debouncing.dart';
import 'info_about_chords_button.dart';

enum Taps { single, double }

class Chords extends ConsumerWidget {
  const Chords({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedChords = ref.watch(selectedChordsProvider);
    final fingerings = ref.watch(chordModelFretboardFingeringProvider);

    return fingerings.when(
        data: (ChordScaleFingeringsModel? scaleFingerings) {
          return Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    // crossAxisAlignment: CrossAxisAlignment.start,
                    children: scaleFingerings!.scaleModel!.completeChordNames
                        .asMap()
                        .entries
                        .map((entry) {
                      final index = entry.key;
                      final c = entry.value;
                      var scale = scaleFingerings.scaleModel!.scale!;
                      var mode = scaleFingerings.scaleModel!.mode!;
                      var value =
                          Scales.data[scale][mode]['scaleStepsRoman'][index];

                      return Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: SizedBox(
                          width: 45, // Set a fixed width for all containers
                          height: 45, // Set a fixed height for all containers
                          child: GestureDetector(
                            onTap: () {
                              Debouncer.handleButtonPress(() {
                                ref
                                    .read(isSequencerPlayingProvider.notifier)
                                    .update((state) => false);
                                int beats = ref.read(beatCounterProvider);
                                if (beats > 40) {
                                  showPopup(context,
                                      "You can't add more than 40 beats");
                                  return;
                                }
                                _addChord(
                                  Taps.single,
                                  ref.read(selectedChordsProvider.notifier),
                                  c,
                                  scaleFingerings,
                                  index,
                                  selectedChords,
                                );
                              });
                            },
                            onDoubleTap: () {
                              Debouncer.handleButtonPress(() {
                                ref
                                    .read(isSequencerPlayingProvider.notifier)
                                    .update((state) => false);
                                if (ref.read(beatCounterProvider) > 40) {
                                  showPopup(context,
                                      "You can't add more than 40 beats");
                                  return;
                                }
                                _addChord(
                                  Taps.double,
                                  ref.read(selectedChordsProvider.notifier),
                                  c,
                                  scaleFingerings,
                                  index,
                                  selectedChords,
                                );
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: ConstantColors.scaleColorMap[value]
                                    .withOpacity(0.6),
                                borderRadius: BorderRadius.circular(
                                    10), // Add rounded corners
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ), // Add a white border
                              ),
                              child: Center(
                                child: FittedBox(
                                  child: Text(
                                    c,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const InfoAboutChordsIcon(),
                ],
              ),
            ),
          );
        },
        loading: () => const CircularProgressIndicator(color: Colors.orange),
        error: (error, stackTrace) => Text('Error: $error'));
  }

  calculateNumberBeats(List<ChordModel> chordList) {
    int count = 0;
    for (var chord in chordList) {
      count += chord.duration;
    }
    return count;
  }

  _addChord(
    Taps tap,
    provider,
    c,
    scaleFingerings,
    index,
    alreadySelectedChords,
  ) {
    var chord =
        addChordModel(tap, c, scaleFingerings, index, alreadySelectedChords);

    provider.addChord(chord);
  }

  addChordModel(
      tap,
      String uiChordName,
      ChordScaleFingeringsModel scaleFingerings,
      index,
      List<ChordModel> alreadySelectedChords) {
    var chordNotes = MusicUtils.getChordInfo(scaleFingerings, index);
    debugPrint("chordNotes: $chordNotes");

    var position = alreadySelectedChords.isEmpty
        ? 0
        : alreadySelectedChords.last.position +
            alreadySelectedChords.last.duration;

    ChordModel? chord = ChordModel(
        id: position,
        noteName: scaleFingerings.scaleModel!.completeChordNames[index], //
        duration: tap == Taps.single ? 2 : 4,
        mode: scaleFingerings.scaleModel!.mode!,
        position: position,
        chordNotesWithIndexesRaw: chordNotes,
        chordFunction: scaleFingerings.scaleModel!.chordTypes[index],
        chordDegree: scaleFingerings.scaleModel!.degreeFunction[index],
        completeChordName: uiChordName,
        scale: scaleFingerings.scaleModel!.scale!,
        originalScaleType: scaleFingerings.scaleModel!.scale!,
        parentScaleKey: scaleFingerings.scaleModel!.parentScaleKey,
        selectedChordPitches: MusicUtils.cleanNotesIndexes(chordNotes)
            .map((n) => MusicUtils.flatsAndSharpsToFlats(n) as String)
            .toList(),
        chordNotesInversionWithIndexes: []);

    return chord;
  }

  showPopup(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text("Too many beats!",
              style: TextStyle(color: Colors.orange)),
          content: Text(message, style: const TextStyle(color: Colors.white)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }
}
