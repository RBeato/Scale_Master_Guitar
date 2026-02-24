import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/tuning_provider.dart';

final numberStringsProvider = Provider((ref) {
  final tuning = ref.watch(tuningProvider);
  return tuning.stringCount;
});
