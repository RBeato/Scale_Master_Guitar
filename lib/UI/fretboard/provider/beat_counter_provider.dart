import 'package:flutter_riverpod/flutter_riverpod.dart';

final beatCounterProvider = StateProvider<int>((ref) => 1);

final currentBeatProvider = StateProvider<int>((ref) => 0);
