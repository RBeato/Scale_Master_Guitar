import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/chord_model.dart';

import '../../fretboard/provider/beat_counter_provider.dart';
import '../../fretboard/service/chord_progression_voice_leading_creator.dart';

final selectedChordsProvider =
    StateNotifierProvider<SelectedChords, List<ChordModel>>(
  (ref) {
    return SelectedChords(ref);
  },
);

class SelectedChords extends StateNotifier<List<ChordModel>> {
  SelectedChords(this.ref, [List<ChordModel>? selectedItems])
      : super(selectedItems ?? []);

  final StateNotifierProviderRef ref;

  List<ChordModel> get selectedItemsList => state;

  void addChord(ChordModel chordModel) {
    updateChords(chordModel);
  }

  void updateProgression(List<ChordModel>? chords) {
    state = VoiceLeadingCreator.buildProgression(chords ?? state);
  }

  updateChords([ChordModel? chordModel]) {
    List<ChordModel> temp = [...state];

    if (chordModel != null) {
      // Voice only the new chord relative to the existing progression.
      // This avoids re-voicing all existing chords with a new random
      // inversion, which would destabilize voicings and increase the
      // chance of shared notes at chord boundaries (causing playback
      // issues on iOS Dart scheduling).
      VoiceLeadingCreator.voiceNewChord(temp, chordModel);
      temp.add(chordModel);
      state = temp;
    } else {
      updateProgression(temp);
    }

    int sum =
        state.fold(0, (previousValue, item) => previousValue + item.duration);

    ref.read(beatCounterProvider.notifier).update((state) => sum);
  }

  // List<ChordModel> filterChords(
  //     List<String> extensions, List<ChordModel> chords) {
  //   final extensionIndexes = {
  //     '7': 3,
  //     '9': 4,
  //     '11': 5,
  //     '13': 6,
  //   };

  //   var c = chords.map((chord) {
  //     List<String> updatedPitches =
  //         chord.allChordExtensions?.take(3).toList() ?? [];

  //     for (var ext in extensions) {
  //       final index = extensionIndexes[ext];
  //       if (index != null) {
  //         updatedPitches.add(chord.allChordExtensions![index]);
  //       }
  //     }
  //     return chord.copyWith(pitches: updatedPitches);
  //   }).toList();
  //   return c;
  // }

  void removeAll() {
    state = [];
  }
}
