import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/chord_scale_model.dart';

final fretboardPageDotsProvider = StateProvider<List<List<bool>>>((ref) => []);

final fretboardPageFingeringsProvider = StateNotifierProvider<
    ChordModelFretboardFingeringNotifier,
    ChordScaleFingeringsModel>((ref) => ChordModelFretboardFingeringNotifier());

class ChordModelFretboardFingeringNotifier
    extends StateNotifier<ChordScaleFingeringsModel> {
  ChordModelFretboardFingeringNotifier() : super(ChordScaleFingeringsModel());

  void addDot(int string, int fret) {
    // Implement logic to add a dot at the specified position
    // You can use the 'string' and 'fret' parameters to determine the position
    // Update the state with the changes
    final updatedModel = state.copyWith(
        // Update the state with the changes
        // For example, you can add a dot at the specified position
        );
    state = updatedModel;
  }

  void removeDot(int string, int fret) {
    // Implement logic to remove a dot at the specified position
    // You can use the 'string' and 'fret' parameters to determine the position
    // Update the state with the changes
    final updatedModel = state.copyWith(
        // Update the state with the changes
        // For example, you can remove a dot at the specified position
        );
    state = updatedModel;
  }

  void update(ChordScaleFingeringsModel updatedModel) {
    state = updatedModel;
  }
}
