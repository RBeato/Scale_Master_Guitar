import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final scaleDropdownValueProvider = StateProvider<String>((ref) {
  debugPrint("scaleDropdownValueProvider changed");
  return "Diatonic Major";
});
