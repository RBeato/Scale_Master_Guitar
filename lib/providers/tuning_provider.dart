import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/instrument_presets.dart';
import '../models/instrument_tuning.dart';

const String _tuningPrefsKey = 'selected_tuning';

class TuningNotifier extends StateNotifier<InstrumentTuning> {
  TuningNotifier() : super(InstrumentPresets.defaultTuning) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final tuningJson = prefs.getString(_tuningPrefsKey);
    if (tuningJson != null) {
      try {
        state = InstrumentTuning.fromJson(jsonDecode(tuningJson));
      } catch (e) {
        // If parsing fails, keep default tuning
        state = InstrumentPresets.defaultTuning;
      }
    }
  }

  Future<void> setTuning(InstrumentTuning tuning) async {
    state = tuning;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tuningPrefsKey, jsonEncode(tuning.toJson()));
  }

  Future<void> resetToDefault() async {
    await setTuning(InstrumentPresets.defaultTuning);
  }
}

final tuningProvider =
    StateNotifierProvider<TuningNotifier, InstrumentTuning>((ref) {
  return TuningNotifier();
});
