import 'package:flutter_riverpod/flutter_riverpod.dart';

final scaleDropdownValueProvider = StateProvider<String>((ref) {
  return "Diatonic Major";
});
