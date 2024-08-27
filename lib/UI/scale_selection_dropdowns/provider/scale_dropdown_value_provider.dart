import 'package:flutter_riverpod/flutter_riverpod.dart';

final scaleDropdownValueProvider = StateProvider<String>((ref) {
  print("scaleDropdownValueProvider changed");
  return "Diatonic Major";
});
