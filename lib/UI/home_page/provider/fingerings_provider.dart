import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test/models/chord_scale_model.dart';

import '../../fretboard/provider/fingerings_provider.dart';

class FingeringsNotifier
    extends StateNotifier<AsyncValue<ChordScaleFingeringsModel?>> {
  FingeringsNotifier(Ref ref) : super(const AsyncValue.loading()) {
    loadFingerings(ref);
  }

  Future<void> loadFingerings(Ref ref) async {
    try {
      final fingerings =
          await ref.read(chordModelFretboardFingeringProvider.future);
      state = AsyncValue.data(fingerings);
    } catch (error) {
      print("Error fetching fingerings data");
    }
  }

  void updateFingerings(ChordScaleFingeringsModel newFingerings) {
    state = AsyncValue.data(newFingerings);
  }
}

final fingeringsProvider = StateNotifierProvider<FingeringsNotifier,
    AsyncValue<ChordScaleFingeringsModel?>>(
  (ref) => FingeringsNotifier(ref),
);
