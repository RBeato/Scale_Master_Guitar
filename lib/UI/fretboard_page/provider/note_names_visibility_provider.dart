import 'package:flutter_riverpod/flutter_riverpod.dart';

// Define a provider to manage the state of note names visibility
final noteNamesVisibilityProvider = StateProvider<bool>((ref) => false);
