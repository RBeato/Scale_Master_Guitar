import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to control the visibility of the piano keyboard on the selection page.
/// Defaults to true (piano visible).
final pianoVisibilityProvider = StateProvider<bool>((ref) => true);
