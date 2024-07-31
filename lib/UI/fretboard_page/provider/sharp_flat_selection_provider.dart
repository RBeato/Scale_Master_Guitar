import 'package:flutter_riverpod/flutter_riverpod.dart';

enum FretboardSharpFlat { flats, sharps }

final sharpFlatSelectionProvider =
    StateProvider<FretboardSharpFlat?>((ref) => null);
